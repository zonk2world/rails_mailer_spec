require "spec_helper"

describe BatchMailer do

  describe "should send test emails" do
    ActionMailer::Base.deliveries.clear

    batch = FactoryGirl.create(:email_batch)
    batch.send_test_batch

    mail = BatchMailer.deliveries.detect { |dd| dd['to'].to_s.split(',')[0] == batch.test_emails.split(',')[0]}
    # let (:mail) { BatchMailer.deliveries[0] }
    # it { mail['to'].to_s.split(',')[0].should == batch.test_emails.split(',')[0] }
    
    it { mail.should_not be_nil }

    # it { BatchMailer.deliveries.length.should == 1 }

    it { mail['from'].to_s.should == EmailBatch::DEFAULT_SENDER }
    it { mail.subject.should == batch.subject }

    it { mail.multipart?.should == true } # because we send plain + html
    it { mail.text_part.decode_body.should match(/#{Regexp.escape(batch.body)}/) }

    it { batch.testing?.should == true }
  end

end
