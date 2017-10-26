class MockRackApp
  attr_reader :env, :requests

  def initialize(*)
    @responses = {}
    @sideeffects = {}
    @requests = []
    super
  end

  def call(env)
    @env = env

    key = url_to_key("#{env['PATH_INFO']}?#{env['QUERY_STRING']}")
    response = @responses.fetch(key)
    sideeffect = @sideeffects[key]
    sideeffect.call(env) if sideeffect

    @requests << Rack::Request.new(env.dup)

    return response
  end

  def mock(url, status: 200, headers: {}, body: ['OK'], &sideeffect)
    @responses[url_to_key(url)] = [status, headers, body]
    @sideeffects[url_to_key(url)] = sideeffect
    return url
  end

  private

  def url_to_key(url)
    uri = URI(url)
    return [uri.path, uri.query.presence]
  end
end
