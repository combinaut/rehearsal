require 'digest'

module Rehearsal
  module ControllerExtensions
    module InstanceMethods
      def preview_url
        # Override this method in the host app controllers
        nil
      end
    end
  end
end
