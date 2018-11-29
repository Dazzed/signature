class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  private
  def get_deal
    client_deal_id = params[:client_deal_id]
    return render 'error/error_page' unless client_deal_id
    @this_deal = Deal.where(:client_deal_id => client_deal_id).first
  end

  def get_template_data
    # Validate presence of template_id
    unless params[:template_id]
      return render 'error/error_page'
    end
    target_template = HelloSign.get_template :template_id => params[:template_id]
    unless target_template
      return render 'error/error_page'
    end
    @target_template = target_template.data

  end

  def validate_signature_params
    uuid = params[:uuid]
    order = params[:order]
    unless uuid and order
      return render 'error_page'
    end
  end

  def get_active_document
    document_id = params[:document_id]
    unless document_id
      return render 'error/error_page'
    end

    @this_document = Document.find(document_id)

    unless @this_document and !@this_document.try(:expired)
      return render 'error/error_page'
    end

    @this_party_index = @this_document.parties.find_index{ |party| party["uuid"] == params[:uuid] }
    return render 'error/error_page' if @this_party_index.nil?
    @this_party = @this_document.parties[@this_party_index]

    # Redirect user to already signed page if he has already signed
    return render 'error/already_signed_warning' if @this_party["is_pending_signature"] != true
  end

  
end
