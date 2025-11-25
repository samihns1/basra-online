# == Schema Information
#
# Table name: gameplayers
#
#  id          :bigint           not null, primary key
#  hand_cards  :text
#  score       :integer
#  seat_number :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  game_id     :integer
#  user_id     :integer
#
class Gameplayer < ApplicationRecord
  belongs_to :user, required: true, class_name: "User", foreign_key: "user_id"
  belongs_to :game, required: true, class_name: "Game", foreign_key: "game_id", counter_cache: true

  def hand_cards_array
    JSON.parse(hand_cards || "[]")
  end

  def hand_cards_array=(arr)
    self.hand_cards = arr.to_json
  end
end
