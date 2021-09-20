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

## 2. Function for scraping of the expense transparent bank accounts based in FIO bank

scrape_fio_expense_accounts <- function(expense_accounts_fio, dir_name, start_date, end_date) {
  
  if (!is.null(expense_accounts_fio$numbers)) {
    print(paste(length(expense_accounts_fio$numbers), "bank account(s) selected, will attempt to run the function."))
    
    # Create list which will be appended  
    full_list <- list()
    full_list_clean <- list()
    
    # We have to create a desired directory, if one does not yet exist
    if (!dir.exists(paste0(dir_name, "/expense_accounts"))) {
      dir.create(paste0(dir_name, "/expense_accounts"))
    } else {
      print("Output directory already exists")
    }
    
    # Repeat the check for subdirectory for individual account datasets
    if (!dir.exists(paste0(dir_name, "/expense_accounts/individual_expense_accounts"))) {
      dir.create(paste0(dir_name, "/expense_accounts/individual_expense_accounts"))
    } else {
      print("Output directory already exists")
    }
    
    for (i in seq_len(length(expense_accounts_fio[[1]]))) {
      
      page <- read_html(paste0("https://ib.fio.cz/ib/transparent?a=", expense_accounts_fio[[2]][i], "&f=", start_date, "&t=", end_date))
      fio_tables <- page %>% html_table(header = TRUE, dec = ",")
      
      if (length(fio_tables) == 1) {
        print(paste("No transactions on the account of party", expense_accounts_fio[[1]][i], "between", start_date, "and", end_date))
      } else if (length(fio_tables) > 1) {
        
        full_list[[expense_accounts_fio[[1]][i]]] <- fio_tables[[2]]
        print(paste(dim(full_list[[expense_accounts_fio[[1]][i]]])[1], "transactions on the account of party", expense_accounts_fio[[1]][i], "between", start_date, "and", end_date))
        
        colnames(full_list[[expense_accounts_fio[[1]][i]]]) <- c(
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
        
        full_list_clean[[expense_accounts_fio[[1]][i]]] <- full_list[[expense_accounts_fio[[1]][i]]] %>% 
          transmute(
            date = as.Date(date, format = "%d.%m.%Y"),
            amount = str_replace_all(string = amount, pattern = "[,]", replacement = "."),
            amount = as.numeric(str_replace_all(string = amount, pattern = "(\\s+|[a-zA-Z])", replacement = "")),
            type = as.character(type),
            contra_account_name = as.character(contra_account_name),
            message_for_recipient = as.character(message_for_recipient),
            ks = as.numeric(ks),
            vs = as.numeric(vs),
            ss = as.numeric(ss),
            note = as.character(note),
            entity_name = expense_accounts_fio[[1]][i]) %>% 
          na_if("")
      }
    }
    
    # Collapse list to a dataset
    yesterday_data <- bind_rows(full_list_clean) %>% distinct()
    
    # Only append the full dataset if there are valid records from yesterday
    if (!dim(yesterday_data)[1] == 0) {
      
      print(paste(dim(yesterday_data)[1], "transactions on some of the selected bank accounts between", start_date, "and", end_date, "- will append"))
      
      # Load in the existing full dataset and merge with yesterday's new data
      all_data <- readRDS(paste0(dir_name, "/expense_accounts/fio_expense_merged_data.rds"))
      
      # Append the existing dataset with new rows from yesterday and delete duplicates
      all_data <- bind_rows(yesterday_data, all_data) %>% distinct() 
      # Save full dataset again both in CSV, RDS and also Arrow/Feather binary format
      saveRDS(object = all_data, file = paste0(dir_name, "/expense_accounts/fio_expense_merged_data.rds"), compress = FALSE)
      fwrite(x = all_data, file = paste0(dir_name, "/expense_accounts/fio_expense_merged_data.csv"))
      write_feather(x = all_data, sink = paste0(dir_name, "/expense_accounts/fio_expense_merged_data.feather"))
      
      # Split dataset to individual accounts
      split_dataset <- split(all_data, all_data$entity_name)
      
      for (i in seq_len(length(split_dataset))) {
        fwrite(x = split_dataset[[i]], file = paste0(dir_name, "/expense_accounts/individual_expense_accounts/", names(split_dataset[i]), ".csv"))
      }
    } else if (dim(yesterday_data)[1] == 0) {
      print(paste("No transactions on any of the selected bank accounts between", start_date, "and", end_date, "no need to append"))
    }
    
  } else if (is.null(expense_accounts_fio$numbers)) {
    print("No bank accounts selected, skipping this step.")
  }
}


## 3. Function for scraping of the donation transparent bank accounts based in FIO bank

scrape_fio_donation_accounts <- function(donation_accounts_fio, dir_name, start_date, end_date) {
  
  if (!is.null(donation_accounts_fio$numbers)) {
    print(paste(length(donation_accounts_fio$numbers), "bank account(s) selected, will attempt to run the function."))
    
  # Create list which will be appended  
    full_list <- list()
    full_list_clean <- list()
    
  # We have to create a desired directory, if one does not yet exist
  if (!dir.exists(paste0(dir_name, "/donation_accounts"))) {
    dir.create(paste0(dir_name, "/donation_accounts"))
  } else {
    print("Output directory already exists")
  }

  # Repeat the check for subdirectory for individual account datasets
  if (!dir.exists(paste0(dir_name, "/donation_accounts/individual_donation_accounts"))) {
    dir.create(paste0(dir_name, "/donation_accounts/individual_donation_accounts"))
  } else {
    print("Output directory already exists")
  }

  for (i in seq_len(length(donation_accounts_fio[[1]]))) {
    
    page <- read_html(paste0("https://ib.fio.cz/ib/transparent?a=", donation_accounts_fio[[2]][i], "&f=", start_date, "&t=", end_date))
    fio_tables <- page %>% html_table(header = TRUE, dec = ",")

    if (length(fio_tables) == 1) {
      print(paste("No transactions on the account of party", donation_accounts_fio[[1]][i], "between", start_date, "and", end_date))
    } else if (length(fio_tables) > 1) {
      
      full_list[[donation_accounts_fio[[1]][i]]] <- fio_tables[[2]]
      print(paste(dim(full_list[[donation_accounts_fio[[1]][i]]])[1], "transactions on the account of party", donation_accounts_fio[[1]][i], "between", start_date, "and", end_date))
      
      colnames(full_list[[donation_accounts_fio[[1]][i]]]) <- c(
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
  
  full_list_clean[[donation_accounts_fio[[1]][i]]] <- full_list[[donation_accounts_fio[[1]][i]]] %>% 
        transmute(
          date = as.Date(date, format = "%d.%m.%Y"),
          amount = str_replace_all(string = amount, pattern = "[,]", replacement = "."),
          amount = as.numeric(str_replace_all(string = amount, pattern = "(\\s+|[a-zA-Z])", replacement = "")),
          type = as.character(type),
          contra_account_name = as.character(contra_account_name),
          message_for_recipient = as.character(message_for_recipient),
          ks = as.numeric(ks),
          vs = as.numeric(vs),
          ss = as.numeric(ss),
          note = as.character(note),
          entity_name = donation_accounts_fio[[1]][i]) %>% 
    na_if("")
    }
  }

  # Collapse list to a dataset
  yesterday_data <- bind_rows(full_list_clean) %>% distinct()
  
  # Only append the full dataset if there are valid records from yesterday
  if (!dim(yesterday_data)[1] == 0) {
    
    print(paste(dim(yesterday_data)[1], "transactions on some of the selected bank accounts between", start_date, "and", end_date, "- will append"))
    
    # Load in the existing full dataset and merge with yesterday's new data
    all_data <- readRDS(paste0(dir_name, "/donation_accounts/fio_donation_merged_data.rds"))

    # Append the existing dataset with new rows from yesterday and delete duplicates
    all_data <- bind_rows(yesterday_data, all_data) %>% distinct() 

    # Save full dataset again both in CSV, RDS and also Arrow/Feather binary format
    saveRDS(object = all_data, file = paste0(dir_name, "/donation_accounts/fio_donation_merged_data.rds"), compress = FALSE)
    fwrite(x = all_data, file = paste0(dir_name, "/donation_accounts/fio_donation_merged_data.csv"))
    write_feather(x = all_data, sink = paste0(dir_name, "/donation_accounts/fio_donation_merged_data.feather"))

    # Split dataset to individual accounts
    split_dataset <- split(all_data, all_data$entity_name)

    for (i in seq_len(length(split_dataset))) {
      fwrite(x = split_dataset[[i]], file = paste0(dir_name, "/donation_accounts/individual_donation_accounts/", names(split_dataset[i]), ".csv"))
    }
  } else if (dim(yesterday_data)[1] == 0) {
    print(paste("No transactions on any of the selected bank accounts between", start_date, "and", end_date, "no need to append"))
  }
  
  } else if (is.null(donation_accounts_fio$numbers)) {
    print("No bank accounts selected, skipping this step.")
  }
}

# ## 4. Function scrapes selected accounts summaries and saves them into one file
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

## 5. Inputs for the FIO scraping function

dir_name <- "data" # Specify the folder, where the tables will be saved

start_date <- format(Sys.Date() - 8, "%d.%m.%Y") # We select date a week ago in a required format by FIO bank

end_date <- format(Sys.Date(), "%d.%m.%Y") # Same as start_date - we only want yesterday

# Load the external list containing names and numbers of the bank accounts
expense_accounts_fio <- readRDS(paste0(dir_name, "/list_of_monitored_accounts/all_accounts_list.rds"))[["expense_accounts_fio"]]

donation_accounts_fio <- readRDS(paste0(dir_name, "/list_of_monitored_accounts/all_accounts_list.rds"))[["donation_accounts_fio"]]

## 6. Running both of the functions

scrape_fio_expense_accounts(expense_accounts_fio = expense_accounts_fio, dir_name = dir_name, start_date, end_date)

scrape_fio_donation_accounts(donation_accounts_fio = donation_accounts_fio, dir_name = dir_name, start_date, end_date)

# scrape_fio_summary(accounts = accounts, dir_name = dir_name)
