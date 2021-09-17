# SCRAPING OF CSOB BANK ACCOUNTS

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

## 2. Function for extraction of the expense transparent bank accounts based in CSOB bank
scrape_csob_expense_accounts <- function(expense_accounts_csob, dir_name, page_rows, start_date, end_date, sort, sort_direction, temporary_cookie_csob) {

  if (!is.null(expense_accounts_csob$numbers)) {
    print("Some bank accounts selected, will attempt to run the function.")
    
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
for (i in seq_len(length(expense_accounts_csob[[1]]))) {
  
full_list[[expense_accounts_csob[[1]][i]]] <- fromJSON(content(httr::VERB(
  verb = "POST",
  url = "https://www.csob.cz/portal/firmy/bezne-ucty/transparentni-ucty/ucet",
  body = paste0('{"accountList":[{"accountNumberM24":"', expense_accounts_csob[[2]][i], '"}],
                "filterList":[{"name":"AccountingDate", "operator":"ge",
                "valueList":["', start_date, '"]},
                {"name":"AccountingDate","operator":"le",
                "valueList":["', end_date, '"]}],
                "sortList":[{"name":"', sort, '",
                "direction":"', sort_direction, '","order":1}],
                "paging":{"rowsPerPage": ', page_rows,
                ', "pageNumber":1}}'),
  httr::add_headers(
    `Connection` = "keep-alive",
    `Content-Type` = "application/json",
    `User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0",
    `Referer` = paste0("https://www.csob.cz/portal/firmy/bezne-ucty/transparentni-ucty/ucet/-/ta/", expense_accounts_csob[[2]][i])
  ),
  httr::set_cookies(
    TSPD_101 = temporary_cookie_csob
  ),
  encode = "raw",
  query = list(
    p_p_id = "etnpwltadetail_WAR_etnpwlta",
    p_p_lifecycle = "2",
    `_etnpwltadetail_WAR_etnpwlta_ta` = expense_accounts_csob[[2]][i],
    p_p_resource_id = "transactionList"
  )
),
as = "text"),
flatten = TRUE)

full_list_clean[[expense_accounts_csob[[1]][i]]] <- full_list[[expense_accounts_csob[[1]][i]]]$accountedTransactions$accountedTransaction %>% 
      unite(col = message_for_recipient,
            c("transactionTypeChoice.domesticPayment.message.message1",
              "transactionTypeChoice.domesticPayment.message.message2",
              "transactionTypeChoice.domesticPayment.message.message3",
              "transactionTypeChoice.domesticPayment.message.message4"),
            sep = "", na.rm = TRUE) %>% 
      unite(col = date,
            c("baseInfo.accountingDate.year",
              "baseInfo.accountingDate.monthValue",
              "baseInfo.accountingDate.dayOfMonth"),
            sep = "-", na.rm = TRUE) %>% 
      transmute(date = as.Date(date),
                amount = as.numeric(baseInfo.accountAmountData.amount),
                type = as.character(baseInfo.transactionDescription),
                contra_account_name = as.character(transactionTypeChoice.domesticPayment.partyName),
                contra_account_number = as.numeric(transactionTypeChoice.domesticPayment.partyAccount.domesticAccount.accountNumber),
                contra_account_bankCode = as.numeric(transactionTypeChoice.domesticPayment.partyAccount.domesticAccount.bankCode),
                message_for_recipient = as.character(message_for_recipient),
                ks = as.numeric(transactionTypeChoice.domesticPayment.symbols.constantSymbol),
                vs = as.numeric(transactionTypeChoice.domesticPayment.symbols.variableSymbol),
                ss = as.numeric(transactionTypeChoice.domesticPayment.symbols.specificSymbol),
                currency = as.character(baseInfo.accountAmountData.currencyCode),
                entity_name = expense_accounts_csob[[1]][i]
                ) %>% 
  na_if("")

}

yesterday_data <- bind_rows(full_list_clean) %>% distinct()

# Only append the full dataset if there are valid records from yesterday
if (!dim(yesterday_data)[1] == 0) {
  
  print(paste(dim(yesterday_data)[1], "recent transactions on some of the selected bank accounts - will append"))
  
  # Load in the existing full dataset merge with yesterday's new data
  all_data <- readRDS(paste0(dir_name, "/expense_accounts/csob_expense_merged_data.rds"))
  
  # Append the existing dataset with new rows from yesterday and delete duplicates
  all_data <- bind_rows(yesterday_data, all_data) %>% distinct()
  
  # Save full dataset again both in CSV, RDS and also Arrow/Feather binary format
  saveRDS(object = all_data, file = paste0(dir_name, "/expense_accounts/csob_expense_merged_data.rds"), compress = FALSE)
  fwrite(x = all_data, file = paste0(dir_name, "/expense_accounts/csob_expense_merged_data.csv"))
  write_feather(x = all_data, sink = paste0(dir_name, "/expense_accounts/csob_expense_merged_data.feather"))
  
  # Split dataset to individual accounts
  split_dataset <- split(all_data, all_data$entity_name)
  
  for (i in seq_len(length(split_dataset))) {
    fwrite(x = split_dataset[[i]], file = paste0(dir_name, "/expense_accounts/individual_expense_accounts/", names(split_dataset[i]), ".csv"))
  }
  
} else if (dim(yesterday_data)[1] == 0) {
  print(paste("No recent transactions on any of the selected bank accounts - no need to append"))
}

  } else if (is.null(expense_accounts_csob$numbers)) {
    print("No bank accounts selected, skipping this step.")
  }

}

## 3. Function for extraction of the donation transparent bank accounts based in KB bank

scrape_csob_donation_accounts <- function(donation_accounts_csob, dir_name, page_rows, start_date, end_date, sort, sort_direction, temporary_cookie_csob) {
  
  if (!is.null(donation_accounts_csob$numbers)) {
    print("Some bank accounts selected, will attempt to run the function.")
    
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
    for (i in seq_len(length(donation_accounts_csob[[1]]))) {
      
      full_list[[donation_accounts_csob[[1]][i]]] <- fromJSON(content(httr::VERB(
        verb = "POST",
        url = "https://www.csob.cz/portal/firmy/bezne-ucty/transparentni-ucty/ucet",
        body = paste0('{"accountList":[{"accountNumberM24":"', donation_accounts_csob[[2]][i], '"}],
                "filterList":[{"name":"AccountingDate", "operator":"ge",
                "valueList":["', start_date, '"]},
                {"name":"AccountingDate","operator":"le",
                "valueList":["', end_date, '"]}],
                "sortList":[{"name":"', sort, '",
                "direction":"', sort_direction, '","order":1}],
                "paging":{"rowsPerPage": ', page_rows,
                ', "pageNumber":1}}'),
        httr::add_headers(
          `Connection` = "keep-alive",
          `Content-Type` = "application/json",
          `User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0",
          `Referer` = paste0("https://www.csob.cz/portal/firmy/bezne-ucty/transparentni-ucty/ucet/-/ta/", donation_accounts_csob[[2]][i])
        ),
        httr::set_cookies(
          TSPD_101 = temporary_cookie_csob
        ),
        encode = "raw",
        query = list(
          p_p_id = "etnpwltadetail_WAR_etnpwlta",
          p_p_lifecycle = "2",
          `_etnpwltadetail_WAR_etnpwlta_ta` = donation_accounts_csob[[2]][i],
          p_p_resource_id = "transactionList"
        )
      ),
      as = "text"),
      flatten = TRUE)
      
      full_list_clean[[donation_accounts_csob[[1]][i]]] <- full_list[[donation_accounts_csob[[1]][i]]]$accountedTransactions$accountedTransaction %>% 
        unite(col = message_for_recipient,
              c("transactionTypeChoice.domesticPayment.message.message1",
                "transactionTypeChoice.domesticPayment.message.message2",
                "transactionTypeChoice.domesticPayment.message.message3",
                "transactionTypeChoice.domesticPayment.message.message4"),
              sep = "", na.rm = TRUE) %>% 
        unite(col = date,
              c("baseInfo.accountingDate.year",
                "baseInfo.accountingDate.monthValue",
                "baseInfo.accountingDate.dayOfMonth"),
              sep = "-", na.rm = TRUE) %>% 
        transmute(date = as.Date(date),
                  amount = as.numeric(baseInfo.accountAmountData.amount),
                  type = as.character(baseInfo.transactionDescription),
                  contra_account_name = as.character(transactionTypeChoice.domesticPayment.partyName),
                  contra_account_number = as.numeric(transactionTypeChoice.domesticPayment.partyAccount.domesticAccount.accountNumber),
                  contra_account_bankCode = as.numeric(transactionTypeChoice.domesticPayment.partyAccount.domesticAccount.bankCode),
                  message_for_recipient = as.character(message_for_recipient),
                  ks = as.numeric(transactionTypeChoice.domesticPayment.symbols.constantSymbol),
                  vs = as.numeric(transactionTypeChoice.domesticPayment.symbols.variableSymbol),
                  ss = as.numeric(transactionTypeChoice.domesticPayment.symbols.specificSymbol),
                  currency = as.character(baseInfo.accountAmountData.currencyCode),
                  entity_name = donation_accounts_csob[[1]][i]
        ) %>% 
        na_if("")
      
    }
    
    yesterday_data <- bind_rows(full_list_clean) %>% distinct()
    
    # Only append the full dataset if there are valid records from yesterday
    if (!dim(yesterday_data)[1] == 0) {
      
      print(paste(dim(yesterday_data)[1], "recent transactions on some of the selected bank accounts - will append"))
      
      # Load in the existing full dataset merge with yesterday's new data
      all_data <- readRDS(paste0(dir_name, "/donation_accounts/csob_donation_merged_data.rds"))
      
      # Append the existing dataset with new rows from yesterday and delete duplicates
      all_data <- bind_rows(yesterday_data, all_data) %>% distinct()
      
      # Save full dataset again both in CSV, RDS and also Arrow/Feather binary format
      saveRDS(object = all_data, file = paste0(dir_name, "/donation_accounts/csob_donation_merged_data.rds"), compress = FALSE)
      fwrite(x = all_data, file = paste0(dir_name, "/donation_accounts/csob_donation_merged_data.csv"))
      write_feather(x = all_data, sink = paste0(dir_name, "/donation_accounts/csob_donation_merged_data.feather"))
      
      # Split dataset to individual accounts
      split_dataset <- split(all_data, all_data$entity_name)
      
      for (i in seq_len(length(split_dataset))) {
        fwrite(x = split_dataset[[i]], file = paste0(dir_name, "/donation_accounts/individual_donation_accounts/", names(split_dataset[i]), ".csv"))
      }
      
    } else if (dim(yesterday_data)[1] == 0) {
      print(paste("No recent transactions on any of the selected bank accounts - no need to append"))
    }
    
  } else if (is.null(donation_accounts_csob$numbers)) {
    print("No bank accounts selected, skipping this step.")
  }
  
}

## 4. Inputs for the CSOB scraping function

dir_name <- "data" # Specify the folder, where the tables will be saved

start_date <- Sys.Date() - 8 # We select date a week ago in a required format by FIO bank

end_date <- Sys.Date() - 1 # Same as start_date - we only want yesterday

page_rows <- 1000 # Maximum number of rows that is returned. We keep this at 1000 and should be sufficient for weekly transaction records

sort <- "AccountingDate" # Which column is used for sorting? We keep this consistent

sort_direction <- "DESC" # Which direction (DESC/ASC) for the sort. We keep this consistent

# Load the external list containing names and links of the bank accounts

expense_accounts_csob <- readRDS(paste0(dir_name, "/list_of_monitored_accounts/all_accounts_list.rds"))[["expense_accounts_csob"]]

donation_accounts_csob <- readRDS(paste0(dir_name, "/list_of_monitored_accounts/all_accounts_list.rds"))[["donation_accounts_csob"]]

temporary_cookie_csob <- Sys.getenv("CSOB_COOKIE")
  
## 5. Running both of the functions
scrape_csob_expense_accounts(expense_accounts_csob = expense_accounts_csob,
                             dir_name = dir_name,
                             page_rows = page_rows,
                             start_date = start_date,
                             end_date = end_date,
                             sort = sort,
                             sort_direction = sort_direction,
                             temporary_cookie_csob = temporary_cookie_csob)

scrape_csob_donation_accounts(donation_accounts_csob = donation_accounts_csob,
                              dir_name = dir_name,
                              page_rows = page_rows,
                              start_date = start_date,
                              end_date = end_date,
                              sort = sort,
                              sort_direction = sort_direction,
                              temporary_cookie_csob = temporary_cookie_csob)
