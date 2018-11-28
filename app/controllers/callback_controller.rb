SIGNATURE_REQUEST_SIGNED = 'signature_request_signed'
SIGNATURE_REQUEST_DOWNLOADABLE = 'signature_request_downloadable'

class CallbackController < ApplicationController
  def hello_sign_callback
    event = JSON.parse(params["json"])
    
    if event["event"]["event_type"] == SIGNATURE_REQUEST_SIGNED
      metadata = event["signature_request"]["metadata"]
      signature_request_id = event["signature_request"]["signature_request_id"]

      if metadata
        contract_id = metadata["contract_id"]
        uuid = metadata["uuid"]
        this_contract = Document.find(contract_id)
        unless this_contract.nil?
          this_contract.handle_request_signed(uuid, signature_request_id)
        end
      end
    end
    if event["event"]["event_type"] == SIGNATURE_REQUEST_DOWNLOADABLE
      #send signed documents to parties
      metadata = event["signature_request"]["metadata"]
      signature_request_id = event["signature_request"]["signature_request_id"]

      if metadata
        contract_id = metadata["contract_id"]
        uuid = metadata["uuid"]
        this_contract = Document.find(contract_id)
        unless this_contract.nil?
          this_contract.send_signed_document(uuid, signature_request_id)
        end
      end

    end
    render json: "Hello API Event Received", status: 200
  end
end
