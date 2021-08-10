# To improve readability of the main script and its length, this script is made
# to be modified. We can add and remove the monitored bank accounts pages and then
# we save the list to a rds file, which is read to the main extraction script.

maindir_name <- "data"

if (!dir.exists(maindir_name)) {
  dir.create(maindir_name)
} else {
  print("Output directory already exists")
}

subdir_name <- "data/list_of_monitored_accounts" # Specify the folder, where the list of accounts will be saved

if (!dir.exists(subdir_name)) {
  dir.create(subdir_name)
} else {
  print("Output directory already exists")
}

# This list is for FIO election expense accounts
expense_accounts_fio <- list(
  names = c(
    "pirati_stan",
    "ods_kdu-csl_top09",
    "spd",
    "cssd",
    "trikolora",
    "zeleni",
    "prisaha"
  ),
 links = c(
   "https://ib.fio.cz/ib/transparent?a=2601909155&f=01.01.2021",
   "https://ib.fio.cz/ib/transparent?a=-48&f=01.01.2021",
   "https://ib.fio.cz/ib/transparent?a=-49&f=01.01.2021",
   "https://ib.fio.cz/ib/transparent?a=-50&f=01.01.2021",
   "https://ib.fio.cz/ib/transparent?a=2001915105&f=01.01.2021",
   "https://ib.fio.cz/ib/transparent?a=2801916675&f=01.01.2021",
   "https://ib.fio.cz/ib/transparent?a=2201968914&f=01.01.2021"
 )
)

saveRDS(expense_accounts_fio, paste0(subdir_name, "/expense_accounts_fio.rds"), compress = FALSE)

# This list is for FIO donation accounts
donation_accounts_fio <- list(
  names = c(
    "cssd",      
    "kdu-csl",
    "ods",       
    "pirati",    
    "prisaha",   
    "spd",    
    "stan",      
    "trikolora", 
    "rozumni",   
    "svobodni",  
    "zeleni"    
  ),
  links = c(
   "https://ib.fio.cz/ib/transparent?a=-8",
   "https://ib.fio.cz/ib/transparent?a=2501710691",
   "https://ib.fio.cz/ib/transparent?a=2701178564",
   "https://ib.fio.cz/ib/transparent?a=2100048174",
   "https://ib.fio.cz/ib/transparent?a=2701968902",
   "https://ib.fio.cz/ib/transparent?a=2900839572",
   "https://ib.fio.cz/ib/transparent?a=2401286707",
   "https://ib.fio.cz/ib/transparent?a=3402078007",
   "https://ib.fio.cz/ib/transparent?a=2901125336",
   "https://ib.fio.cz/ib/transparent?a=7505075050",
   "https://ib.fio.cz/ib/transparent?a=2400146729"
   )
)

saveRDS(donation_accounts_fio, paste0(subdir_name, "/donation_accounts_fio.rds"), compress = FALSE)


# This list is for expense accounts extracted through Hlidac Statu API
expense_accounts_hlidac <- list(
  names = c(
    "ano_2011",
    "kscm"
  ),
  numbers = c(
    "4090453/0100",
    "217343303/0300"
  )
)

saveRDS(expense_accounts_hlidac, paste0(subdir_name, "/expense_accounts_hlidac.rds"), compress = FALSE)

# This list is for donation accounts extracted through Hlidac Statu API
donation_accounts_hlidac <- list(
  names = c(
    "ano_2011",
    "kscm_moneta",
    "kscm_csob",
    "top_09",
    "soukromnici"
  ),
  numbers = c(
    "4070217/0100",
    "7777377773/0600",
    "280728599/0300",
    "20091122/0800",
    "115-3902720297/0100"
  )
)

saveRDS(donation_accounts_hlidac, paste0(subdir_name, "/donation_accounts_hlidac.rds"), compress = FALSE)
