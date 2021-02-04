# frozen_string_literal: true

require 'rails_helper'

RSpec.describe S3BackupService do
  let(:sut) { described_class.new }

  describe 'with correct keys' do
    it 'uploads and encrypts and downloads' do
      sut.upload(file_fixture('encryption_test.txt').to_s)
      sut.download('encryption_test.txt', file_fixture('testing.pem').to_s, Rails.root.join('tmp/'))
      # check are they the same?
      expect(file_fixture('encryption_test.txt').read).to eq(File.read(Rails.root.join('tmp/encryption_test.txt')))
    end
  end
end
