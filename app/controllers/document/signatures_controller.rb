require 'open-uri'
class Document::SignaturesController < ApplicationController
  
  before_action :validate_signature_params, only: [:new]
  before_action :get_active_document, only: [:new]
  before_action :get_signer_information, only: [:new]
  before_action :validate_signature_request_id, only: [:show]

  def new
    #Create an embedded template request for signing.
    @signed_url = HellosignService::get_embedded_sign_url(@document.parties[@party_index][:signature_id])
    @should_pay = @document.parties[@party_index]["should_pay"]
    @client_email = @party["email"]
  end

  def show
    file_bin = HellosignService::signature_request_files(@signature_request_id)
    send_data file_bin, :disposition => 'attachment', :filename=>"signedDocument.pdf"
  end

  private
  def validate_signature_params
    uuid = params[:uuid]
    order = params[:order]
    unless uuid and order
      return render 'error/error_page'
    end
  end

  def get_active_document
    document_id = params[:document_id]
    unless document_id
      return render 'error/error_page'
    end

    @document = Document.find(document_id)
    unless @document and !@document.try(:expired)
      return render 'error/error_page'
    end
  end

  # TODO refactor, not scalable
  def get_signer_information
    @party_index = @document.parties.find_index{ |party| party["uuid"] == params[:uuid] }
    return render 'error/error_page' if @party_index.nil?
    @party = @document.parties[@party_index]

    # Redirect user to already signed page if he has already signed
    return render 'error/already_signed_warning' if @party["is_pending_signature"] != true
    return render 'error/document_expired' if @document.deal.documents[@document.deal.documents.count - 1].id != @document.id
    deal_params = JSON.parse(@document.deal.deal_attributes)
    return if deal_params['template_id'] == HELLOSIGN_TEMPLATES[:SUBSCRIPTION_AGREEMENT]
    return render 'error/document_expired' if deal_params["expiry_date"].to_date <= Date.today
  end  

  def validate_signature_request_id
    @signature_request_id = params[:id]
    return render 'error/error_page' if @signature_request_id.nil?
  end

end