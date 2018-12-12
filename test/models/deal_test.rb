require 'test_helper'

class DealTest < ActiveSupport::TestCase
  test "Create new deal" do
    deal_params = {"client_deal_id"=>"_12345abcdef", "IsAvailable"=>"Full Time available", "Actual Job Description"=>"Senior React JS Developer", "Validity date"=>"Upto April 2019", "Manager"=>"niraj.bothra@gmail.com", "Client"=>"sameep.dev@gmail.com", "deal_amount"=>"1000", "deal_title"=>"First Deal", "deal_currency"=>"USD"}

    deal = Deal.new(:client_deal_id => deal_params["client_deal_id"], :deal_attributes => deal_params.to_json)

    assert deal.save
  end
  test "Update deal" do
    deal_params = {"client_deal_id"=>"_12345abcdefg", "IsAvailable"=>"Full Time available", "Actual Job Description"=>"Senior React JS Developer", "Validity date"=>"Upto April 2019", "Manager"=>"niraj.bothra@gmail.com", "Client"=>"sameep.dev@gmail.com", "deal_amount"=>"1000", "deal_title"=>"First Deal", "deal_currency"=>"USD"}
    deal = Deal.new(:client_deal_id => deal_params["client_deal_id"], :deal_attributes => deal_params.to_json)
    deal.save

    update_deal_params = {"client_deal_id"=>"_12345abcdefg", "IsAvailable"=>"Full Time available", "Actual Job Description"=>"Senior React JS Developer", "Validity date"=>"Upto April 2019", "Manager"=>"niraj.bothra@gmail.com", "Client"=>"sameep.dev@gmail.com", "deal_amount"=>"1990", "deal_title"=>"First Deal", "deal_currency"=>"USD"}

    update_deal = Deal.find_by(:client_deal_id => update_deal_params["client_deal_id"])

    update_deal.deal_attributes = update_deal_params.to_json

    assert update_deal.save
  end
end
