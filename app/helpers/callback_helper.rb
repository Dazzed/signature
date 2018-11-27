module CallbackHelper
  def signature_request_signed_callback(event)
    metadata = event["signature_request"]["metadata"]
    signature_request_id = event["signature_request"]["signature_request_id"]
    if metadata
      contract_id = metadata["contract_id"]
      uuid = metadata["uuid"]
      this_contract = Document.find(contract_id)
      unless this_contract.nil?
        all_parties = this_contract.parties
        this_party_index = all_parties.find_index{|party| party["signature_request_id"] == signature_request_id}
        if this_party_index
          this_party = all_parties[this_party_index]
          this_contract.parties[this_party_index]["is_pending_signature"] = false
          this_contract.parties[this_party_index]["signed_at"] = Time.now
          this_contract.save!

          if this_party["order"] == 0
            new_party = all_parties.find{|party| party["order"] == 1}
            return if new_party.nil?
            link = "#{ENV['EMAIL_SIGNING_URL']}?contract_id=#{this_contract.id.to_s}&uuid=#{new_party["uuid"]}&order=#{new_party["order"]}"
            UserNotifierMailer.send_signature_request_email(all_parties, new_party["email"], link, this_contract.document_title).deliver
          end
        end
      end
    end
  end
end
