# aws-s3-publish-readonly

This helper script simplifies the process of uploading a file to an S3 bucket, then generating a presigned URL. When the file is uploaded to a private bucket, this is a nice way to grant access to the file to specific people by providing the signed URL.

The script will make use of the AWS credentials available in the environment, be it the appropriate environment variables or the ones defined in the credentials file (`.aws/creds`).

If the default credentials are temporary (e.g., granted by STS), then you probably want to sign the URL with another AWS profile with long lasting credentials, otherwise the recipients of the URL might not be able to access the content. For this, you can use the `-p` option to specify an alternate profile:

```
s3publish.sh -b my-bucket -f /path/to/file.zip -p signingProfile
```
