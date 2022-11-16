OPERATOR_SCHEMA = {
    "project_id": {
        "required": True,
        "type": "string",
    },
    "zone": {
        "required": True,
        "type": "string",
        "default": "us-central1-a",
    },
    "machine_type": {
        "required": True,
        "type": "string",
        "default": "n1-standard-1",
    },
    "firewall": {
        "required": True,
        "type": "string",
        "default": "bentoctl-firewall",
    },
    "gpu_type": {
        "required": True,
        "type": "string",
        "default": "nvidia-tesla-k80",
    },
    "gpu_units": {
        "required": True,
        "type": "string",
        "default": "0",
    },

    "service_account_email": {
        "required": True,
        "type": "string",
    },
    "gcp_credentials_path": {
        "required": True,
        "type": "string",
    },
    "gcp_disk_size": {
        "required": True,
        "type": "integer",
    }
}

OPERATOR_NAME = "google-compute-engine"
OPERATOR_MODULE = "google_compute_engine"
OPERATOR_DEFAULT_TEMPLATE = "terraform"
