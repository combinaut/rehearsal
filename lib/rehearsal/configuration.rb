require 'ostruct'

module Rehearsal
  module Configuration
    mattr_accessor :preview_url
    mattr_accessor :trigger
    mattr_accessor :redirect_limit

    self.trigger = ->(request) {
      request.params['rehearsal'] == 'true'
    }
    self.redirect_limit = 15
  end
end
