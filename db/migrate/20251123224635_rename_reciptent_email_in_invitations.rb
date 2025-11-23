class RenameReciptentEmailInInvitations < ActiveRecord::Migration[8.0]
  def change
    rename_column :invitations, :reciptent_email, :recipient_email
  end
end
