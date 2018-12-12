require 'test_helper'

class PaymentThanksControllerTest < ActionDispatch::IntegrationTest
  test "Payment Thank You" do
    get deal_payment_thanks_url
    assert_response :success
    assert_select "p", "Your payment has been processed successfully."
  end

end

