require 'rehearsal/controller_extensions'

module Rehearsal
  class Engine < Rails::Engine
    initializer 'rehearsal.load_controller_extensions' do |app|
      ActiveSupport.on_load(:action_controller) do
        include ControllerExtensions::InstanceMethods
      end
    end
  end
end
