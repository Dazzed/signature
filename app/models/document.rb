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

  belongs_to :deal

  before_create :init_timestamp
  after_create :send_signing_request

  def handle_request_signed(signature_id)
    all_parties = self.parties
    party_index = all_parties.find_index{|party| party["signature_id"] == signature_id}
    if party_index
      party = all_parties[party_index]
      self.parties[party_index]["is_pending_signature"] = false
      self.parties[party_index]["signed_at"] = Time.now
      self.save!

      if party["order"] == 0
        new_party = all_parties.find{|party| party["order"] == 1}
        return if new_party.nil?
        link = "#{ENV['EMAIL_SIGNING_URL']}?document_id=#{self.id.to_s}&uuid=#{new_party["uuid"]}&order=#{new_party["order"]}"
        UserNotifierMailer.send_signature_request_email(all_parties, new_party["email"], link, self.document_title).deliver
      end
    end
  end

  def send_signed_document(signature_request_id)
    all_parties = self.parties
    HellosignService::send_signed_document(signature_request_id)
    all_parties.each do |party|
      UserNotifierMailer.send_signed_document(signature_request_id + '.pdf', self.document_title, party["email"]).deliver
    end
    self.complete = true
    self.save!
  end

  private
  
  def init_timestamp
    self["createdAt"] = Time.new
  end

  def send_signing_request
    # create an embedded request for signature
    document = self
    embedded_request = HellosignService::create_embedded_signature_request_with_template(document)
    signature_request_id = embedded_request.data["signature_request_id"]

    #update the signature_id and signature_request_id on document.
    self.parties.each_with_index do |party, i|
      self.parties[i]["signature_request_id"] = signature_request_id
      self.parties[i]["signature_id"] = embedded_request.signatures[i].signature_id
    end
    self.save!

    #email the first person to sign the document
    self.parties.each { |party|
      if party[:order] == 0
        link = "#{ENV['EMAIL_SIGNING_URL']}?document_id=#{self.id.to_s}&uuid=#{party[:uuid]}&order=#{party[:order]}"
        UserNotifierMailer.send_signature_request_email(
          self.parties, 
          party[:email], 
          link, 
          self.document_title
        ).deliver
      end
    }
  end

end
