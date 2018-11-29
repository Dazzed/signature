require "time"

class Deal
  # deal_id (ObjectId)
  # params (Object)
  # common_uuid (String)
  # createdAt (Date)
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  store_in collection: "deal"

  before_create :init_timestamp

  private
  def init_timestamp
    self["createdAt"] = Time.new
  end
end
