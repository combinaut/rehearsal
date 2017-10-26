# Rehearsal

Rehearsal is a Rack Middleware gem that allows model changes to be previewed without persisting them to the database.
It achieves this by intercepting the original update request and spawning a second request to Rails for a preview,
wrapping both in a single database transaction that is rolled back after the preview is generated.

## Installation

Simply include the gem in your bundle, or `require` it by hand.

## Options

### trigger

The trigger defines a proc that enables the rehearsal mechanism for the request. Keep in mind the request has not yet
reached Rails itself, and won't have data from `ApplicationController`.

```ruby
# This is the default trigger, but you can override it with any proc you want
Rehearsal::Configuration.trigger = ->(request) {
  request.params['rehearsal'] == 'true'
}
```

### preview_url

The preview url is the path of the second request which will show the preview of the changes made in the first request.
The preview url may be defined in the following ways:

- as a param, i.e. `params[:preview_url]` This method overrides all other methods of setting the url
- as a proc, e.g. `Rehearsal::Configuration.preview_url = ->(controller) { controller.my_preview_url }`
- as a symbol, e.g. `Rehearsal::Configuration.preview_url = :some_method` The method will be called on the controller the update request is sent to
- as a value, e.g. `Rehearsal::Configuration.preview_url = '/my_previews'`

NOTE: If left blank, the preview url will be determined from the response of the update request. If that request returns
a redirect, the redirect chain will be followed until the response is not a redirect.
