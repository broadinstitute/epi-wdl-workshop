# Epigenomics WDL workshop

This repository contains scripts
for running WDL workflows on Google cloud.

We will show how to use them during the Broad Epigenomics WDL workshop.
After that, attendees will be able to run other workflows in their
own Google cloud projects.

## Setup

Please install Docker for
[Windows](https://download.docker.com/win/stable/Docker%20for%20Windows%20Installer.exe),
[Mac](https://download.docker.com/mac/stable/Docker.dmg),
or your favorite
[Linux](https://docs.docker.com/install/#supported-platforms) distribution
(unfortunately, the official links for **Windows** and **Mac** on that last page
require registration, so don't use them 😉).

## Submit a workflow

Please open command line and run
```
docker run --rm -it -v epi-cromwell:/cromwell -v $PWD:/workflow quay.io/broadinstitute/epi-cromwell \
  broad-epi-wdl-workshop /example/Alignment.wdl /example/alignment.inputs.json
```
Here, `broad-epi-wdl-workshop` is the name of the Google cloud project
for the workshop. Please change it to your own project when you
start submitting your own workflows.

`/example/Alignment.wdl` and `/example/alignment.inputs.json`
are the paths to the WDL and workflow inputs inside the Docker
container.

While technically not required for the examples,
`-v $PWD:/workflow` says that you're mounting the
current working directory into `/workflow` directory
inside the container. That way, you will be able to submit
your future workflows as follows:
```
docker run --rm -it -v epi-cromwell:/cromwell -v $PWD:/workflow quay.io/broadinstitute/epi-cromwell \
  your-google-project-id workflow.wdl inputs.json
```
where `workflow.wdl` and `inputs.json` are your own
WDL file and its inputs, located in the current
working directory on the command line.

*Note:* If you're running this command **on Windows command line**,
please replace `$PWD` with `%cd%`.

The command from above will initially prompt you to
authenticate on Google cloud. Please copy-paste the
link from the terminal into your browser, follow the
on-screen prompts, and then copy-paste the resulting
code back into the terminal and hit Enter.

Once this is done, the command will remember your
credentials for any future workflows, so you
will not have to re-authenticate again.

Any subsequent command invocations should take
only a couple seconds, unless you start working on
a new project, in which case it will
re-run a short setup script first.

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
