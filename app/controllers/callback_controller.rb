SIGNATURE_REQUEST_SIGNED = 'signature_request_signed'
SIGNATURE_REQUEST_DOWNLOADABLE = 'signature_request_downloadable'

class CallbackController < ApplicationController
  def hello_sign_callback
    event = JSON.parse(params["json"])
    
    if is_event_type_valid(event["event"]["event_type"])
      metadata = event["signature_request"]["metadata"]
      signature_request_id = event["signature_request"]["signature_request_id"]
      if metadata
        document_id = metadata["document_id"]
        document = Document.find(document_id)
        unless document.nil?
          if event["event"]["event_type"] == SIGNATURE_REQUEST_SIGNED
            signature_id = event["event"]["event_metadata"]["related_signature_id"]
            document.handle_request_signed(signature_id)
          end
          #send signed documents to parties
          if event["event"]["event_type"] == SIGNATURE_REQUEST_DOWNLOADABLE && event["signature_request"]["is_complete"]
            document.send_signed_document(signature_request_id)
          end
        end
      end
    end
    render json: "Hello API Event Received", status: 200
  end

  private 
  def is_event_type_valid(event_type)
    if event_type == SIGNATURE_REQUEST_SIGNED || event_type == SIGNATURE_REQUEST_DOWNLOADABLE
      return true
    else
      return false
    end
  end
end
