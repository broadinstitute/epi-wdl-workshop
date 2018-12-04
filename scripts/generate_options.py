#!/usr/bin/env python

import json
from sys import argv

project = argv[1]
bucket = argv[2]
key_file = argv[3]

OPTIONS_FILE = 'options.json'

BACKEND = 'PAPIv2'

JES_GCS_ROOT = 'gs://' + bucket + '/workflows'
MONITORING_SCRIPT = 'gs://' + bucket + '/scripts/monitoring.sh'
LOGS_DIR = 'gs://' + bucket + '/logs'

DEFAULT_DISK = 'local-disk 10 HDD'
ZONES = [
  'us-east1-b', 'us-east1-c', 'us-east1-d',
  'us-central1-a', 'us-central1-b', 'us-central1-c', 'us-central1-f',
  'us-west1-a', 'us-west1-b', 'us-west1-c'
]
MAX_PREEMPTIBLE = 3
MAX_RETRIES = 1

def main():
  with open(key_file, 'r') as f:
    key = json.load(f)

  with open(OPTIONS_FILE, 'w') as out:
    options = {
      'backend': BACKEND,
      'google_project': project,
      'user_service_account_json': json.dumps(key),
      'google_compute_service_account': key['client_email'],
      'jes_gcs_root': JES_GCS_ROOT,
      'monitoring_script': MONITORING_SCRIPT,
      'final_workflow_log_dir': LOGS_DIR,
      'default_runtime_attributes': {
        'disks': DEFAULT_DISK,
        'zones': ZONES,
        'preemptible': MAX_PREEMPTIBLE,
        'maxRetries': MAX_RETRIES,
      },
    }
    json.dump(options, out, indent=2)

if __name__ == '__main__':
    main()
