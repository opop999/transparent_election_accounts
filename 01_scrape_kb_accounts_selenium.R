# Package names
packages <- c("RSelenium", "data.table", "rvest", "dplyr", "tidyr", "stringr", "xml2", "arrow")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

# Turn off scientific notation of numbers
options(scipen = 999)

## 2. Function to initiate the Selenium/Docker based workflow
initiate_docker_container_and_connect <- function(address, host_port, container_port) {

  # Pull the necessary Docker image
 # system("docker pull selenium/standalone-firefox:3.141.59")

  # Start the Docker container
  # system(paste0(
  #   "docker run --rm -d --name selenium_headless -p ",
  #   host_port,
  #   ":",
  #   container_port,
  #   " -e START_XVFB=false --shm-size='2g' selenium/standalone-firefox:3.141.59"
  # ),
  # wait = TRUE
  # )

  # Connect to a Docker instance of headless Firefox server
  remote_driver <- remoteDriver(
    remoteServerAddr = address,
    port = host_port,
    browserName = "firefox",
    extraCapabilities = list("moz:firefoxOptions" = list(
      args = list("--headless")
    ))
  )

  # Assign the remote driver as an object to a global environment, so we could close the connection with a separate function
  assign("remDr", remote_driver, envir = .GlobalEnv)

  # Wait several seconds
  Sys.sleep(5)

  # Request to the server to instantiate browser
  remDr$open()
}

