# Description: This file merges GRACE cells with the virtual water flows estimates.

# ENVIRONMENT SETUP ------------------------------------------------------------

# run setup script
source("code/setup.R")

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

# CLEAN VIRTUAL WATER IMPORT DATA ----------------------------------------------

# load virtual water flows data
virtual_water <- read_csv("data/intermediate/trade/virtualwater_baseline.csv")

exp_iso <- unique(virtual_water$i_iso3)
imp_iso <- unique(virtual_water$j_iso3)
all_iso <- unique(c(exp_iso,imp_iso))

setdiff(exp_iso, imp_iso)
setdiff(imp_iso,exp_iso) # FSM is not an exporter of any of the crops

# total water exports
tot_w_exp <- virtual_water %>% 
  group_by(i_iso3) %>% 
  summarize(virt_w_exp=sum(virtualwater_bluegreen,na.rm=T))

# total water imports
tot_w_imp <- virtual_water %>% 
  group_by(j_iso3) %>% 
  summarize(virt_w_imp=sum(virtualwater_bluegreen,na.rm=T))

# combine exports and imports
water_trade <- all_iso %>% 
  data.frame() %>% 
  rename(iso=".") %>% 
  left_join(tot_w_exp,by=c("iso"="i_iso3")) %>% 
  left_join(tot_w_imp,by=c("iso"="j_iso3")) %>% 
  mutate(virt_w_netimp=case_when(is.na(virt_w_imp) ~ -virt_w_exp,
                                 is.na(virt_w_exp) ~ virt_w_imp,
                                 TRUE ~ virt_w_imp-virt_w_exp),
         virt_w_netimp_km3=virt_w_netimp/10^9)

# export water flows data
write_csv(water_trade,
          "data/intermediate/trade/water_trade.csv")

# MERGE GRACE WITH VIRTUAL WATER IMPORTS ---------------------------------------

# merge
grace_virtwflows <- grace %>%  
  left_join(water_trade,by=c("country_code"="iso")) %>% 
  dplyr::select(lon,lat,lonspan,latspan,country_code,areahec,
                delta_wd_cm_yr,rain_cm_yr,groundwater,neg_gwater_depth,surface_water,
                virt_w_exp,virt_w_imp,virt_w_netimp,virt_w_netimp_km3)

# export
write_dta(grace_virtwflows,
          "data/intermediate/grace_merged/grace_virtwflows.dta")
