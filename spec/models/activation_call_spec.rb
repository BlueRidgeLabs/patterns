require 'rails_helper'

describe ActivationCall do
  let(:activation_call) { FactoryBot.create(:activation_call) }

  describe "instance methods" do
    describe "#type_transcript" do
      it "works" do
        activation_call.update(call_type: ActivationCall::CALL_TYPE_ACTIVATE)
        expect(activation_call.type_transcript).to eq(I18n.t('activation_call.transcript.activate'))
        activation_call.update(call_type: ActivationCall::CALL_TYPE_CHECK)
        expect(activation_call.type_transcript).to eq(I18n.t('activation_call.transcript.check'))
        activation_call.update_columns(call_type: "covfefe")
        expect(activation_call.type_transcript).to be_nil
      end
    end
  end
end
