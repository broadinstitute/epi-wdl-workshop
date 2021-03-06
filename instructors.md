# Notes to the **instructors** of the workshop

These are the additional steps taken
in preparation for the workshop.

1)  Create Google project `broad-epi-wdl-workshop`.
2)  Create `epi-wdl-workshop-users` group in FireCloud.
3)  Add admin/member emails to this group as needed.
4)  Assign *Editor*, *Project IAM Admin*, and *Service Account Admin* roles
    for `epi-wdl-workshop-users@firecloud.org` in project's IAM console.
5)  Contact #ftfy channel in Slack to whitelist the group
    for submission of workflows to CaaS.
6)  Create bucket `broad-epi-wdl-workshop-data`.
7)  Copy example data into the bucket.
8)  Enable Google Container Registry API in the project.
9)  Pull GCR Docker images from `broad-epigenomics` project
    and push them to `broad-epi-wdl-workshop` project.
