require 'sendgrid-ruby'
require 'securerandom'
require "time"
include SendGrid

class HomeController < ApplicationController
  def callbacks
    # byebug
    event = JSON.parse(params["json"])
    if event["event"]["event_type"] == "signature_request_signed"
      helpers.signature_request_signed_callback(event)
    end
    render json: "Hello API Event Received", status: 200
  end

  def new
  end

  def init
    # Validate deal_id
    deal_id = params[:deal_id]
    return render 'errorPage' unless deal_id
    @thisDeal = Storage.where(:deal_id => deal_id).first
    # If this is a new deal, Then create a new deal and assign it a common uuid
    # Also save the incoming dynamic params in the deal.
    if @thisDeal.nil?
      commonUuid = SecureRandom.hex
      @thisDeal = Storage.create({
        :deal_id => deal_id,
        :params => params.to_json,
        :commonUuid => commonUuid,
      })
    else
      # IF the deal record already exists, then simply update the dynamic params
      @thisDeal.update(:params => params.to_json)
    end
    # Fetch all contracts related to this deal for display in the view.
    @contracts = Contract.where(:deal_id => deal_id)
    # Fetch all templates from Hellosign that can be used for a new contract
    templateRes = HelloSign.get_templates
    @templates = helpers.pluckFieldsForTemplateSelection(templateRes)
  end

  def getForm
    # Validate presence of templateId
    unless params[:templateId] && params[:deal_id]
      return render 'errorPage'
    end
    targetTemplate = HelloSign.get_template :template_id => params[:templateId]
    unless targetTemplate
      return render 'errorPage'
    end
    # Fetch the deal record and get the dynamic params.
    @thisDeal = Storage.where(:deal_id => params[:deal_id]).first
    @thisDealParams = JSON.parse(@thisDeal.params)
    @targetTemplate = targetTemplate.data
    render json: {
      template_form: (render_to_string partial: 'template_form', locals: {thisDeal: @thisDeal, thisDealParams: @thisDealParams, targetTemplate:  @targetTemplate}, layout: false),
      # deal_status: (render_to_string partial: 'template_status', locals: {thisDeal: @thisDeal, thisDealParams: @thisDealParams, targetTemplate:  @targetTemplate}, layout: false)
    }
  end

  def sendEmails
    template_id = params["template_id"]
    deal_id = params["deal_id"]
    # VALIDATIONS
    unless template_id && deal_id
      return render 'errorPage'
    end
    
    @thisDeal = Storage.where(:deal_id => deal_id).first
    unless @thisDeal
      return render 'errorPage'
    end
    # END VALIDATIONS

    # Fetch the template from hellosign and fill in the dynamic read-only params placeholder info.
    targetTemplate = HelloSign.get_template :template_id => params[:template_id]
    targetTemplate = targetTemplate.data
    # Construct parties info to save in the newly created contract based on info from the hellosign template and form data
    parties = targetTemplate["signer_roles"].map{ |signerRole|
      thisOrder = signerRole.data["order"] # order is the signer order
      {
        :order => thisOrder,
        :name => signerRole.data["name"],
        :email => params["signer_roles"][thisOrder.to_s],
        :index => thisOrder.to_i,
        :uuid => SecureRandom.hex,
        # Bool signer_roles_pay[order] from view will reveal if the signee in the order must pay.
        :should_pay => params["signer_roles_pay"] ? params["signer_roles_pay"][thisOrder.to_s] == "true" : false,
        :is_pending_signature => true
      }
    }
    # Create a new contract in database
    new_contract = Contract.create({
      :name => params["contractName"],
      :storage_id => @thisDeal.id,
      :deal_id => deal_id,
      :parties => parties,
      :template_id => template_id,
      :custom_fields => params["custom_fields"].permit!.to_h
    })

    # Send Email to relevant parties
    parties.each { |thisParty|
      link = "#{ENV['EMAIL_SIGNING_URL']}?contract_id=#{new_contract.id.to_s}&uuid=#{thisParty[:uuid]}&order=#{thisParty[:order]}"
      UserNotifierMailer.send_signature_request_email(parties, thisParty[:email], link).deliver
    }

    redirect_to home_success_path
  end

  def initiateSigning
    # VALIDATIONS
    uuid = params[:uuid]
    order = params[:order]
    contract_id = params[:contract_id]
    unless uuid and order and contract_id
      return render 'errorPage'
    end

    thisContract = Contract.find(contract_id)

    unless thisContract and !thisContract.try(:expired)
      return render 'errorPage'
    end

    thisPartyIndex = thisContract.parties.find_index{ |party| party["uuid"] == uuid }
    return render 'errorPage' if thisPartyIndex.nil?
    thisParty = thisContract.parties[thisPartyIndex]

    # END VALIDATIONS

    embedded_request = HelloSign.create_embedded_signature_request_with_template(
      :test_mode => 1,
      :client_id => ENV["HELLO_SIGN_CLIENT_ID"],
      :template_id => thisContract.template_id,
      :subject => 'Test Subject',
      :message => "Signature requested at #{Time.now}",
      :signers => [
        {
          :email_address => thisParty["email"],
          :name => thisParty["name"],
          :role => thisParty["name"]
        }
      ],
      :custom_fields => thisContract.custom_fields.map{ |k,v| {:name => k, :value => v} },
      :metadata => {
        "contract_id": contract_id,
        "uuid": uuid
      }
    )

    signature_request_id = embedded_request.data["signature_request_id"]
    # Unique signature request id for the party
    thisContract.parties[thisPartyIndex]["signature_request_id"] = signature_request_id
    thisContract.save!

    @signed_url = get_sign_url(embedded_request)
    @should_pay = thisContract.parties[thisPartyIndex]["should_pay"]
  end

  def stripe_update
    Stripe.api_key = "sk_test_RSuK6LLUlCJZ8qLiIKV9kthb"
    token = params[:stripeToken]

    charge = Stripe::Charge.create({
      amount: 999,
      currency: "usd",
      description: "Example charge",
      source: token,
    })
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
end
