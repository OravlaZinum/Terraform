terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone = var.zone
}

#VPC
resource "google_compute_network" "vpc_network" {
  name = "zinum-vpc"
}

#Virtual Machine
resource "google_compute_instance" "vm_instance" {
  name         = "bastion"
  machine_type = "n1-standard-1"
  tags = ["bastion"] 

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  metadata_startup_script = file(var.bastion_script)

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
}
