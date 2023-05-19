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
