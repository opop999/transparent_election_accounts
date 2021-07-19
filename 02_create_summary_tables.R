library(dplyr)
library(readr)
library(tidyr)
library(stringr)

full_transactions_table <- readRDS("data/merged_data.rds")

if (!dir.exists("data/summary_tables")) {
  dir.create("data/summary_tables")
} else {
  print("output directory already exists")
}


transactions_summary <- full_transactions_table %>%
  filter(castka < 0) %>% 
  transmute(datum, vydaj_mil = abs(castka)/1000000, id = as.factor(id)) %>% 
  arrange(datum) %>% 
  group_by(id) %>% 
  mutate(kumulativni_vydaje_mil = cumsum(vydaj_mil))

 
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
  
  group_by(page_name, page_id) %>%
  summarise(
    total_ads = n(),
    unique_ads = n_distinct(ad_creative_body),
    percent_unique = round(unique_ads / total_ads, digits = 3),
    # lower_spend = sum(spend_lower, na.rm = TRUE),
    # upper_spend = sum(spend_upper, na.rm = TRUE),
    avg_spend = round(((sum(spend_lower, na.rm = TRUE) + sum(spend_upper, na.rm = TRUE)) / 2), digits = 0),
    per_ad_avg_spend = round(avg_spend / total_ads, digits = 0),
    # total_lower_impressions = sum(impressions_lower, na.rm = TRUE),
    # total_upper_impressions = sum(impressions_upper, na.rm = TRUE),
    total_avg_impressions = round(((sum(impressions_lower, na.rm = TRUE) + sum(impressions_upper, na.rm = TRUE)) / 2), digits = 0),
    per_ad_avg_impression = round(total_avg_impressions / total_ads, digits = 0),
    total_min_reach = sum(potential_reach_lower, na.rm = TRUE),
    per_ad_min_reach = round(total_min_reach / total_ads, digits = 0),
    avg_ad_runtime = round(mean(ad_delivery_stop_time - ad_delivery_start_time, na.rm = TRUE), digits = 1)
  ) %>%
  arrange(desc(total_ads))