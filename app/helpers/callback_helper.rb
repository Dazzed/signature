module CallbackHelper
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

          if thisParty["order"] == 0
            newParty = allParties.find{|party| party["order"] == 1}
            return if newParty.nil?
            link = "#{ENV['EMAIL_SIGNING_URL']}?contract_id=#{thisContract.id.to_s}&uuid=#{newParty["uuid"]}&order=#{newParty["order"]}"
            UserNotifierMailer.send_signature_request_email(allParties, newParty["email"], link).deliver
          end
        end
      end
    end
  end
end
