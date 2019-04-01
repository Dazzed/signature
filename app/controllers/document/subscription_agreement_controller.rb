require 'open-uri'
class Document::SubscriptionAgreementController < ApplicationController

  def new
    get_template
    return render 'error/error_page' if @target_template.nil?
  
    get_and_update_deal
    create_document

    render json: {"success": true}
  end

  private

  def get_and_update_deal
    client_deal_id = params[:client_deal_id]
    return render 'error/error_page' unless client_deal_id
    @deal = Deal.find_or_create_by!(client_deal_id: client_deal_id)
    @deal.update_attributes!(deal_attributes: params.to_json) unless !params[:show_status].nil?
  end

  def get_template
    if HELLOSIGN_TEMPLATES.values.include?(params[:template_id])
      @target_template = SignatureService::get_template_data(params[:template_id])
    end
  end

  def create_document
    signer_roles = { "0"=> params[:Subscriber], "1"=> params[:Issuer] }
    parties = SignatureService::get_parties(@target_template, signer_roles, { "0"=>"false" })

    new_document = @deal.documents.create({
      :client_deal_id => @deal.client_deal_id,
      :parties => parties,
      :template_id => @target_template["template_id"],
      :document_title => @target_template["title"],
      :deal_attributes => subscription_attributes,
      :address => '123 Fake St',
      :complete => false
    })
  end

  def subscription_attributes
    params.permit(SUBSCRIPTION_AGREEMENT_FIELDS).to_h
  end
end
