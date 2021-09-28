%w[
    CW_ACCOUNT_NAME
    CW_ACCOUNT_DOMAIN
    CW_ACCOUNT_EMAIL
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

admin = SuperAdmin.where(email: ENV["CW_ADMIN_EMAIL"]).first_or_create(password: ENV["CW_ADMIN_PASSWORD"])
admin.update(password: ENV["CW_ADMIN_PASSWORD"])

::Redis::Alfred.delete(::Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)

account = Account.find_or_create_by(domain: ENV["CW_ACCOUNT_DOMAIN"]) do |acc|
  acc.name = ENV["CW_ACCOUNT_NAME"]
  acc.support_email = ENV["CW_ACCOUNT_EMAIL"]
end
account.update(name: ENV["CW_ACCOUNT_NAME"], support_email: ENV["CW_ACCOUNT_EMAIL"])

user = User.find_or_create_by(email: ENV["CW_ADMIN_EMAIL"]) do |user|
  user.name = "Admin"
  user.password = ENV["CW_ADMIN_PASSWORD"]
  user.skip_confirmation!
end
user.update(password: ENV["CW_ADMIN_PASSWORD"])

token = AccessToken.where(owner_id: user.id).first
if (ENV["CW_ADMIN_ACCESS_TOKEN"].presence || token.token) != token.token
  token.update(token: ENV["CW_ADMIN_ACCESS_TOKEN"])
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

if ENV.has_key?("CW_WEB_WIDGET") && ENV["CW_WEB_WIDGET"] == "true"
  %w[
      CW_WEB_WIDGET_NAME
      CW_WEB_WIDGET_SITE_URL
      CW_WEB_WIDGET_SITE_TOKEN
      CW_WEB_WIDGET_HMAC_TOKEN
    ].each do |env_var|
      if !ENV.has_key?(env_var) || ENV[env_var].blank?
        raise <<~EOL
        Missing environment variable: #{env_var}
        EOL
      end
    end
  
  widget = Channel::WebWidget.find_or_create_by(account: account, website_url: ENV["CW_WEB_WIDGET_SITE_URL"]) do |w|
    w.website_token = ENV["CW_WEB_WIDGET_SITE_TOKEN"]
    w.hmac_token = ENV["CW_WEB_WIDGET_HMAC_TOKEN"]
  end
  widget.update(
                widget_color:          ENV["CW_WEB_WIDGET_COLOR"].presence || "#009CE0",
                welcome_title:         ENV["CW_WEB_WIDGET_WELCOME_TITLE"].presence || "",
                welcome_tagline:       ENV["CW_WEB_WIDGET_WELCOME_TAGLINE"].presence || "",
                reply_time:            (ENV["CW_WEB_WIDGET_REPLY_TIME"].presence || "0").to_i,
                pre_chat_form_enabled: (ENV["CW_WEB_WIDGET_PRE_CHAT_FORM_ENABLED"].presence || "") == "true",
                website_token:         ENV["CW_WEB_WIDGET_SITE_TOKEN"],
                hmac_token:            ENV["CW_WEB_WIDGET_HMAC_TOKEN"]
                )
  inbox = Inbox.find_or_create_by(channel: widget, account: account, name: ENV["CW_WEB_WIDGET_NAME"])
  InboxMember.find_or_create_by(user: user, inbox: inbox)
end

GlobalConfig.clear_cache