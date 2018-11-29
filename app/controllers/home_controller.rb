require 'sendgrid-ruby'
require 'securerandom'
require "time"
include SendGrid

class HomeController < ApplicationController

  # before_action :get_deal, only: [:init_deal_data, :get_form_for_template, :email_document_for_signature]
  # before_action :get_template_data, only: [:get_form_for_template, :email_document_for_signature]
  # before_action :validate_signature_params, only: [:initiate_signature]
  # before_action :get_active_document, only: [:initiate_signature]

  # def init_deal_data
  #   # If this is a new deal, Then create a new deal and assign it a common uuid
  #   # Also save the incoming dynamic params in the deal.
  #   if @this_deal.nil?
  #     common_uuid = SecureRandom.hex
  #     @this_deal = Deal.create({
  #       :client_deal_id => params[:client_deal_id],
  #       :params => params.to_json,
  #       :common_uuid => common_uuid,
  #     })
  #   else
  #     # IF the deal record already exists, then simply update the dynamic params
  #     @this_deal.update(:params => params.to_json)
  #   end
  #   # Fetch all documents related to this deal for display in the view.
  #   @documents = Document.where(:deal_id => @this_deal.id)
  #   # Fetch all templates from Hellosign that can be used for a new document
  #   @templates = HellosignService.new().get_templates
  # end

  # def get_form_for_template
  #   # Fetch the deal dynamic params.
  #   @this_deal_params = JSON.parse(@this_deal.params)
  #   render :layout => false
  # end

  # def email_document_for_signature
  #   # Construct parties info to save in the newly created document based on info from the hellosign template and form data
  #   parties = HellosignService.new().get_parties(@target_template, params[:signer_roles], params[:signer_roles_pay])

  #   # Create a new document in database
  #   new_document = Document.create({
  #     :deal_id => @this_deal.id,
  #     :client_deal_id => @this_deal.client_deal_id,
  #     :parties => parties,
  #     :template_id => @target_template["template_id"],
  #     :document_title => @target_template["title"],
  #     :deal_attributes => params["custom_fields"].permit!.to_h,
  #     :complete => false
  #   })

  #   redirect_to "/init_alternate/#{@this_deal.client_deal_id}?show_status=true"
  # end

  # def initiate_signature
  #   #Create an embedded template request for signing.
  #   @signed_url = HellosignService.new().get_embedded_sign_url(@this_document.parties[@this_party_index][:signature_id])
  #   @should_pay = @this_document.parties[@this_party_index]["should_pay"]
  #   @signer_email = @this_party["email"]
  # end

  # def view_stripe 
  #   @signer_email = params[:email]
  # end

  # def stripe_update
  #   token = params[:stripeToken]

  #   charge = StripeService.new({
  #     amount: 999,
  #     currency: "usd",
  #     description: "Charge for document",
  #     source: token,
  #   }).create_charge

  #   redirect_to thank_you_path
  # end

  # private
  # def get_deal
  #   client_deal_id = params[:client_deal_id]
  #   return render 'error_page' unless client_deal_id
  #   @this_deal = Deal.where(:client_deal_id => client_deal_id).first
  # end

  # def get_template_data
  #   # Validate presence of template_id
  #   unless params[:template_id]
  #     return render 'error_page'
  #   end
  #   target_template = HelloSign.get_template :template_id => params[:template_id]
  #   unless target_template
  #     return render 'error_page'
  #   end
  #   @target_template = target_template.data

  # end

  # def validate_signature_params
  #   uuid = params[:uuid]
  #   order = params[:order]
  #   unless uuid and order
  #     return render 'error_page'
  #   end
  # end

  # def get_active_document
  #   document_id = params[:document_id]
  #   unless document_id
  #     return render 'error_page'
  #   end

  #   @this_document = Document.find(document_id)

  #   unless @this_document and !@this_document.try(:expired)
  #     return render 'error_page'
  #   end

  #   @this_party_index = @this_document.parties.find_index{ |party| party["uuid"] == params[:uuid] }
  #   return render 'error_page' if @this_party_index.nil?
  #   @this_party = @this_document.parties[@this_party_index]

  #   # Redirect user to already signed page if he has already signed
  #   return render 'already_signed_warning' if @this_party["is_pending_signature"] != true
  # end

end
