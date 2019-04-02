require "hello_sign"
require 'securerandom'

class HellosignService

  def self.get_templates
    template_list = HelloSign.get_templates
    return template_list.data["templates"].map { |template|
      template_id, 
      reusable_form_id,
      title,
      message,
      signer_roles,
      cc_roles,
      documents,
      custom_fields,
      named_form_fields = template.values_at(
        "template_id", "reusable_form_id", "title", "message", "signer_roles", "cc_roles", 
        "documents", "custom_fields", "named_form_fields") 
      {
        :template_id => template_id, 
        :reusable_form_id => reusable_form_id,
        :title => title,
        :message => message,
        :signer_roles => signer_roles,
        :cc_roles => cc_roles,
        :documents => documents,
        :custom_fields => custom_fields,
        :named_form_fields => named_form_fields
      }
    }
  end

  def self.get_template_data(template_id)
    target_template = HelloSign.get_template :template_id => template_id
    false unless target_template

    target_template.data

  end

  def self.get_parties(target_template_data, signer_roles, signer_roles_pay)
    target_template_data["signer_roles"].map{ |signer_role|
      signer_order = signer_role.data["order"] # order is the signer order
      {
        :order => signer_order,
        :name => signer_role.data["name"],
        :email => signer_roles[signer_order.to_s],
        :uuid => SecureRandom.hex,
        # Bool signer_roles_pay[order] from view will reveal if the signee in the order must pay.
        :should_pay => signer_roles_pay ? signer_roles_pay[signer_order.to_s] == "true" : false,
        :is_pending_signature => true
      }
    }
  end

  def self.create_embedded_signature_request_with_template(document)
    signers = []
    document.parties.each do |party|
      signers.push({
        :email_address => party[:email],
        :name => party[:name],
        :role => party[:name]
      })
    end
    HelloSign.create_embedded_signature_request_with_template(  
      :test_mode => 1,
      :client_id => Rails.application.credentials[Rails.env.to_sym][:HELLO_SIGN_CLIENT_ID],
      :template_id => document.template_id,
      :subject => document.document_title,
      :message => "Signature requested at #{Time.now}",
      :signers => signers,
      :custom_fields => document.deal_attributes.map{ |k,v| {:name => k, :value => v} },
      :metadata => {
        "document_id": document.id
      }
    )    
  end

  def self.store_signed_document(signature_request_id)
    file_bin = HelloSign.signature_request_files :signature_request_id => signature_request_id, :file_type => 'pdf'
    open("public/" + signature_request_id + ".pdf", "wb") do |file|
      file.write(file_bin)
    end
  end

  def self.signature_request_files(signature_request_id)
    HelloSign.signature_request_files :signature_request_id => signature_request_id, :file_type => 'pdf'
  end

  def self.get_embedded_sign_url(sign_id)
    HelloSign.get_embedded_sign_url :signature_id => sign_id
  end

  def self.preview(preview_params, custom_fields)
    preview = HelloSign.create_embedded_unclaimed_draft_with_template(
        :test_mode => 1,
        :client_id => Rails.application.credentials[Rails.env.to_sym][:HELLO_SIGN_CLIENT_ID],
        :template_id => preview_params[:template_id],
        :requester_email_address => 'investorrelations@fundthatflip.com',
        :signing_redirect_url => 'https://www.fundthatflip.com/',
        :requesting_redirect_url => 'https://www.fundthatflip.com/',
        :signers => [
          {
            :email_address => preview_params[:borrower_email],
            :name => preview_params[:borrower_name],
            :role => 'Borrower'
          },
          {
            :email_address => preview_params[:approver_email],
            :name => preview_params[:approver_name],
            :role => 'Approver'
          }
        ],
        :custom_fields => custom_fields.map{ |k,v| {:name => k, :value => v} }
    )
    preview.claim_url
  end

end