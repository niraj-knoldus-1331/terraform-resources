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
data_gen_func = "data_gen_func"
input_bucket = "de-da-poc-data"
output_bucket = "medication-forms"
num_records = 10
function_entry_point_data_gen = "generate_data"
service_account_email = "data-generator@de-da-poc.iam.gserviceaccount.com"
topic_id = "pharmacy-medication-form-data"