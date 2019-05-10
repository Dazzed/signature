class DealsController < ApplicationController

  before_action :validate_deal_params, only: [:index]

  def index
    # If this is a new deal, Then create a new deal
    # Also save the incoming dynamic params in the deal.
    @deal = Deal.find_or_create_by!(:client_deal_id => params[:client_deal_id])
    @deal.update_attributes!(deal_attributes: params.to_json) unless !params[:show_status].nil?
    @deal_params = JSON.parse(@deal.deal_attributes)
    @template_id = params[:template_id]
    # @preview_url = SignatureService::preview(preview_params, custom_fields_params) if params[:template_id].present?
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

  def non_broker_templates
    HELLOSIGN_TEMPLATES.key(@template_id).to_s.include?('NO_BROKER')
  end

  def custom_fields_params
    custom_fields = if non_broker_templates
                      TERM_SHEET_CUSTOM_FIELDS.select{ |field| !field.include?('broker') }
                    else
                      custom_fields = TERM_SHEET_CUSTOM_FIELDS
                    end
    @deal_params.select{|k, v| custom_fields.include?(k) }
  end
end