require "time"

class Storage
  # deal_id (ObjectId)
  # params (Object)
  # commonUuid (String)
  # createdAt (Date)
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  store_in collection: "storage"

  before_create :init_timestamp

  private
  def init_timestamp
    self["createdAt"] = Time.new
  end
end
