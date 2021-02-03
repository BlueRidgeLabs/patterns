require 'aws-sdk-s3'
require 'openssl'

# Uploads an object to an Amazon S3 bucket. The object's contents
#   are encrypted with an RSA public key.
#
# Prerequisites:
#
# - An Amazon S3 bucket.
#
# @param s3_encryption_client [Aws::S3::EncryptionV2::Client] An initialized
#   Amazon S3 encryption client.
# @param bucket_name [String] The bucket's name.
# @param object_key [String] The name of the object.
# @param object_content [String] The content to add to the object.
# @return [Boolean] true if the object was uploaded; otherwise, false.
# @example
#   exit 1 unless object_uploaded_with_public_key_encryption?(
#     Aws::S3::EncryptionV2::Client.new(
#       encryption_key: OpenSSL::PKey::RSA.new(File.read('my-public-key.pem')),
#       key_wrap_schema: :rsa_oaep_sha1,
#       content_encryption_schema: :aes_gcm_no_padding,
#       security_profile: :v2,
#       region: 'us-east-1'
#     ),
#     'doc-example-bucket',
#     'my-file.txt',
#     'This is the content of my-file.txt.'
#   )
class S3Encryptor

def object_uploaded_with_public_key_encryption?(
  s3_encryption_client,
  bucket_name,
  object_key,
  object_content
)
  s3_encryption_client.put_object(
    bucket: bucket_name,
    key: object_key,
    body: object_content
  )
  return true
rescue StandardError => e
  puts "Error uploading object: #{e.message}"
  return false
end

# Full example call:
# Prerequisites: an RSA key pair.
def perform(path)
  bucket_name = Rails.con
  object_key = 'my-file.txt'
  object_content = 'This is the content of my-file.txt.'
  region = 'us-east-1'
  public_key_file = 'my-public-key.pem'
  public_key = OpenSSL::PKey::RSA.new(File.read(public_key_file))

  # When initializing this Amazon S3 encryption client, note:
  # - For key_wrap_schema, use rsa_oaep_sha1 for asymmetric keys.
  # - For security_profile, for reading or decrypting objects encrypted
  #     by the v1 encryption client, use :v2_and_legacy instead.
  s3_encryption_client = Aws::S3::EncryptionV2::Client.new(
    encryption_key: public_key,
    key_wrap_schema: :rsa_oaep_sha1,
    content_encryption_schema: :aes_gcm_no_padding,
    security_profile: :v2,
    region: region
  )

  if object_uploaded_with_public_key_encryption?(
    s3_encryption_client,
    bucket_name,
    object_key,
    object_content
  )
    puts 'Object uploaded.'
  else
    puts 'Object not uploaded.'
  end
end
end

# https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/s3-example-client-side-decrypt-item-with-private-key.html
class S3DownloadDecryptor
  def download_object_with_private_key_encryption(
  s3_encryption_client,
  bucket_name,
  object_key
)
  response = s3_encryption_client.get_object(
    bucket: bucket_name,
    key: object_key
  )
  return response.body.read
rescue StandardError => e
  puts "Error downloading object: #{e.message}"
end

# Full example call:
# Prerequisites: the same RSA key pair you originally used to encrypt the object.
def run_me
  bucket_name = 'doc-example-bucket'
  object_key = 'my-file.txt'
  region = 'us-east-1'
  private_key_file = 'my-private-key.pem'
  private_key = OpenSSL::PKey::RSA.new(File.read(private_key_file))

  # When initializing this Amazon S3 encryption client, note:
  # - For key_wrap_schema, use rsa_oaep_sha1 for asymmetric keys.
  # - For security_profile, for reading or decrypting objects encrypted
  #     by the v1 encryption client, use :v2_and_legacy instead.
  s3_encryption_client = Aws::S3::EncryptionV2::Client.new(
    encryption_key: private_key,
    key_wrap_schema: :rsa_oaep_sha1,
    content_encryption_schema: :aes_gcm_no_padding,
    security_profile: :v2,
    region: region
  )
  puts "The content of '#{object_key}' in bucket '#{bucket_name}' is:"
  puts download_object_with_private_key_encryption(
    s3_encryption_client,
    bucket_name,
    object_key
  )
end

end
