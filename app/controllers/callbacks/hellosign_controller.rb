SIGNATURE_REQUEST_SIGNED = 'signature_request_signed'
SIGNATURE_REQUEST_DOWNLOADABLE = 'signature_request_downloadable'

class Callbacks::HellosignController < ApplicationController
  before_action :validate_callback_event_type
  before_action :validate_callback_metadata
  before_action :validate_document

  def create
    signature_request_id = @event["signature_request"]["signature_request_id"]
    if @event["event"]["event_type"] == SIGNATURE_REQUEST_SIGNED
      signature_id = @event["event"]["event_metadata"]["related_signature_id"]
      @document.handle_request_signed(signature_id)
    end
    #send signed documents to parties
    if @event["event"]["event_type"] == SIGNATURE_REQUEST_DOWNLOADABLE && @event["signature_request"]["is_complete"]
      @document.send_signed_document(signature_request_id)
    end
    render json: "Hello API Event Received", status: 200
  end

  private 
  def validate_callback_event_type
    @event = JSON.parse(params["json"])
    if (!(@event["event"]["event_type"] == SIGNATURE_REQUEST_SIGNED || @event["event"]["event_type"] == SIGNATURE_REQUEST_DOWNLOADABLE))
      render json: "Hello API Event Received", status: 200
    end    
  end

  def validate_callback_metadata
    @metadata = @event["signature_request"]["metadata"]
    if !@metadata
      render json: "Hello API Event Received", status: 200
    end
  end

  def validate_document
    document_id = @metadata["document_id"]
    @document = Document.find(document_id)
    if @document.nil?
      render json: "Hello API Event Received", status: 200
    end
  end
end
