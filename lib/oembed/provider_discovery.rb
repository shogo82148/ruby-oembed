require 'open-uri'

module OEmbed
  # Uses {oEmbed Discover}[http://oembed.com/#section4] to generate a new Provider
  # instance about a URL for which a Provider didn't previously exist.
  class ProviderDiscovery
    class << self

    # Discover the Provider for the given url, then call Provider#raw on that provider.
    # The query parameter will be passed to both discover_provider and Provider#raw
    # @deprecated *Note*: This method will be made private in the future.
    def raw(url, query={})
      provider = discover_provider(url, query)
      provider.raw(url, options)
    end

    # Discover the Provider for the given url, then call Provider#get on that provider.
    # The query parameter will be passed to both discover_provider and Provider#get
    def get(url, query={})
      provider = discover_provider(url, query)
      provider.get(url, query)
    end

    # Returns a new Provider instance based on information from oEmbed discovery
    # performed on the given url.
    #
    # The options Hash recognizes the following keys:
    # :format:: If given only discover endpoints for the given format. If not format is given, use the first available format found.
    def discover_provider(url, options = {})
      uri = URI.parse(url)
      data = open(uri.to_s()).read

      format = options[:format]

      if format.nil? || format == :json
        provider_endpoint ||= /<link.*href=['"]*([^\s'"]+)['"]*.*application\/json\+oembed.*>/.match(data)[1] rescue nil
        provider_endpoint ||= /<link.*application\/json\+oembed.*href=['"]*([^\s'"]+)['"]*.*>/.match(data)[1] rescue nil
        format ||= :json if provider_endpoint
      end
      if format.nil? || format == :xml
        # {The specification}[http://oembed.com/#section4] says XML discovery should have
        # type="text/xml+oembed" but some providers use type="application/xml+oembed"
        provider_endpoint ||= /<link.*href=['"]*([^\s'"]+)['"]*.*(application|text)\/xml\+oembed.*>/.match(data)[1] rescue nil
        provider_endpoint ||= /<link.*(application|text)\/xml\+oembed.*href=['"]*([^\s'"]+)['"]*.*>/.match(data)[2] rescue nil
        format ||= :xml if provider_endpoint
      end

      provider_endpoint = URI.parse(provider_endpoint)
      provider_endpoint.query = nil
      provider_endpoint = provider_endpoint.to_s

      Provider.new(provider_endpoint, format || OEmbed::Formatter.default)
      end

    end
  end
end
