require 'test_helper'

class HellosignControllerTest < ActionDispatch::IntegrationTest
  test "HelloSign Callback" do
    post callbacks_hellosign_index_url, params: {"json" => "{\"event\": {\"event_type\": \"signature_request_signed\",\"event_metadata\": {\"signature_request_id\": \"1234\",\"related_signature_id\": \"5678\"}},\"signature_request\": {\"metadata\": {\"document_id\": \"" + Document.first.id + "\"}}}"}
    
    assert_response :success
  end

end
