# frozen_string_literal: true

require "rails_helper"

describe Cart do
  let(:cart) { FactoryBot.create(:cart) }

  describe "callbacks" do
    context "person added to, and removed from, cart" do
      it "enqueues RapidproPersonGroupJob 'add'/'remove' jobs, respectively" do
        person = FactoryBot.create(:person)
        expect(RapidproPersonGroupJob).to receive(:perform_async).with(person.id, cart.id, "add")
        expect(RapidproPersonGroupJob).to receive(:perform_async).with(person.id, cart.id, "remove")
        cart.people << person
        cart.remove_person(person.id)
      end
    end
  end

  describe "public instance methods" do
    describe "#add_user(user_id)" do
      it "adds user to cart, if they aren't already there" do
        cart.users.destroy_all
        user = FactoryBot.create(:user)
        cart.add_user(user.id)
        expect(cart.reload.users.length).to eq(1)
        expect(cart.users.find_by(id: user.id)).to be_truthy
        cart.add_user(user.id)
        expect(cart.reload.users.length).to eq(1)
      end
    end

    describe "#remove_person(person_id)" do
      it "removes person from cart, if they exist" do
        cart.people.destroy_all
        person = FactoryBot.create(:person)
        cart.people << person
        cart.remove_person(person.id)
        expect(cart.reload.people.length).to eq(0)
        expect { cart.remove_person(person.id) }.not_to raise_error
      end
    end
  end

  describe "private instance methods" do
    describe "#update_rapidpro" do
      context "rapidpro_sync is true" do
        it "enqueues Rapidpro create group job" do
          cart.update(rapidpro_sync: true)
          expect(RapidproGroupJob).to receive(:perform_async).with(cart.id, "create")
          cart.send(:update_rapidpro)
        end
      end

      context "rapidpro_sync is false" do
        it "enqueues Rapidpro delete group job" do
          cart.update(rapidpro_sync: false)
          expect(RapidproGroupJob).to receive(:perform_async).with(cart.id, "delete")
          cart.send(:update_rapidpro)
        end
      end
    end
  end
end
