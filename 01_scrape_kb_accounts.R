# SCRAPING OF KB BANK ACCOUNTS

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

## 2. Function for extraction of the expense transparent bank accounts based in KB bank

scrape_kb_expense_accounts <- function(expense_accounts_kb, dir_name, max_results) {
  
  if (!is.null(expense_accounts_kb$numbers)) {
    print(paste(length(expense_accounts_kb$numbers), "bank account(s) selected, will attempt to run the function."))
    
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
  
  # Outer loop to deal with more than one accounts
  for (o in seq_len(length(expense_accounts_kb[[1]]))) {

  # Inner loop, which loops over multiple pages of the account  
  for (i in seq.int(from = 0, to = max_results, by = 50)) {
    
    sub_dataset_name <- paste0(expense_accounts_kb[[1]][o], ".", as.character(i))
    
    full_list[[sub_dataset_name]] <- fromJSON(content(GET(url = paste0("https://www.kb.cz/transparentsapi/transactions/",
                                                                      expense_accounts_kb[[2]][o], "?skip=", i)), as = "text"))[[3]]
  }
    
  }
  
  # Transform yesterday's new dataset to the format malleable for joining with the older dataset
  yesterday_data <- full_list[lengths(full_list) != 0] %>% 
    bind_rows(.id = "entity_name") %>%
    distinct() %>%
    separate(as.character(symbols), into = c("vs", "ks", "ss"), sep = "/", convert = TRUE) %>% 
    transmute(
      id = as.character(id),
      date = as.Date(str_replace_all(string = date, pattern = "&nbsp;", replacement = " "), format = "%d.%m.%Y"),
      amount = str_replace_all(string = amount, pattern = "[,]", replacement = "."),
      amount = as.numeric(str_replace_all(string = amount, pattern = "(\\s+|[a-zA-Z])", replacement = "")),
      vs = as.numeric(vs),
      ks = as.numeric(ks),
      ss = as.numeric(ss),
      note = as.character(str_squish(str_replace_all(string = note, pattern = "<br />", replacement = " - "))),
      entity_name = as.character(gsub(x = entity_name, pattern = "\\..*", replacement = ""))
    )
  
  # Only append the full dataset if there are valid records from yesterday
  if (!dim(yesterday_data)[1] == 0) {
    
    print(paste(dim(yesterday_data)[1], "recent transactions on some of the selected bank accounts - will append"))
    
  # Load in the existing full dataset merge with yesterday's new data
  all_data <- readRDS(paste0(dir_name, "/expense_accounts/kb_expense_merged_data.rds"))
  
  # Append the existing dataset with new rows from yesterday and delete duplicates
  all_data <- bind_rows(yesterday_data, all_data) %>% distinct()
  
  # Save full dataset again both in CSV, RDS and also Arrow/Feather binary format
  saveRDS(object = all_data, file = paste0(dir_name, "/expense_accounts/kb_expense_merged_data.rds"), compress = FALSE)
  fwrite(x = all_data, file = paste0(dir_name, "/expense_accounts/kb_expense_merged_data.csv"))
  write_feather(x = all_data, sink = paste0(dir_name, "/expense_accounts/kb_expense_merged_data.feather"))
  
  # Split dataset to individual accounts
  split_dataset <- split(all_data, all_data$entity_name)
  
  for (i in seq_len(length(split_dataset))) {
    fwrite(x = split_dataset[[i]], file = paste0(dir_name, "/expense_accounts/individual_expense_accounts/", names(split_dataset[i]), ".csv"))
  }

  } else if (dim(yesterday_data)[1] == 0) {
    print(paste("No recent transactions on any of the selected bank accounts - no need to append"))
  }
  
  } else if (is.null(expense_accounts_kb$numbers)) {
    print("No bank accounts selected, skipping this step.")
  }
}

## 3. Function for extraction of the donation transparent bank accounts based in KB bank
 
