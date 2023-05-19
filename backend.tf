terraform {
  backend "gcs" {
    bucket  = "de-da-poc-tf-state-prod"
    prefix  = "terraform/state"
  }
}
