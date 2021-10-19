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

# Initiate an empty list, serving as a list of all of the lists
all_accounts_list <- list()

# 1.1. This list is for FIO election expense accounts --------------------------

all_accounts_list[["expense_accounts_fio"]] <- list(
  names = c(
    "pirati_stan",
    "ods_kdu-csl_top09",
    "spd",
    "cssd",
    "trikolora",
    "zeleni",
    "prisaha"
  ),
  numbers = c(
    "2601909155",
    "-48",
    "-49",
    "-50",
    "2001915105",
    "2801916675",
    "2201968914"
  )
)


# 1.2. This list is for FIO donation accounts --------------------------

all_accounts_list[["donation_accounts_fio"]] <- list(
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
  numbers = c(
   "-8",
   "2501710691",
   "2701178564",
   "2100048174",
   "2701968902",
   "2900839572",
   "2401286707",
   "3402078007",
   "2901125336",
   "7505075050",
   "2400146729"
   )
)

# 2.1 This list is for expense accounts extracted through Hlidac Statu API --------------------------
all_accounts_list[["expense_accounts_hlidac"]] <- list(
  names = c(
    "ano_2011",
    "kscm"
  ),
  numbers = c(
    "4090453/0100",
    "217343303/0300"
  )
)

# 2.2 This list is for donation accounts extracted through Hlidac Statu API --------------------------

all_accounts_list[["donation_accounts_hlidac"]] <- list(
  names = c(
    "ano_2011",
    "kscm",
    "top_09",
    "soukromnici"
  ),
  numbers = c(
    "4070217/0100",
     "478648033/0300",
    "20091122/0800",
    "115-3902720297/0100"
  )
)


# 3.1 This list is for expense accounts extracted through KB API and/or direct extraction-----
all_accounts_list[["expense_accounts_kb"]] <- list(
  names = c(
    "ano_2011"
  ),
  numbers = c(
    "4090453" # This is formatting for KB API request
  ),
  urls = c(
    "4090453" # This is formatting for direct KB URL
  )
)


# 3.2 This list is for donation accounts extracted through KB API and/or direct extraction----

all_accounts_list[["donation_accounts_kb"]] <- list(
  names = c(
    "ano_2011",
    "soukromnici"
  ),
  numbers = c( # This is formatting for KB API request
    "4070217",
    "1153902720297"
  ),
  urls = c( # This is formatting for direct KB URL
    "4070217",
    "115-3902720297"
  )
)


# 4.1 This list is for expense accounts extracted through CSOB API --------------------------

all_accounts_list[["expense_accounts_csob"]] <- list(
  names = c(
    "kscm"
  ),
  numbers = c(
    "217343303"
  )
)


# 4.2 This list is for donation accounts extracted through CSOB API --------------------------

all_accounts_list[["donation_accounts_csob"]] <- list(
  names = c(
    "kscm"
  ),
  numbers = c(
    "478648033"
  )
)


# 5.1 This list is for expense accounts extracted through Ceska Sporitelna (CS) API --------------------------

all_accounts_list[["expense_accounts_cs"]] <- list(
  names = c(),
  numbers = c()
)


# 5.2 This list is for donation accounts extracted through Ceska Sporitelna (CS) API --------------------------

all_accounts_list[["donation_accounts_cs"]] <- list(
  names = c(
    "top_09"
  ),
  numbers = c(
    "000000-0020091122"
  )
)

# Save the list of lists for all of the accounts --------------------------
saveRDS(all_accounts_list, paste0(subdir_name, "/all_accounts_list.rds"), compress = FALSE) 
