# White Label Configuration for Omniflex
# This file customizes Chatwoot branding to Omniflex

Rails.application.config.to_prepare do
  # Override default brand name
  GlobalConfig.class_eval do
    def self.get(key, default = nil)
      case key
      when 'BRAND_NAME'
        ENV.fetch('CHATWOOT_BRAND_NAME', 'Omniflex')
      when 'BRAND_URL'
        ENV.fetch('CHATWOOT_BRAND_URL', 'https://lecard.omniflex.com.br')
      else
        super
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
