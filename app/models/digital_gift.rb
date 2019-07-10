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

  after_create :save_transaction

  # TODO: (EL) move all of this into GiftrocketService
  def self.campaigns
    Giftrocket::Campaign.list
  end

  def self.current_budget
    (GiftrocketService.balance_funding_source.available_cents / 100).to_money
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

  # TODO: (EL) probably move into digital_gift_service
  def create_order_on_giftrocket!(reward)
    order_params = GiftrocketService.create_order!(self, reward)
    update(order_params)
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

    def save_transaction
      TransactionLog.create(transaction_type: 'DigitalGift',
                           from_id: user.budget.id,
                           user_id: user.id,
                           amount: total_for_budget,
                           from_type: 'Budget',
                           recipient_id: id,
                           recipient_type: 'DigitalGift')
    end
end
