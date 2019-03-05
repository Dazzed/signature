class Api::DocumentStatusController < ApplicationController
  before_action :validate_deal_params, only: [:index]

  def index
    # Get the first match of the client_deal_id 
    @deal = Deal.where(:client_deal_id => params[:client_deal_id]).first
    if @deal.nil?
      return render json: {"success": false, "message": "Invalid deal id"} 
    end

    deal_documents = []
    @deal.documents.each do |document|
      doc = {
        "_id" => document.id,
        "client_deal_id" => document.client_deal_id,
        "parties" => document.parties,
        "template_id" => document.template_id,
        "document_title" => document.document_title,
        "deal_attributes" => document.deal_attributes,
        "complete" => document.complete,
        "deal_id" => document.deal_id,
        "createdAt" => document.createdAt,
        "apiLink" => document_signature_path(document.parties[0]["signature_request_id"])
      }
      deal_documents.push(doc)
    end
    render json: {"success": true, "document_status": deal_documents}
  end
  
  private
  def validate_deal_params
    client_deal_id = params[:client_deal_id]
    return render json: {"success": false, "message": "Invalid deal id"} unless client_deal_id    
  end
end
