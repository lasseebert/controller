require 'lotus/utils/hash'

module Lotus
  module Action
    # A set of HTTP Cookies
    #
    # It acts as an Hash
    #
    # @since 0.1.0
    #
    # @see Lotus::Action::Cookies#cookies
    class CookieJar
      # The key that returns raw cookies from the Rack env
      #
      # @since 0.1.0
      HTTP_HEADER       = 'HTTP_COOKIE'.freeze

      # The key used by Rack to set the cookies as an Hash in the env
      #
      # @since 0.1.0
      COOKIE_HASH_KEY   = 'rack.request.cookie_hash'.freeze

      # The key used by Rack to set the cookies as a String in the env
      #
      # @since 0.1.0
      COOKIE_STRING_KEY = 'rack.request.cookie_string'.freeze

      # Initialize the CookieJar
      #
      # @param env [Hash] a raw Rack env
      # @param headers [Hash] the response headers
      #
      # @return [CookieJar]
      #
      # @since 0.1.0
      def initialize(env, headers)
        @_headers = headers
        @cookies  = Utils::Hash.new(extract(env)).symbolize!
      end

      # Finalize itself, by setting the proper headers to add and remove
      # cookies, before the response is returned to the webserver.
      #
      # @return [void]
      #
      # @since 0.1.0
      #
      # @see Lotus::Action::Cookies#finish
      def finish
        @cookies.each {|k,v| v.nil? ? delete_cookie(k) : set_cookie(k, v) }
      end

      # Returns the object associated with the given key
      #
      # @param key [Symbol] the key
      #
      # @return [Object,nil] return the associated object, if found
      #
      # @since 0.2.0
      def [](key)
        @cookies[key]
      end

      # Associate the given value with the given key and store them
      #
      # @param key [Symbol] the key
      # @param value [Object] the value
      #
      # @return [void]
      #
      # @since 0.2.0
      def []=(key, value)
        @cookies[key] = value
      end

      private
      # Extract the cookies from the raw Rack env.
      #
      # This implementation is borrowed from Rack::Request#cookies.
      #
      # @since 0.1.0
      # @api private
      def extract(env)
        hash   = env[COOKIE_HASH_KEY] ||= {}
        string = env[HTTP_HEADER]

        return hash if string == env[COOKIE_STRING_KEY]
        hash.clear

        # According to RFC 2109:
        #   If multiple cookies satisfy the criteria above, they are ordered in
        #   the Cookie header such that those with more specific Path attributes
        #   precede those with less specific.  Ordering with respect to other
        #   attributes (e.g., Domain) is unspecified.
        cookies = ::Rack::Utils.parse_query(string, ';,') { |s| ::Rack::Utils.unescape(s) rescue s }
        cookies.each { |k,v| hash[k] = Array === v ? v.first : v }
        env[COOKIE_STRING_KEY] = string
        hash
      end

      # Set a cookie in the headers
      #
      # @since 0.1.0
      # @api private
      def set_cookie(key, value)
        ::Rack::Utils.set_cookie_header!(@_headers, key, value)
      end

      # Remove a cookie from the headers
      #
      # @since 0.1.0
      # @api private
      def delete_cookie(key)
        ::Rack::Utils.delete_cookie_header!(@_headers, key, {})
      end
    end
  end
end
