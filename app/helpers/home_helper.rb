module HomeHelper
  def pluckFieldsForTemplateSelection(templateResponse)
    return templateResponse.data["templates"].map { |thisTemplate|
      template_id, 
      reusable_form_id,
      title,
      message,
      signer_roles,
      cc_roles,
      documents,
      custom_fields,
      named_form_fields = thisTemplate.values_at(
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

  def signature_request_signed_callback(event)
    metadata = event["signature_request"]["metadata"]
    signature_request_id = event["signature_request"]["signature_request_id"]
    if metadata
      contract_id = metadata["contract_id"]
      uuid = metadata["uuid"]
      thisContract = Document.find(contract_id)
      unless thisContract.nil?
        allParties = thisContract.parties
        thisPartyIndex = allParties.find_index{|party| party["signature_request_id"] == signature_request_id}
        if thisPartyIndex
          thisParty = allParties[thisPartyIndex]
          thisContract.parties[thisPartyIndex]["is_pending_signature"] = false
          thisContract.parties[thisPartyIndex]["signed_at"] = Time.now
          thisContract.save!
        end
      end
    end
  end
end
