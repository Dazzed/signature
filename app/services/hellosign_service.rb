require "hello_sign"
require 'securerandom'

class HellosignService

  def initialize
    
  end

  def get_templates
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
        "documents", "custom_fields", "named_form_fields"
      )
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

  def get_template_data(template_id)
    target_template = HelloSign.get_template :template_id => template_id
    false unless target_template

    target_template.data

  end

  def get_parties(target_template_data, signer_roles, signer_roles_pay)
    target_template_data["signer_roles"].map{ |signer_role|
      this_order = signer_role.data["order"] # order is the signer order
      {
        :order => this_order,
        :name => signer_role.data["name"],
        :email => signer_roles[this_order.to_s],
        :index => this_order.to_i,
        :uuid => SecureRandom.hex,
        # Bool signer_roles_pay[order] from view will reveal if the signee in the order must pay.
        :should_pay => signer_roles_pay ? signer_roles_pay[this_order.to_s] == "true" : false,
        :is_pending_signature => true
      }
    }
  end

  def create_embedded_signature_request_with_template(contract, party, contract_id, uuid)
    HelloSign.create_embedded_signature_request_with_template(  
      :test_mode => 1,
      :client_id => ENV["HELLO_SIGN_CLIENT_ID"],
      :template_id => contract.template_id,
      :subject => 'Test Subject',
      :message => "Signature requested at #{Time.now}",
      :signers => [
        {
          :email_address => party["email"],
          :name => party["name"],
          :role => party["name"]
        }
      ],
      :custom_fields => contract.deal_attributes.map{ |k,v| {:name => k, :value => v} },
      :metadata => {
        "contract_id": contract_id,
        "uuid": uuid
      }
    )    
  end

  def send_signed_document(signature_request_id, uuid)
    file_bin = HelloSign.signature_request_files :signature_request_id => signature_request_id, :file_type => 'pdf'
    open("public/" + uuid + ".pdf", "wb") do |file|
      file.write(file_bin)
    end
  end

end