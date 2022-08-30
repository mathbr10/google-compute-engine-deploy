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

variable "default_service_account_email" {
  description = "Email from default service account"
  default     = "607243883309-compute@developer.gserviceaccount.com"
}

variable "gpu_type" {
  description = "GPU type"
  default     = "nvidia-tesla-k80" 
}

variable "gpu_units" {
  description = "Number of GPUs"
  default     = "0"
}

################################################################################
# Resources
################################################################################

# Data source for container registry image
data "google_container_registry_image" "bento_service" {
  name    = var.image_repository
  project = var.project_id
}

data "template_file" "startup_script" {
  template = "${file("start-up-script.sh")}"
  vars = {
    IMAGE_TAG = var.image_tag
    GPU_UNITS = var.gpu_units
    VERSION = "2.1.5"
    OS = "linux"
    ARCH = "amd64"
  }
}

resource "google_compute_instance" "vm" {
  project                   = var.project_id
  name                      = "${var.deployment_name}-instance"
  machine_type              = var.machine_type
  zone                      = var.zone
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
      size = 50 // Required when using GPU
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  guest_accelerator{
    type = var.gpu_type // Type of GPU attahced
    count = var.gpu_units // Num of GPU attached
  }
  scheduling{
    on_host_maintenance = "TERMINATE" // Need to terminate GPU on maintenance
  }

  # metadata_startup_script = "${file("start-up-script.sh")}"
  metadata_startup_script = "${data.template_file.startup_script.rendered}"

  service_account {
    email = var.default_service_account_email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  provisioner "local-exec" {
    command = <<-EOT
        attempt_counter=0
        max_attempts=40
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