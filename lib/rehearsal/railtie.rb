require 'rehearsal/middleware'

module Rehearsal
  class Railtie < Rails::Railtie
    initializer "rehearsal.init" do |app|
      # Insert as high up in the stack as we can so the env hash is as clean as possible for the preview request
      app.config.middleware.insert_after('Rack::Lock', Rehearsal::Middleware)
    end
  end
end
