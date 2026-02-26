# ivcap-rnaseq-nextflow

This repository is a **minimal, worked example** showing how to **package a Nextflow pipeline** so it can be **deployed and executed on IVCAP**.

The pipeline implemented here is based on the Nextflow training material:

* https://training.nextflow.io/latest/nf4_science/rnaseq/03_multi-sample/

In this repo the pipeline focuses on a *paired-end* RNA-seq QC workflow using:

* **FastQC** (initial QC)
* **Trim Galore** (adapter trimming + post-trim QC)
* **MultiQC** (aggregated QC report)

> Note: There is a HISAT2 module present, but alignment is currently commented out in `main.nf`.

## Table of contents

* [Repository layout (high level)](#repository-layout-high-level)
* [Prerequisites](#prerequisites)
* [Run locally](#run-locally)
* [Deploy to IVCAP](#deploy-to-ivcap)
  * [Deploy (one command)](#deploy-one-command)
  * [Deploy the pipeline artifact (manual step)](#deploy-the-pipeline-artifact-manual-step)
  * [Deploy/update the IVCAP service definition (manual step)](#deployupdate-the-ivcap-service-definition-manual-step)
* [Test an IVCAP job request](#test-an-ivcap-job-request)
* [Notes / known quirks](#notes--known-quirks)
* [More instructions will follow](#more-instructions-will-follow)

## Repository layout (high level)

* `main.nf` — Nextflow entrypoint
* `nextflow.config` — Nextflow configuration (Docker enabled, reports/timeline/trace enabled)
* `modules/` — DSL2 modules used by the workflow
* `data/` — example inputs for local runs
  * `data/paired-end.csv` — example samplesheet used by default
* `schema_input.json` — JSON schema describing the sample input file structure (used by the IVCAP controller)
* `ivcap-service.yaml` — IVCAP *service definition* template (references the packaged pipeline artifact)
* `tests/simple_rnaseq_ivcap.json` — example IVCAP job request
* `Makefile` — convenience targets for running, packaging, deploying, and testing

## Prerequisites

* Nextflow (and Docker if running with containers)
* **IVCAP CLI** (for deployment/testing against an IVCAP environment)
  * Install instructions: https://github.com/ivcap-works/ivcap-cli

## Run locally

This repo is configured to run with Docker.

```bash
$ make run
rm -rf .nextflow* work results
nextflow run "main.nf" \
        -c nextflow.config \
        -c conf/weblog.disabled.config \
        -params-file params.json \
        -cache false
Nextflow 25.10.4 is available - Please consider updating your version to it

 N E X T F L O W   ~  version 25.10.0

Launching `main.nf` [gloomy_shirley] DSL2 - revision: c8dbf9d8e0

executor >  local (13)
[cd/a09841] process > FASTQC (3)      [100%] 6 of 6 ✔
[71/218fb3] process > TRIM_GALORE (5) [100%] 6 of 6 ✔
[51/85944c] process > MULTIQC         [100%] 1 of 1 ✔
```

By default the pipeline reads the sample sheet from `data/paired-end.csv` (see `nextflow.config` and `main.nf`). Results are written to `results/`.

## Deploy to IVCAP

> This repository assumes you have the **IVCAP CLI** installed and configured.

The following make target will deploy this pipeline to the IVCAP platform configured as default in the `ivcap` cli command (`ivcap context get`)

```bash
make deploy
```

Under the hood this will:

1. **Tar up the pipeline** (Nextflow scripts, config, modules, and `schema_input.json`) into a single file (see `make package`, producing `simple-rna-seq.tar`).
2. **Upload that tarball to IVCAP** as an *artifact* (pipeline definition bundle).
3. **Register/update the service** identified by `SERVICE_ID` so it references the uploaded artifact id/URN in the Nextflow controller section of the service definition (see `ivcap-service.yaml`).



## Test an IVCAP job request

An example request payload is provided:

* `tests/simple_rnaseq_ivcap.json`

Submit it with:

```bash
make test-job
```

```text
$ make test-job
ivcap job create urn:ivcap:service:a98b81a8-9279-509f-9c0e-40d39e83058a -f tests/simple_rnaseq_ivcap.json --stream
---------
{
  "SeqID": "00013567",
  "eventID": "019c988c-1d3a-7ba6-8460-0cceaaac908a",
  "type": "ivcap.job.status",
  "schema": "urn:ivcap:schema:job.status.1",
  "source": "nxf-a98b81a8-9279-509f-9c0e-40d39e83058a-srkhwjtq",
  "timestamp": "2026-02-26T06:04:05.25563056Z",
  "data": {
    "job-urn": "urn:ivcap:job:d0e8225e-7de5-479e-b2c7-e8f23201c63e",
    "status": "executing"
  }
}
---------
{
  "SeqID": "00013568",
  "eventID": "019c988c-3f97-73fc-acfa-888e22b3a9db",
  "type": "ivcap.job.event",
  "schema": "urn:ivcap:schema:service.event.step.start.1",
  "source": "nxf-a98b81a8-9279-509f-9c0e-40d39e83058a-srkhwjtq",
  "timestamp": "2026-02-26T06:04:14.064734819Z",
  "data": {
    "$schema": "urn:ivcap:schema:service.event.step.start.1",
    "name": "download pipeline",
    "options": {
      "pipeline": "urn:ivcap:artifact:19111634-fe92-4585-8d0c-0f889c38d1de"
    }
  }
}
---------
...
---------
{
  "SeqID": "00013575",
  "eventID": "019c988f-20ab-7391-a435-fd0a22e78f11",
  "type": "ivcap.job.status",
  "schema": "urn:ivcap:schema:job.status.1",
  "source": "nxf-a98b81a8-9279-509f-9c0e-40d39e83058a-srkhwjtq",
  "timestamp": "2026-02-26T06:07:22.787549187Z",
  "data": {
    "job-urn": "urn:ivcap:job:d0e8225e-7de5-479e-b2c7-e8f23201c63e",
    "status": "succeeded"
  }
}
---------

       Name  nxf-a98b81a8-9279-509f-9c0e-40d39e83058a-srkhwjtq

         ID  urn:ivcap:job:d0e8225e-7de5-479e-b2c7-e8f23201c63e (@1)
     Status  executing
 Started At  3 minutes ago (26 Feb 26 17:04 AEDT)
    Service  urn:ivcap:service:a98b81a8-9279-509f-9c0e-40d39e83058a (@2)
     Policy  urn:ivcap:policy:ivcap.base.service
    Account  urn:ivcap:account:45a06508-5c3a-4678-8e6d-e6399bf27538
```

## Notes / known quirks

* `nextflow.config` sets `docker.fixOwnership = true` to avoid root-owned files in `work/`.
* Input handling:
  * Local runs default to `data/paired-end.csv`.
  * The workflow also accepts `--input <path>` or `--input_csv <path>`.

## More instructions will follow

This README is intentionally kept small and focused on the packaging/deployment mechanics. Additional, IVCAP-specific instructions will be added next.
