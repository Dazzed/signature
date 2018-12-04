class Deal::PaymentsController < ApplicationController

  before_action :validate_deal_params, only: [:new, :create]
  
  def new 
    @deal = Deal.find_by(:client_deal_id => params[:client_deal_id])
    @deal_attributes = JSON.parse(@deal.deal_attributes)
    @client_email = params[:client_email]
  end

  def create
    token = params[:stripeToken]
    @deal = Deal.find_by(:client_deal_id => params[:client_deal_id])
    @deal_attributes = JSON.parse(@deal.deal_attributes)

    charge = StripeService.new({
      deal_attributes: @deal_attributes,
      source: token,
    }).create_charge

    redirect_to deal_payment_thanks_path
  end
  
  private
  def validate_deal_params
    client_deal_id = params[:client_deal_id]
    return render 'error/error_page' unless client_deal_id    
  end

end