# The purpose of this 'test' is to render emails to disk,
# So that a developer can look in tmp/emails and open them up and verify that they look OK
# Also, to have Jenkins archive them to make it easier to check if a build look OK

require "spec_helper"

describe "RenderMailers", :slow => true do

  let(:user) { FactoryGirl.create(:user) }

  before(:each) do
    @filename = nil # set this on your test to pin the filename; i just make it the name of the mailer method responsible for sending the mail
  end

  describe "UserMailer emails" do

    before(:each) do
      user.update_email = "test@bz.com"
      UserMailer.deliveries.clear
    end

    after(:each) do
      UserMailer.deliveries.length.should == 1
      mail = UserMailer.deliveries[0]
      save_emails_to_disk(mail, @filename)
    end

    it { @filename="welcome_message"; UserMailer.welcome_message(user).deliver }
    it { @filename="confirm_email"; UserMailer.confirm_email(user, "/signup").deliver }
    it { @filename="password_reset"; UserMailer.password_reset(user, '/reset_password').deliver }
    it { @filename="password_changed"; UserMailer.password_changed(user).deliver }
    it { @filename="updated_email"; UserMailer.updated_email(user).deliver }
    it { @filename="updating_email"; UserMailer.updating_email(user).deliver }

    describe "has sending user" do
      let(:user2) { FactoryGirl.create(:user) }
      let(:friend_request) {FactoryGirl.create(:friend_request, user:user, friend: user2)}

      it { @filename="text_message"; UserMailer.text_message(user.email, user2.id, user2.name, user2.resolved_photo_url, 'Get online!!').deliver }
      it { @filename="friend_request"; UserMailer.friend_request(user.email, 'So and so has sent you a friend request.', friend_request.id).deliver}
    end
  end

  describe "InvitedUserMailer emails" do

    let(:user2) { FactoryGirl.create(:user) }
    let(:invited_user) { FactoryGirl.create(:invited_user, :sender => user2) }
    let(:admin_invited_user) { FactoryGirl.create(:invited_user) }

    before(:each) do
      InvitedUserMailer.deliveries.clear
    end

    after(:each) do
      UserMailer.deliveries.length.should == 2
      # NOTE! we take the second email, because the act of creating the InvitedUser model
      # sends an email too, before our it {} block runs.  This is because we have an InvitedUserObserver
      mail = InvitedUserMailer.deliveries[1]
      save_emails_to_disk(mail, @filename)
    end

    it { @filename="friend_invitation"; InvitedUserMailer.deliveries.clear; InvitedUserMailer.friend_invitation(invited_user).deliver }
    it { @filename="welcome_betauser"; InvitedUserMailer.welcome_betauser(admin_invited_user).deliver }
  end

  describe "Daily Scheduled Session emails" do
    let (:scheduled_batch) { FactoryGirl.create(:email_batch_scheduled_session) }
    let(:music_session) { FactoryGirl.create(:music_session) }
    let (:drums) { FactoryGirl.create(:instrument, :description => 'drums') }
    let (:guitar) { FactoryGirl.create(:instrument, :description => 'guitar') }
    let (:bass) { FactoryGirl.create(:instrument, :description => 'bass') }
    let (:vocals) { FactoryGirl.create(:instrument, :description => 'vocal') }

    let (:drummer) { FactoryGirl.create(:user, :last_jam_locidispid => 1, :last_jam_addr => 1) }
    let (:guitarist) { FactoryGirl.create(:user, :last_jam_locidispid => 1, :last_jam_addr => 1) }
    let (:bassist) { FactoryGirl.create(:user, :last_jam_locidispid => 1, :last_jam_addr => 1) }
    let (:vocalist) { FactoryGirl.create(:user, :last_jam_locidispid => 1, :last_jam_addr => 1) }

    let (:session1) do
      FactoryGirl.create(:music_session,
                         :creator => drummer,
                         :scheduled_start => Time.now() + 2.days,
                         :musician_access => true,
                         :approval_required => false,
                         :created_at => Time.now - 1.hour)
    end

    let (:session2) do
      FactoryGirl.create(:music_session,
                         :creator => drummer,
                         :scheduled_start => Time.now() + 2.days,
                         :musician_access => true,
                         :approval_required => false,
                         :created_at => Time.now - 1.hour)
    end

    before(:each) do
      BatchMailer.deliveries.clear
      scheduled_batch.reset!

      drummer.musician_instruments << FactoryGirl.build(:musician_instrument, user: drummer, instrument: drums, proficiency_level: 2)
      drummer.musician_instruments << FactoryGirl.build(:musician_instrument, user: drummer, instrument: guitar, proficiency_level: 2)

      guitarist.musician_instruments << FactoryGirl.build(:musician_instrument, user: guitarist, instrument: guitar, proficiency_level: 2)
      guitarist.musician_instruments << FactoryGirl.build(:musician_instrument, user: guitarist, instrument: bass, proficiency_level: 2)

      vocalist.musician_instruments << FactoryGirl.build(:musician_instrument, user: vocalist, instrument: vocals, proficiency_level: 2)

      FactoryGirl.create(:rsvp_slot, :instrument => drums, :music_session => session1)
      FactoryGirl.create(:rsvp_slot, :instrument => guitar, :music_session => session1)
      FactoryGirl.create(:rsvp_slot, :instrument => bass, :music_session => session1)

      FactoryGirl.create(:rsvp_slot, :instrument => drums, :music_session => session2)
      FactoryGirl.create(:rsvp_slot, :instrument => guitar, :music_session => session2)
      FactoryGirl.create(:rsvp_slot, :instrument => bass, :music_session => session2)

      JamRuby::Score.createx(1, 'a', 1, 1, 'a', 1, 10)
      JamRuby::Score.createx(1, 'a', 1, 2, 'a', 2, Score::MAX_YELLOW_LATENCY + 1)
    end

    after(:each) do
      BatchMailer.deliveries.length.should == 1
      mail =  BatchMailer.deliveries[0]
      save_emails_to_disk(mail, @filename)
    end

    it "daily sessions" do @filename="daily_sessions"; scheduled_batch.deliver_batch end
  end

end

def save_emails_to_disk(mail, filename)
  # taken from: https://github.com/originalpete/actionmailer_extensions/blob/master/lib/actionmailer_extensions.rb
  # this extension does not work with ActionMailer 3.x, but this method is all we need

  if filename.nil?
    filename = mail.subject
  end

  email_output_dir = 'tmp/emails'
  FileUtils.mkdir_p(email_output_dir) unless File.directory?(email_output_dir)
  filename = "#{filename}.eml"
  File.open(File.join(email_output_dir, filename), "w+") {|f|
    f << mail.encoded
  }
end