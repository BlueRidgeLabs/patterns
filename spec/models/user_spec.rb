# frozen_string_literal: true

require "rails_helper"

describe User do
  let(:user) { FactoryBot.create(:user) }

  describe "instance methods" do
    describe "#approve!" do
      it "sets approved true" do
        user.update(approved: false)
        expect(Rails.logger).to receive(:info).with(I18n.t("user.approved", email: user.email))
        user.approve!
        expect(user.reload.approved).to eq(true)
      end
    end

    describe "#unapprove!" do
      it "sets approved true" do
        user.update(approved: true)
        expect(Rails.logger).to receive(:info).with(I18n.t("user.unapproved", email: user.email))
        user.unapprove!
        expect(user.reload.approved).to eq(false)
      end
    end
  end
end
