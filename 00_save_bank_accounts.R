# To improve readability of the main script and its length, this script is made
# to be modified. We can add and remove the monitored bank accounts pages and then
# we save the list to a rds file, which is read to the main extraction script.

accounts_fio <- list(
  names = c(
    "pirati_stan",
    "ods_kdu_top09",
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

saveRDS(accounts_fio, "accounts_fio.rds", compress = FALSE)
