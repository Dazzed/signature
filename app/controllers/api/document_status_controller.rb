class Api::DocumentStatusController < ApplicationController
  before_action :validate_deal_params, only: [:index]

  def index
    # Get the first match of the client_deal_id 
    @deal = Deal.where(:client_deal_id => params[:client_deal_id]).first
    if @deal.nil?
      return render json: {"success": false, "message": "Invalid deal id"} 
    end
    render json: {"success": true, "document_status": @deal.documents}
  end
  
  private
  def validate_deal_params
    client_deal_id = params[:client_deal_id]
    return render json: {"success": false, "message": "Invalid deal id"} unless client_deal_id    
  end
end
