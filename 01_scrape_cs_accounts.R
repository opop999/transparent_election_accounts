# SCRAPING OF Ceska Sporitelna (CS) BANK ACCOUNTS

## 1. Loading the required R libraries

# Package names
packages <- c("dplyr", "data.table", "arrow", "stringr", "jsonlite", "httr", "tidyr")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

## 2. Function for extraction of the expense transparent bank accounts based in CS bank
scrape_cs_expense_accounts <- function(expense_accounts_cs, dir_name, page_rows, sort, sort_direction, api_key) {
  
  if (!is.null(expense_accounts_cs$numbers)) {
    print(paste(length(expense_accounts_cs$numbers), "bank account(s) selected, will attempt to run the function."))
    
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
    
    # Create list which will be appended  
    full_list <- list()
    full_list_clean <- list()
    
    # Loop to deal with more than one accounts
    for (i in seq_len(length(expense_accounts_cs[[1]]))) {
      
      
      full_list[[expense_accounts_cs[[1]][i]]] <- fromJSON(content(httr::VERB(
        verb = "GET",
        url = paste0("https://api.csas.cz/webapi/api/v3/transparentAccounts/", expense_accounts_cs[[2]][i], "/transactions"),
        httr::add_headers(
          `WEB-API-key` = api_key
        ),
        query = list(
          order = sort_direction,
          page = "0", 
          size = page_rows,
          sort = sort
        )
      ), as = "text"), flatten = TRUE)[["transactions"]]
      
      
      full_list_clean[[expense_accounts_cs[[1]][i]]] <- full_list[[expense_accounts_cs[[1]][i]]] %>% 
        transmute(date = as.Date(processingDate),
                  amount = as.numeric(amount.value),
                  type = as.character(typeDescription),
                  ks = as.numeric(sender.constantSymbol),
                  vs = as.numeric(sender.variableSymbol),
                  ss = as.numeric(sender.specificSymbol),
                  contra_account_name = as.character(sender.name),
                  message_for_recipient = as.character(sender.description),
                  entity_name = expense_accounts_cs[[1]][i])
      
    }
    
    yesterday_data <- bind_rows(full_list_clean) %>% distinct()
    
    # Only append the full dataset if there are valid records from yesterday
    if (!dim(yesterday_data)[1] == 0) {
      
      print(paste(dim(yesterday_data)[1], "recent transactions on some of the selected bank accounts - will append"))
      
      # Load in the existing full dataset merge with yesterday's new data
      all_data <- readRDS(paste0(dir_name, "/expense_accounts/cs_expense_merged_data.rds"))
      
      # Append the existing dataset with new rows from yesterday and delete duplicates
      all_data <- bind_rows(yesterday_data, all_data) %>% distinct()
      
      # Save full dataset again both in CSV, RDS and also Arrow/Feather binary format
      saveRDS(object = all_data, file = paste0(dir_name, "/expense_accounts/cs_expense_merged_data.rds"), compress = FALSE)
      fwrite(x = all_data, file = paste0(dir_name, "/expense_accounts/cs_expense_merged_data.csv"))
      write_feather(x = all_data, sink = paste0(dir_name, "/expense_accounts/cs_expense_merged_data.feather"))
      
      # Split dataset to individual accounts
      split_dataset <- split(all_data, all_data$entity_name)
      
      for (i in seq_len(length(split_dataset))) {
        fwrite(x = split_dataset[[i]], file = paste0(dir_name, "/expense_accounts/individual_expense_accounts/", names(split_dataset[i]), ".csv"))
      }
      
    } else if (dim(yesterday_data)[1] == 0) {
      print(paste("No recent transactions on any of the selected bank accounts - no need to append"))
    }
    
  } else if (is.null(expense_accounts_cs$numbers)) {
    print("No bank accounts selected, skipping this step.")
  }
  
}

