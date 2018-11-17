#!/usr/bin/env python

import json
from sys import argv

project = argv[1]
bucket = argv[2]
key_file = argv[3]

OPTIONS_FILE = 'options.json'

DEFAULT_CPU = 2
DEFAULT_MEMORY = '2G'
DEFAULT_DISK = 'local-disk 25 HDD'
ZONES = [
  'us-east1-b', 'us-east1-c', 'us-east1-d',
  'us-central1-a', 'us-central1-b', 'us-central1-c', 'us-central1-f',
  'us-west1-a', 'us-west1-b', 'us-west1-c'
]
MAX_PREEMPTIBLE = 3
MAX_RETRIES = 1

def main():
  with open(key_file, 'r') as f:
    key = json.dumps(json.load(f))

  with open(OPTIONS_FILE, 'w') as out:
    options = {
      'google_project': project,
      'jes_gcs_root': 'gs://' + bucket,
      'user_service_account_json': key,
      'default_runtime_attributes': {
        'cpu': DEFAULT_CPU,
        'memory': DEFAULT_MEMORY,
        'disks': DEFAULT_DISK,
        'zones': ZONES,
        'preemptible': MAX_PREEMPTIBLE,
        'maxRetries': MAX_RETRIES,
      },
    }
    json.dump(options, out, indent=2)

if __name__ == '__main__':
    main()
