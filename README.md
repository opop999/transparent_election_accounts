[![Transparent Accounts Scrape with Docker Image](https://github.com/opop999/transparent_election_accounts/actions/workflows/docker.yml/badge.svg)](https://github.com/opop999/transparent_election_accounts/actions/workflows/docker.yml)

[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/)

# This repository is part of a [umbrella project](https://github.com/opop999?tab=projects) of the [2021 pre-election monitoring](https://www.transparentnivolby.cz/snemovna2021/) by the Czech chapter of Transparency International.

## Goal: Extraction & analysis of transparent election bank accounts of political parties/movements 

### We aim for an automated workflow, which would inform analysts covering the financing of the Czech 2021 parliamentary elections. This would ideally include:
-Extraction of the raw tables with transactions data, providing complete information. To this end, we directly scrape the bank accounts using Rvest package. In the automatization part, we use GitHub Actions which run using a [Docker container](https://hub.docker.com/u/rocker) to provide better compatibility and robustness.

-Transformation of the data to only include transactions of interest.

-Entity extraction (companies information) and matching it with ARES database that includes more information.

-Training and deployement of a classification model to help identify transaction types. 

### Current status (19 July 2021):
-We have automatized the extraction of FIO-bank transparent accounts (once per 24h) using the GitHub Actions flow with cron trigger. We can use the R-Lib repository for GH Actions (on macOS-latest), but, for better compatibility, we chose an appropriate Docker container (rocker/tidyverse on ubuntu-latest).

-We have sychronized the structure of the repository with other repositories under the pre-election monitoring umbrella

### Target transparent bank accounts (incomplete list - work in progress):

| **POLITICAL SUBJECT**                 | **URL**                                                   | **WORKS?**              |
| :---                                  | :---                                                      | :---                    |
| Piráti a Starostové                   | <https://ib.fio.cz/ib/transparent?a=2601909155>           | TRUE                    |
| ODS, KDU-ČSL a TOP 09                 | <https://ib.fio.cz/ib/transparent?a=-48>                  | TRUE                    |
| SPD                                   | <https://ib.fio.cz/ib/transparent?a=-49>                  | TRUE                    |
| ČSSD                                  | <https://ib.fio.cz/ib/transparent?a=-50>                  | TRUE                    |
| Trikolóra                             | <https://ib.fio.cz/ib/transparent?a=2001915105>           | TRUE                    |
| Strana zelených                       | <https://ib.fio.cz/ib/transparent?a=2801916675>           | TRUE                    |
| Přísaha                               | <https://ib.fio.cz/ib/transparent?a=2201968914>           | TRUE                    |
| ANO 2011                              | <https://www.kb.cz/cs/transparentni-ucty/4090453>            | NOT YET                 |
| KSČM                                  | <https://www.csob.cz/portal/firmy/bezne-ucty/transparentni-ucty/ucet/-/ta/217343303>                        | NOT YET                 |
