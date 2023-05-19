locals {
  iam_to_primitive = {
    "roles/bigquery.dataOwner" : "OWNER"
    "roles/bigquery.dataEditor" : "WRITER"
    "roles/bigquery.dataViewer" : "READER"
  }
}

resource "google_bigquery_dataset" "datasets" {
  for_each                    = var.bigquery_datasets
  dataset_id                  = each.value.datasetName
  friendly_name               = each.value.datasetName
  description                 = each.value.datasetName
  location                    = var.location
  delete_contents_on_destroy  = var.delete_contents_on_destroy
  default_table_expiration_ms = var.default_table_expiration_ms
  project                     = var.project_id
  labels                      = var.labels
  dynamic "default_encryption_configuration" {
    for_each = var.encryption_key == null ? [] : [var.encryption_key]
    content {
      kms_key_name = var.encryption_key
    }
  }

  dynamic "access" {
    for_each = var.access
    content {
      # BigQuery API converts IAM to primitive roles in its backend.
      # This causes Terraform to show a diff on every plan that uses IAM equivalent roles.
      # Thus, do the conversion between IAM to primitive role here to prevent the diff.
      role = lookup(local.iam_to_primitive, access.value.role, access.value.role)

      domain         = lookup(access.value, "domain", null)
      group_by_email = lookup(access.value, "group_by_email", null)
      user_by_email  = lookup(access.value, "user_by_email", null)
      special_group  = lookup(access.value, "special_group", null)
    }
  }
}


resource "google_storage_bucket" "cloudfunciton_bucket" {
  for_each = var.buckets
  name     = each.value.bucketName
  location = var.location
  labels   = var.labels
  encryption {
    default_kms_key_name = ""
  }
}
resource "google_storage_bucket_object" "content_folder" {
  for_each   = var.bucket_objects
  name       = each.value.objectName
  content    = "Not really a directory, but it's empty."
  bucket     = each.value.bucketName
  depends_on = [google_storage_bucket.cloudfunciton_bucket]
}

resource "google_pubsub_topic" "pubsub_topic" {
  for_each = var.pubsub_topics
  name     = each.value.topicName

  message_retention_duration = "86600s"
}


resource "google_kms_key_ring" "keyring" {
  name     = var.key_ring_name
  location = "global"
}


resource "google_kms_crypto_key" "example-key" {
  name     = var.key_set_name
  key_ring = google_kms_key_ring.keyring.id

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_artifact_registry_repository" "artifactory-repo" {
  location      = var.location
  repository_id = "docker-images-test"
  description   = "docker repository"
  format        = "DOCKER"
}



