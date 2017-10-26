require 'rehearsal/middleware'

module Rehearsal
  class Railtie < Rails::Railtie
    initializer "rehearsal.init" do |app|
      app.config.middleware.use Rehearsal::Middleware
    end
  end
end
