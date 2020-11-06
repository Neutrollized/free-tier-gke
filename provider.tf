terraform {
  required_version = "~> 0.13.0"
}

// Configure the GCP provider
provider "google" {
  version     = "~> 3.0"
  project     = var.project_id
  credentials = file(var.credentials_file_path)
  region      = var.region
  zone        = var.zone
}

provider "google-beta" {
  version     = "~> 3.0"
  project     = var.project_id
  credentials = file(var.credentials_file_path)
  region      = var.region
  zone        = var.zone
}
