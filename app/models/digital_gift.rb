# frozen_string_literal: true

# == Schema Information
#
# Table name: digital_gifts
#
#  id                :bigint(8)        not null, primary key
#  order_details     :text(65535)
#  created_by        :integer          not null
#  user_id           :integer
#  person_id         :integer
#  reward_id         :integer
#  giftrocket_status :string(255)
#  external_id       :string(255)
#  order_id          :string(255)
#  gift_id           :string(255)
#  link              :text(65535)
#  amount_cents      :integer          default(0), not null
#  amount_currency   :string(255)      default("USD"), not null
#  fee_cents         :integer          default(0), not null
#  fee_currency      :string(255)      default("USD"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  campaign_id       :string(255)
#  campaign_title    :string(255)
#  funding_source_id :string(255)
#  sent              :boolean
#  sent_at           :datetime
#  sent_by           :integer
#

# first we create the giftrocket, with a person and user and created_by
# then we check budgets, local and remote
# then we try to make the order
# then if the order is successful
# we create the reward and update the front end
# if error, we update the front end with an error
class DigitalGift < ApplicationRecord
  include Rewardable
  page 50

  monetize :fee_cents
  has_one :budget, through: :user
  has_one :transaction_log, as: :recipient
  has_many :comments, as: :commentable, dependent: :destroy

  validate :can_order? # doesn't actually validate

  after_create :save_transaction
  delegate :name, to: :person
  attr_accessor :giftable_id
  attr_accessor :giftable_type

  def self.campaigns
    Giftrocket::Campaign.list
  end

  def self.funding_sources
    Giftrocket::FundingSource.list
  end

  def self.balance_funding_source
    DigitalGift.funding_sources.find { |fs| fs.method == "balance" }
  end

  def self.current_budget
    (DigitalGift.funding_sources.find { |fs| fs.method == "balance" }.available_cents / 100).to_money
  end

  def self.orders
    Giftrocket::Order.list
  end

  def self.gifts
    Giftrocket::Gift.list
  end

  def fetch_gift
    raise if gift_id.nil?

    Giftrocket::Gift.retrieve(gift_id)
  end

  def check_status
    # STATUS                          Explanation
    # SCHEDULED_FOR_FUTURE_DELIVERY   self explanatory
    # DELIVERY_ATTEMPTED              receipt not confirmed
    # EMAIL_BOUNCED                   only if we email things
    # DELIVERED                       receipt confirmed (Everytime, this)
    # I assume REDEEMED is a status?

    fetch_gift.status
  end

  # is this really how I want to do it?
  def request_link
    raise if person_id.nil? || giftable_id.nil? || giftable_type.nil?
    raise unless can_order?

    self.funding_source_id = DigitalGift.balance_funding_source.id

    self.campaign_id = if amount.to_i < 20
      # small dollar amounts, no fee
      ENV["GIFTROCKET_LOW_CAMPAIGN"]
    else
      # high dolalr amounts, $2 fee
      ENV["GIFTROCKET_HIGH_CAMPAIGN"]
    end

    generate_external_id

    my_order = Giftrocket::Order.create!(generate_order)
    self.fee = my_order.payment.fees
    self.order_id = my_order.id

    gift = my_order.gifts.first
    self.gift_id = gift.id
    self.link = gift.raw["recipient"]["link"]
    self.order_details = Base64.encode64(Marshal.dump(my_order))
  end

  def expected_fee
    # fee is $3 if amount is less than $20
    amount.to_i < 20 ? 0.to_money : 3.to_money
  end

  # this is where we check if we can actually request this gift
  # first from our user's team budget
  # then from giftrocket, and then we make the request
  def can_order?
    (amount + expected_fee) <= user.available_budget
  end

  # maybe this is just a
  def generate_external_id
    self.external_id = { person_id: person_id,
                         giftable_id: giftable_id,
                         giftable_type: giftable_type }.to_json

    external_id
  end

  # rubocop:disable Security/MarshalLoad
  # we want to save the full object. probably don't need to,
  # but it's handy
  def order_data
    @order_data ||= Marshal.load(Base64.decode64(order_details))
  end
  # rubocop:enable Security/MarshalLoad

  # use actioncable again to update our front end status
  def update_frontend_success; end

  def update_frontend_failure; end

  private
    def generate_gifts
      raise if person.nil?

      [
        {
          amount: amount.to_s,
          recipient: {
            name: person.full_name,
            delivery_method: "LINK"
          }
        }
      ]
    end

    def generate_order
      {
        external_id: external_id,
        funding_source_id: funding_source_id,
        campaign_id: campaign_id,
        gifts: generate_gifts
      }
    end

    def save_transaction
      TransactionLog.create(transaction_type: "DigitalGift",
                            from_id: user.budget.id,
                            user_id: user.id,
                            amount: total_for_budget,
                            from_type: "Budget",
                            recipient_id: id,
                            recipient_type: "DigitalGift")
    end
end
