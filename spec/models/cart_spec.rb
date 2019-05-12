require 'rails_helper'

describe Cart do
  let(:cart) { FactoryBot.create(:cart) }

  describe "methods" do
    describe "#add_user_to_cart(user_id)" do
      it "adds user to cart, if they aren't already there" do
        cart.users.destroy_all
        user = FactoryBot.create(:user)
        cart.add_user_to_cart(user.id)
        expect(cart.reload.users.length).to eq(1)
        expect(cart.users.find_by(id: user.id)).to be_truthy
        cart.add_user_to_cart(user.id)
        expect(cart.reload.users.length).to eq(1)
      end
    end
  end
end
