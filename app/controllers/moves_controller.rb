class MovesController < ApplicationController
  def index
    matching_moves = Move.all
    @list_of_moves = matching_moves.order({ created_at: :desc })
    render({ template: "move_templates/index" })
  end

  def show
    the_id = params.fetch("path_id")
    matching_moves = Move.where({ id: the_id })
    @the_move = matching_moves.at(0)
    render({ template: "move_templates/show" })
  end

  def create
    if current_user.nil?
      redirect_to("/", { alert: "You must be signed in to play a card." })
      return
    end

    game_id = params.fetch("query_game_id").to_i
    card_code = params.fetch("query_card_played")

    @game = Game.where(id: game_id).first

    if @game.nil?
      redirect_to("/", { alert: "Game not found." })
      return
    end

    gameplayer = Gameplayer.where(game_id: @game.id, user_id: current_user.id).first

    if gameplayer.nil?
      redirect_to("/games/#{@game.id}", { alert: "You are not a player in this game." })
      return
    end

    hand = gameplayer.hand_cards_array

    unless hand.include?(card_code)
      redirect_to("/games/#{@game.id}", { alert: "You don't have that card in your hand." })
      return
    end

    hand.delete(card_code)
    gameplayer.hand_cards_array = hand

    table = @game.table_cards_array

    capture_result = apply_basra_rules(table, card_code)
    captured_cards = capture_result[:captured_cards]
    basra = capture_result[:basra]

    new_table = table - captured_cards
    @game.table_cards_array = new_table

    move = Move.new
    move.game_id = @game.id
    move.user_id = current_user.id
    move.move_number = (@game.moves.count + 1)
    move.card_played = card_code
    move.captured_cards = captured_cards.to_json
    move.basra = basra
    move.points_earned = basra ? 10 : 0

    if basra
      gameplayer.score = (gameplayer.score || 0) + 10
    end

    if move.valid? && gameplayer.valid? && @game.valid?
      Move.transaction do
        move.save!
        gameplayer.save!
        @game.save!
      end

      notice_msg = "Played #{card_code}."
      notice_msg += " Basra!" if basra

      redirect_to("/games/#{@game.id}", { notice: notice_msg })
    else
      errors = (move.errors.full_messages +
                gameplayer.errors.full_messages +
                @game.errors.full_messages).uniq
      redirect_to("/games/#{@game.id}", { alert: errors.to_sentence })
    end
  end

  def update
    the_id = params.fetch("path_id")
    the_move = Move.where({ id: the_id }).at(0)

    the_move.game_id = params.fetch("query_game_id")
    the_move.user_id = params.fetch("query_user_id")
    the_move.move_number = params.fetch("query_move_number")
    the_move.card_played = params.fetch("query_card_played")
    the_move.captured_cards = params.fetch("query_captured_cards")
    the_move.basra = params.fetch("query_basra")
    the_move.points_earned = params.fetch("query_points_earned")

    if the_move.valid?
      the_move.save
      redirect_to("/moves/#{the_move.id}", { notice: "Move updated successfully." })
    else
      redirect_to("/moves/#{the_move.id}", { alert: the_move.errors.full_messages.to_sentence })
    end
  end

  def destroy
    the_id = params.fetch("path_id")
    the_move = Move.where({ id: the_id }).at(0)
    the_move.destroy
    redirect_to("/moves", { notice: "Move deleted successfully." })
  end

  private

  def apply_basra_rules(table_cards, card_code)
    rank = card_rank(card_code)
    suit = card_suit(card_code)

    if rank == "J"
      return { captured_cards: table_cards.dup, basra: false }
    end

    if card_code == "7♦" || card_code == "7D"
      total_table_value = table_numeric_value(table_cards)
      if total_table_value == 7 || table_cards.length == 1
        return { captured_cards: table_cards.dup, basra: true }
      else
        return { captured_cards: table_cards.dup, basra: false }
      end
    end

    captured = []

    same_rank_cards = table_cards.select { |c| card_rank(c) == rank }
    captured.concat(same_rank_cards)

    value = card_value(rank)
    if value
      sum_combo = find_sum_combo(table_cards, value)
      captured.concat(sum_combo) if sum_combo
    end

    captured.uniq!

    basra = false
    if captured.any?
      remaining = table_cards - captured
      basra = remaining.empty?
    end

    { captured_cards: captured, basra: basra }
  end

  def card_rank(code)
    code[0..-2]
  end

  def card_suit(code)
    code[-1]
  end

  def card_value(rank)
    return 1 if rank == "A"
    return nil if ["Q", "K", "J"].include?(rank)
    rank.to_i.zero? ? nil : rank.to_i
  end

  def table_numeric_value(table_cards)
    table_cards.map { |c| card_value(card_rank(c)) || 0 }.sum
  end

  def find_sum_combo(table_cards, target)
    numeric_cards = table_cards.select { |c| card_value(card_rank(c)) }
    n = numeric_cards.length
    (1..n).each do |k|
      numeric_cards.combination(k).each do |combo|
        sum = combo.map { |c| card_value(card_rank(c)) }.sum
        return combo if sum == target
      end
    end
    nil
  end
end
