# White Label Configuration for Omniflex
# This file customizes Chatwoot branding to Omniflex

Rails.application.config.after_initialize do
  # Override default brand name by patching the db_fallback method
  GlobalConfig.instance_eval do
    class << self
      alias_method :original_db_fallback, :db_fallback

      def db_fallback(config_key)
        case config_key
        when 'BRAND_NAME'
          ENV.fetch('CHATWOOT_BRAND_NAME', 'Omniflex')
        when 'BRAND_URL'
          ENV.fetch('CHATWOOT_BRAND_URL', 'https://lecard.omniflex.com.br')
        else
          original_db_fallback(config_key)
        end
      end
    end
  end
end

# Set default meta tags for Open Graph
module DefaultMetaTags
  def default_meta_tags
    {
      site: 'Omniflex',
      title: 'Omniflex - Atendimento ao Cliente',
      description: 'Sistema de atendimento ao cliente da Omniflex. Respondemos em instantes!',
      keywords: 'atendimento, suporte, chat, omniflex',
      og: {
        title: 'Omniflex',
        description: 'Sistema de atendimento ao cliente da Omniflex. Respondemos em instantes!',
        type: 'website',
        site_name: 'Omniflex'
      },
      twitter: {
        card: 'summary_large_image',
        title: 'Omniflex',
        description: 'Sistema de atendimento ao cliente da Omniflex. Respondemos em instantes!'
      }
    }
  end
end

ActionView::Base.include DefaultMetaTags
