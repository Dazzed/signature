require 'sendgrid-ruby'
require 'securerandom'
require "time"
include SendGrid

class HomeController < ApplicationController
  def callbacks
    # byebug
    event = JSON.parse(params["json"])
    if event["event"]["event_type"] == "signature_request_signed"
      metadata = event["signature_request"]["metadata"]
      signature_request_id = event["signature_request"]["signature_request_id"]
      if metadata
        commonUuid = metadata["commonUuid"]
        uuid = metadata["uuid"]
        storageRecord = Storage.where(:commonUuid => commonUuid).first
        unless storageRecord.nil?
          allParties = storageRecord.stats["parties"]
          thisPartyIndex = allParties.find_index{|party| party["signature_request_id"] == signature_request_id}
          if thisPartyIndex
            thisParty = allParties[thisPartyIndex]
            storageRecord.stats["parties"][thisPartyIndex]["is_pending_signature"] = false
            storageRecord.stats["parties"][thisPartyIndex]["signed_at"] = Time.now
            storageRecord.save!
          end
        end
      end
    end
    render json: "Hello API Event Received", status: 200
  end

  def new
  end

  def init
    deal_id = params[:deal_id]
    return render 'errorPage' unless deal_id
    @thisDeal = Storage.where(:deal_id => deal_id).first
    if @thisDeal.nil?
      commonUuid = SecureRandom.hex
      @thisDeal = Storage.create!({
        :deal_id => deal_id,
        :params => params.to_json,
        :commonUuid => commonUuid,
      })
    else
      @thisDeal.update(:params => params.to_json)
    end
    templateRes = HelloSign.get_templates
    @templates = helpers.pluckFieldsForTemplateSelection(templateRes)
  end

  def getForm
    unless params[:templateId] && params[:deal_id]
      return render 'errorPage'
    end
    targetTemplate = HelloSign.get_template :template_id => params[:templateId]
    unless targetTemplate
      return render 'errorPage'
    end
    @thisDeal = Storage.where(:deal_id => params[:deal_id]).first
    @thisDealParams = JSON.parse(@thisDeal.params)
    @targetTemplate = targetTemplate.data
    render json: {
      template_form: (render_to_string partial: 'template_form', locals: {thisDeal: @thisDeal, thisDealParams: @thisDealParams, targetTemplate:  @targetTemplate}, layout: false),
      deal_status: (render_to_string partial: 'template_status', locals: {thisDeal: @thisDeal, thisDealParams: @thisDealParams, targetTemplate:  @targetTemplate}, layout: false)
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
    targetTemplate = HelloSign.get_template :template_id => params[:template_id]
    targetTemplate = targetTemplate.data
    parties = targetTemplate["signer_roles"].map{ |signerRole|
      thisOrder = signerRole.data["order"]
      {
        :order => thisOrder,
        :name => signerRole.data["name"],
        :email => params["signer_roles"][thisOrder.to_s],
        :index => thisOrder.to_i,
        :uuid => SecureRandom.hex,
        :should_pay => params["signer_roles_pay"] ? params["signer_roles_pay"][thisOrder.to_s] == "true" : false,
        :is_pending_signature => true
      }
    }
    # update the record in database
    @thisDeal.update(
      :stats => {
        :parties => parties,
        :template_id => template_id,
        :custom_fields => params["custom_fields"].permit!.to_h
      }
    )

    # Send Email to relevant parties
    parties.each { |thisParty|
      link = "#{ENV['EMAIL_SIGNING_URL']}?commonUuid=#{@thisDeal[:commonUuid]}&uuid=#{thisParty[:uuid]}&order=#{thisParty[:order]}"
      UserNotifierMailer.send_signature_request_email(parties, thisParty[:email], link).deliver
    }

    redirect_to home_success_path
  end

  def initiateSigning
    uuid = params[:uuid]
    order = params[:order]
    commonUuid = params[:commonUuid]
    unless uuid and order and commonUuid
      return render 'errorPage'
    end
    
    storageRecord = Storage.where(:commonUuid => commonUuid).first
    
    unless storageRecord and !storageRecord.try(:expired)
      return render 'errorPage'
    end

    thisPartyIndex = storageRecord.stats["parties"].find_index{ |party| party["uuid"] == uuid }
    thisParty = storageRecord.stats["parties"][thisPartyIndex]
    unless thisParty
      return render 'errorPage'
    end

    embedded_request = HelloSign.create_embedded_signature_request_with_template(
      :test_mode => 1,
      :client_id => ENV["HELLO_SIGN_CLIENT_ID"],
      :template_id => storageRecord.stats["template_id"],
      :subject => 'Test Subject',
      :message => "Signature requested at #{Time.now}",
      :signers => [
        {
          :email_address => thisParty["email"],
          :name => thisParty["name"],
          :role => thisParty["name"]
        }
      ],
      :custom_fields => storageRecord.stats["custom_fields"].map{ |k,v| {:name => k, :value => v} },
      :metadata => {
        "commonUuid": commonUuid,
        "uuid": uuid
      }
    )

    pp embedded_request.data["signature_request_id"]

    signature_request_id = embedded_request.data["signature_request_id"]
    storageRecord.stats["parties"][thisPartyIndex]["signature_request_id"] = signature_request_id
    storageRecord.save!

    @signed_url = get_sign_url(embedded_request)
    @should_pay = thisParty["should_pay"]
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
