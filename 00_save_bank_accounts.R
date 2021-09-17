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


# 3.1 This list is for expense accounts extracted through KB API --------------------------
all_accounts_list[["expense_accounts_kb"]] <- list(
  names = c(
    "ano_2011"
  ),
  numbers = c(
    "4090453"
  )
)


# 3.2 This list is for donation accounts extracted through KB API --------------------------

all_accounts_list[["donation_accounts_kb"]] <- list(
  names = c(
    "ano_2011",
    "soukromnici"
  ),
  numbers = c(
    "4070217",
    "1153902720297"
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
