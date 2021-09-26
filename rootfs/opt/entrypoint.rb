%w[
    CW_ACCOUNT_NAME
    CW_ACCOUNT_DOMAIN
    CW_ADMIN_EMAIL
    CW_ADMIN_PASSWORD
  ].each do |env_var|
    if !ENV.has_key?(env_var) || ENV[env_var].blank?
      raise <<~EOL
      Missing environment variable: #{env_var}
      EOL
    end
  end

GlobalConfig.clear_cache

SuperAdmin.where(email: ENV["CW_ADMIN_EMAIL"]).first_or_create(password: ENV["CW_ADMIN_PASSWORD"])
SuperAdmin.where(email: ENV["CW_ADMIN_EMAIL"]).update(password: ENV["CW_ADMIN_PASSWORD"])

::Redis::Alfred.delete(::Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)

account = Account.find_or_create_by(domain: ENV["CW_ACCOUNT_DOMAIN"]) do |acc|
  acc.name = ENV["CW_ACCOUNT_NAME"]
  acc.support_email = ENV.fetch('MAILER_SENDER_EMAIL')
end

user = User.find_or_create_by(email: ENV["CW_ADMIN_EMAIL"]) do |user|
  user.name = "Admin"
  user.password = ENV["CW_ADMIN_PASSWORD"]
  user.skip_confirmation!
end

AccountUser.find_or_create_by(account_id: account.id, user_id: user.id, role: :administrator)

%w[
    CW_INSTALLATION_NAME
    CW_LOGO_THUMBNAIL
    CW_LOGO
    CW_BRAND_URL
    CW_WIDGET_BRAND_URL
    CW_BRAND_NAME
    CW_TERMS_URL
    CW_PRIVACY_URL
    CW_DISPLAY_MANIFEST
    CW_MAILER_INBOUND_EMAIL_DOMAIN
    CW_MAILER_SUPPORT_EMAIL
    CW_CREATE_NEW_ACCOUNT_FROM_DASHBOARD
    CW_INSTALLATION_EVENTS_WEBHOOK_URL
    CW_CHATWOOT_INBOX_TOKEN
    CW_CHATWOOT_INBOX_HMAC_KEY
    CW_API_CHANNEL_NAME
    CW_API_CHANNEL_THUMBNAIL
    CW_ANALYTICS_TOKEN
    CW_ANALYTICS_HOST
  ].each do |env_var|
    if ENV.has_key?(env_var)
      instConfig = InstallationConfig.find_or_create_by(name: env_var[3..]) do |conf|
        conf.value = ENV[env_var]
      end
      instConfig.update(value: ENV[env_var])
    end
  end

GlobalConfig.clear_cache