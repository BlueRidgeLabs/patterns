# frozen_string_literal: true

# Uploads an object to an Amazon S3 bucket. The object's contents
#   are encrypted with an RSA public key.
#
# Downloads an object from an S3 bucket, and decrypts it with a *supplied* private key.


# https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/s3-example-client-side-decrypt-item-with-private-key.html

class S3BackupService
    def initialize
      @bucket_name = Rails.application.credentials.aws[:backup_bucket]
      @region = Rails.application.credentials.aws[:region]
      @public_key = OpenSSL::PKey::RSA.new(Rails.application.credentials.backup_public_key)
    end

    # Full example call:
    # Prerequisites: an RSA key pair.
    def upload(path)
      object_key = File.basename(path)
      object_content = File.read(path)

      # When initializing this Amazon S3 encryption client, note:
      # - For key_wrap_schema, use rsa_oaep_sha1 for asymmetric keys.
      # - For security_profile, for reading or decrypting objects encrypted
      #     by the v1 encryption client, use :v2_and_legacy instead.
      s3_encryption_client = Aws::S3::EncryptionV2::Client.new(
        encryption_key: @public_key,
        key_wrap_schema: :rsa_oaep_sha1,
        content_encryption_schema: :aes_gcm_no_padding,
        security_profile: :v2,
        region: @region
      )

      if object_uploaded_with_public_key_encryption?(
        s3_encryption_client,
        object_key,
        object_content
      )
        Rails.logger.info 'Object uploaded.'
      else
        Rails.logger.info 'Object not uploaded.'
      end
    end

    # Full example call:
    # Prerequisites: the same RSA key pair you originally used to encrypt the object.
    def download(object_key, private_key_path, output_directory = '/tmp/')
      private_key = OpenSSL::PKey::RSA.new(File.read(private_key_path))

      # When initializing this Amazon S3 encryption client, note:
      # - For key_wrap_schema, use rsa_oaep_sha1 for asymmetric keys.
      # - For security_profile, for reading or decrypting objects encrypted
      #     by the v1 encryption client, use :v2_and_legacy instead.
      s3_encryption_client = Aws::S3::EncryptionV2::Client.new(
        encryption_key: private_key,
        key_wrap_schema: :rsa_oaep_sha1,
        content_encryption_schema: :aes_gcm_no_padding,
        security_profile: :v2,
        region: @region
      )

      obj = download_object_with_private_key_encryption(
        s3_encryption_client,
        @bucket_name,
        object_key
      )
      File.open("#{output_directory}#{object_key}", 'w') { |file| file.write(obj) }
    end

    private

    def download_object_with_private_key_encryption(
      s3_encryption_client,
      object_key)

      response = s3_encryption_client.get_object(
        bucket: @bucket_name,
        key: object_key
      )
      response.body.read
    rescue StandardError => e
      Rails.logger.info "Error downloading object: #{e.message}"
    end

    def object_uploaded_with_public_key_encryption?(
      s3_encryption_client,
      object_key,
      object_content)

      s3_encryption_client.put_object(
        bucket: @bucket_name,
        key: object_key,
        body: object_content
      )
      true
    rescue StandardError => e
      Rails.logger.info "Error uploading object: #{e.message}"
      false
    end
end
