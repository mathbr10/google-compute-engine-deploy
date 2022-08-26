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
    
    "default_service_account_email": {
        "required": True,
        "type": "string",
        "default": "607243883309-compute@developer.gserviceaccount.com",
    },
}

OPERATOR_NAME = "google-compute-engine"
OPERATOR_MODULE = "google_compute_engine"
OPERATOR_DEFAULT_TEMPLATE = "terraform"
