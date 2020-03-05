# frozen_string_literal: true

# amount: dg_params['amount'],
# person_id: dg_params['person_id'],
# giftable_type: dg_params['giftable_type'],
# giftable_id: dg_params['giftable_id'],
# reason: dg_params['reason'],
# notes: dg_params['notes']

class DigitalGiftService
  class << self
    def validate_params(current_user, params)
      validate_giftable!(params)
      validate_amount!(current_user, params)
    end

    # TODO: (EL) work out kinks, test, and call inside of dg_controller
    def create(user, params)
      validate_giftable!(params)
      validate_amount!(user, params)

      user_id = user.id
      team = user&.team
      dg_params = params.slice(:amount, :person_id).merge({ user_id: user_id, created_by: user_id })
      reward_params = params.merge({ finance_code: team&.finance_code, team: team, rewardable_type: "DigitalGift" })
      digital_gift = DigitalGift.new(dg_params)
      reward = Reward.new(reward_params)

      if digital_gift.valid?
        digital_gift.create_order_on_giftrocket!(reward)
        reward.rewardable_id = digital_gift.id
        reward.save
        digital_gift.assign(reward.id) # is this necessary?
        digital_gift.save
      else
        raise digital_gift.errors.full_messages
      end
    end

    def validate_giftable!(params)
      giftable = giftable_for(params)
      raise "No giftable object present" if giftable.nil?

      person_name = giftable.person.full_name
      if params[:giftable_type] == "Invitation"
        raise "#{person_name} isn't marked as 'attended'." unless giftable.attended?
        raise "#{person_name} Already has a digital gift" if giftable.has_digitable_gift?
      end
    end

    def validate_amount!(user, params)
      budget_insufficient = params["amount"].to_money + 2.to_money >= user.available_budget
      raise "Insufficient Team Budget" if budget_insufficient
    end

    def giftable_for(params)
      id, type = params.values_at(:giftable_id, :giftable_type)
      klass = GIFTABLE_TYPES.fetch(type)
      klass.find_by(id: id)
    end
  end
end
