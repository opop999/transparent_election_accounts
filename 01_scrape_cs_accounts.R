#



# IF CONDITION = IS NOT NULL

full_list <- list()

full_list[[as.character(i)]] <- fromJSON(content(httr::VERB(
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


dir_name <- "data" 
page_rows <- 100
sort <- "processingDate"
sort_direction <- "DESC"
api_key <- Sys.getenv("CS_TOKEN")


expense_accounts_cs <- readRDS(paste0(dir_name, "/list_of_monitored_accounts/all_accounts_list.rds"))[["expense_accounts_cs"]]

donation_accounts_cs <- readRDS(paste0(dir_name, "/list_of_monitored_accounts/all_accounts_list.rds"))[["donation_accounts_cs"]]




