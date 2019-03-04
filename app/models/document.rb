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

  attr_accessor :api_link
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
      self.email_next_party(party)
    end
  end

  def email_next_party(party)
    all_parties = self.parties
    if party["order"] == 0
      new_party = all_parties.find{|party| party["order"] == 1}
      return if new_party.nil?
      link = "#{ENV['EMAIL_SIGNING_URL']}?document_id=#{self.id.to_s}&uuid=#{new_party["uuid"]}&order=#{new_party["order"]}"
      UserNotifierMailer.send_signature_request_email(all_parties, new_party["email"], link, self.document_title).deliver
    end
  end
  def send_signed_document(signature_request_id)
    all_parties = self.parties
    HellosignService::store_signed_document(signature_request_id)
    all_parties.each do |party|
      UserNotifierMailer.email_signed_document(signature_request_id + '.pdf', self.document_title, party["email"]).deliver
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
    HellosignCreateSigningRequestJob.perform_now(document)
  end

end
