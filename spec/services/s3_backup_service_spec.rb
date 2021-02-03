# frozen_string_literal: true

require 'rails_helper'

RSpec.describe S3BackupService do
  let(:sut) { described_class }

  xdescribe 'sends expected args to s3' do
    xit 'works' do
      expect(Rails.logger.info).to receive('Object uploaded')
      sut.upload('spec/fixtures/encryption_test.txt')
    end

    xit 'does not work' do
    end
  end
end
