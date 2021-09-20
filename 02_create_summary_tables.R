# 1. Load the required R libraries

# Package names
packages <- c("tidyr", "dplyr", "data.table", "stringr", "lubridate", "arrow")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

dir_name <- "data" 
all_banks_expense_list <- list()
all_banks_donation_list <- list()

# Specify all of the banks that we extract data from
bank_names <- c("fio", "csob", "kb", "cs")

# Load the table created in the previous step
for (i in seq_len(length(bank_names))) {
  all_banks_expense_list[[bank_names[i]]] <- readRDS(paste0(dir_name, "/expense_accounts/", bank_names[i], "_expense_merged_data.rds"))
  all_banks_donation_list[[bank_names[i]]] <- readRDS(paste0(dir_name, "/donation_accounts/", bank_names[i], "_donation_merged_data.rds"))
}

# Combine the datasets in the list to one large dataset
all_banks_expense_merged_data <- bind_rows(all_banks_expense_list)
all_banks_donation_merged_data <- bind_rows(all_banks_donation_list)

# Save full datasets in CSV, RDS and also Arrow/Feather binary format
saveRDS(object = all_banks_expense_merged_data, file = paste0(dir_name, "/expense_accounts/all_banks_expense_merged_data.rds"), compress = FALSE)
fwrite(x = all_banks_expense_merged_data, file = paste0(dir_name, "/expense_accounts/all_banks_expense_merged_data.csv"))
write_feather(x = all_banks_expense_merged_data, sink = paste0(dir_name, "/expense_accounts/all_banks_expense_merged_data.feather"))

saveRDS(object = all_banks_donation_merged_data, file = paste0(dir_name, "/donation_accounts/all_banks_donation_merged_data.rds"), compress = FALSE)
fwrite(x = all_banks_donation_merged_data, file = paste0(dir_name, "/donation_accounts/all_banks_donation_merged_data.csv"))
write_feather(x = all_banks_donation_merged_data, sink = paste0(dir_name, "/donation_accounts/all_banks_donation_merged_data.feather"))

# Create a desired output directory, if one does not yet exist
if (!dir.exists(paste0(dir_name, "/summary_tables"))) {
  dir.create(paste0(dir_name, "/summary_tables"))
} else {
  print("Output directory already exists")
}

# 2. Creating a summary table of a total spending since 1.1.2021
total_spend_summary <- all_banks_expense_merged_data %>%
  filter(amount < 0) %>%
  transmute(date,
    spend_million = round(abs(amount) / 1000000, digits = 3),
    entity_name = as.factor(entity_name),
    entity_id = as.numeric(entity_name)
  ) %>%
  group_by(entity_name, entity_id) %>%
  summarise(total_spend_million = sum(spend_million)) %>%
  arrange(desc(total_spend_million)) %>%
  ungroup()

# 3. Creating a summary table with cumulative spending per page throughout time
time_summary <- all_banks_expense_merged_data %>%
  filter(amount < 0) %>%
  transmute(date,
    spend_million = abs(amount) / 1000000,
    entity_name = as.factor(entity_name),
    entity_id = as.numeric(entity_name)
  ) %>%
  arrange(date) %>%
  group_by(entity_name) %>%
  mutate(cumulative_spend_million = cumsum(spend_million)) %>%
  ungroup()

# 4. Saving both tables to csv and rds files
fwrite(total_spend_summary, "data/summary_tables/total_spend_summary.csv")
saveRDS(object = total_spend_summary, file = "data/summary_tables/total_spend_summary.rds", compress = FALSE)

fwrite(time_summary, "data/summary_tables/time_summary.csv")
saveRDS(object = time_summary, file = "data/summary_tables/time_summary.rds", compress = FALSE)
