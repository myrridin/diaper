# == Schema Information
#
# Table name: items
#
#  id            :integer          not null, primary key
#  name          :string
#  category      :string
#  created_at    :datetime
#  updated_at    :datetime
#  barcode_count :integer
#

FactoryGirl.define do
	factory :item do
		sequence(:name) { |n| "#{n}T Diapers" }
		category "disposable"
	end
end