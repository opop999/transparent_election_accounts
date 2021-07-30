# 1. Load the required R libraries

# Package names
packages <- c("tidyr", "dplyr", "readr", "stringr", "lubridate")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages], repos = "http://cran.rstudio.com")
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

# Load the table created in the previous step
full_transactions_table <- readRDS("data/merged_data.rds")

# Create a desired output directory, if one does not yet exist
if (!dir.exists("data/summary_tables")) {
  dir.create("data/summary_tables")
} else {
  print("Output directory already exists")
}

# 2. Creating a summary table of a total spending since 1.1.2021
total_spend_summary <- full_transactions_table %>%
  filter(amount < 0) %>%
  transmute(date,
    spend_million = abs(amount) / 1000000,
    entity_name = as.factor(entity_name),
    entity_id = as.numeric(entity_name)
  ) %>%
  group_by(entity_name, entity_id) %>%
  summarise(total_spend_million = sum(spend_million)) %>%
  arrange(desc(total_spend_million)) %>%
  ungroup()

# 3. Creating a summary table with cumulative spending per page throughout time
time_summary <- full_transactions_table %>%
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
write_csv(total_spend_summary, "data/summary_tables/total_spend_summary.csv")
saveRDS(object = total_spend_summary, file = "data/summary_tables/total_spend_summary.rds", compress = FALSE)

write_csv(time_summary, "data/summary_tables/time_summary.csv")
saveRDS(object = time_summary, file = "data/summary_tables/time_summary.rds", compress = FALSE)
