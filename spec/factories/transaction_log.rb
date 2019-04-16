# require 'faker'

# FactoryBot.define do
#   factory :transaction_log do
#     transient do
#       admin_user FactoryBot.create(:user, :admin)
#     end

#     amount 100
#     recipient_type 'Budget'
#     transaction_type 'Topup'
#     recipient_id  admin_user.id
#     from_id admin_user.id
#     from_type 'User'
#     user_id admin_user.id
#   end
# end
