require 'sendgrid-ruby'
require 'securerandom'
require "time"
include SendGrid

class DealController < ApplicationController

  before_action :get_deal, only: [:show]

  def show
    # If this is a new deal, Then create a new deal and assign it a common uuid
    # Also save the incoming dynamic params in the deal.
    if @this_deal.nil?
      common_uuid = SecureRandom.hex
      @this_deal = Deal.create({
        :client_deal_id => params[:client_deal_id],
        :params => params.to_json,
        :common_uuid => common_uuid,
      })
    else
      # IF the deal record already exists, then simply update the dynamic params
      @this_deal.update(:params => params.to_json)
    end
    # Fetch all templates from Hellosign that can be used for a new document
    @templates = HellosignService.new().get_templates

  end
  
  def payment 
    @signer_email = params[:email]
  end

  def payment_update
    token = params[:stripeToken]

    charge = StripeService.new({
      amount: 999,
      currency: "usd",
      description: "Charge for document",
      source: token,
    }).create_charge

    redirect_to deal_thank_you_path
  end
  
end