class HellosignCreateSigningRequestJob < ApplicationJob
  queue_as :default

  def perform(document)
    # Do something later

    embedded_request = SignatureService::create_embedded_signature_request_with_template(document)
    signature_request_id = embedded_request.data["signature_request_id"]

    #update the signature_id and signature_request_id on document.
    document.parties.each_with_index do |party, i|
      document.parties[i]["signature_request_id"] = signature_request_id
      document.parties[i]["signature_id"] = embedded_request.signatures[i].signature_id
    end
    document.save!

    #email the first person to sign the document
    document.parties.each { |party|
      if party[:order] == 0
        link = "#{Rails.application.credentials[Rails.env.to_sym][:EMAIL_SIGNING_URL]}?document_id=#{document.id.to_s}&uuid=#{party[:uuid]}&order=#{party[:order]}"
        UserNotifierMailer.send_signature_request_email(
          document.parties, 
          party[:email], 
          link, 
          document
        ).deliver
      end
    }
    
  end
end