## 3. Function for extraction of the donation transparent bank accounts based in CS bank
scrape_cs_donation_accounts <- function(donation_accounts_cs, dir_name, page_rows, sort, sort_direction, api_key) {
  
  if (!is.null(donation_accounts_cs$numbers)) {
    print(paste(length(donation_accounts_cs$numbers), "bank account(s) selected, will attempt to run the function."))
    
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
    
    # Create list which will be appended  
    full_list <- list()
    full_list_clean <- list()
    
    # Loop to deal with more than one accounts
    for (i in seq_len(length(donation_accounts_cs[[1]]))) {
    
    
full_list[[donation_accounts_cs[[1]][i]]] <- fromJSON(content(httr::VERB(
  verb = "GET",
  url = paste0("https://api.csas.cz/webapi/api/v3/transparentAccounts/", donation_accounts_cs[[2]][i], "/transactions"),
  httr::add_headers(
    `WEB-API-key` = api_key
  ),
  query = list(
    order = sort_direction,
    page = "0", 
    size = page_rows,
    sort = sort
  )
), as = "text"), flatten = TRUE)[["transactions"]]


full_list_clean[[donation_accounts_cs[[1]][i]]] <- full_list[[donation_accounts_cs[[1]][i]]] %>% 
  transmute(date = as.Date(processingDate),
            amount = as.numeric(amount.value),
            type = as.character(typeDescription),
            ks = as.numeric(sender.constantSymbol),
            vs = as.numeric(sender.variableSymbol),
            ss = as.numeric(sender.specificSymbol),
            contra_account_name = as.character(sender.name),
            message_for_recipient = as.character(sender.description),
            entity_name = donation_accounts_cs[[1]][i])
    }
    
    yesterday_data <- bind_rows(full_list_clean) %>% distinct()
    
    # Only append the full dataset if there are valid records from yesterday
    if (!dim(yesterday_data)[1] == 0) {
      
      print(paste(dim(yesterday_data)[1], "recent transactions on some of the selected bank accounts - will append"))
      
      # Load in the existing full dataset merge with yesterday's new data
      all_data <- readRDS(paste0(dir_name, "/donation_accounts/cs_donation_merged_data.rds"))
      
      # Append the existing dataset with new rows from yesterday and delete duplicates
      all_data <- bind_rows(yesterday_data, all_data) %>% distinct()
      
      # Save full dataset again both in CSV, RDS and also Arrow/Feather binary format
      saveRDS(object = all_data, file = paste0(dir_name, "/donation_accounts/cs_donation_merged_data.rds"), compress = FALSE)
      fwrite(x = all_data, file = paste0(dir_name, "/donation_accounts/cs_donation_merged_data.csv"))
      write_feather(x = all_data, sink = paste0(dir_name, "/donation_accounts/cs_donation_merged_data.feather"))
      
      # Split dataset to individual accounts
      split_dataset <- split(all_data, all_data$entity_name)
      
      for (i in seq_len(length(split_dataset))) {
        fwrite(x = split_dataset[[i]], file = paste0(dir_name, "/donation_accounts/individual_donation_accounts/", names(split_dataset[i]), ".csv"))
      }
      
    } else if (dim(yesterday_data)[1] == 0) {
      print(paste("No recent transactions on any of the selected bank accounts - no need to append"))
    }

  } else if (is.null(donation_accounts_cs$numbers)) {
    print("No bank accounts selected, skipping this step.")
  }

}

## 4. Inputs for the CS scraping function
dir_name <- "data" 
page_rows <- 100
sort <- "processingDate" # Which column is used for sorting? We keep this consistent
sort_direction <- "DESC" # Which direction (DESC/ASC) for the sort. We keep this consistent
api_key <- Sys.getenv("CS_TOKEN") 

expense_accounts_cs <- readRDS(paste0(dir_name, "/list_of_monitored_accounts/all_accounts_list.rds"))[["expense_accounts_cs"]]
donation_accounts_cs <- readRDS(paste0(dir_name, "/list_of_monitored_accounts/all_accounts_list.rds"))[["donation_accounts_cs"]]

## 5. Running both of the functions
scrape_cs_expense_accounts(expense_accounts_cs = expense_accounts_cs,
                             dir_name = dir_name,
                             page_rows = page_rows,
                             sort = sort,
                             sort_direction = sort_direction,
                             api_key = api_key)

scrape_cs_donation_accounts(donation_accounts_cs = donation_accounts_cs,
                              dir_name = dir_name,
                              page_rows = page_rows,
                              sort = sort,
                              sort_direction = sort_direction,
                              api_key = api_key)
