
# WORK IN PROGRESS --------------------------------------------------------



# SCRAPING OF BANK ACCOUNTS FROM HLIDAC STATU DATABASE

## 1. Loading the required R libraries

# Package names
packages <- c("httr", "data.table", "arrow", "dplyr", "jsonlite")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))


# Extracting information for donation accounts
#  ANO
# -https://www.kb.cz/cs/transparentni-ucty/4070217
# 
# KSČM 
# -https://transparentniucty.moneta.cz/homepage/-/transparent-account/7777377773
# -https://www.csob.cz/portal/podnikatele-firmy-a-instituce/produkty/ucty-a-platebni-styk/bezne-platebni-ucty/transparentni-ucet/ucet/-/tu/280728599
# 
# TOP09
# -https://www.csas.cz/cs/transparentni-ucty#/000000-0020091122


donation_accounts_yesterday <- function(account, account_name, start_date, end_date, dir_name, sort, descending) {
  
  # We initialize empty dataset to which we add rows with each loop iteration
  yesterday_data <- tibble()
  
  # We have to create a desired directory, if one does not yet exist
  if (!dir.exists(dir_name)) {
    dir.create(dir_name)
  } else {
    print("Output directory already exists")
  }
  
  # Construct url call to query the number of pages from yesterday's posts
  url_call <- paste0(
    "https://www.hlidacstatu.cz/api/v2/datasety/transparentni-ucty-transakce/hledat?dotaz=CisloUctu%3A",
    account,
    "%20Datum%3A%5B",
    start_date,
    "%20TO%20",
    end_date,
    "%5D&sort=",
    sort,
    "&desc=",
    descending
  )
  
  # Get total number of pages from the initial result. We divide the number of
  # total posts by 25 (this is the size of one API page) and apply ceiling to get
  # full number
  pages <- ceiling(
    fromJSON(
      content(
        GET(
          url_call,
          add_headers(
            "Authorization" = Sys.getenv("HS_TOKEN")
          )
        ),
        as = "text"
      )
    )[[1]] / 25
  )
  
  # Unfortunately, Hlidac's API supports an upper limit of 200 pages so we have to
  # set an upper hard limit
  for (i in seq_len(pages)[seq_len(pages) <= 200]) {
    
    # Formulate URL for the GET request for Facebook from yesterday
    paginated_url_call <- paste0(url_call, "&strana=", i)
    
    # Send GET request to the API of Hlidac Statu
    result_raw <- GET(paginated_url_call, add_headers("Authorization" = Sys.getenv("HS_TOKEN")))
    
    # Transform JSON output to a dataframe
    result_df <- fromJSON(content(result_raw, as = "text"))[[3]]
    
    yesterday_data <- bind_rows(yesterday_data, result_df)
  }
  
  # Only append the full dataset if there are records from yesterday
  if (account_name == "Facebook" & !dim(yesterday_data)[1] == 0) {
    # We are saving the merged dataframes with yesterday's data as CSV
    fwrite(x = yesterday_data, file = paste0(dir_name, "/individual_donation_accounts/yesterday_data_donation_", tolower(account_name), ".csv"))

    # Load in the existing full dataset merge with yesterday's new data
    all_data <- readRDS(paste0(dir_name, "/all_data_", tolower(account_name), ".rds"))
    
    # Append the existing dataset with new rows from yesterday and delete duplicates
    all_data <- bind_rows(yesterday_data, all_data) %>% distinct()
    
    # Save full dataset again both in CSV, RDS and also Arrow/Feather binary format
    saveRDS(object = all_data, file = paste0(dir_name, "/all_data_", tolower(account_name), ".rds"), compress = FALSE)
    fwrite(x = all_data, file = paste0(dir_name, "/all_data_", tolower(account_name), ".csv"))
    write_feather(x = all_data, sink = paste0(dir_name, "/all_data_", tolower(account_name), ".feather"))
    
  } else if (account_name == "Facebook" & dim(yesterday_data)[1] == 0) {
    print("FB dataset from yesterday is empty, no need to append")
  }
  
}

## 3. Inputs for the function
dir_name <- "data/donation_accounts/" # Specify the folder, where the tables will be saved

start_date <- Sys.Date() - 1000 # We select yesterday's date in YYYY-MM-DD format

end_date <- Sys.Date() # Same as start_date - we only want yesterday

sort <- "Datum" # Which column is used for sorting? We keep this consistent

descending <- 1 # 1 is descending sort, 0 is ascending. We keep this consistent

# account <- "20091122/0800"
# account_name <- "top_09_cs"
# 
# account <- "280728599/0300"
# account_name <- "kscm_csob"

# account <- "7777377773/0600"
# account_name <- "kscm_moneta"

# account <- "4070217/0100"
# account_name <- "ano_kb"

