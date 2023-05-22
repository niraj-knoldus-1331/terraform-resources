bigquery_datasets = {
  medication_form = {
    datasetName = "test_dataset",
  }
}
buckets = {
  de-da-poc-test-bucket= {
    bucketName = "de-da-poc-test-bucket",
  }
}
pubsub_topics = {
  test-topic = {
    topicName = "test-topic",
  }
}
bucket_objects = {
  test-topic = {
    objectName = "test-object",
    bucketName = "de-da-poc-test-bucket"
  }
}
key_set_name = "keyring-example"
key_ring_name = "crypto-key-example"
project_id = "de-da-poc"
region     = "us-east1"
location   = "us"
function_name = "gcs-to-pubsub"
runtime = "python39"
function_entry_point = "read_from_gcs"
service_account_email = "data-generator@de-da-poc.iam.gserviceaccount.com"
topic_id = "pharmacy-medication-form-data"