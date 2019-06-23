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

    def create(user, params)
      validate_giftable!(params)
      validate_amount!(user, params)

      user_id = user.id
      team = user&.team
      dg_params = params.slice(:amount, :person_id, :giftable_type, :giftable_id).merge({ user_id: user_id })
      reward_params = params.merge({ created_by: user_id, finance_code: team&.finance_code, team: team, rewardable_type: 'DigitalGift' })
      digital_gift = DigitalGift.new(dg_params)
      reward = Reward.new(reward_params)

      # TODO: refactor
      if digital_gift.valid? && digital_gift.can_order? # if it's not valid, error out
        digital_gift.request_link
        if digital_gift.save
          @reward.rewardable_id = digital_gift.id
          @reward.save
          digital_gift.assign(@reward.id) # is this necessary?
          digital_gift.save
        end
      else
        flash[:error] = digital_gift.errors
        @success = false
      end
    end

    def validate_giftable!(params)
      giftable = giftable_for(params)
      raise 'No giftable object present' if giftable.nil?
      person_name = giftable.person.full_name
      if params[:giftable_type] == 'Invitation'
        raise "#{person_name} isn't marked as 'attended'." unless giftable.attended?
        raise "#{person_name} Already has a digital gift" if giftable.has_digitable_gift?
      end
    end

    def validate_amount!(user, params)
      budget_insufficient = params['amount'].to_money + 2.to_money >= user.available_budget
      raise 'Insufficient Team Budget' if budget_insufficient
    end

    def giftable_for(params)
      id, type = params.values_at(:giftable_id, :giftable_type)
      klass = GIFTABLE_TYPES.fetch(type)
      klass.find_by_id(id)
    end
  end
end
