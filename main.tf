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
resource "google_storage_bucket" "cloudfunciton_bucket" {
  name     = "${var.project_id}-cloud-function"
  location = var.location
  encryption {
    default_kms_key_name = ""
  }
}
data "archive_file" "publishToPubSub" {
  type        = "zip"
  output_path = "${path.module}/resources/publishToPubSub/function.zip"
  source {
    content  = file("${path.module}/resources/publishToPubSub/main.py")
    filename = "main.py"
  }
  source {
    content  = file("${path.module}/resources/publishToPubSub/requirements.txt")
    filename = "requirements.txt"
  }
}
data "archive_file" "dataGen" {
  type        = "zip"
  output_path = "${path.module}/resources/dataGen/dataGen.zip"
  source {
    content  = file("${path.module}/resources/dataGen/main.py")
    filename = "main.py"
  }
  source {
    content  = file("${path.module}/resources/dataGen/requirements.txt")
    filename = "requirements.txt"
  }
}

# Upload the zip to the bucket. The archive in Cloud Storage uses the md5 of the zip file.
resource "google_storage_bucket_object" "archive" {
  name       = "src-${data.archive_file.publishToPubSub.output_md5}.zip"
  bucket     = google_storage_bucket.cloudfunciton_bucket.name
  source     = "${path.module}/resources/publishToPubSub/function.zip"
  depends_on = [data.archive_file.publishToPubSub]
}
# Upload the zip to the bucket. The archive in Cloud Storage uses the md5 of the zip file.
resource "google_storage_bucket_object" "archive1" {
  name       = "src-${data.archive_file.dataGen.output_md5}.zip"
  bucket     = google_storage_bucket.cloudfunciton_bucket.name
  source     = "${path.module}/resources/dataGen/dataGen.zip"
  depends_on = [data.archive_file.publishToPubSub]
}

resource "google_storage_bucket_object" "data-gen" {
  name       = "src-${data.archive_file.publishToPubSub.output_md5}.zip"
  bucket     = google_storage_bucket.cloudfunciton_bucket.name
  source     = "${path.module}/resources/publishToPubSub/function.zip"
  depends_on = [data.archive_file.publishToPubSub]
}
resource "google_cloudfunctions_function" "function-publish" {
  name    = var.function_name
  runtime = var.runtime

  available_memory_mb   = 256
  entry_point           = var.function_entry_point_data_gen
  timeout               = 60
  project               = var.project_id
  region                = var.region
  trigger_http          = true
  source_archive_bucket = google_storage_bucket.cloudfunciton_bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  service_account_email = var.service_account_email

  environment_variables = {
    PROJECT_ID = var.project_id
    TOPIC_ID   = var.topic_id
  }
}
resource "google_cloudfunctions_function" "dataGen-func" {
  name    = var.data_gen_func
  runtime = var.runtime

  available_memory_mb   = 256
  entry_point           = var.function_entry_point
  timeout               = 60
  project               = var.project_id
  region                = var.region
  trigger_http          = true
  source_archive_bucket = google_storage_bucket.cloudfunciton_bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  service_account_email = var.service_account_email

  environment_variables = {
    INPUT_BUCKET  = var.input_bucket
    OUTPUT_BUCKET = var.output_bucket
    NUM_RECORDS   = var.num_records
  }
}

# Make the function public - TODO : authentication
resource "google_cloudfunctions_function_iam_member" "invoker-monitor" {
  project        = google_cloudfunctions_function.function-publish.project
  region         = google_cloudfunctions_function.function-publish.region
  cloud_function = google_cloudfunctions_function.function-publish.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}
resource "google_cloudfunctions_function_iam_member" "invoker-data-gen" {
  project        = google_cloudfunctions_function.dataGen-func.project
  region         = google_cloudfunctions_function.dataGen-func.region
  cloud_function = google_cloudfunctions_function.dataGen-func.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}


