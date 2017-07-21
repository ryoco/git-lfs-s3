module GitLfsS3
  module UploadService
    class Base
      include AwsHelpers
      
      attr_reader :object, :aws_object

      def initialize(object, aws_object)
        @object = object
        @aws_object = aws_object
      end

      def response
        raise "Override"
      end

      def status
        raise "Override"
      end

      private

      def server_url
        GitLfsS3::Application.settings.server_url
      end
    end
  end
end
