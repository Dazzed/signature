require 'sendgrid-ruby'
require 'securerandom'
require "time"
include SendGrid

class DocumentController < ApplicationController
  
  before_action :get_deal, only: [:index, :new, :create]
  before_action :get_template_data, only: [:new, :create]
  before_action :validate_signature_params, only: [:initiate_signature]
  before_action :get_active_document, only: [:initiate_signature]

  def index
    @documents = Document.where(:deal_id => @this_deal.id)
    render :layout => false
  end
  
  def new
    @this_deal_params = JSON.parse(@this_deal.params)
    render :layout => false
  end

  def create
    # Construct parties info to save in the newly created document based on info from the hellosign template and form data
    parties = HellosignService.new().get_parties(@target_template, params[:signer_roles], params[:signer_roles_pay])

    # Create a new document in database
    new_document = Document.create({
      :deal_id => @this_deal.id,
      :client_deal_id => @this_deal.client_deal_id,
      :parties => parties,
      :template_id => @target_template["template_id"],
      :document_title => @target_template["title"],
      :deal_attributes => params["custom_fields"].permit!.to_h,
      :complete => false
    })

    redirect_to "/deal/show/#{@this_deal.client_deal_id}"
  end

  def initiate_signature
    #Create an embedded template request for signing.
    @signed_url = HellosignService.new().get_embedded_sign_url(@this_document.parties[@this_party_index][:signature_id])
    @should_pay = @this_document.parties[@this_party_index]["should_pay"]
    @signer_email = @this_party["email"]
  end

end