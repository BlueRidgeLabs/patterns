class GiftrocketService
  SMALL_DOLLAR_THRESHOLD = 20

  class << self
    def create_order!(digital_gift)
      funding_source_id = balance_funding_source.id
      external_id = external_id_for(digital_gift)
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

    def campaign_id_for(digital_gift)
      if digital_gift.amount.to_i < SMALL_DOLLAR_THRESHOLD
        # small dollar amounts, no fee
        ENV['GIFTROCKET_LOW_CAMPAIGN']
      else
        # high dolalr amounts, $2 fee
        ENV['GIFTROCKET_HIGH_CAMPAIGN']
      end
    end

    def external_id_for(digital_gift)
      {
        person_id: digital_gift.person_id,
        giftable_id: digital_gift.giftable_id,
        giftable_type: digital_gift.giftable_type
      }.to_json
    end

    def generate_gifts_for(digital_gift)
      person = digital_gift.person
      raise if person.nil?
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
