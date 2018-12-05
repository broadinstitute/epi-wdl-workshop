# Epigenomics WDL workshop

This repository contains scripts
for running WDL workflows on Google cloud.

We will show how to use them during the Broad Epigenomics WDL workshop.
After that, attendees will be able to run other workflows in their
own Google cloud projects.

## Setup

### Sign up for FireCloud

Access to Epigenomics Cromwell is managed through
[FireCloud](https://portal.firecloud.org/),
so **please register there first** with your Broad email (preferred).

Additionally, your email needs to be whitelisted by
[Wintergreen team](mailto:wintergreen@broadinstitute.org) (David and Denis)
so you are allowed to submit workflows.

### Install Docker

Please install Docker for
[Windows](https://download.docker.com/win/stable/Docker%20for%20Windows%20Installer.exe),
[Mac](https://download.docker.com/mac/stable/Docker.dmg),
or your favorite
[Linux](https://docs.docker.com/install/#supported-platforms) distribution
(unfortunately, the official links for *Windows* and *Mac* on that last page
require registration, so don't use them 😉).

*Note:* that Windows link only works for **Windows 10 Pro & above**.
If you have Windows 7 or Windows 10 Home, you will have to install
[Docker Toolbox](https://docs.docker.com/toolbox/toolbox_install_windows/) instead.

## Submit a workflow

Please open command line and run
```
docker run --rm -it -v epi-cromwell:/cromwell -v "$PWD":/workflow:ro quay.io/broadinstitute/epi-cromwell \
  <google-project-id> /example/hello_world.wdl /example/hello_world.inputs.json
```
**Replace** `<google-project-id>` with your Google project ID.
**During** the workshop, this will be `broad-epi-wdl-workshop`.
However, if you're following these instructions **after** the workshop,
you will need to use your own project ID.

*Note:* If you're running this command **on Windows command line**,
additionally replace `$PWD` with `%cd%` and remove `\` at the end.
You will also have to copy and paste each of the above lines
into the same line.

`/example/hello_world.wdl` and `/example/hello_world.inputs.json`
are the paths to the example WDL and workflow inputs *inside* the Docker
container.

While technically not required for the example,
`-v "$PWD":/workflow:ro` says that you're mounting
*the current working directory on your command line*
into the container path `/workflows` in read-only mode.
That way, you will be able to submit
your future workflows as follows:
```
docker run --rm -it -v epi-cromwell:/cromwell -v "$PWD":/workflow:ro quay.io/broadinstitute/epi-cromwell \
  <google-project-id> workflow.wdl inputs.json
```
where `workflow.wdl` and `inputs.json` are your own
WDL file and its inputs, located in the current
working directory on the command line.

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

Addionally, this Docker image will be periodically
updated, so we encourage you to run
```
docker pull quay.io/broadinstitute/epi-cromwell
```
from time to time.

## Monitor workflows

Cromwell team provides a nice UI for *monitoring* your workflows.
Please navigate to [Job Manager](https://job-manager.caas-prod.broadinstitute.org/)
and log in with your Broad account.

**Note**: some browsers and/or their extensions may prohibit
certain cookies on many websites. You will have to *disable*
such plugins for this site.

## After the workshop

To start running workflows in your own project,
you need to be an *Owner* of that project, and
then run the command from above using your project ID.

Additionally, your "Cromwell pet service account"
needs to be whitelisted by
[Wintergreen team](mailto:wintergreen@broadinstitute.org)
if you'd like to be able to access "production" data
for Epigenomics Program from workflows in your project.
