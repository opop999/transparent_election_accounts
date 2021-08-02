# SCRAPING OF FIO BANK ACCOUNTS

## 1. Loading the required R libraries

# Package names
packages <- c("rvest", "dplyr", "data.table", "arrow", "stringr")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

## 2. Function for scraping of the transparent bank accounts based in FIO bank

# Argument "parties_accounts_links" accepts vector with url links to FIO accounts
# "parties_names" accepts parties' names - order must match "parties_accounts_links"

scrape_fio <- function(accounts, dir_name) {
  # We initialize empty dataset to which we add rows with each loop iteration
  merged_dataset <- tibble()
  
  # We have to create a desired directory, if one does not yet exist
  if (!dir.exists(dir_name)) {
    dir.create(dir_name)
  } else {
    print("Output directory already exists")
  }
  
  # Repeat the check for subdirectory for individual account datasets
  if (!dir.exists(paste0(dir_name, "/individual_accounts"))) {
    dir.create(paste0(dir_name, "/individual_accounts"))
  } else {
    print("Output directory already exists")
  }
  
  for (i in seq_len(length(accounts[[1]]))) {
    page <- read_html(accounts[[2]][i])
    fio_tables <- page %>% html_table(header = TRUE, dec = ",")
    table_transactions <- fio_tables[[2]]
    colnames(table_transactions) <- c(
      "date",
      "amount",
      "type",
      "contra_account_name",
      "message_for_recipient",
      "ks",
      "vs",
      "ss",
      "note"
    )
    
    table_transactions <- table_transactions %>%
      mutate(
        amount = str_replace_all(string = amount, pattern = "[,]", replacement = "."),
        amount = as.numeric(str_replace_all(string = amount, pattern = "(\\s+|[a-zA-Z])", replacement = ""))
      )
    
    myfile <- paste0(dir_name, "/individual_accounts/", accounts[[1]][i], ".csv")
    fwrite(table_transactions, file = myfile)
    
    # With each iteration of loop, we append the complete dataset
    table_transactions <- table_transactions %>% mutate(
      entity_name = accounts[[1]][i],
      date = as.Date(date, format = "%d.%m.%Y")
    )
    merged_dataset <- bind_rows(merged_dataset, table_transactions)
  }
  # We are saving the merged dataframes as CSV and RDS file (for speed in R)
  
  fwrite(x = merged_dataset, file = paste0(dir_name, "/merged_data.csv"))
  saveRDS(object = merged_dataset, file = paste0(dir_name, "/merged_data.rds"), compress = FALSE)
  write_feather(x = merged_dataset, sink = paste0(dir_name, "/merged_data.feather"))
}

###############

# 3. Function scrapes selected accounts summaries and saves them into one file

scrape_fio_summary <- function(accounts, dir_name) {
  summary_list <- list()
  
  if (!dir.exists(dir_name)) {
    dir.create(dir_name)
  } else {
    print("Output directory already exists")
  }
  
  for (i in seq_len(length(accounts[[1]]))) {
    page <- read_html(accounts[[2]][i])
    fio_tables <- page %>% html_table(header = TRUE, dec = ",")
    table_party_summary <- fio_tables[[1]]
    table_party_summary <- table_party_summary %>%
      slice(1) %>%
      as.character()
    summary_list[[accounts[[1]][i]]] <- table_party_summary
  }
  
  table_total_summary <- as_tibble(t(as_tibble(summary_list)), rownames = "entity")
  colnames(table_total_summary) <- c(
    "entity",
    "balance_january_2021",
    "balance_today",
    "sum_income",
    "sum_costs",
    "sum_total",
    "current_balance"
  )
  
  table_total_summary <- table_total_summary %>%
    mutate(across(.cols = 2:7, .fns = ~ str_replace_all(., pattern = "[,]", replacement = "."))) %>%
    mutate(across(.cols = 2:7, .fns = ~ str_replace_all(., pattern = "(\\s+|[a-zA-Z])", replacement = "")))
  
  fwrite(table_total_summary, file = paste0(dir_name, "/current_accounts_overview.csv"))
}

## 4. Inputs for the FIO scraping function

dir_name <- "data" # Specify the folder, where the tables will be saved

# Load the external list containing names and links of the bank accounts
accounts <- readRDS("data/accounts_fio.rds")

## 5. Running both of the functions

scrape_fio(accounts = accounts, dir_name = dir_name)

scrape_fio_summary(accounts = accounts, dir_name = dir_name)