# account <- "20091122/0800"
# account_name <- "top_09_cs"
# 
# account <- "217343303/0300"
# account_name <- "kscm_csob_spend"

# 
#  account <- "4090453/0100"
#  account_name <- "ano_kb_spend"


## 4. Running the function






















# ## 2. Function for scraping of the transparent bank accounts based in FIO bank
# 
# # Argument "parties_accounts_links" accepts vector with url links to FIO accounts
# # "parties_names" accepts parties' names - order must match "parties_accounts_links"
# 
# scrape_fio <- function(accounts, dir_name) {
#   # We initialize empty dataset to which we add rows with each loop iteration
#   merged_dataset <- tibble()
#   
#   # We have to create a desired directory, if one does not yet exist
#   if (!dir.exists(dir_name)) {
#     dir.create(dir_name)
#   } else {
#     print("Output directory already exists")
#   }
#   
#   # Repeat the check for subdirectory for individual account datasets
#   if (!dir.exists(paste0(dir_name, "/individual_accounts"))) {
#     dir.create(paste0(dir_name, "/individual_accounts"))
#   } else {
#     print("Output directory already exists")
#   }
#   
#   for (i in seq_len(length(accounts[[1]]))) {
#     page <- read_html(accounts[[2]][i])
#     fio_tables <- page %>% html_table(header = TRUE, dec = ",")
#     table_transactions <- fio_tables[[2]]
#     colnames(table_transactions) <- c(
#       "date",
#       "amount",
#       "type",
#       "contra_account_name",
#       "message_for_recipient",
#       "ks",
#       "vs",
#       "ss",
#       "note"
#     )
#     
#     table_transactions <- table_transactions %>%
#       mutate(
#         amount = str_replace_all(string = amount, pattern = "[,]", replacement = "."),
#         amount = as.numeric(str_replace_all(string = amount, pattern = "(\\s+|[a-zA-Z])", replacement = ""))
#       )
#     
#     myfile <- paste0(dir_name, "/individual_accounts/", accounts[[1]][i], ".csv")
#     fwrite(table_transactions, file = myfile)
#     
#     # With each iteration of loop, we append the complete dataset
#     table_transactions <- table_transactions %>% mutate(
#       entity_name = accounts[[1]][i],
#       date = as.Date(date, format = "%d.%m.%Y")
#     )
#     merged_dataset <- bind_rows(merged_dataset, table_transactions)
#   }
#   # We are saving the merged dataframes as CSV and RDS file (for speed in R)
#   
#   fwrite(x = merged_dataset, file = paste0(dir_name, "/merged_data.csv"))
#   saveRDS(object = merged_dataset, file = paste0(dir_name, "/merged_data.rds"), compress = FALSE)
#   write_feather(x = merged_dataset, sink = paste0(dir_name, "/merged_data.feather"))
# }
# 
# ###############
# 
# # 3. Function scrapes selected accounts summaries and saves them into one file
# 
# scrape_fio_summary <- function(accounts, dir_name) {
#   summary_list <- list()
#   
#   if (!dir.exists(dir_name)) {
#     dir.create(dir_name)
#   } else {
#     print("Output directory already exists")
#   }
#   
#   for (i in seq_len(length(accounts[[1]]))) {
#     page <- read_html(accounts[[2]][i])
#     fio_tables <- page %>% html_table(header = TRUE, dec = ",")
#     table_party_summary <- fio_tables[[1]]
#     table_party_summary <- table_party_summary %>%
#       slice(1) %>%
#       as.character()
#     summary_list[[accounts[[1]][i]]] <- table_party_summary
#   }
#   
#   table_total_summary <- as_tibble(t(as_tibble(summary_list)), rownames = "entity")
#   colnames(table_total_summary) <- c(
#     "entity",
#     "balance_january_2021",
#     "balance_today",
#     "sum_income",
#     "sum_costs",
#     "sum_total",
#     "current_balance"
#   )
#   
#   table_total_summary <- table_total_summary %>%
#     mutate(across(.cols = 2:7, .fns = ~ str_replace_all(., pattern = "[,]", replacement = "."))) %>%
#     mutate(across(.cols = 2:7, .fns = ~ str_replace_all(., pattern = "(\\s+|[a-zA-Z])", replacement = "")))
#   
#   fwrite(table_total_summary, file = paste0(dir_name, "/current_accounts_overview.csv"))
# }
# 
# ## 4. Inputs for the FIO scraping function
# 
# dir_name <- "data" # Specify the folder, where the tables will be saved
# 
# # Load the external list containing names and links of the bank accounts
# accounts <- readRDS("data/accounts_fio.rds")
# 
# ## 5. Running both of the functions
# 
# scrape_fio(accounts = accounts, dir_name = dir_name)
# 
# scrape_fio_summary(accounts = accounts, dir_name = dir_name)
