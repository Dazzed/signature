require 'sendgrid-ruby'
require "time"
include SendGrid

class DealController < ApplicationController

  before_action :validate_deal_params, only: [:show, :client_payment, :payment_update]

  def show
    # If this is a new deal, Then create a new deal
    # Also save the incoming dynamic params in the deal.
    @deal = Deal.find_or_create_by!(:client_deal_id => params[:client_deal_id])
    @deal.update_attributes!(deal_attributes: params.to_json) unless !params[:show_status].nil?
    # Fetch all templates from Hellosign that can be used for a new document
    @templates = HellosignService::get_templates

  end
  
  def client_payment 
    @deal = Deal.find_by(:client_deal_id => params[:client_deal_id])
    @deal_attributes = JSON.parse(@deal.deal_attributes)
    @client_email = params[:client_email]
  end

  def payment_update
    token = params[:stripeToken]
    @deal = Deal.find_by(:client_deal_id => params[:client_deal_id])
    @deal_attributes = JSON.parse(@deal.deal_attributes)

    charge = StripeService.new({
      deal_attributes: @deal_attributes,
      source: token,
    }).create_charge

    redirect_to deal_thank_you_path
  end
  
  private
  def validate_deal_params
    client_deal_id = params[:client_deal_id]
    return render 'error/error_page' unless client_deal_id    
  end
end