class DealsController < ApplicationController

  before_action :validate_deal_params, only: [:index]

  def index
    # If this is a new deal, Then create a new deal
    # Also save the incoming dynamic params in the deal.
    @deal = Deal.find_or_create_by!(:client_deal_id => params[:client_deal_id])
    @deal.update_attributes!(deal_attributes: params.to_json) unless !params[:show_status].nil?
    # Fetch all templates from Hellosign that can be used for a new document
    @templates = HellosignService::get_templates

  end
  
  private
  def validate_deal_params
    client_deal_id = params[:client_deal_id]
    return render 'error/error_page' unless client_deal_id    
  end
end