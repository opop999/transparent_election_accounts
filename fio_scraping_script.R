library(rvest)
library(tidyverse)

# SCRAPING FIO ÚČTŮ

## Funkce pro scraping FIO

# Funkce pro scraping vsech zvolenych uctu
# Argument funkce "parties_accounts_links" akceptuje vektor s odkazy na FIO bankovni ucty
# Argument funkce "parties_names" akceptuje jmena stran - jejich format je volitelny, ale poradi musi byt shodne s "parties_accounts_links"

scrape_fio <- function(parties_accounts_links, parties_names) {
  
  for (i in 1:length(parties_names)) {
    page <- read_html(parties_accounts_links[i])
    fio_tables <- page %>% html_table(header = TRUE, dec = ",")
    table_transactions <- fio_tables[[2]]
    colnames(table_transactions) <- c("datum",
                                      "castka",
                                      "typ",
                                      "nazev_protiuctu",
                                      "zprava_pro_prijemce",
                                      "ks",
                                      "vs",
                                      "ss",
                                      "poznamka")
    myfile <- paste0("test/", parties_names[i], ".csv")
    write_excel_csv(table_transactions, file = myfile)
  }   
}

###############

# Funkce pro scraping vsech zvolenych uctu s cilem ulozeni souhrnu jejich stavu do jedne tabulky

scrape_fio_summary <- function(parties_accounts_links, parties_names) {
  
  summary_list <- list()
  
  for (i in 1:length(parties_names)) {
    
    page <- read_html(parties_accounts_links[i])
    fio_tables <- page %>% html_table(header = TRUE, dec = ",")
    table_party_summary <- fio_tables[[1]]
    table_party_summary <- table_party_summary %>% slice(1) %>% as.character()
    summary_list[[parties_names[i]]] <- table_party_summary
  }
  
  table_total_summary <- as_tibble(t(as_tibble(summary_list)), rownames = "strana")
  colnames(table_total_summary) <- c("strana", "stav_leden_2021", "stav_dnes", "suma_prijmu", "suma_vydaju", "suma_celkem", "bezny_zustatek") 
  write_excel_csv(table_total_summary, file = "test/aktualni_stav_vsech_uctu.csv")
}


## Vstupy pro funkce FIO

names <- c("pirati_stan", 
           "ods_kdu_top09",
           "spd", 
           "cssd",
           "trikolora",
           "zeleni",
           "prisaha")

links <- c("https://ib.fio.cz/ib/transparent?a=2601909155&f=01.01.2021", 
           "https://ib.fio.cz/ib/transparent?a=-48&f=01.01.2021", 
           "https://ib.fio.cz/ib/transparent?a=-49&f=01.01.2021", 
           "https://ib.fio.cz/ib/transparent?a=-50&f=01.01.2021", 
           "https://ib.fio.cz/ib/transparent?a=2001915105&f=01.01.2021", 
           "https://ib.fio.cz/ib/transparent?a=2801916675&f=01.01.2021", 
           "https://ib.fio.cz/ib/transparent?a=2201968914&f=01.01.2021")

scrape_fio(parties_accounts_links = links, parties_names = names)

scrape_fio_summary(parties_accounts_links = links, parties_names = names)
