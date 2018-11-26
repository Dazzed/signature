module HomeHelper
  def pluckFieldsForTemplateSelection(template_response)
    return template_response.data["templates"].map { |thisTemplate|
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
end
