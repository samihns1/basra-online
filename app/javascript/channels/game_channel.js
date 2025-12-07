import { createConsumer } from "@rails/actioncable"

const consumer = createConsumer()

export function subscribeToGameFromDom(gameId) {
  if (!gameId) return

  consumer.subscriptions.create({ channel: "GameChannel", game_id: gameId }, {
    received(data) {
      if (!data || !data.event) return
      if (data.event === 'winner') {
        // Redirect all clients to the winner page for this game
        window.location.href = `/games/${gameId}/winner`
      } else if (data.event === 'tie') {
        // Notify players and reload so the UI shows waiting/start next round
        try {
          if (data.message) alert(data.message)
        } catch (e) {}
        window.location.reload()
      }
    }
  })
}

export default consumer
