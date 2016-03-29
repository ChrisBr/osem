class Commercial < ActiveRecord::Base
  require 'oembed'

  belongs_to :commercialable, polymorphic: true

  validates :url, presence: true
  validates :url, format: URI::regexp(%w(http https))

  validate :valid_url

  def self.render_from_url(url)
    register_provider
    begin
      resource = OEmbed::Providers.get(Commercial.get_url(url), maxwidth: 560, maxheight: 315)
      { html: resource.html.html_safe }
    rescue StandardError => exception
      { error: exception.message }
    end
  end

  private

  def self.get_url(url)
    OEmbed::Providers.find(url).nil? ? '' : url
  end

  def valid_url
    result = Commercial.render_from_url(Commercial.get_url(url))
    if result[:error]
      errors.add(:base, result[:error])
    end
  end

  def self.register_provider
    speakerdeck = OEmbed::Provider.new('http://speakerdeck.com/oembed.json')
    speakerdeck << 'https://speakerdeck.com/*'
    speakerdeck << 'http://speakerdeck.com/*'

    OEmbed::Providers.register(
        OEmbed::Providers::Youtube,
        OEmbed::Providers::Vimeo,
        OEmbed::Providers::Slideshare,
        OEmbed::Providers::Flickr,
        OEmbed::Providers::Instagram,
        speakerdeck
    )
  end
end
