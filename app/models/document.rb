require "time"

# deal_id (Object_id)
# parties (Array)
# template_id(String)
# deal_attributes (Object)
# createdAt(Date)
class Document
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  store_in collection: "contracts"

  before_create :init_timestamp

  private
  def init_timestamp
    self["createdAt"] = Time.new
  end
end
