require 'ostruct'

module Rehearsal
  module Configuration
    mattr_accessor :preview_url
    mattr_accessor :trigger

    self.trigger = ->(request) {
      request.params['rehearsal'] == 'true'
    }
  end
end
