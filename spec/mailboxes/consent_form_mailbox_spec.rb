require 'rails_helper'

RSpec.describe ConsentFormMailbox, type: :mailbox do
  # before :each do
  #   @file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'brl_consent_form_2020.pdf'), 'application/pdf')
  # end

  let(:person) { FactoryBot.create(:person) }
  subject do
    receive_inbound_email_from_mail(
      from: 'from-address@example.com',
      to: 'consent.form.ao0v9ahsdbcnkjn@example.com',
      subject: person.token.to_s,
      body: "I'm a sample body",
      attachments: [{'consent.pdf' => File.read(Rails.root.join('spec', 'fixtures', 'files', 'brl_consent_form_2020.pdf'))}]
    )
  end

  xit do
    expect { subject }.to change(person.consent_form, :attached?).from(false).to(true)
  end
end
