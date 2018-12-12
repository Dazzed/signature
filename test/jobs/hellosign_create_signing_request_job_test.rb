require 'test_helper'

class HellosignCreateSigningRequestJobTest < ActiveJob::TestCase
  test "Signing Request Sent" do
    
    HellosignCreateSigningRequestJob.perform_now(Document.first)
    assert !Document.first.parties[0]["signature_request_id"].nil?
  end
end
