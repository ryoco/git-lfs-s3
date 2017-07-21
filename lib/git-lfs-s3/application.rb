module GitLfsS3
  class Application < Sinatra::Application
    include AwsHelpers

    class << self
      attr_reader :auth_callback

      def on_authenticate(&block)
        @auth_callback = block
      end

      def authentication_enabled?
        !auth_callback.nil?
      end

      def perform_authentication(username, password)
        auth_callback.call(username, password)
      end
    end

    configure do
      disable :sessions
      enable :logging
    end

    helpers do
      def logger
        settings.logger
      end
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && self.class.auth_callback.call(
        @auth.credentials[0], @auth.credentials[1]
      )
    end

    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Invalid username or password"])
      end
    end

    def error_resp(status_code, message)
      status(status_code)
      resp = {
        'message' => message,
        'documentation_url': "https://lfs-server.com/docs/errors",
        'request_id' => SecureRandom::uuid
      }
      body MultiJson.dump(resp)
    end

    before { protected! }

    get '/' do
      "Git LFS S3 is online."
    end

    post '/objects/batch', provides: 'application/vnd.git-lfs+json' do
      params = JSON.parse(request.body.read)

      operation = params['operation']
      transfers = params['transfers']
      objects = params['objects']

      case operation
        when 'download'
          r_response = {'objects' => []}
          r_status = 200
          logger.debug "DOWNLOAD"

          service = UploadService.service_for_download(objects)
          service.map { |s|
            r_response['objects'].push(s.response)
            r_status = s.status
          }
          status r_status
          body MultiJson.dump(r_response)
        when 'upload'
          r_response = {'objects' => []}
          r_status = 200
          logger.debug "UPLOAD"

          service = UploadService.service_for_upload(objects)
          service.map { |s|
            r_response['objects'].push(s.response)
            r_status = s.status
          }
          status r_status
          body MultiJson.dump(r_response)
        else
          error_resp(442, "Validation error.")
      end
    end

    post '/locks/verify', provides: 'application/vnd.git-lfs+json' do
      data = MultiJson.load(request.body.tap { |b| b.rewind }.read)
      object = object_data(data['oid'])

      if object.exists? && object.size == data['size']
        status 200
      else
        status 404
      end
    end
  end
end
