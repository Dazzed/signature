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

  private
  def init_timestamp
    self["createdAt"] = Time.new
  end
end
