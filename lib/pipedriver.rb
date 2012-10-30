# Pipedriver Ruby bindings
# API Spec somewhere

# Gems
require 'cgi'
require 'set'
require 'rubygems'
require 'openssl'
require 'active_support/inflector'

gem 'rest-client', '~> 1.4'
require 'rest_client'
require 'multi_json'

# Version
require 'pipedriver/version'

# Operations
require 'pipedriver/api_operations/create'
require 'pipedriver/api_operations/edit'
require 'pipedriver/api_operations/delete'
require 'pipedriver/api_operations/list'

# Resources
require 'pipedriver/util'
require 'pipedriver/json'
require 'pipedriver/pipedriver_object'
require 'pipedriver/api_resource'
require 'pipedriver/singleton_api_resource'
require 'pipedriver/activity'
require 'pipedriver/activity_type'
require 'pipedriver/currency'
require 'pipedriver/deal'
require 'pipedriver/deal_field'
require 'pipedriver/file'
require 'pipedriver/filter'
require 'pipedriver/organization'
require 'pipedriver/organization_field'
require 'pipedriver/person'
require 'pipedriver/person_field'
require 'pipedriver/pipeline'
require 'pipedriver/product'
require 'pipedriver/product_field'
require 'pipedriver/search_result'
require 'pipedriver/stage'
require 'pipedriver/user'
require 'pipedriver/user_setting'

# Errors
require 'pipedriver/errors/pipedrive_error'
require 'pipedriver/errors/api_error'
require 'pipedriver/errors/api_connection_error'
require 'pipedriver/errors/invalid_request_error'
require 'pipedriver/errors/authentication_error'

