class InvitationMailer < ApplicationMailer
  default from: "no-reply@basra-game.com"  

  def game_invite(invitation)
    @invitation = invitation
    @game       = invitation.game
    @sender     = invitation.sender

    @game_url = game_url(@game)

    mail(
      to:   @invitation.recipient_email,
      subject: "#{@sender.username} invited you to a Basra game!"
    )
  end
end