## 3. Function for extraction of the expense transparent bank accounts based in KB bank
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

    for (o in seq_len(length(expense_accounts_kb[[1]]))) {
      remDr$navigate(paste0("https://www.kb.cz/cs/transparentni-ucty/", expense_accounts_kb[[3]][o]))

      # Wait before the load_more button accessible
      load_more <- NULL
      while (is.null(load_more)) {
        load_more <- tryCatch(
          {
            remDr$findElement(using = "css selector", value = ".btn-outline-secondary")
          },
          error = function(e) {
            NULL
          }
        )
      }

      print(paste("Element of page scroll button located on page", expense_accounts_kb[[1]][o]))

      # Inner loop, which loops over multiple pages of the account
      for (i in seq_len(ceiling(max_results / 50 - 1))) {
        load_more$clickElement()

        Sys.sleep(runif(1, min = 2.5, max = 3.5))

        print(paste("Page nr:", i, "of account", expense_accounts_kb[[1]][o], "finished loading"))
      }
      page_source <- read_html(unlist(remDr$getPageSource()))
      # Convert <br> tags to \n in order to get clear separation of text within the last column
      xml_find_all(page_source, ".//br") %>% xml_add_sibling("p", "\n")
      xml_find_all(page_source, ".//br") %>% xml_remove()

      full_list[[expense_accounts_kb[[1]][o]]] <- page_source %>%
        html_element(css = "main") %>%
        html_table(header = FALSE, dec = ",") %>%
        slice(-1) # delete first row, which is the header in Czech
    }

    yesterday_data <- full_list[lengths(full_list) != 0] %>%
      bind_rows(.id = "entity_name") %>%
      separate(X3, into = c("vs", "ks", "ss"), sep = "/", convert = TRUE) %>%
      transmute(
        date = as.Date(str_replace_all(string = X1, "\\s", ""), format = "%d.%m.%Y"), # We have to replace the breaking space
        amount = str_replace_all(string = X2, pattern = "[,]", replacement = "."),
        amount = as.numeric(str_replace_all(string = amount, pattern = "(\\s+|[a-zA-Z])", replacement = "")),
        vs = as.numeric(vs),
        ks = as.numeric(ks),
        ss = as.numeric(ss),
        note = as.character(str_squish(str_replace_all(string = X4, pattern = "\n", replacement = " - "))),
        entity_name = as.character(entity_name)
      ) %>% 
      filter(date >= as.Date("2021-10-08")) # This is set for compatibility reasons between the API vs. Selenium-based dataset

    # Only append the full dataset if there are valid records from yesterday
    if (!dim(yesterday_data)[1] == 0) {
      print(paste(dim(yesterday_data)[1], "recent transactions on some of the selected bank accounts - will append"))

      # Load in the existing full dataset merge with yesterday's new data
      all_data <- readRDS(paste0(dir_name, "/expense_accounts/kb_expense_merged_data.rds")) 
      
      # Append the existing dataset with new rows from yesterday and delete full duplicates
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


## 4. Function for extraction of the donation transparent bank accounts based in KB bank
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
    
    for (o in seq_len(length(donation_accounts_kb[[1]]))) {
      remDr$navigate(paste0("https://www.kb.cz/cs/transparentni-ucty/", donation_accounts_kb[[3]][o]))
      
      # Wait before the load_more button accessible
      load_more <- NULL
      while (is.null(load_more)) {
        load_more <- tryCatch(
          {
            remDr$findElement(using = "css selector", value = ".btn-outline-secondary")
          },
          error = function(e) {
            NULL
          }
        )
      }
      
      print(paste("Element of page scroll button located on page", donation_accounts_kb[[1]][o]))
      
      # Inner loop, which loops over multiple pages of the account
      for (i in seq_len(ceiling(max_results / 50 - 1))) {
        load_more$clickElement()
        
        Sys.sleep(runif(1, min = 2.5, max = 3.5))
        
        print(paste("Page nr:", i, "of account", donation_accounts_kb[[1]][o], "finished loading"))
      }
      page_source <- read_html(unlist(remDr$getPageSource()))
      # Convert <br> tags to \n in order to get clear separation of text within the last column
      xml_find_all(page_source, ".//br") %>% xml_add_sibling("p", "\n")
      xml_find_all(page_source, ".//br") %>% xml_remove()
      
      full_list[[donation_accounts_kb[[1]][o]]] <- page_source %>%
        html_element(css = "main") %>%
        html_table(header = FALSE, dec = ",") %>%
        slice(-1) # delete first row, which is the header in Czech
    }
    
    yesterday_data <- full_list[lengths(full_list) != 0] %>%
      bind_rows(.id = "entity_name") %>%
      separate(X3, into = c("vs", "ks", "ss"), sep = "/", convert = TRUE) %>%
      transmute(
        date = as.Date(str_replace_all(string = X1, "\\s", ""), format = "%d.%m.%Y"), # We have to replace the breaking space
        amount = str_replace_all(string = X2, pattern = "[,]", replacement = "."),
        amount = as.numeric(str_replace_all(string = amount, pattern = "(\\s+|[a-zA-Z])", replacement = "")),
        vs = as.numeric(vs),
        ks = as.numeric(ks),
        ss = as.numeric(ss),
        note = as.character(str_squish(str_replace_all(string = X4, pattern = "\n", replacement = " - "))),
        entity_name = as.character(entity_name)
      ) %>% 
      filter(date >= as.Date("2021-10-08")) # This is set for compatibility reasons between the API vs. Selenium-based dataset
    
    # Only append the full dataset if there are valid records from yesterday
    if (!dim(yesterday_data)[1] == 0) {
      print(paste(dim(yesterday_data)[1], "recent transactions on some of the selected bank accounts - will append"))
      
      # Load in the existing full dataset merge with yesterday's new data
      all_data <- readRDS(paste0(dir_name, "/donation_accounts/kb_donation_merged_data.rds")) 
      
      # Append the existing dataset with new rows from yesterday and delete full duplicates
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


## 5. Function to end the Selenium/Docker workflow
close_browser_and_docker_container <- function(remote_driver) {

  # Close the browser
  remote_driver$quit()

  # Stop the Docker container
 # system("docker stop selenium_headless")
}

## 6. Inputs for the KB extraction function
address <- "localhost"
host_port <- 4445L
container_port <- 4444
max_results <- 250
dir_name <- "data" # Specify the folder, where the tables will be saved

# Load the external list containing names and links of the bank accounts
expense_accounts_kb <- readRDS(paste0(dir_name, "/list_of_monitored_accounts/all_accounts_list.rds"))[["expense_accounts_kb"]]
donation_accounts_kb <- readRDS(paste0(dir_name, "/list_of_monitored_accounts/all_accounts_list.rds"))[["donation_accounts_kb"]]

## 7. Running all of the functions in the specific order
initiate_docker_container_and_connect(address, host_port, container_port)
scrape_kb_expense_accounts(expense_accounts_kb = expense_accounts_kb, dir_name = dir_name, max_results = max_results)
scrape_kb_donation_accounts(donation_accounts_kb = donation_accounts_kb, dir_name = dir_name, max_results = max_results)
close_browser_and_docker_container(remote_driver = remDr)
