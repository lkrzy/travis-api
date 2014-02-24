require 'travis/api/app'
require 'addressable/uri'
require 'active_record/base'

class Travis::Api::App
  # Superclass for HTTP endpoints. Takes care of prefixing.
  class Endpoint < Base
    include Travis::Services::Helpers

    set(:prefix) { "/" << name[/[^:]+$/].underscore }
    set disable_root_endpoint: false
    register :scoping
    helpers :current_user, :flash, :db_follower

    # TODO hmmm?
    before { flash.clear }
    after { content_type :json unless content_type }

    error(ActiveRecord::RecordNotFound, Sinatra::NotFound) { not_found }
    not_found {
      if content_type =~ /json/
        if body && !body.empty?
          body
        else
          { 'file' => 'not found' }
        end
      else
        'file not found'
      end
    }

    private

      def redis
        Thread.current[:redis] ||= ::Redis.connect(url: Travis.config.redis.url)
      end

      def endpoint(link, query_values = {})
        link = url(File.join(env['travis.global_prefix'], link), true, false)
        uri  = Addressable::URI.parse(link)
        query_values = query_values.merge(uri.query_values) if uri.query_values
        uri.query_values = query_values
        uri.to_s
      end

      def safe_redirect(url)
        redirect(endpoint('/redirect', to: url), 301)
      end
  end
end
