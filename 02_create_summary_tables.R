## 1. Load the required R libraries

# Package names
packages <- c("tidyr", "dplyr", "readr", "stringr", "lubridate")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
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

summary_table_total_spend <- full_transactions_table %>%
  filter(amount < 0) %>%
  transmute(date,
            spend_million = abs(amount) / 1000000,
            entity_name = as.factor(entity_name),
            entity_id = as.numeric(entity_name)) %>%
  group_by(entity_name, entity_id) %>%
  summarise(total_spend_million = sum(spend_million)) %>%
  arrange(desc(total_spend_million)) %>%
  ungroup()

transactions_summary <- full_transactions_table %>%
  filter(amount < 0) %>%
  transmute(date,
            spend_million = abs(amount) / 1000000,
            entity_name = as.factor(entity_name),
            entity_id = as.numeric(entity_name)) %>%
  arrange(date) %>%
  group_by(entity_name) %>%
  mutate(cumulative_spend_million = cumsum(spend_million)) %>% 
  ungroup()



election_date <- as.Date("2021-10-08")

spend_over_time <- ggplotly(
  transactions_summary %>%
    ggplot(aes(x = date, y = cumulative_spend_million, color = entity_name)) +
    geom_line() +
    geom_vline(aes(xintercept = as.numeric(election_date)), color = "#db1d0b") +
    geom_text(aes(x = election_date, y = 0, label = "elections"), color = "#03457f", size = 4, angle = 90, vjust = -0.4, hjust = 0) +
    theme_minimal() +
    scale_y_continuous(
      breaks = seq(0, 1000, 100),
      labels = seq(0, 1000, 100)
    ) +
    scale_x_date(date_breaks = "1 months", date_labels = "%m") +
    coord_cartesian(xlim = c(as.Date("2021-01-01"), as.Date("2021-11-26"))) +
    theme(legend.title = element_blank()) +
    xlab(element_blank()) +
    ylab(element_blank()) +
    ggtitle("Political party cumulative spending (millions CZK), January 2021-present")
)

spend_over_time






#  dplyr::filter(datum %in% as.Date(seq(as.Date("2021-01-01"), as.Date("2021-10-08"), by = "7 days")))
  
  
seq(as.Date("2021-01-01"), as.Date("2021-10-08"), by = "7 days")
  

library(ggplot2)
library(plotly)
library(lubridate)

ggplot(transactions_summary_weeks, aes(x = week, y = kumulativni_vydaje_mil, color = id)) + 
  geom_line() +
  # geom_point() +
  scale_x_date(date_breaks = "1 months", date_labels = "%m")

  
transactions_summary_weeks <- transactions_summary %>% 
  mutate(week = floor_date(datum, 
                           unit = "week"))
  # zacatek <- as.Date("2021-06-01")
  # konec <- as.Date("2021-05-08")
  # 
  
  geom_vline(aes(xintercept = as.Date("2021-10-08"))) +
  scale_x_date(date_breaks = "1 months", date_labels = "%m", limits = c(zacatek, konec)) +
  theme_minimal() +
  theme(legend.title = element_blank()) +
  ylab("celkove vydaje (mil.CZK)") +
  xlab(element_blank())

# xlim(as.Date("2021-01-01"), as.Date("2021-12-31")) +
# limits = c(as.Date("2021-01-01"), as.Date("2021-12-31"))) +
  
