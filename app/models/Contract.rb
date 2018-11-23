require "time"

class Contract
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  store_in collection: "contracts"

  before_create :init_timestamp

  private
  def init_timestamp
    self["createdAt"] = Time.new
  end
end
