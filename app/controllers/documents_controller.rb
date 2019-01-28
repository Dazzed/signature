class DocumentsController < ApplicationController
  
  before_action :get_deal, only: [:new, :create]
  before_action :get_template_data, only: [:new, :create]
  
  def new
    @deal_params = JSON.parse(@deal.deal_attributes)
    render :layout => false
  end

  def create
    # Construct parties info to save in the newly created document based on info from the hellosign template and form data
    parties = HellosignService::get_parties(@target_template, params[:signer_roles], params[:signer_roles_pay])

    # Create a new document in database
    new_document = @deal.documents.create({
      :client_deal_id => @deal.client_deal_id,
      :parties => parties,
      :template_id => @target_template["template_id"],
      :document_title => @target_template["title"],
      :deal_attributes => params["deal_attributes"].permit!.to_h,
      :complete => false
    })

    redirect_to deals_path + "?client_deal_id=#{@deal.client_deal_id}&show_status=true"
  end

  private
  def get_deal
    client_deal_id = params[:client_deal_id]
    return render 'error/error_page' unless client_deal_id
    @deal = Deal.where(:client_deal_id => client_deal_id).first
  end
 
  def get_template_data
    # Validate presence of template_id
    unless params[:template_id]
      return render 'error/error_page'
    end
    @target_template = HellosignService::get_template_data(params[:template_id])
    unless @target_template
      return render 'error/error_page'
    end

    @target_template["signer_roles"].each do |signer_role|
      if signer_role.data["order"].nil?
        return render 'error/error_page'
      end
    end
  end

end