scrape_kb_donation_accounts <- function(donation_accounts_kb, dir_name, max_results) {
  
if (!is.null(donation_accounts_kb$numbers)) {
  print(paste(length(donation_accounts_kb$numbers), "bank account(s) selected, will attempt to run the function."))
  
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

  # Outer loop to deal with more than one accounts
  for (o in seq_len(length(donation_accounts_kb[[1]]))) {

    # Inner loop, which loops over multiple pages of the account
    for (i in seq.int(from = 0, to = max_results, by = 50)) {

      sub_dataset_name <- paste0(donation_accounts_kb[[1]][o], ".", as.character(i))

      full_list[[sub_dataset_name]] <- fromJSON(content(GET(url = paste0("https://www.kb.cz/transparentsapi/transactions/",
                                                                         donation_accounts_kb[[2]][o], "?skip=", i)), as = "text"))[[3]]
    }

  }

  # Transform yesterday's new dataset to the format malleable for joining with the older dataset
  yesterday_data <- full_list[lengths(full_list) != 0] %>% 
    bind_rows(.id = "entity_name") %>%
    distinct() %>%
    separate(as.character(symbols), into = c("vs", "ks", "ss"), sep = "/", convert = TRUE) %>% 
    transmute(
      id = as.character(id),
      date = as.Date(str_replace_all(string = date, pattern = "&nbsp;", replacement = " "), format = "%d.%m.%Y"),
      amount = str_replace_all(string = amount, pattern = "[,]", replacement = "."),
      amount = as.numeric(str_replace_all(string = amount, pattern = "(\\s+|[a-zA-Z])", replacement = "")),
      vs = as.numeric(vs),
      ks = as.numeric(ks),
      ss = as.numeric(ss),
      note = as.character(str_squish(str_replace_all(string = note, pattern = "<br />", replacement = " - "))),
      entity_name = as.character(gsub(x = entity_name, pattern = "\\..*", replacement = ""))
    )

  # Only append the full dataset if there are valid records from yesterday
  if (!dim(yesterday_data)[1] == 0) {

    print(paste(dim(yesterday_data)[1], "recent transactions on some of the selected bank accounts - will append"))

    # Load in the existing full dataset merge with yesterday's new data
    all_data <- readRDS(paste0(dir_name, "/donation_accounts/kb_donation_merged_data.rds"))

    # Append the existing dataset with new rows from yesterday and delete duplicates
    all_data <- bind_rows(yesterday_data, all_data) %>% distinct()

    # Save full dataset again both in CSV, RDS and also Arrow/Feather binary format
    saveRDS(object = all_data, file = paste0(dir_name, "/donation_accounts/kb_donation_merged_data.rds"), compress = FALSE)
    fwrite(x = all_data, file = paste0(dir_name, "/donation_accounts/kb_donation_merged_data.csv"))
    write_feather(x = all_data, sink = paste0(dir_name, "/donation_accounts/kb_donation_merged_data.feather"))

    # Split dataset to individual accounts
    split_dataset <- split(all_data, all_data$entity_name)

    for (i in seq_len(length(split_dataset))) {
      fwrite(x = split_dataset[[i]], file = paste0(dir_name, "/donation_accounts/individual_donation_accounts/", names(split_dataset[i]), ".csv"))
    }

  } else if (dim(yesterday_data)[1] == 0) {
    print(paste("No recent transactions on any of the selected bank accounts - no need to append"))
  }

} else if (is.null(donation_accounts_kb$numbers)) {
  print("No bank accounts selected, skipping this step.")
}
}


## 4. Inputs for the KB extraction function

max_results <- 250

dir_name <- "data" # Specify the folder, where the tables will be saved

# Load the external list containing names and links of the bank accounts
expense_accounts_kb <- readRDS(paste0(dir_name, "/list_of_monitored_accounts/all_accounts_list.rds"))[["expense_accounts_kb"]]

donation_accounts_kb <- readRDS(paste0(dir_name, "/list_of_monitored_accounts/all_accounts_list.rds"))[["donation_accounts_kb"]]

## 5. Running both of the functions

scrape_kb_expense_accounts(expense_accounts_kb = expense_accounts_kb, dir_name = dir_name, max_results = max_results)

scrape_kb_donation_accounts(donation_accounts_kb = donation_accounts_kb, dir_name = dir_name, max_results = max_results)