module Pipedriver
  @@api_key = nil
  @@api_base = 'https://api.pipedrive.com/v1'
  @@verify_ssl_certs = false

  def self.api_url(url='')
    @@api_base + url
  end

  def self.api_key=(api_key)
    @@api_key = api_key
  end

  def self.api_key
    @@api_key
  end

  def self.api_base=(api_base)
    @@api_base = api_base
  end

  def self.api_base
    @@api_base
  end

  def self.verify_ssl_certs=(verify)
    @@verify_ssl_certs = verify
  end

  def self.verify_ssl_certs
    @@verify_ssl_certs
  end

  def self.request(method, url, api_key, params={}, headers={})
    api_key ||= @@api_key
    raise AuthenticationError.new('No API key provided.  (HINT: set your API key using "Pipedriver.api_key = <API-KEY>".  You can generate API keys from the Pipedrive web interface.  See https://developers.pipedrive.com/v1 for details.)') unless api_key

    if !verify_ssl_certs
      unless @no_verify
        $stderr.puts "WARNING: Running without SSL cert verification.  Execute 'Pipedriver.verify_ssl_certs = true' to enable verification."
        @no_verify = true
      end
      ssl_opts = { :verify_ssl => false }
    elsif !Util.file_readable(@@ssl_bundle_path)
      unless @no_bundle
        $stderr.puts "WARNING: Running without SSL cert verification because #{@@ssl_bundle_path} isn't readable"
        @no_bundle = true
      end
      ssl_opts = { :verify_ssl => false }
    else
      ssl_opts = {
        :verify_ssl => OpenSSL::SSL::VERIFY_PEER,
        :ssl_ca_file => @@ssl_bundle_path
      }
    end
    uname = (@@uname ||= RUBY_PLATFORM =~ /linux|darwin/i ? `uname -a 2>/dev/null`.strip : nil)
    lang_version = "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE})"
    ua = {
      :bindings_version => Pipedriver::VERSION,
      :lang => 'ruby',
      :lang_version => lang_version,
      :platform => RUBY_PLATFORM,
      :publisher => 'pipedriver',
      :uname => uname
    }

    params = Util.objects_to_ids(params)
    
    url = self.api_url(url)
    
    params ||= {}
    params[:api_token] = api_key
    
    case method.to_s.downcase.to_sym
    when :get, :head, :delete
      # Make params into GET parameters
      if params && params.count > 0
        query_string = Util.flatten_params(params).collect{|key, value| "#{key}=#{Util.url_encode(value)}"}.join('&')
        url += "?#{query_string}"
      end
      payload = nil
    else
      payload = Util.flatten_params(params).collect{|(key, value)| "#{key}=#{Util.url_encode(value)}"}.join('&')
    end

    begin
      headers = { :x_pipedriver_client_user_agent => Pipedriver::JSON.dump(ua) }.merge(headers)
    rescue => e
      headers = {
        :x_pipedriver_client_raw_user_agent => ua.inspect,
        :error => "#{e} (#{e.class})"
      }.merge(headers)
    end

    headers = {
      :user_agent => "Pipedrive/v1 RubyBindings/#{Pipedriver::VERSION}",
      :content_type => 'application/x-www-form-urlencoded',
      :accept => 'application/json'
    }.merge(headers)
    opts = {
      :method => method,
      :url => url,
      :headers => headers,
      :open_timeout => 30,
      :payload => payload,
      :timeout => 80
    }.merge(ssl_opts)
    
    puts "Here is the URL: #{url}"
    begin
      response = execute_request(opts)
    rescue SocketError => e
      self.handle_restclient_error(e)
    rescue NoMethodError => e
      # Work around RestClient bug
      if e.message =~ /\WRequestFailed\W/
        e = APIConnectionError.new('Unexpected HTTP response code')
        self.handle_restclient_error(e)
      else
        raise
      end
    rescue RestClient::ExceptionWithResponse => e
      if rcode = e.http_code and rbody = e.http_body
        self.handle_api_error(rcode, rbody)
      else
        self.handle_restclient_error(e)
      end
    rescue RestClient::Exception, Errno::ECONNREFUSED => e
      self.handle_restclient_error(e)
    end

    rbody = response.body
    rcode = response.code
    begin
      # Would use :symbolize_names => true, but apparently there is
      # some library out there that makes symbolize_names not work.
      resp = Pipedriver::JSON.load(rbody)
    rescue MultiJson::DecodeError
      raise APIError.new("Invalid response object from API: #{rbody.inspect} (HTTP response code was #{rcode})", rcode, rbody)
    end

    resp = Util.symbolize_names(resp)
    [resp, api_key]
  end

  private

  def self.execute_request(opts)
    RestClient::Request.execute(opts)
  end

  def self.handle_api_error(rcode, rbody)
    begin
      error_obj = Pipedriver::JSON.load(rbody)
      error_obj = Util.symbolize_names(error_obj)
      error = error_obj[:error] or raise RuntimeError.new # escape from parsing
    rescue MultiJson::DecodeError, RuntimeError
      raise APIError.new("Invalid response object from API: #{rbody.inspect} (HTTP response code was #{rcode})", rcode, rbody)
    end

    case rcode
    when 400, 404 then
      raise invalid_request_error(error, rcode, rbody, error_obj)
    when 401
      raise authentication_error(error, rcode, rbody, error_obj)
    when 402
      raise card_error(error, rcode, rbody, error_obj)
    else
      raise api_error(error, rcode, rbody, error_obj)
    end
  end

  def self.invalid_request_error(error, rcode, rbody, error_obj)
    InvalidRequestError.new(error[:message], error[:param], rcode, rbody, error_obj)
  end

  def self.authentication_error(error, rcode, rbody, error_obj)
    AuthenticationError.new(error, rcode, rbody, error_obj)
  end

  def self.card_error(error, rcode, rbody, error_obj)
    CardError.new(error[:message], error[:param], error[:code], rcode, rbody, error_obj)
  end

  def self.api_error(error, rcode, rbody, error_obj)
    APIError.new(error[:message], rcode, rbody, error_obj)
  end

  def self.handle_restclient_error(e)
    case e
    when RestClient::ServerBrokeConnection, RestClient::RequestTimeout
      message = "Could not connect to Pipedrive (#{@@api_base}).  Please check your internet connection and try again."
    when RestClient::SSLCertificateNotVerified
      message = "Could not verify Pipedrive's SSL certificate.  Please make sure that your network is not intercepting certificates.  (Try going to https://developers.pipedrive.com/v1 in your browser.)"
    when SocketError
      message = "Unexpected error communicating when trying to connect to Pipedrive.  HINT: You may be seeing this message because your DNS is not working."
    else
      message = "Unexpected error communicating with Pipedrive."
    end
    message += "\n\n(Network error: #{e.message})"
    raise APIConnectionError.new(message)
  end
end
