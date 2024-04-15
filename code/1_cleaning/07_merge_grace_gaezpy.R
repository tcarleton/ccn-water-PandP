# Description: This file calculates the crop-specific and across-crop productivity
# of each GRACE cell using potential yields data from GAEZ.

# ENVIRONMENT SETUP ------------------------------------------------------------

# run setup script
source("code/0_env_setup/00_setup.R")

# CLEAN GRACE DATA -------------------------------------------------------------

# load GRACE data
grace <- read_dta("data/input/grace/grace.dta")

# restrict to arable land cells and cells with valid delta_TWS data
grace <- grace %>% 
  filter(!((past_area_frac==0 & sage_crop_area_frac==0) |
             (is.na(past_area_frac) & is.na(sage_crop_area_frac)) |
             (past_area_frac==0 & is.na(sage_crop_area_frac)) |
             (is.na(past_area_frac) & sage_crop_area_frac==0))) %>% 
  filter(!is.na(delta_wd_cm_yr))

# CLEAN POTENTIAL YIELD DATA ---------------------------------------------------

# load GAEZ data and collapse at the grace level
gaez <- read_csv("data/input/gaez/gaez.csv") %>% 
  mutate(lon_grace=round(lon_grace,3),
         lat_grace=round(lat_grace,3)) %>% 
  dplyr::select(lon_grace,lat_grace,ends_with("aei_yld"))

grace_py <- gaez %>% 
  group_by(lon_grace, lat_grace) %>% 
  summarize_all(mean, na.rm = TRUE) %>% 
  ungroup()

is.nan.data.frame <- function(x)
  do.call(cbind, lapply(x, is.nan))
grace_py[is.nan(grace_py)] <- NA # turn all NaN's into NA's

# pivot grace data longer
grace_l <- grace %>% 
  pivot_longer(cols= starts_with("caf_"),
               names_to = "caf_crop",
               names_prefix = "caf_",
               values_to = "caf")

# ACROSS-CROP AVERAGE PRODUCTIVITY CALCULATIONS --------------------------------

# calculate z-scores of potential yields
z_score <- function(x) {
  (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
}

py_cols <- grep("aei_yld$", names(grace_py), value = TRUE) # list of columns starting with py

grace_py_zscore <- grace_py %>% 
  mutate(across(all_of(py_cols), z_score)) %>% 
  pivot_longer(cols = ends_with("aei_yld"),
               names_to = "gaez_crop",
               values_to = "py_zscore") %>% 
  mutate(gaez_crop=substr(gaez_crop,1,4))

# combine potential yield z-scores with crop area fraction
caf_gaezpy_crosswalk <- read_csv("data/input/hand/caf_gaezpy_crosswalk.csv") # crosswalk
grace_py_zscore <- grace_py_zscore %>% 
  left_join(caf_gaezpy_crosswalk,by=c("gaez_crop"="gaez_name")) # join with crosswalk

grace_caf_py <- grace_l %>% 
  left_join(grace_py_zscore,by=c("lon"="lon_grace",
                                 "lat"="lat_grace",
                                 "caf_crop"="caf_name")) %>% 
  filter(!is.na(gaez_crop))  # drop all crops not present in GAEZ data

# calculate cross-crop productivity with weighted mean of potential yield z-scores
across_crop_avg_prod <- grace_caf_py %>% 
  group_by(lon,lat,lonspan,latspan,delta_wd_cm_yr,
           rain_cm_yr,areahec,groundwater,neg_gwater_depth) %>% 
  summarize(py_z_wmean = weighted.mean(py_zscore,caf)) %>% 
  ungroup()

# export data to make decile plots in Stata
write_dta(across_crop_avg_prod,
          "data/intermediate/grace_merged/across_crop_avg_pot_yld.dta")

# CROP-SPECIFIC PRODUCTIVITY CALCULATIONS --------------------------------------

# crop specific potential yields
grace_py_crops <- grace_py %>% 
  dplyr::select(lon_grace,lat_grace,rice_aei_yld,whea_aei_yld,
                maiz_aei_yld,soyb_aei_yld)

crop_spec_prod <- grace %>% 
  dplyr::select(!(starts_with("caf"))) %>% 
  left_join(grace_py_crops,by=c("lon"="lon_grace",
                                "lat"="lat_grace"))

write_dta(crop_spec_prod,
          "data/intermediate/grace_merged/crop_spec_pot_yld.dta")