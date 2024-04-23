# Is the world running out of fresh water?
This repository contains code and data necessary to replicate the findings of Carleton, Crews, and Nath (2024).

## Setup
Scripts in this repository are written in Python, Stata and R. Throughout this document, it is assumed that the replicator operates from a working directory containing all necessary files and folders, which are detailed in the structure below.

### File/folder structure
```text
├── code
│   ├── run.sh
│   ├── 0_env_setup
│   │   └── setup.R
│   ├── 1_cleaning
│   │   ├── 01_country_crosswalk.R
│   │   ├── 02_crop_crosswalk.R
│   │   ├── 03_build_tradedata.py
│   │   ├── 04_build_proddata.py
│   │   ├── 05_fill_tradedata.do
│   │   ├── 06_virtualwater.py
│   │   ├── 07_crop_water_use.do
│   │   ├── 08_merge_grace_gaez.R
│   │   ├── 09_merge_grace_agemp.R
│   │   ├── 10_merge_grace_virtwflows.R
│   └── 2_analysis
│       ├── 01_make_maps.R
│       ├── maps
│       │   ├── fig1.R
│       │   ├── fig2a.R
│       │   ├── fig2c.R
│       │   ├── fig2e.R
│       │   ├── fig3a.R
│       │   ├── figA1a.R
│       │   ├── figA1c.R
│       │   ├── figA4a.R
│       │   ├── figA4c.R
│       ├── 02_make_scatterplots.do
│       ├── scatterplots
│       │   ├── fig2b.do
│       │   ├── fig2d.do
│       │   ├── fig2f.do
│       │   ├── fig3b.do
│       │   ├── figA1b.do
│       │   ├── figA1d.do
│       │   ├── figA2.do
│       │   ├── figA3.do
│       │   ├── figA4b.do
│       │   ├── figA5.do
│       │   ├── figA6.do
│       │   ├── figA7.do
│       │   ├── figA8.do
│       └── 03_intext_stats.do
├── data
│   ├── input
│   │   ├── ag_emp_share
│   │   │   └── P_Data_Extract_From_World_Development_Indicators.xlsx
│   │   ├── baci_comtrade
│   │   │   ├── BACI_HS07_Y2009_V202102.csv
│   │   │   ├── country_codes_V202102.csv
│   │   │   └── product_codes_HS07_V202102.csv
│   │   ├── cds_2016
│   │   │   ├── CountryNamesNumbers.csv
│   │   │   └── crop_names_numbers_codes.csv
│   │   ├── crop_water_footprint
│   │   │   ├── Report47Appendix-II.xlsx
│   │   │   └── water_intensity_per_tonne.csv
│   │   ├── faostat
│   │   │   ├── fmrsudan_qcl.csv
│   │   │   ├── fmrsudan_qv.csv
│   │   │   ├── Prices_E_All_Data_(Normalized).csv
│   │   │   ├── Production_Crops_Livestock_E_All_Data_(Normalized).csv
│   │   │   └── Value_of_Production_E_All_Data_(Normalized).csv
│   │   ├── gaez
│   │   │   └── gaez.csv
│   │   ├── grace
│   │   │   └── grace.dta
│   │   ├── gaez
│   │   │   └── gaez.csv
│   │   ├── hand
│   │   │   ├── caf_gaezpy_crosswalk.csv
│   │   │   ├── fao_country_crosswalk.csv
│   │   │   └── FCL_HS_mappings_2020-01-07.csv
│   │   ├── nra
│   │   │   ├── AgIncentivesNRP.csv
│   │   │   └── UpdatedDistortions_to_AgriculturalIncentives_database_0613.xls
│   └── intermediate
│       ├── crosswalks
│       ├── grace_merged
│       ├── production
│       └── trade
└── results
```

### Software requirements
The code was last run on a Linux terminal with Stata, R, and Python. The following packages/libraries were installed and used:
1. *Stata 17*
 - egenmore
2. *R 4.2.3*
 - tidyverse=2.0.0
 - haven=2.5.2
 - readxl=1.4.2
 - broom=1.0.4
 - sf=1.0-12
 - rnaturalearthdata=1.0.0
 - rnaturalearth=1.0.1
 - cowplot=1.1.1
 - scales=1.2.1
 - biscale=1.0.0
 - dichromat=2.0-0.1
 - geosphere=1.5-18
3. *Python 3*
 - numpy=1.13.5
 - pandas=1.5.3
 - fuzzywuzzy=0.18.0
 - regex=2023.10.3

### Description of datasets
| File | Source | 
|:-------------|:----:|
| `data/input/ag_emp_share/P_Data_Extract_From_World_Development_Indicators.xlsx` | Agricultural employment share in 2009. Obtained from the World Bank's [World Development Indicators Database](https://databank.worldbank.org/source/world-development-indicators). |
| `data/input/baci_comtrade/BACI_HS07_Y2009_V202102.csv` `data/input/baci_comtrade/country_codes_V202102.csv` `data/input/baci_comtrade/product_codes_HS07_V202102.csv` | Bilateral trade flows (version HS07) from UN Comtrade obtained through the BACI portal hosted by [CEPII](http://www.cepii.fr/CEPII/fr/bdd_modele/bdd_modele_item.asp?id=37). |
| `data/input/cds_2016/CountryNamesNumbers.csv` `data/input/cds_2016/crop_names_numbers_codes.csv` | Lists of unique country/crop names, numbers, *and codes*. The names and numbers match those used by [Costinot, Donaldson, & Smith (2016)](https://www.journals.uchicago.edu/doi/10.1086/684719), which get extracted from their replication package. |
| `data/input/crop_water_footprint/Report47Appendix-II.xlsx` | Crop water intensity data from [Mekonnen and Hoekstra (2011)](https://hess.copernicus.org/articles/15/1577/2011/) hosted by the [Water Footprint Network](https://www.waterfootprint.org/publications/) under "Value of Water Report: 47: The green, blue and grey water footprint of farm crops and derived crop products" |
| `data/input/crop_water_footprint/water_intensity_per_tonne.csv` | Table 4 of [Mekonnen & Hoekstra (2011)](https://hess.copernicus.org/articles/15/1577/2011/). |
| `data/input/faostat/fmrsudan_qcl.csv` `data/input/faostat/fmrsudan_qv.csv` | FAOSTAT Data Download interface to download the [QCL](https://www.fao.org/faostat/en/#data/QCL) and [QV](https://www.fao.org/faostat/en/#data/QV) data series for the former Sudan before the secession of South Sudan in 2011. |
| `data/input/faostat/Prices_E_All_Data_(Normalized).csv` `data/input/faostat/Production_Crops_Livestock_E_All_Data_(Normalized).csv` `data/input/faostat/Value_of_Production_E_All_Data_(Normalized).csv` | FAOSTAT Data Download interface to download the [QCL](https://www.fao.org/faostat/en/#data/QCL) and [QV](https://www.fao.org/faostat/en/#data/QV) data series for all countries. |

## Instructions for replication
the replicator must place the path of their working directory on line 19 of the script `run.sh`.
