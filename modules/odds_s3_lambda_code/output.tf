output "s3_bucket" {
  value = aws_s3_bucket.this.id
}

output "folders" {
  value = [for f in aws_s3_object.folders : f.key]
}