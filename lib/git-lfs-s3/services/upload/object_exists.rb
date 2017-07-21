module GitLfsS3
  module UploadService
    class ObjectExists < Base
      def self.should_handle?(object, aws_object)
        aws_object.exists? && aws_object.size == object['size']
      end

      def response
        {
          'oid': aws_object.key,
          'size': aws_object.size,
          'actions': {
            'download': {
              'href': aws_object.presigned_url(:get),
              'expires_at': (Time.now + 900).iso8601,
              'expires_in': 900,
            }
          }
        }
      end

      def status
        200
      end
    end
  end
end
