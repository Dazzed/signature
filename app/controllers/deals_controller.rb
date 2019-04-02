class DealsController < ApplicationController

  before_action :validate_deal_params, only: [:index]

  def index
    # If this is a new deal, Then create a new deal
    # Also save the incoming dynamic params in the deal.
    @deal = Deal.find_or_create_by!(:client_deal_id => params[:client_deal_id])
    @deal.update_attributes!(deal_attributes: params.to_json) unless !params[:show_status].nil?
    @deal_params = JSON.parse(@deal.deal_attributes)
    @preview_url = HellosignService::preview(preview_params, custom_fields_params) if params[:template_id].present?
  end
  
  private
  def validate_deal_params
    client_deal_id = params[:client_deal_id]
    return render 'error/error_page' unless client_deal_id    
  end

  def preview_params
    {
      template_id: params[:template_id],
      borrower_email: params[:Borrower],
      borrower_name: params[:borrower_full_name],
      approver_email: params[:Approver],
      approver_name: params[:approver_name]
    }
  end

  def custom_fields_params
    @deal_params.select{|k, v| TERM_SHEET_CUSTOM_FIELDS.include?(k) }
  end
end