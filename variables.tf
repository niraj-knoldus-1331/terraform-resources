variable "project_id" {}
variable "region" {}
variable "location" {}
variable "bigquery_datasets" {
  description = "BigQuery DataSets"
  type = map(object({
    datasetName = string
  }))
}
variable "buckets" {
  description = "BigQuery DataSets"
  type = map(object({
    bucketName = string
  }))
}
variable "pubsub_topics" {
  description = "Pub Sub Topics"
  type = map(object({
    topicName = string
  }))
}
variable "bucket_objects" {
  description = "Pub Sub Topics"
  type = map(object({
    bucketName = string,
    objectName = string
  }))
}
variable "key_set_name" {
  default = ""
}
variable "key_ring_name" {
  default = ""
}
variable "function_name" {
  default = ""
}
variable "runtime" {
  default = ""
}
variable "function_entry_point" {
  default = ""
}
variable "service_account_email" {
  default = ""
}
variable "topic_id" {
  default = ""
}
variable "delete_contents_on_destroy" {
  description = "(Optional) If set to true, delete all the tables in the dataset when destroying the resource; otherwise, destroying the resource will fail if tables are present."
  type        = bool
  default     = null
}

variable "deletion_protection" {
  description = "Whether or not to allow Terraform to destroy the instance. Unless this field is set to false in Terraform state, a terraform destroy or terraform apply that would delete the instance will fail"
  type        = bool
  default     = false
}

variable "default_table_expiration_ms" {
  description = "TTL of tables using the dataset in MS"
  type        = number
  default     = null
}
variable "encryption_key" {
  description = "Default encryption key to apply to the dataset. Defaults to null (Google-managed)."
  type        = string
  default     = null
}

variable "labels" {
  description = "Key value pairs in a map for dataset labels"
  type        = map(string)
  default     = {}
}

# Format: list(objects)
# domain: A domain to grant access to.
# group_by_email: An email address of a Google Group to grant access to.
# user_by_email:  An email address of a user to grant access to.
# special_group: A special group to grant access to.
variable "access" {
  description = "An array of objects that define dataset access for one or more entities."
  type        = any

  # At least one owner access is required.
  default = [
    {
      role          = "roles/bigquery.dataOwner"
      special_group = "projectOwners"
    }
  ]
}

