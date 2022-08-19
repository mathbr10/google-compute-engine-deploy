################################################################################
# Input variable definitions
################################################################################

variable "deployment_name" {
  description = "Name of the deployment."
  type        = string
}

variable "image_tag" {
  description = "full image gcr image tag"
  type        = string
}

variable "image_repository" {
  description = "gcr repository name"
  type        = string
}

variable "image_version" {
  description = "gcr image version"
  type        = string
}

variable "project_id" {
  description = "GCP project to use for creating deployment."
  type        = string
}

variable "machine_type" {
  description = "GCP machine type."
  default     = "n1-standard-1"
}

variable "zone" {
  description = "GCP zone."
  default     = "us-central1-a"
}

variable "firewall" {
  description = "The firewall aplied to the compute engine."
  default     = "bentoctl-firewall"
}

#variable "service_account_id" {
#  description = "The service account id."
#  default     = "ai-engine-tf-sa"
#}

variable "default_service_account_email" {
  description = "Email from default service account"
  default     = "607243883309-compute@developer.gserviceaccount.com"
}


################################################################################
# Resources
################################################################################

# Data source for container registry image
data "google_container_registry_image" "bento_service" {
  name    = var.image_repository
  project = var.project_id
}

module "gce-container" {
  # https://registry.terraform.io/modules/terraform-google-modules/container-vm/google/latest
  source         = "terraform-google-modules/container-vm/google"
  cos_image_name = "cos-stable-77-12371-89-0"
  container = {
    image = "${data.google_container_registry_image.bento_service.image_url}:${var.image_version}"
    env = [
      {
        name  = "BENTOML_PORT"
        value = "3000"
      },
    ]
  }

  restart_policy = "Always"
}


##################
#Creating a service account for this deploy - Not working - Can not serve
##################

#provider "google" {
#  project     = var.project_id
#  region      = "us-central1"
#}

#resource "google_service_account" "created_service_account" {
#  account_id   = var.service_account_id
#  display_name = "AI Engine Terraform Service Account"
#}

#resource "google_service_account_key" "mykey" {
#  service_account_id = google_service_account.created_service_account.name
#}

#resource "google_service_account_iam_binding" "admin-account-iam" {
#  service_account_id = google_service_account.created_service_account.name
#  role               = "roles/editor"

#  members = [
#    join(":", ["serviceAccount", google_service_account.created_service_account.email])
#  ]
#}

##################
#Creating a service account for this deploy as IAM member - Not working - Can not serve
##################

#provider "google" {
#  project     = var.project_id
#  region      = "us-central1"
#}

#data "google_compute_default_service_account" "default" {
#}

#resource "google_service_account" "created_service_account" {
#  account_id   = var.service_account_id
#  display_name = "AI Engine Terraform Service Account"
#}

#resource "google_service_account_key" "mykey" {
#  service_account_id = google_service_account.created_service_account.name
#}

#resource "google_service_account_iam_member" "admin-account-iam" {
#  service_account_id = google_service_account.created_service_account.name
#  role               = "roles/editor"
#  member             = "serviceAccount:${google_service_account.created_service_account.email}"
#}

## Allow SA service account use the default GCE account
#resource "google_service_account_iam_member" "gce-default-account-iam" {
#  service_account_id = data.google_compute_default_service_account.default.name
#  role               = "roles/editor"
#  member             = "serviceAccount:${google_service_account.created_service_account.email}"
#}

resource "google_compute_instance" "vm" {
  project                   = var.project_id
  name                      = "${var.deployment_name}-instance"
  machine_type              = var.machine_type
  zone                      = var.zone
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = module.gce-container.source_image
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    gce-container-declaration = module.gce-container.metadata_value
    google-logging-enabled    = "true"
    google-monitoring-enabled = "true"
  }

  labels = {
    container-vm = module.gce-container.vm_container_label
  }

  #service_account {
  #  email = google_service_account.created_service_account.email
  #  scopes = [
  #    "https://www.googleapis.com/auth/cloud-platform",
  #  ]
  #}

  service_account {
    email = var.default_service_account_email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  provisioner "local-exec" {
    command = <<-EOT
        attempt_counter=0
        max_attempts=20
        printf 'waiting for server to start'
        until $(curl --output /dev/null --silent --head --fail http://${self.network_interface.0.access_config.0.nat_ip}:3000); do
            if [ $attempt_counter -eq $max_attempts ];then
              echo "Max attempts reached"
              exit 1
            fi

            printf '.'
            attempt_counter=$(($attempt_counter+1))
            sleep 15
        done
        EOT
  }
}

resource "google_compute_firewall" "default" {
  name    = var.firewall
  network = "default"
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["3000"]
  }

  source_ranges = ["0.0.0.0/0"]
  source_tags = ["http"]
}

################################################################################
# Output value definitions
################################################################################

output "endpoint" {
  description = "IP address for the instance"
  value       = "http://${google_compute_instance.vm.network_interface.0.access_config.0.nat_ip}:3000"
}
