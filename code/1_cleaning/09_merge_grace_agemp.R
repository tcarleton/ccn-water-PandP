# Description: This file merges GRACE cells with agricultural employment share
# data from the World Bank for analysis.

# ENVIRONMENT SETUP ------------------------------------------------------------

# run setup script
source("code/0_env_setup/setup.R")

# CLEAN GRACE DATA -------------------------------------------------------------

# load GRACE data
grace <- read_dta("data/input/grace/grace.dta") %>% 
  mutate(across(where(is.labelled), as_factor)) # use labels rather than factors

# restrict to arable land cells and cells with valid delta_TWS data
grace <- grace %>% 
  filter(!((past_area_frac==0 & sage_crop_area_frac==0) |
             (is.na(past_area_frac) & is.na(sage_crop_area_frac)) |
             (past_area_frac==0 & is.na(sage_crop_area_frac)) |
             (is.na(past_area_frac) & sage_crop_area_frac==0))) %>% 
  filter(!is.na(delta_wd_cm_yr))

# CLEAN AG EMPLOYMENT SHARE DATA -----------------------------------------------

# load world bank data on share of employment in agriculture
wb_extract <- read_excel("data/input/ag_emp_share/P_Data_Extract_From_World_Development_Indicators.xlsx") %>% 
  filter(!is.na(`Series Code`)) %>%
  rename(country_code=`Country Code`)
wb_extract[wb_extract == ".."] <- NA_character_

# pivot longer
ag_emp_share <- wb_extract %>% 
  pivot_longer(cols=starts_with("2"),
               names_to = "year",
               values_to = "ag_emp_share") %>% 
  mutate(year=as.numeric(substr(year,1,4)),
         ag_emp_share=as.numeric(ag_emp_share)) %>% 
  group_by(country_code) %>% 
  summarize(ag_emp_share = mean(ag_emp_share, na.rm=T))

# MERGE GRACE WITH AG EMPLOYMENT DATA ------------------------------------------

# merge
grace_ag_emp_share <- grace %>% 
  left_join(ag_emp_share,by=c("country_code")) %>%
  dplyr::select(lon,lat,lonspan,latspan,country_code,delta_wd_cm_yr,rain_cm_yr,areahec,
                groundwater,neg_gwater_depth,ag_emp_share)

# export
write_dta(grace_ag_emp_share,
          "data/intermediate/grace_merged/grace_ag_emp_share.dta")
