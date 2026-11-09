# Applies the Community branding defaults from config/installation_config.yml
# to InstallationConfig. ConfigLoader only creates missing rows, so existing
# installations keep the upstream Chatwoot values until this runs.
module Cca::Branding
  KEYS = %w[
    INSTALLATION_NAME
    BRAND_NAME
    LOGO
    LOGO_DARK
    LOGO_THUMBNAIL
    BRAND_URL
    WIDGET_BRAND_URL
    TERMS_URL
    PRIVACY_URL
  ].freeze

  def self.apply!
    defaults = YAML.safe_load(ERB.new(Rails.root.join('config/installation_config.yml').read).result)
                   .index_by { |config| config['name'] }

    ActiveRecord::Base.transaction do
      KEYS.each do |key|
        default = defaults.fetch(key)
        config = InstallationConfig.find_or_initialize_by(name: key)
        config.value = default['value']
        config.save! # InstallationConfig clears the GlobalConfig cache on commit
      end
    end
  end
end
