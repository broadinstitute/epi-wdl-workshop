#!/usr/bin/env python

import sys
from oauth2client.service_account import ServiceAccountCredentials

SCOPES = [
  'https://www.googleapis.com/auth/userinfo.profile',
  'https://www.googleapis.com/auth/userinfo.email'
]

def main():
  credentials = ServiceAccountCredentials.from_json_keyfile_name(
    sys.argv[1], scopes=SCOPES)
  print(credentials.get_access_token().access_token)

if __name__ == '__main__':
  main()
