require 'test_helper'

class DealsControllerTest < ActionDispatch::IntegrationTest
  test "Deal Index" do
    
    get deals_url, params: {"client_deal_id"=>"_12345abcde", "IsAvailable"=>"Full Time available", "Actual Job Description"=>"Senior React JS Developer", "Validity date"=>"Upto April 2019", "Manager"=>"niraj.bothra@gmail.com", "Client"=>"sameep.dev@gmail.com", "deal_amount"=>"1000", "deal_title"=>"First Deal", "deal_currency"=>"USD"}

    assert_response :success
    assert_equal Deal.all.count, 1

    assert_select "h3", 'Select A Template 4'
  end
end
