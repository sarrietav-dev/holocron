email = ENV["ADMIN_EMAIL"]
password = ENV["ADMIN_PASSWORD"]

if email.present? && password.present?
  user = User.find_or_initialize_by(email_address: email)
  user.password = password
  user.password_confirmation = password
  user.save!
else
  warn "Set ADMIN_EMAIL and ADMIN_PASSWORD to seed the Holocron account."
end
