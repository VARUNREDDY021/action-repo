variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "folders" {
  description = "List of folders to create in the S3 bucket"
  type        = list(string)
}

variable "common_tags" {
    type = map(any)
}