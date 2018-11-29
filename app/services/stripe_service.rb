require 'stripe'
class StripeService

  def initialize(params)
    @token = params[:token]
    @deal_attributes = params[:deal_attributes]
  end
  
  def create_charge
    begin
      # This will return a Stripe::Charge object
      external_charge_service.create(charge_attributes)
    rescue
      false
    end
  end

  private

  attr_reader :deal_attributes, :token

  #Stripe charge service
  def external_charge_service
    Stripe::Charge
  end

  #attributes for charge api.
  def charge_attributes
    {
      amount: deal_attributes["deal_amount"],
      token: token,
      currency: deal_attributes["deal_currency"],
      description: deal_attributes["deal_title"]
    }
  end

end