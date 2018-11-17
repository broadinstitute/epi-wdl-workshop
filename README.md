# Epigenomics WDL workshop

This repository contains scripts
for running WDL workflows on Google cloud.

We will show how to use them during the Broad Epigenomics WDL workshop.
After that, attendees will be able to run other workflows in their
own Google cloud projects.

## Initial setup

We will pre-create a demo project to run example workflows.
After the workshop, you can create a separate project
and run the same script to set it up.

1)  Install [Google Cloud SDK](https://cloud.google.com/sdk/).

    During the setup, please select `broad-epi-wdl-workshop` project.

2)  Clone this repo and run `./setup.sh` in its directory

This will create **`options.json`** file, which contains
your **credentials** for submission of workflows to WDL execution service (Cromwell).
*Please keep this file in a secure place!*

If at any point you lost `options.json` or just want to
re-create it, just re-run step 2.

## Submit a workflow

```
./submit.sh options.json workflow.wdl inputs.json
```
Here, `workflow.wdl` and `inputs.json` are the files
containing your WDL and its inputs
(we will explain the syntax during the workshop).

For more advanced use, you can add various options
to `options.json`, such as the default runtime
parameters or the location for Cromwell logs.
For details, please see [Workflow Options](https://cromwell.readthedocs.io/en/stable/wf_options/Overview/).

## Monitor workflows

Cromwell team provides a nice UI for *monitoring* your workflows.
Please navigate to [Job Manager](https://job-manager.caas-prod.broadinstitute.org/)
and log in with your Broad account.

**Note**: some browsers and/or their extensions may prohibit
certain cookies on many websites. You will have to *disable*
such plugins for this site.

## After the workshop

You can apply the *initial* setup described above
to any other Google project on your own.

However, in order to *submit* the workflows in
another project, your Google email or group
needs to be **whitelisted** in FireCloud.

Additionally, to access data in *Epigenomics production buckets*,
your service account will need to be whitelisted for
those buckets.

Please contact Wintergreen team (David and Denis)
for assistance with these steps.
