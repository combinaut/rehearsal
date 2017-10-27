require 'uri'

module Rehearsal
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      @original_env = env.dup
      @request_env = env
      @redirects_followed = []
      request = Rack::Request.new(@request_env)

      if rehearsal?(request)
        rehearse(request) { process_request(request) }
      else
        process_request(request)
      end
    end

    private

    def rehearse(request)
      ActiveRecord::Base.logger.info "Rehearsal beginning"
      response = nil
      ActiveRecord::Base.transaction do
        response = objectify_response(yield)
        if response.successful? || response.redirect?
          preview_url = preview_url(request)
          response = request_url(preview_url) if preview_url
          response = follow_redirect(response) while response.redirect?
        end

        raise ActiveRecord::Rollback
      end
      ActiveRecord::Base.logger.info "Rehearsal ending"

      return [response.status, response.header, response.body]
    end

    def rehearsal?(request)
      case Configuration.trigger
      when Proc
        Configuration.trigger.call(request)
      else
        Configuration.trigger
      end
    end

    def preview_url(request)
      return request.params['preview_url'] if request.params.key?('preview_url')
      case Configuration.preview_url
      when Symbol
        action_controller.send(Configuration.preview_url)
      when Proc
        Configuration.preview_url.call(action_controller)
      else
        Configuration.preview_url
      end
    end

    def follow_redirect(response)
      @redirects_followed << response.location
      if @redirects_followed.count > Configuration.redirect_limit
        raise TooManyRedirectsError, "Exceeded redirect limit of #{Configuration.redirect_limit}: #{redirect_history}"
      elsif @redirects_followed.count(response.location) > 1
        raise RedirectLoopError, "Redirect loop detected: #{redirect_history}"
      end
      request_url(response.location)
    end

    def request_url(url)
      uri = URI(url)
      params = Rack::Utils.parse_query(uri.query)
      request = ActionDispatch::Request.new @original_env.dup.merge({
        'rehearsal.preview' => true,
        'REQUEST_METHOD' => 'GET',
        'REQUEST_URI' => url,
        'REQUEST_PATH' => uri.path,
        'PATH_INFO' => uri.path,
        'QUERY_STRING' => uri.query
      })

      return objectify_response(process_request(request))
    end

    def process_request(request)
      @app.call(request.env)
    end

    def objectify_response(response)
      Rack::Response.new(response[2], response[0], response[1])
    end

    def action_controller
      @request_env.fetch('action_controller.instance')
    end

    def redirect_history
      @redirects_followed.join(' -> ')
    end
  end

  # EXCEPTIONS
  class RehearsalError < StandardError; end
  class RedirectLoopError < RehearsalError; end
  class TooManyRedirectsError < RehearsalError; end
end
