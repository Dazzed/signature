require 'sendgrid-ruby'
require 'securerandom'
require "time"
include SendGrid

class HomeController < ApplicationController
  def init
    templateRes = HelloSign.get_templates
    @templates = helpers.pluckFieldsForTemplateSelection(templateRes)
  end

  def getForm
    targetTemplate = HelloSign.get_template :template_id => params[:templateId]
    @targetTemplate = targetTemplate.data
    render :partial => 'template_form'
  end

  def sendEmails
    template_id = params["template_id"]
    targetTemplate = HelloSign.get_template :template_id => params[:template_id]
    targetTemplate = targetTemplate.data
    parties = targetTemplate["signer_roles"].map{ |signerRole|
      thisOrder = signerRole.data["order"]
      {
        :order => thisOrder,
        :name => signerRole.data["name"],
        :email => params["signer_roles"][thisOrder.to_s],
        :index => thisOrder.to_i,
        :uuid => SecureRandom.hex
      }
    }

    # Save the record in database
    commonUuid = SecureRandom.hex
    Storage.create!({
      :parties => parties,
      :template_id => template_id,
      :commonUuid => commonUuid,
      :custom_fields => params["custom_fields"].permit!.to_h
    })

    # Send Email to relevant parties
    parties.each { |thisParty|
      link = "#{ENV['EMAIL_SIGNING_URL']}?commonUuid=#{commonUuid}&uuid=#{thisParty[:uuid]}&order=#{thisParty[:order]}"
      UserNotifierMailer.send_signature_request_email(parties, thisParty[:email], link).deliver
    }

    redirect_to '/'
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

    thisParty = storageRecord.parties.find{ |party| party["uuid"] == uuid }

    unless thisParty
      return render 'errorPage'
    end

    embedded_request = HelloSign.create_embedded_signature_request_with_template(
      :test_mode => 1,
      :client_id => ENV["HELLO_SIGN_CLIENT_ID"],
      :template_id => storageRecord.template_id,
      :subject => 'Test Subject',
      :message => "Signature requested at #{Time.now}",
      :signers => [
        {
          :email_address => thisParty["email"],
          :name => thisParty["name"],
          :role => thisParty["name"]
        }
      ],
      :custom_fields => storageRecord.custom_fields.map{ |k,v| {:name => k, :value => v} }
    )
    @signed_url = get_sign_url(embedded_request)
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
