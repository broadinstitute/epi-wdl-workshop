#!/usr/bin/env python

import json
from sys import argv

project = argv[1]
bucket = argv[2]
key_file = argv[3]

options_file = 'options.json'

def main():
  with open(key_file, 'r') as f:
    key = json.dumps(json.load(f))

  with open(options_file, 'w') as out:
    options = {
      'google_project': project,
      'jes_gcs_root': 'gs://' + bucket,
      'user_service_account_json': key,
    }
    json.dump(options, out, indent=2)

if __name__ == "__main__":
    main()
