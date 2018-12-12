require 'test_helper'

class PaymentsControllerTest < ActionDispatch::IntegrationTest
  test "New Deal Payment" do
    get new_deal_payment_url, params: { :client_deal_id => "_12345abcde", :client_email => "niraj.bothra@gmail.com"}
    assert_response :success
  end
  
  test "New Deal Payment - Fail " do
    get new_deal_payment_url, params: {}
    assert_response :success
    assert_select "p", 'Looks like you have reached here incorrectly.'
  end

  test "Create Deal Payment" do 
    token = "abcd"
    post deal_payments_url, params: {:client_deal_id => "_12345abcde", :stripeToken => token }
    assert_response :redirect
    assert_redirected_to deal_payment_thanks_url

  end

  test "Create Deal Payment - Fail" do
    post deal_payments_url, params: { }
    assert_response :success
    assert_select "p", 'Looks like you have reached here incorrectly.'
  end

end
 