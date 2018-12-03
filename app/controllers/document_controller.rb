require 'sendgrid-ruby'
require "time"
include SendGrid

class DocumentController < ApplicationController
  
  before_action :get_deal, only: [:new, :create]
  before_action :get_template_data, only: [:new, :create]
  before_action :validate_signature_params, only: [:initiate_signature]
  before_action :get_active_document, only: [:initiate_signature]
  before_action :get_signer_information, only: [:initiate_signature]
  

  def new
    @deal_params = JSON.parse(@deal.deal_attributes)
    render :layout => false
  end

  def create
    # Construct parties info to save in the newly created document based on info from the hellosign template and form data
    parties = HellosignService::get_parties(@target_template, params[:signer_roles], params[:signer_roles_pay])

    # Create a new document in database
    new_document = @deal.documents.create({
      :client_deal_id => @deal.client_deal_id,
      :parties => parties,
      :template_id => @target_template["template_id"],
      :document_title => @target_template["title"],
      :deal_attributes => params["deal_attributes"].permit!.to_h,
      :complete => false
    })

    redirect_to "/deal/show/#{@deal.client_deal_id}?show_status=true"
  end

  def initiate_signature
    #Create an embedded template request for signing.
    @signed_url = HellosignService::get_embedded_sign_url(@document.parties[@party_index][:signature_id])
    @should_pay = @document.parties[@party_index]["should_pay"]
    @client_email = @party["email"]
  end

  private
  def get_deal
    client_deal_id = params[:client_deal_id]
    return render 'error/error_page' unless client_deal_id
    @deal = Deal.where(:client_deal_id => client_deal_id).first
  end
 
  def get_template_data
    # Validate presence of template_id
    unless params[:template_id]
      return render 'error/error_page'
    end
    @target_template = HellosignService::get_template_data(params[:template_id])
    unless @target_template
      return render 'error/error_page'
    end
  end

  def validate_signature_params
    uuid = params[:uuid]
    order = params[:order]
    unless uuid and order
      return render 'error_page'
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

  def get_signer_information
    @party_index = @document.parties.find_index{ |party| party["uuid"] == params[:uuid] }
    return render 'error/error_page' if @party_index.nil?
    @party = @document.parties[@party_index]

    # Redirect user to already signed page if he has already signed
    return render 'error/already_signed_warning' if @party["is_pending_signature"] != true
  end

end