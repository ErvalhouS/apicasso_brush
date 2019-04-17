# frozen_string_literal: true

module Apicasso
  # A module to inject Autoracing data consumption behavior
  class Brush
    # A plugger to classes on a service using APIcasso.
    # Receives the URL to get an object from the API.
    def self.brush_on(resource_url = nil, opts = {})
      if resource_url.nil?
        raise Exception, "Configuration error.\nYou should pass the URL for your APIcasso resource as the first parameter\n# => brush_on 'https://my.api/path/to/resource'"
      elsif opts[:token].nil?
        raise Exception, "Configuration error.\nYou should pass a token option to authenticate.\n# => brush_on 'https://my.api/path/to/resource', token: '5e1o5ba77ca7f0d4'"
      end

      # Interface into options set on initialization
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        # Token used to connect into resource's APIcasso instance
        def self.apicasso_token
          "#{opts[:token]}"
        end
        # Base URL to resource, used to query from APIcasso instance
        def self.resource_url
          "#{resource_url}"
        end
        # Method that sets a default include query on this resource
        def self.getter_include
          "include=#{opts[:include].try(:map, &:to_s).try(:join, ',')}" if "#{opts[:include]}".present?
        end
      RUBY
    end

    # Constructor that can receive the ID of the object to search as first parameter
    # and/or object attributes as second parameters
    def initialize(id = nil, object = {})
      @object = object
      @id = id || object[:id]
      instantiate if id.present? && !object.present?
    end

    # Instantiates the object by getting it from APIcasso
    def instantiate
      objectify! URI.parse(getter_url)
    end

    # Base getter URL for current resource
    def getter_url
	    self.class.resource_url + @id.to_s + '?' + self.class.getter_include.to_s
    end

    # Attributes from this object
    def attributes
      @object
    end

    # Overriding `method_missing` to enable fields being retrieved from @object
    def method_missing(meth, *args, &block)
      @object[meth.to_sym] || super
    end

    # Reloads the object by getting from APIcasso
    def reload!
      instantiate if @id.present?
    end

    # Reloads @object variable by receiving the URL used to get the object
    def objectify!(url)
      @object = get_object(url)
    end

    # Saves current object to APIcasso
    def save
      @object = save_object(URI.parse(getter_url)) if @object.is_a? Hash
      @id = @object[:id]
    end

    # Updates current object to APIcasso
    def update(opts = {})
      @object.merge(opts)
      @object = save_object(URI.parse(getter_url)) if @object.is_a? Hash
      @id = @object[:id]
    end

    # Create objects, either using batch or individual request.
    def self.update(opts = {})
      if opts.is_a? Array
        url = URI.parse("#{resource_url.chomp('/' + resource_url.split('/').last)}/batch_update")
        http = Net::HTTP.new(url.host, url.port)

        brush_collection(JSON.parse(retrieve(http, patch_request(url)).read_body))
      elsif opts.is_a? Hash
        object = find(opts[:id])
        object.update(opts)
      end
    end

    # Lists all objects from APIcasso of this class.
    # Can receive a hash of parameters to be passed
    # as query string into the APIcasso instance
    def self.all(opts = {})
      query = "?per_page=-1#{url_encode(opts)}&#{self.getter_include}"
      url = URI.parse("#{resource_url}#{query}")
      http = Net::HTTP.new(url.host, url.port)

      response = JSON.parse(retrieve(http, get_request(url)).read_body).deep_symbolize_keys
      brush_collection(response)
    end

    # Create objects, either using batch or individual request.
    def self.create(opts = {})
      if opts.is_a? Array
        url = URI.parse("#{resource_url.chomp('/' + resource_url.split('/').last)}/batch_create")
        http = Net::HTTP.new(url.host, url.port)

        brush_collection(JSON.parse(retrieve(http, post_request(url, opts)).read_body))
      else
        url = URI.parse(resource_url.to_s)
        http = Net::HTTP.new(url.host, url.port)

        new(nil, JSON.parse(retrieve(http, post_request(url, opts)).read_body))
      end
    end

    # Finds object based on opts finder, if no record is find it
    # creates one using individual request.
    def self.find_or_create_by(opts = {})
      raise ::Exception, 'Pass attributes as hash' unless opts.is_a? Hash

      object = nil
      unless object = find_by(opts)
        object = create(opts)
      end
      object
    end

    # Finds a object based on attributes conditions
    def self.find_by(opts = {})
      where(opts).try(:[], 0)
    end

    # Finds a object based on attributes conditions,
    # raises not found exception when query has no match
    def self.find_by!(opts = {})
      object = find_by(opts)
      raise ::Exception, 'Not Found' if object.nil?
    end

    # Finds a resource with the given id
    def self.find(id)
      new(id)
    end

    # Returns an array of objects that matches a given query,
    # which is the first parameter. This query can be a string of an
    # ransack URL query or a hash where the keys would be *_eq operators.
    def self.where(query = '', opts = {})
      query = "?per_page=-1#{stringfy_ransackable(query)}#{url_encode(opts)}&#{getter_include}"
      url = URI.parse("#{resource_url}#{query}")
      http = Net::HTTP.new(url.host, url.port)

      response = JSON.parse(retrieve(http, get_request(url)).read_body).deep_symbolize_keys
      brush_collection(response)
    end

    # Destroys current object on APIcasso
    def destroy
      @object = @id = delete_object(URI.parse(getter_url))
    end

    alias delete destroy

    private

    def get_object(url)
      http = Net::HTTP.new(url.host, url.port)
      JSON.parse(self.class.retrieve(http, self.class.get_request(url)).read_body).deep_symbolize_keys
    end

    def save_object(url)
      http = Net::HTTP.new(url.host, url.port)
      meth = (@id.present? ? 'patch' : 'post')
      JSON.parse(self.class.retrieve(http, self.class.send("#{meth}_request", url, @object)).read_body).deep_symbolize_keys
    end

    def delete_object(url)
      http = Net::HTTP.new(url.host, url.port)
      self.class.retrieve(http, self.class.delete_request(url))
    end

    class << self
      def stringfy_ransackable(query = nil)
        if query.is_a? String
          '&' + query
        elsif query.is_a? Hash
          '&q={' + query.map do |key, value|
            "\"#{key}_eq\": \"#{value}\""
          end.join(',') + '}'
        end
      end

      def url_encode(query = {})
        return if query.nil?

        '&' + query.map do |key, value|
          "#{key}=#{value}"
        end.join('&')
      end

      def retrieve(http, request)
        response = http.request(request)
        check_success response.code
        response
      end

      def check_success(status)
        case status
        when '404', 404
          raise ::Exception, 'Resource not found, are you sure you have configured your `brush_on` URL'
        when '401', 401
          raise ::Exception, 'Invalid Token'
        when '403', 403
          raise ::Exception, "Not authorized to #{request::METHOD} on resource"
        else
          raise ::Exception, 'Error when fetching from APIcasso' if status.to_i > 400
        end
      end

      def delete_request(url)
        request = Net::HTTP::Delete.new(url)
        request['Authorization'] = "Token token=#{apicasso_token}"
        request
      end

      def get_request(url)
        request = Net::HTTP::Get.new(url)
        request['Authorization'] = "Token token=#{apicasso_token}"
        request
      end

      def patch_request(url, body)
        request = Net::HTTP::Patch.new(url)
        request['Authorization'] = "Token token=#{apicasso_token}"
        request['Content-Type'] = 'application/json'
        request.body = { resource_url.split('/').last.singularize => body }.to_json
        request
      end

      def post_request(url, body)
        request = Net::HTTP::Post.new(url)
        request['Authorization'] = "Token token=#{apicasso_token}"
        request['Content-Type'] = 'application/json'
        request.body = { resource_url.split('/').last.singularize => body }.to_json
        request
      end

      def brush_collection(response)
        (response.is_a?(Hash) ? response[:entries] : response).map do |object|
          new(nil, object)
        end
      end
    end
  end
end
