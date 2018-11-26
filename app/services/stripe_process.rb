require 'stripe'
class StripeProcess

  def initialize(params)
    @token = params[:token]
    @amount = params[:amount]
    @description = params[:description]
    @currency = params[:currency]
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

  attr_reader :amount, :description, :token, :currency

  #Stripe charge service
  def external_charge_service
    Stripe::Charge
  end

  #attributes for charge api.
  def charge_attributes
    {
      amount: amount,
      token: token,
      currency: currency,
      description: description
    }
  end

end