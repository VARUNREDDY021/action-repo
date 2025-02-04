resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  acl    = "private"
}

resource "aws_s3_object" "folders" {
  count   = length(var.folders)
  bucket  = aws_s3_bucket.this.bucket
  key     = "${var.folders[count.index]}/"  # Create the folder by setting the key as folder name
  acl     = "private"
  content = ""  # Empty content for folder creation
}