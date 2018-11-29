require "time"

class Deal
  # deal_id (ObjectId)
  # deal_attributes (Object)
  # createdAt (Date)
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  store_in collection: "deal"

  has_many :documents

  before_create :init_timestamp

  private
  def init_timestamp
    self["createdAt"] = Time.new
  end
end
