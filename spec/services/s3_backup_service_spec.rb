# frozen_string_literal: true

require 'rails_helper'

RSpec.describe S3BackupService do
  let(:sut) { described_class.new }

  xdescribe 'sends expected args to s3' do
    xit 'works' do
      # sut.upload(file_fixture('encryption_test.txt').to_s)
      # sut.download('encryption_text.txt',file_fixture('encryption_test.txt').to_s,"#{Rails.root.to_s}/tmp/")
      # check are they the same?
      # probably using vcr, I think.
    end
  end
end
