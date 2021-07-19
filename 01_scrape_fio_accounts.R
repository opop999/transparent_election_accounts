# SCRAPING OF FIO BANK ACCOUNTS

## 1. Loading the required R libraries
library(rvest)
library(dplyr)
library(readr)
library(stringr)

## 2. Function for scraping of the transparent bank accounts based in FIO bank

# Argument "parties_accounts_links" accepts vector with url links to FIO accounts
# "parties_names" accepts parties' names - order must match "parties_accounts_links"

scrape_fio <- function(parties_accounts_links, parties_names) {
  # We initialize empty dataset to which we add rows with each loop iteration
  merged_dataset <- tibble()

  # We have to create a desired directory, if one does not yet exist
  if (!dir.exists(dir_name)) {
    dir.create(dir_name)
  } else {
    print("Output directory already exists")
  }

  for (i in seq_len(length(parties_names))) {
    page <- read_html(parties_accounts_links[i])
    fio_tables <- page %>% html_table(header = TRUE, dec = ",")
    table_transactions <- fio_tables[[2]]
    colnames(table_transactions) <- c(
      "datum",
      "castka",
      "typ",
      "nazev_protiuctu",
      "zprava_pro_prijemce",
      "ks",
      "vs",
      "ss",
      "poznamka"
    )
    
    table_transactions <- table_transactions %>% 
      mutate(
        castka = str_replace_all(string = castka, pattern = "[,]", replacement = "."),
        castka = as.numeric(str_replace_all(string = castka, pattern = "(\\s+|[a-zA-Z])", replacement = ""))
      )
    
    myfile <- paste0(dir_name, "/", parties_names[i], ".csv")
    write_excel_csv(table_transactions, file = myfile)

    # With each iteration of loop, we append the complete dataset
    table_transactions <- table_transactions %>% mutate(id = parties_names[i],
                                                        datum = as.Date(datum, format = "%d.%m.%y"))
    merged_dataset <- bind_rows(merged_dataset, table_transactions)
  }
  # We are saving the merged dataframes as CSV and RDS file (for speed in R)
  myfile_merged_csv <- paste0(dir_name, "/merged_data.csv")
  myfile_merged_rds <- paste0(dir_name, "/merged_data.rds")
  write_excel_csv(x = merged_dataset, file = myfile_merged_csv)
  saveRDS(object = merged_dataset, file = myfile_merged_rds, compress = FALSE)
}

###############

# 3. Function scrapes selected accounts summaries and saves them into one file

scrape_fio_summary <- function(parties_accounts_links, parties_names) {
  summary_list <- list()

  if (!dir.exists(dir_name)) {
    dir.create(dir_name)
  } else {
    print("Output directory already exists")
  }

  for (i in seq_len(length(parties_names))) {
    page <- read_html(parties_accounts_links[i])
    fio_tables <- page %>% html_table(header = TRUE, dec = ",")
    table_party_summary <- fio_tables[[1]]
    table_party_summary <- table_party_summary %>%
      slice(1) %>%
      as.character()
    summary_list[[parties_names[i]]] <- table_party_summary
  }

  table_total_summary <- as_tibble(t(as_tibble(summary_list)), rownames = "strana")
  colnames(table_total_summary) <- c(
    "strana",
    "stav_leden_2021",
    "stav_dnes",
    "suma_prijmu",
    "suma_vydaju",
    "suma_celkem",
    "bezny_zustatek"
  )
  
  table_total_summary <- table_total_summary %>% 
    mutate(across(.cols = 2:7, .fns = ~ str_replace_all(., pattern = "[,]", replacement = "."))) %>% 
    mutate(across(.cols = 2:7, .fns = ~ str_replace_all(., pattern = "(\\s+|[a-zA-Z])", replacement = "")))
  
  myfile <- paste0(dir_name, "/current_accounts_overview.csv")
  write_excel_csv(table_total_summary, file = myfile)
}

## 4. Inputs for the FIO scraping function

dir_name <- "data" # Specify the folder, where the tables will be saved

names <- c(
  "pirati_stan",
  "ods_kdu_top09",
  "spd",
  "cssd",
  "trikolora",
  "zeleni",
  "prisaha"
)

links <- c(
  "https://ib.fio.cz/ib/transparent?a=2601909155&f=01.01.2021",
  "https://ib.fio.cz/ib/transparent?a=-48&f=01.01.2021",
  "https://ib.fio.cz/ib/transparent?a=-49&f=01.01.2021",
  "https://ib.fio.cz/ib/transparent?a=-50&f=01.01.2021",
  "https://ib.fio.cz/ib/transparent?a=2001915105&f=01.01.2021",
  "https://ib.fio.cz/ib/transparent?a=2801916675&f=01.01.2021",
  "https://ib.fio.cz/ib/transparent?a=2201968914&f=01.01.2021"
)

## 5. Running both of the functions 

scrape_fio(parties_accounts_links = links, parties_names = names)

scrape_fio_summary(parties_accounts_links = links, parties_names = names)
