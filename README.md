[![GitHub_Actions_Automation](https://github.com/opop999/transparent_election_accounts/actions/workflows/main.yml/badge.svg)](https://github.com/opop999/transparent_election_accounts/actions/workflows/main.yml)

# Transparent election accounts extraction and analysis: Czech parliamentary elections 2021

### Goal: To have an automated workflow, which would inform analysts covering the financing of the Czech 2021 parliamentary elections. This would ideally include:
-Extraction of the raw tables with transactions data, providing complete information.
-Transformation of the data to only include transactions of interest.
-Entity extraction (companies information) and matching it with ARES database that includes more information.
-Training and deployement of a classification model to help identify transaction types. 

### Current status (1 July 2021):
-We have automatized the extraction of FIO-bank transparent accounts (once per 24h) using the GitHub Actions flow with cron trigger.
