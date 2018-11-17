# Epigenomics WDL workshop

This repository contains scripts to set up user environment
for running WDL workflows on Google cloud.

We will show how to use them during the Broad Epigenomics WDL workshop.
After that, attendees will be able to run other workflows in their
own Google cloud projects.

## Initial setup

We will pre-create a demo project to run example workflows.
After the workshop, you can create a separate project
and run the same scripts to set it up.

1)  Install [Google Cloud SDK](https://cloud.google.com/sdk/).

    During the setup, please select `broad-epi-wdl-workshop` project.

2)  Clone this repo and run `./setup.sh` in its directory

This will create `options.json` file, which will
be used to submit all workflows to WDL execution service (Cromwell).

## Submit a workflow

To submit a workflow, run
```
./submit.sh options.json workflow.wdl inputs.json
```
Here, `workflow.wdl` and `inputs.json` are the files
containing your WDL workflow and its inputs
(we will explain the syntax during the workflow).

For more advanced use, you can add various options
to `options.json`, such as the default runtime
parameters or the directory for WDL logs.
For details, please see [Workflow Options](https://cromwell.readthedocs.io/en/stable/wf_options/Overview/).
