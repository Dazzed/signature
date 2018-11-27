SIGNATURE_REQUEST_SIGNED = 'signature_request_signed'

class CallbackController < ApplicationController
  def hello_sign_callback
    event = JSON.parse(params["json"])
    if event["event"]["event_type"] == SIGNATURE_REQUEST_SIGNED
      helpers.signature_request_signed_callback(event)
    end
    render json: "Hello API Event Received", status: 200
  end
end
