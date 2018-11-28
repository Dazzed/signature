require "time"

# deal_id (Object_id)
# parties (Array)
# template_id(String)
# deal_attributes (Object)
# createdAt(Date)
class Document
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  store_in collection: "documents"

  before_create :init_timestamp
  after_create :send_signing_request

  def send_signing_request
    # Send Email to relevant parties
    self.parties.each { |this_party|
      if this_party[:order] == 0
        link = "#{ENV['EMAIL_SIGNING_URL']}?contract_id=#{self.id.to_s}&uuid=#{this_party[:uuid]}&order=#{this_party[:order]}"
        UserNotifierMailer.send_signature_request_email(
          self.parties, 
          this_party[:email], 
          link, 
          self.document_title
        ).deliver
      end
    }
  end

  def handle_request_signed(uuid, signature_request_id)
    all_parties = self.parties
    this_party_index = all_parties.find_index{|party| party["signature_request_id"] == signature_request_id}
    if this_party_index
      this_party = all_parties[this_party_index]
      self.parties[this_party_index]["is_pending_signature"] = false
      self.parties[this_party_index]["signed_at"] = Time.now
      self.save!

      if this_party["order"] == 0
        new_party = all_parties.find{|party| party["order"] == 1}
        return if new_party.nil?
        link = "#{ENV['EMAIL_SIGNING_URL']}?contract_id=#{self.id.to_s}&uuid=#{new_party["uuid"]}&order=#{new_party["order"]}"
        UserNotifierMailer.send_signature_request_email(all_parties, new_party["email"], link, self.document_title).deliver
      end
    end
  end

  def send_signed_document(uuid, signature_request_id)
    all_parties = self.parties
    this_party_index = all_parties.find_index{|party| party["signature_request_id"] == signature_request_id}
    if this_party_index
      this_party = all_parties[this_party_index]
      if this_party["order"] == 1
        HellosignService.new().send_signed_document(signature_request_id, uuid)
        all_parties.each do |party|
          UserNotifierMailer.send_signed_document(uuid + '.pdf', self.document_title, party["email"]).deliver
        end
      end
    end
  end

  private
  def init_timestamp
    self["createdAt"] = Time.new
  end
end
