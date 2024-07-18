# --------------------------------------------------------------------------------------
# Variables - conditional resources
variable "create_aqvis_destroyable" {
  description = "Boolean to determine if destroyable resources for running AQvis web app should be created."
  type        = bool
  default     = true
}
# Variables - conditional resources
# --------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region to deploy the resources"
  default     = "eu-central-1"
}

variable "aws_secret_key_id" {
  description = "AWS secret key id"
  type = string
  sensitive = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key"
  type = string
  sensitive = true
}

variable "mongodb_connection_uri" {
  description = "Mongo db connection URI."
  types = string
  sensitive = true
}

variable "mongodb_connection_uri_test" {
  description = "Mongo db connection URI for test"
  types = string
  sensitive = true
}

variable "secret_key" {
  description = "secret key for encryption/decryption"
  type = string
  sensitive = true
}