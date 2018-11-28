require 'sendgrid-ruby'
require 'securerandom'
require "time"
include SendGrid

class HomeController < ApplicationController

  before_action :get_deal, only: [:init_deal_data, :get_form_for_template, :email_document_for_signature]
  before_action :get_template_data, only: [:get_form_for_template, :email_document_for_signature]
  before_action :validate_signature_params, only: [:initiate_signature]
  before_action :get_active_contract, only: [:initiate_signature]

  def init_deal_data

    # If this is a new deal, Then create a new deal and assign it a common uuid
    # Also save the incoming dynamic params in the deal.
    if @this_deal.nil?
      common_uuid = SecureRandom.hex
      @this_deal = Storage.create({
        :deal_id => deal_id,
        :params => params.to_json,
        :common_uuid => common_uuid,
      })
    else
      # IF the deal record already exists, then simply update the dynamic params
      @this_deal.update(:params => params.to_json)
    end
    # Fetch all contracts related to this deal for display in the view.
    @contracts = Document.where(:deal_id => @this_deal.deal_id)
    # Fetch all templates from Hellosign that can be used for a new contract
    @templates = HellosignService.new().get_templates
  end

  def get_form_for_template
    # Fetch the deal dynamic params.
    @this_deal_params = JSON.parse(@this_deal.params)

    render json: {
      template_form: (
        render_to_string partial: 'template_form', locals: {
          this_deal: @this_deal,
          this_deal_params: @this_deal_params,
          target_template:  @target_template
        },
        layout: false
      ),
    }
  end

  def email_document_for_signature
    # Construct parties info to save in the newly created contract based on info from the hellosign template and form data
    parties = HellosignService.new().get_parties(@target_template, params[:signer_roles], params[:signer_roles_pay])

    document_title  = @target_template["title"]

    # Create a new document in database
    new_document = Document.create({
      :storage_id => @this_deal.id,
      :deal_id => @this_deal.deal_id,
      :parties => parties,
      :template_id => @target_template["template_id"],
      :document_title => document_title,
      :deal_attributes => params["custom_fields"].permit!.to_h
    })

    redirect_to "/init_alternate/#{@this_deal.deal_id}?show_status=true"
  end

  def initiate_signature

    #Create an embedded template request for signing.
    embedded_request = HellosignService.new().create_embedded_signature_request_with_template(@this_contract, @this_party, params[:contract_id], params[:uuid])

    signature_request_id = embedded_request.data["signature_request_id"]
    
    # Unique signature request id for the party
    @this_contract.parties[@this_party_index]["signature_request_id"] = signature_request_id
    @this_contract.save!

    @signed_url = get_sign_url(embedded_request)
    @should_pay = @this_contract.parties[@this_party_index]["should_pay"]
    @signer_email = @this_party["email"]
  end

  def view_stripe 
    @signer_email = params[:email]
  end

  def stripe_update
    token = params[:stripeToken]

    charge = StripeService.new({
      amount: 999,
      currency: "usd",
      description: "Charge for contract",
      source: token,
    }).create_charge

    redirect_to thank_you_path
  end

  def success
  end

  private
  def get_sign_url(embedded_request)
    sign_id = get_first_signature_id(embedded_request)
    HelloSign.get_embedded_sign_url :signature_id => sign_id
  end

  def get_first_signature_id(embedded_request)
    embedded_request.signatures[0].signature_id
  end

  def get_deal
    deal_id = params[:deal_id]
    return render 'error_page' unless deal_id
    @this_deal = Storage.where(:deal_id => deal_id).first
  end

  def get_template_data
    # Validate presence of template_id
    unless params[:template_id]
      return render 'error_page'
    end
    target_template = HelloSign.get_template :template_id => params[:template_id]
    unless target_template
      return render 'error_page'
    end
    @target_template = target_template.data

  end

  def validate_signature_params
    uuid = params[:uuid]
    order = params[:order]
    unless uuid and order
      return render 'error_page'
    end
  end

  def get_active_contract
    contract_id = params[:contract_id]
    unless contract_id
      return render 'error_page'
    end

    # VALIDATIONS
    @this_contract = Document.find(contract_id)

    unless @this_contract and !@this_contract.try(:expired)
      return render 'error_page'
    end

    @this_party_index = @this_contract.parties.find_index{ |party| party["uuid"] == params[:uuid] }
    return render 'error_page' if @this_party_index.nil?
    @this_party = @this_contract.parties[@this_party_index]

    # Redirect user to already signed page if he has already signed
    return render 'already_signed_warning' if @this_party["is_pending_signature"] != true

    # END VALIDATIONS

  end

end
