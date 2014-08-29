require "spec_helper"

###########################################################
# We test just the mailer templating here.                #
# In other words, make sure there are no glaring oopsies, #
# such as broken templates, or sending to wrong address   #
###########################################################


describe UserMailer do

  let(:user) { FactoryGirl.create(:user) }

  before(:each) do
    UserMailer.deliveries.clear
  end



  describe "should send confirm email" do

    let (:mail) { UserMailer.deliveries[0] }
    let (:signup_confirmation_url) { "http://example.com/confirm" }
    let (:signup_confirmation_url_with_token  ) { "#{signup_confirmation_url}/#{user.signup_token}" }

    before(:each) do
      UserMailer.confirm_email(user, signup_confirmation_url_with_token).deliver
    end


    it { UserMailer.deliveries.length.should == 1 }
    it { mail['from'].to_s.should == UserMailer::DEFAULT_SENDER }
    it { mail['to'].to_s.should == user.email }
    it { mail.multipart?.should == true } # because we send plain + html

    # verify that the messages are correctly configured
    it { mail.html_part.body.include?("Welcome").should be_true }
    it { mail.html_part.body.include?(signup_confirmation_url_with_token).should be_true }
    it { mail.text_part.body.include?("Welcome").should be_true  }
    it { mail.text_part.body.include?(signup_confirmation_url_with_token).should be_true }
  end

  describe "should send welcome email" do

    let (:mail) { UserMailer.deliveries[0] }

    before(:each) do
      UserMailer.welcome_message(user).deliver
    end


    it { UserMailer.deliveries.length.should == 1 }
    it { mail['from'].to_s.should == UserMailer::DEFAULT_SENDER }
    it { mail['to'].to_s.should == user.email }
    it { mail.multipart?.should == true } # because we send plain + html

    # verify that the messages are correctly configured
    it { mail.html_part.body.include?("delighted").should be_true }
    it { mail.text_part.body.include?("delighted").should be_true  }
  end

  describe "should send reset password" do

    let(:mail) { UserMailer.deliveries[0] }
    before(:each) do
      UserMailer.password_reset(user, '/reset_password').deliver
    end


    it { UserMailer.deliveries.length.should == 1 }

    it { mail['from'].to_s.should == UserMailer::DEFAULT_SENDER }
    it { mail['to'].to_s.should == user.email }
    it { mail.multipart?.should == true } # because we send plain + html

    # verify that the messages are correctly configured
    it { mail.html_part.body.include?("Reset").should be_true }
    it { mail.text_part.body.include?("Reset").should be_true }
  end

  describe "should send change password confirmation" do

    let(:mail) { UserMailer.deliveries[0] }

    before(:each) do
      UserMailer.password_changed(user).deliver
    end

    it { UserMailer.deliveries.length.should == 1 }

    it { mail['from'].to_s.should == UserMailer::DEFAULT_SENDER }
    it { mail['to'].to_s.should == user.email }
    it { mail.multipart?.should == true } # because we send plain + html

    # verify that the messages are correctly configured
    it { mail.html_part.body.include?("changed your password").should be_true }
    it { mail.text_part.body.include?("changed your password").should be_true }
  end

  describe "should send update email confirmation" do

    let(:mail) { UserMailer.deliveries[0] }

    before(:each) do
      UserMailer.updated_email(user).deliver
    end

    it { UserMailer.deliveries.length.should == 1 }

    it { mail['from'].to_s.should == UserMailer::DEFAULT_SENDER }
    it { mail['to'].to_s.should == user.email }
    it { mail.multipart?.should == true } # because we send plain + html

    # verify that the messages are correctly configured
    it { mail.html_part.body.include?("<b>#{user.email}</b> has been confirmed as your new email address.").should be_true }
    it { mail.text_part.body.include?("#{user.email} has been confirmed as your new email address.").should be_true }
  end

  describe "should send updating email" do

    let(:mail) { UserMailer.deliveries[0] }

    before(:each) do
      user.update_email = "test@bz.com"
      UserMailer.updating_email(user).deliver
    end

    it { UserMailer.deliveries.length.should == 1 }

    it { mail['from'].to_s.should == UserMailer::DEFAULT_SENDER }
    it { mail['to'].to_s.should == user.update_email }
    it { mail.multipart?.should == true } # because we send plain + html

    # verify that the messages are correctly configured
    it { mail.html_part.body.include?("to confirm your change in email").should be_true }
    it { mail.text_part.body.include?("to confirm your change in email").should be_true }
  end


  # describe "sends new musicians email" do

  #   let(:mail) { UserMailer.deliveries[0] }

  #   before(:each) do
  #     UserMailer.new_musicians(user, User.musicians).deliver
  #   end

  #   it { UserMailer.deliveries.length.should == 1 }

  #   it { mail['from'].to_s.should == UserMailer::DEFAULT_SENDER }
  #   it { mail['to'].to_s.should == user.email }
  #   it { mail.multipart?.should == true } # because we send plain + html

  #   # verify that the messages are correctly configured
  #   it { mail.html_part.body.include?("New BZ.Inc in your Area").should be_true }
  #   it { mail.text_part.body.include?("New BZ.Inc in your Area").should be_true }
  # end

end
