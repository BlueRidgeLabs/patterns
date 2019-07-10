# frozen_string_literal: true

class GiftrocketService
  SMALL_DOLLAR_THRESHOLD = 20

  class << self
    def create_order!(digital_gift, reward)
      validate_orderable!(digital_gift, reward)
      funding_source_id = balance_funding_source.id
      external_id = external_id_for(digital_gift, reward)
      campaign_id = campaign_id_for(digital_gift)
      order = Giftrocket::Order.create!({
        external_id: external_id,
        funding_source_id: funding_source_id,
        campaign_id: campaign_id,
        gifts: generate_gifts_for(digital_gift)
      })
      gift = order.gifts.first
      {
        external_id: external_id,
        funding_source_id: funding_source_id,
        campaign_id: campaign_id,
        fee: order.payment.fees,
        order_id: order.id,
        gift_id: gift.id,
        link: gift.raw['recipient']['link'],
        order_details: Base64.encode64(Marshal.dump(order))
      }
    end

    def balance_funding_source
      Giftrocket::FundingSource.list.find { |fs| fs.method == 'balance' }
    end

    private

      def validate_orderable!(digital_gift, reward)
        user = digital_gift.user
        associations_are_invalid = digital_gift.person_id.nil? || reward.giftable_id.nil? || reward.giftable_type.nil?
        budget_sufficient = (digital_gift.amount + expected_fee_for(digital_gift)) <= user.available_budget
        raise if associations_are_invalid
        raise 'Insufficient budget to order from Giftrocket' unless budget_sufficient
      end

      def expected_fee_for(digital_gift)
        digital_gift.amount.to_i < SMALL_DOLLAR_THRESHOLD ? 0.to_money : 3.to_money
      end

      def campaign_id_for(digital_gift)
        if digital_gift.amount.to_i < SMALL_DOLLAR_THRESHOLD
          # small dollar amounts, no fee
          ENV['GIFTROCKET_LOW_CAMPAIGN']
        else
          # high dolalr amounts, $2 fee
          ENV['GIFTROCKET_HIGH_CAMPAIGN']
        end
      end

      def external_id_for(digital_gift, reward)
        {
          person_id: digital_gift.person_id,
          giftable_id: reward.giftable_id,
          giftable_type: reward.giftable_type
        }.to_json
      end

      def generate_gifts_for(digital_gift)
        person = digital_gift.person
        [
          {
            amount: digital_gift.amount.to_s,
            recipient: {
              name: person.full_name,
              delivery_method: 'LINK'
            }
          }
        ]
      end

  end
end
