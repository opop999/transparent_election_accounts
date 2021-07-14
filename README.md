[![Transparent Accounts Scrape with Docker Image](https://github.com/opop999/transparent_election_accounts/actions/workflows/docker.yml/badge.svg)](https://github.com/opop999/transparent_election_accounts/actions/workflows/docker.yml)

[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/)

# This repository is part of a [umbrella project](https://github.com/opop999?tab=projects) of the 2021 pre-election monitoring by the Czech chapter of Transparency International.

## Repository Focus: Transparent election bank accounts of political parties and movements and their extraction and analysis

### Goal: To have an automated workflow, which would inform analysts covering the financing of the Czech 2021 parliamentary elections. This would ideally include:
-Extraction of the raw tables with transactions data, providing complete information. To this end, we directly scrape the bank accounts using Rvest package. In the automatization part, we use GitHub Actions which run using a [Docker container](https://hub.docker.com/u/rocker) to provide better compatibility and robustness.

-Transformation of the data to only include transactions of interest.

-Entity extraction (companies information) and matching it with ARES database that includes more information.

-Training and deployement of a classification model to help identify transaction types. 

### Current status (1 July 2021):
-We have automatized the extraction of FIO-bank transparent accounts (once per 24h) using the GitHub Actions flow with cron trigger. We can use the R-Lib repository for GH Actions (on macOS-latest), but, for better compatibility, we chose an appropriate Docker container (rocker/tidyverse on ubuntu-latest).
