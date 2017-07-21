require "git-lfs-s3/services/upload/base"
require "git-lfs-s3/services/upload/object_exists"
require "git-lfs-s3/services/upload/upload_required"

module GitLfsS3
  module UploadService
    extend self
    extend AwsHelpers

    def service_for_download(objects)
      mdl = ObjectExists
      objects.map { |obj|
        aws_obj = object_data(obj['oid'])
        mdl.new(obj, aws_obj) if mdl.should_handle?(obj, aws_obj) 
      }.compact
    end

    def service_for_upload(objects)
      mdl = UploadRequired
      objects.map { |obj|
        aws_obj = object_data(obj['oid'])
        mdl.new(obj, aws_obj) if mdl.should_handle?(obj, aws_obj) 
      }.compact
    end

  end
end
