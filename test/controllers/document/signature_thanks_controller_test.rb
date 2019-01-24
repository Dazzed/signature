require 'test_helper'

class SignatureThanksControllerTest < ActionDispatch::IntegrationTest
  test "Signature Thank You" do
    get document_signature_thanks_url
    assert_response :success
    assert_select "p", "Your request has been processed successfully."
  end
end
