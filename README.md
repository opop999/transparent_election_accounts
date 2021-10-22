[![Transparent bank accounts extraction with Docker and Selenium](https://github.com/opop999/transparent_election_accounts/actions/workflows/docker_with_selenium.yml/badge.svg)](https://github.com/opop999/transparent_election_accounts/actions/workflows/docker_with_selenium.yml)

[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/)

# This repository is part of an [umbrella project](https://github.com/opop999?tab=projects) of the [2021 pre-election monitoring](https://www.transparentnivolby.cz/snemovna2021/) by the Czech chapter of Transparency International.

## Goal: Extraction & analysis of transparent election bank accounts of political parties/movements 

### We aim for an automated workflow, which would inform analysts covering the financing of the Czech 2021 parliamentary elections and beyond. 

### Current status (20 September 2021):
-We have automatized the daily extraction of FIO, CSOB, Ceska Sporitelna and Komercni Banka transparent bank accounts of the political parties using the GitHub Actions flow. We can use the R-Lib repository for GH Actions, but, for better compatibility, we chose an appropriate [Docker container](https://hub.docker.com/u/rocker) to provide better compatibility and robustness.

-We are no longer using the pipeline with [Hlidac Statu API](https://www.hlidacstatu.cz/data/Index/transparentni-ucty-transakce), as the database currently lacks data on some bank accounts (although the script itself is left as is in this repository)

-We have synchronized the structure of the repository with other repositories under the pre-election monitoring umbrella

-Dashboard is finalized and contains further links of interest, including used data sources

-First version of trained machine learning algoritm (based on random forest) is available in the "ml_model" folder together with visualizations and experimental labeling of new, out-of-sample data

### Work in Progress

-Entity extraction (companies information) and matching it with appropriate databases (such as ARES) that includes more information.

-Training and deployment of machine learning classification model to help identify transaction types. 

### Selected transparent bank accounts:

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
