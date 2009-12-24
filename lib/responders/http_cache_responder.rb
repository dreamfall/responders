module Responders
  # Set HTTP Last-Modified headers based on the given resource. It's used only
  # on API behavior (to_format) and is useful for a client to check in the server
  # if a resource changed after a specific date or not.
  #
  # This is not usually not used in html requests because pages contains a lot
  # information besides the resource information, as current_user, flash messages,
  # widgets... that are better handled with other strategies, as fragment caches and
  # the digest of the body.
  #
  module HttpCacheResponder
    def initialize(controller, resources, options={})
      super
      @http_cache = options.delete(:http_cache)
    end

    def to_format
      if do_http_cache?
        timestamp = resources.flatten.map do |resource|
          (resource.updated_at || Time.now).utc if resource.respond_to?(:updated_at)
        end.compact.max

        controller.response.last_modified = timestamp if timestamp
        if request.fresh?(controller.response)
          head :not_modified
          return
        end
      end

      super
    end

  protected

    def do_http_cache?
      get? && @http_cache != false && !new_record? && controller.response.last_modified.nil?
    end

    def new_record?
      resource.respond_to?(:new_record?) && resource.new_record?
    end
  end
end