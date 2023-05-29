import os
from concurrent import futures
from typing import Callable

from google.cloud import pubsub_v1
from google.cloud import storage

project_id = os.getenv("PROJECT_ID","de-da-poc")
topic_id = os.getenv("TOPIC_ID","pharmacy-medication-form-data")

def read_from_gcs(event, context):
    """Triggered by a change to a Cloud Storage bucket.
    Args:
         event (dict): Event payload.
         context (google.cloud.functions.Context): Metadata for the event.
    """
    print('Processing file', event)
    bucket_name = event['bucket']
    file_name = event['name']
    message = get_file_from_gcs(bucket_name, file_name)
    publish_message_to_topic(message)


def get_file_from_gcs(bucket_name, file_name):
    """
    Download a file (blob) from the bucket given a file name into a specific folder
    defined by the path parameter.
    """
    # Retrieve the bucket
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name=bucket_name)
    # Retrieve blob through its file_name from bucket
    blob = bucket.blob(file_name)
    # Download blob as byte
    downloaded_file = blob.download_as_bytes()

    return downloaded_file


"""Publishes multiple messages to a Pub/Sub topic with an error handler."""

def publish_message_to_topic(message):
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project_id, topic_id)
    publish_futures = []

    # When you publish a message, the client returns a future.
    publish_future = publisher.publish(topic_path, message)
    # Non-blocking. Publish failures are handled in the callback function.
    publish_future.add_done_callback(get_callback(publish_future, message))
    publish_futures.append(publish_future)

    # Wait for all the publishing futures to resolve before exiting.
    futures.wait(publish_futures, return_when=futures.ALL_COMPLETED)

    print(f"Published messages with error handler to {topic_path}.")

def get_callback(
    publish_future: pubsub_v1.publisher.futures.Future, data: str
) -> Callable[[pubsub_v1.publisher.futures.Future], None]:
    def callback(publish_future: pubsub_v1.publisher.futures.Future) -> None:
        try:
            # Wait 60 seconds for the publish call to succeed.
            print(publish_future.result(timeout=60))
        except futures.TimeoutError:
            print(f"Publishing {data} timed out.")

    return callback

if __name__ == "__main__":
    event = {'bucket': 'medication-forms', 'contentType': 'application/json', 'crc32c': 'P5JFlQ==', 'etag': 'CNbrxaChiP8CEAE=', 'generation': '1684735618282966', 'id': 'medication-forms/medication_form-15.json/1684735618282966', 'kind': 'storage#object', 'md5Hash': 'qEH8SaBQzr8YDJXjfHSkiQ==',
             'mediaLink': 'https://storage.googleapis.com/download/storage/v1/b/medication-forms/o/medication_form-15.json?generation=1684735618282966&alt=media',
             'metageneration': '1', 'name': 'medication_form-15.json',
             'selfLink': 'https://www.googleapis.com/storage/v1/b/medication-forms/o/medication_form-15.json',
             'size': '4533', 'storageClass': 'STANDARD', 'timeCreated': '2023-05-22T06:06:58.381Z', 'timeStorageClassUpdated': '2023-05-22T06:06:58.381Z', 'updated': '2023-05-22T06:06:58.381Z'}
    read_from_gcs(event, None)


