require 'sendgrid-ruby'
require 'securerandom'
require "time"
include SendGrid

class HomeController < ApplicationController
  def init_deal_data
    # Validate deal_id
    deal_id = params[:deal_id]
    return render 'error_page' unless deal_id
    @this_deal = Storage.where(:deal_id => deal_id).first
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
    @contracts = Document.where(:deal_id => deal_id)
    # Fetch all templates from Hellosign that can be used for a new contract
    template_list = HelloSign.get_templates
    @templates = helpers.pluckFieldsForTemplateSelection(template_list)
  end

  def get_form_for_template
    # Validate presence of template_id
    unless params[:template_id] && params[:deal_id]
      return render 'error_page'
    end
    target_template = HelloSign.get_template :template_id => params[:template_id]
    unless target_template
      return render 'error_page'
    end
    # Fetch the deal record and get the dynamic params.
    @this_deal = Storage.where(:deal_id => params[:deal_id]).first
    @this_deal_params = JSON.parse(@this_deal.params)
    @target_template = target_template.data
    render json: {
      template_form: (
        render_to_string partial: 'template_form', locals: {
          this_deal: @this_deal,
          this_deal_params: @this_deal_params,
          target_template:  @target_template
        },
        layout: false
      ),
      # deal_status: (render_to_string partial: 'template_status', locals: {this_deal: @this_deal, this_deal_params: @this_deal_params, target_template:  @target_template}, layout: false)
    }
  end

  def email_document_for_signature
    template_id = params["template_id"]
    deal_id = params["deal_id"]
    # VALIDATIONS
    unless template_id && deal_id
      return render 'error_page'
    end
    
    @this_deal = Storage.where(:deal_id => deal_id).first
    unless @this_deal
      return render 'error_page'
    end
    # END VALIDATIONS

    # Fetch the template from hellosign and fill in the dynamic read-only params placeholder info.
    target_template = HelloSign.get_template :template_id => params[:template_id]
    return render 'error_page' unless target_template
    target_template_data = target_template.data
    # Construct parties info to save in the newly created contract based on info from the hellosign template and form data
    parties = target_template_data["signer_roles"].map{ |signer_role|
      this_order = signer_role.data["order"] # order is the signer order
      {
        :order => this_order,
        :name => signer_role.data["name"],
        :email => params["signer_roles"][this_order.to_s],
        :index => this_order.to_i,
        :uuid => SecureRandom.hex,
        # Bool signer_roles_pay[order] from view will reveal if the signee in the order must pay.
        :should_pay => params["signer_roles_pay"] ? params["signer_roles_pay"][this_order.to_s] == "true" : false,
        :is_pending_signature => true
      }
    }

    document_title  = target_template_data["title"]

    # Create a new document in database
    new_document = Document.create({
      :storage_id => @this_deal.id,
      :deal_id => deal_id,
      :parties => parties,
      :template_id => template_id,
      :document_title => document_title,
      :deal_attributes => params["custom_fields"].permit!.to_h
    })
    document_title  = target_template_data["title"]

    # Send Email to relevant parties
    parties.each { |this_party|
      if this_party[:order] == 0
        link = "#{ENV['EMAIL_SIGNING_URL']}?contract_id=#{new_document.id.to_s}&uuid=#{this_party[:uuid]}&order=#{this_party[:order]}"
        UserNotifierMailer.send_signature_request_email(
          parties, 
          this_party[:email], 
          link, 
          document_title
        ).deliver
      end
    }

    redirect_to "/init_alternate/#{deal_id}?show_status=true"
  end

  def initiate_signature
    # VALIDATIONS
    uuid = params[:uuid]
    order = params[:order]
    contract_id = params[:contract_id]
    unless uuid and order and contract_id
      return render 'error_page'
    end

    this_contract = Document.find(contract_id)

    unless this_contract and !this_contract.try(:expired)
      return render 'error_page'
    end

    this_party_index = this_contract.parties.find_index{ |party| party["uuid"] == uuid }
    return render 'error_page' if this_party_index.nil?
    this_party = this_contract.parties[this_party_index]

    # Redirect user to already signed page if he has already signed
    return render 'already_signed_warning' if this_party["is_pending_signature"] != true

    # END VALIDATIONS

    embedded_request = HelloSign.create_embedded_signature_request_with_template(
      :test_mode => 1,
      :client_id => ENV["HELLO_SIGN_CLIENT_ID"],
      :template_id => this_contract.template_id,
      :subject => 'Test Subject',
      :message => "Signature requested at #{Time.now}",
      :signers => [
        {
          :email_address => this_party["email"],
          :name => this_party["name"],
          :role => this_party["name"]
        }
      ],
      :custom_fields => this_contract.deal_attributes.map{ |k,v| {:name => k, :value => v} },
      :metadata => {
        "contract_id": contract_id,
        "uuid": uuid
      }
    )

    signature_request_id = embedded_request.data["signature_request_id"]
    # Unique signature request id for the party
    this_contract.parties[this_party_index]["signature_request_id"] = signature_request_id
    this_contract.save!

    @signed_url = get_sign_url(embedded_request)
    @should_pay = this_contract.parties[this_party_index]["should_pay"]
    @signer_email = this_party["email"]
  end

  def view_stripe 
    @signer_email = params[:email]
  end

  def stripe_update
    token = params[:stripeToken]

    charge = StripeProcess.new({
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
end
