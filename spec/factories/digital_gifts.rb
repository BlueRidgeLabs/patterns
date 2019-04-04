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

require 'faker'
