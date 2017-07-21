module GitLfsS3
  module UploadService
    class UploadRequired < Base
      def self.should_handle?(object, aws_object)
        !aws_object.exists? || aws_object.size != object['size']
      end

      def response
        {
          'oid': aws_object.key,
          'size': object['size'],
          'actions': {
            'upload': {
              'href': aws_object.presigned_url(:put),
              'header' => upload_headers,
              'expires_at': (Time.now + 900).iso8601,
              'expires_in': 900,
            }
          }
        }
      end

      def status
        200
      end

      private

      def upload_headers
        nil
      end
    end
  end
end
