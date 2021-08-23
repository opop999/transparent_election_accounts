[![Transparent Accounts Scrape with Docker Image](https://github.com/opop999/transparent_election_accounts/actions/workflows/docker.yml/badge.svg)](https://github.com/opop999/transparent_election_accounts/actions/workflows/docker.yml)

[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/)

# This repository is part of an [umbrella project](https://github.com/opop999?tab=projects) of the [2021 pre-election monitoring](https://www.transparentnivolby.cz/snemovna2021/) by the Czech chapter of Transparency International.

## Goal: Extraction & analysis of transparent election bank accounts of political parties/movements 

### We aim for an automated workflow, which would inform analysts covering the financing of the Czech 2021 parliamentary elections. This would ideally include:
-Extraction of the raw tables with transactions data, providing complete information. To this end, we directly scrape the bank accounts using Rvest package and [Hlidac Statu API](https://www.hlidacstatu.cz/data/Index/transparentni-ucty-transakce) . In the automatization part, we use GitHub Actions which run using a [Docker container](https://hub.docker.com/u/rocker) to provide better compatibility and robustness.

-Transformation of the data to only include transactions of interest.

-Entity extraction (companies information) and matching it with ARES database that includes more information.

-Training and deployement of a classification model to help identify transaction types. 

### Current status (10 August 2021):
-We have automatized the extraction of FIO-bank transparent accounts (once per 24h) using the GitHub Actions flow with cron trigger. We can use the R-Lib repository for GH Actions (on macOS-latest), but, for better compatibility, we chose an appropriate Docker container (rocker/tidyverse on ubuntu-latest).

-We have sychronized the structure of the repository with other repositories under the pre-election monitoring umbrella

-Dashboard is finalized and contains further links of interest, including data sources (not yet for all accounts)

-First version of trained machine learning algoritm (based on random forest) is available in the "ml_model" folder together with visualizations and experimental labelling of new, out-of-sample data

### Target transparent bank accounts (work in progress - due to the complexity of scraping, not all accounts have to be available in their entirety):

| **POLITICAL SUBJECT**                 | **URL**                                                   | **TYPE OF ACCOUNT**        |
| :---                                  | :---                                                      | :---                       |
| Piráti a Starostové                   | <https://ib.fio.cz/ib/transparent?a=2601909155>           | EXPENSE                    |
| ODS, KDU-ČSL a TOP 09                 | <https://ib.fio.cz/ib/transparent?a=-48>                  | EXPENSE                    |
| SPD                                   | <https://ib.fio.cz/ib/transparent?a=-49>                  | EXPENSE                    |
| ČSSD                                  | <https://ib.fio.cz/ib/transparent?a=-50>                  | EXPENSE                    |
| Trikolóra                             | <https://ib.fio.cz/ib/transparent?a=2001915105>           | EXPENSE                    |
| Strana zelených                       | <https://ib.fio.cz/ib/transparent?a=2801916675>           | EXPENSE                    |
| Přísaha                               | <https://ib.fio.cz/ib/transparent?a=2201968914>           | EXPENSE                    |
| ANO 2011                              | <https://www.kb.cz/cs/transparentni-ucty/4090453>         | EXPENSE                    |
| KSČM                                  | <https://www.csob.cz/portal/firmy/bezne-ucty/transparentni-ucty/ucet/-/ta/217343303>   | EXPENSE                    |
| ČSSD                                  | <https://ib.fio.cz/ib/transparent?a=-8>                   | DONATION                   |
| KDU-ČSL                               | <https://ib.fio.cz/ib/transparent?a=2501710691>           | DONATION                   |
| ODS                                   | <https://ib.fio.cz/ib/transparent?a=2701178564>           | DONATION                   |
| Piráti                                | <https://ib.fio.cz/ib/transparent?a=2100048174>           | DONATION                   |
| Přísaha                               | <https://ib.fio.cz/ib/transparent?a=2701968902>           | DONATION                   |
| SPD                                   | <https://ib.fio.cz/ib/transparent?a=2900839572>           | DONATION                   |
| STAN                                  | <https://ib.fio.cz/ib/transparent?a=2401286707>           | DONATION                   |
| Trikolóra                             | <https://ib.fio.cz/ib/transparent?a=3402078007>           | DONATION                   |
| Rozumní                               | <https://ib.fio.cz/ib/transparent?a=2901125336>           | DONATION                   |
| Svobodní                              | <https://ib.fio.cz/ib/transparent?a=7505075050>           | DONATION                   |
| Zelení                                | <https://ib.fio.cz/ib/transparent?a=2400146729>           | DONATION                   |
| ANO 2011                              | <https://www.kb.cz/cs/transparentni-ucty/4070217>         | DONATION                   |
| TOP 09                                | <https://www.csas.cz/cs/transparentni-ucty#/000000-0020091122>           | DONATION                   |
| Soukromníci                           | <https://www.kb.cz/cs/transparentni-ucty/115-3902720297>  | DONATION                   |
| KSČM                                  | <https://www.csob.cz/portal/firmy/bezne-ucty/transparentni-ucty/ucet/-/ta/478648033>  | DONATION                   |








