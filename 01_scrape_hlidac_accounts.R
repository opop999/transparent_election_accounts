
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

## 2. Formulating the function, which uses Hlidac Statu API to extract expense accounts

extract_expense_accounts_hlidac <- function(expense_accounts_hlidac, start_date, end_date, dir_name, sort, descending) {
  
  if (!is.null(expense_accounts_hlidac$numbers)) {
    print(paste(length(expense_accounts_hlidac$numbers), "bank account(s) selected, will attempt to run the function."))
    
    # We initialize empty dataset to which we add rows with each loop iteration
    yesterday_data <- tibble()
    
    # We have to create a desired directory, if one does not yet exist
    if (!dir.exists(dir_name)) {
      dir.create(dir_name)
    } else {
      print("Output directory already exists")
    }
    
    # First outer loop, which goes through the list of supplied accounts
    for (i in seq_len(length(expense_accounts_hlidac[[1]]))) {
      
      # Construct url call to query the number of pages from yesterday's posts
      url_call <- paste0(
        "https://www.hlidacstatu.cz/api/v2/datasety/transparentni-ucty-transakce/hledat?dotaz=CisloUctu%3A",
        expense_accounts_hlidac[[2]][i],
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
      
      
      if (pages == 0) {
        
        print(paste("No transactions on the account of party", expense_accounts_hlidac[[1]][i], "between", start_date, "and", end_date))
        
      } else if (pages > 0) {
        
        print(paste(pages, "pages of transactions on the account of party", expense_accounts_hlidac[[1]][i], "between", start_date, "and", end_date))
        
        # Unfortunately, Hlidac's API supports an upper limit of 200 pages so we have to set an upper hard limit
        for (f in seq_len(pages)[seq_len(pages) <= 200]) {
          
          # Formulate URL for the GET request for Facebook from yesterday
          paginated_url_call <- paste0(url_call, "&strana=", f)
          
          # Send GET request to the API of Hlidac Statu
          result_raw <- GET(paginated_url_call, add_headers("Authorization" = Sys.getenv("HS_TOKEN")))
          
          # Transform JSON output to a dataframe
          result_df <- fromJSON(content(result_raw, as = "text"))[[3]] %>% mutate(
            entity_name = expense_accounts_hlidac[[1]][i],
            Datum = as.Date(Datum),
            DbCreated = as.Date(DbCreated)) 
          
          yesterday_data <- bind_rows(yesterday_data, result_df)
        }
        
      }
    }
    
    # Only append the full dataset if there are records from yesterday
    if (!dim(yesterday_data)[1] == 0) {
      
      print(paste(dim(yesterday_data)[1], "transactions on some of the selected bank accounts between", start_date, "and", end_date, "- will append"))
      
      # Load in the existing full dataset merge with yesterday's new data
      all_data <- readRDS(paste0(dir_name, "/expense_accounts/hlidac_expense_merged_data.rds"))
      
      # Append the existing dataset with new rows from yesterday and delete duplicates
      all_data <- bind_rows(yesterday_data, all_data) %>% distinct()
      
      # Save full dataset again both in CSV, RDS and also Arrow/Feather binary format
      saveRDS(object = all_data, file = paste0(dir_name, "/expense_accounts/hlidac_expense_merged_data.rds"), compress = FALSE)
      fwrite(x = all_data, file = paste0(dir_name, "/expense_accounts/hlidac_expense_merged_data.csv"))
      write_feather(x = all_data, sink = paste0(dir_name, "/expense_accounts/hlidac_expense_merged_data.feather"))
      
      # Split dataset to individual accounts
      split_dataset <- split(all_data, all_data$entity_name)
      
      for (l in seq_len(length(split_dataset))) {
        fwrite(x = split_dataset[[l]], file = paste0(dir_name, "/expense_accounts/individual_expense_accounts/", names(split_dataset[l]), ".csv"))
      }
      
    } else if (dim(yesterday_data)[1] == 0) {
      print(paste("No transactions on any of the selected bank accounts between", start_date, "and", end_date, "no need to append"))
    }
    
  } else if (is.null(expense_accounts_hlidac$numbers)) {
    print("No bank accounts selected, skipping this step.")
  }
}


## 3. Formulating the function, which uses Hlidac Statu API to extract donation accounts

extract_donation_accounts_hlidac <- function(donation_accounts_hlidac, start_date, end_date, dir_name, sort, descending) {
  
  if (!is.null(donation_accounts_hlidac$numbers)) {
    print(paste(length(donation_accounts_hlidac$numbers), "bank account(s) selected, will attempt to run the function."))
  
  # We initialize empty dataset to which we add rows with each loop iteration
  yesterday_data <- tibble()
  
  # We have to create a desired directory, if one does not yet exist
  if (!dir.exists(dir_name)) {
    dir.create(dir_name)
  } else {
    print("Output directory already exists")
  }
  
  # First outer loop, which goes through the list of supplied accounts
  for (i in seq_len(length(donation_accounts_hlidac[[1]]))) {
  
  # Construct url call to query the number of pages from yesterday's posts
  url_call <- paste0(
    "https://www.hlidacstatu.cz/api/v2/datasety/transparentni-ucty-transakce/hledat?dotaz=CisloUctu%3A",
    donation_accounts_hlidac[[2]][i],
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
  
  
  if (pages == 0) {
    
  print(paste("No transactions on the account of party", donation_accounts_hlidac[[1]][i], "between", start_date, "and", end_date))
    
  } else if (pages > 0) {
    
    print(paste(pages, "pages of transactions on the account of party", donation_accounts_hlidac[[1]][i], "between", start_date, "and", end_date))
    
    # Unfortunately, Hlidac's API supports an upper limit of 200 pages so we have to set an upper hard limit
    for (f in seq_len(pages)[seq_len(pages) <= 200]) {
      
      # Formulate URL for the GET request for Facebook from yesterday
      paginated_url_call <- paste0(url_call, "&strana=", f)
      
      # Send GET request to the API of Hlidac Statu
      result_raw <- GET(paginated_url_call, add_headers("Authorization" = Sys.getenv("HS_TOKEN")))
      
      # Transform JSON output to a dataframe
      result_df <- fromJSON(content(result_raw, as = "text"))[[3]] %>% mutate(
        entity_name = donation_accounts_hlidac[[1]][i],
        Datum = as.Date(Datum),
        DbCreated = as.Date(DbCreated)) 
      
      yesterday_data <- bind_rows(yesterday_data, result_df)
    }
    
  }
  }
    
  # Only append the full dataset if there are records from yesterday
  if (!dim(yesterday_data)[1] == 0) {
    
    print(paste(dim(yesterday_data)[1], "transactions on some of the selected bank accounts between", start_date, "and", end_date, "- will append"))
    
    
    # Load in the existing full dataset merge with yesterday's new data
    all_data <- readRDS(paste0(dir_name, "/donation_accounts/hlidac_donation_merged_data.rds"))
    
    # Append the existing dataset with new rows from yesterday and delete duplicates
    all_data <- bind_rows(yesterday_data, all_data) %>% distinct()
    
    # Save full dataset again both in CSV, RDS and also Arrow/Feather binary format
    saveRDS(object = all_data, file = paste0(dir_name, "/donation_accounts/hlidac_donation_merged_data.rds"), compress = FALSE)
    fwrite(x = all_data, file = paste0(dir_name, "/donation_accounts/hlidac_donation_merged_data.csv"))
    write_feather(x = all_data, sink = paste0(dir_name, "/donation_accounts/hlidac_donation_merged_data.feather"))
    
    # Split dataset to individual accounts
    split_dataset <- split(all_data, all_data$entity_name)
    
    for (l in seq_len(length(split_dataset))) {
      fwrite(x = split_dataset[[l]], file = paste0(dir_name, "/donation_accounts/individual_donation_accounts/", names(split_dataset[l]), ".csv"))
    }
    
  } else if (dim(yesterday_data)[1] == 0) {
    print(paste("No transactions on any of the selected bank accounts between", start_date, "and", end_date, "no need to append"))
  }
  
  } else if (is.null(donation_accounts_hlidac$numbers)) {
    print("No bank accounts selected, skipping this step.")
  }
}

## 4. Inputs for the functions

dir_name <- "data" # Specify the folder, where the tables will be saved

# Load the external list containing names and links of the bank accounts
expense_accounts_hlidac <- readRDS(paste0(dir_name, "/list_of_monitored_accounts/all_accounts_list.rds"))[["expense_accounts_hlidac"]]

donation_accounts_hlidac <- readRDS(paste0(dir_name, "/list_of_monitored_accounts/all_accounts_list.rds"))[["donation_accounts_hlidac"]]

start_date <- Sys.Date() - 8 # We select a date week ago in a required format in YYYY-MM-DD format

end_date <- Sys.Date() # Same as start_date - we only want yesterday

sort <- "Datum" # Which column is used for sorting? We keep this consistent

descending <- 1 # 1 is descending sort, 0 is ascending. We keep this consistent


## 5. Running the functions

extract_donation_accounts_hlidac(donation_accounts_hlidac = donation_accounts_hlidac,
                                 start_date = start_date,
                                 end_date = end_date,
                                 dir_name = dir_name, 
                                 sort = sort,
                                 descending = descending)

extract_expense_accounts_hlidac(expense_accounts_hlidac = expense_accounts_hlidac,
                                 start_date = start_date,
                                 end_date = end_date,
                                 dir_name = dir_name, 
                                 sort = sort,
                                 descending = descending)

