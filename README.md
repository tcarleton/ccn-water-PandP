# Is the world running out of fresh water?
This repository contains code and data necessary to replicate the findings of Carleton, Crews, and Nath (AEA Papers and Proceedings, 2024).

## Setup
Scripts in this repository are written in Python, Stata, and R. Throughout this document, it is assumed that the replicator operates from a working directory containing all necessary files and folders, which are detailed in the structure below.

### File/folder structure
```text
├── code
│   ├── run.sh
│   ├── 0_env_setup
│   │   └── setup.R
│   ├── 1_cleaning
│   │   ├── 01_country_crosswalk.py
│   │   ├── 02_crop_crosswalk.py
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
| `data/input/cds_2016/CountryNamesNumbers.csv` `data/input/cds_2016/crop_names_numbers_codes.csv` | Lists of unique country/crop names, numbers, *and codes*. The names and numbers match those used by [Costinot, Donaldson, & Smith (2016)](https://www.journals.uchicago.edu/doi/10.1086/684719), which got extracted from their replication package. |
| `data/input/crop_water_footprint/Report47Appendix-II.xlsx` | Crop water intensity data from [Mekonnen and Hoekstra (2011)](https://hess.copernicus.org/articles/15/1577/2011/) hosted by the [Water Footprint Network](https://www.waterfootprint.org/publications/) under "Value of Water Report: 47: The green, blue and grey water footprint of farm crops and derived crop products." |
| `data/input/crop_water_footprint/water_intensity_per_tonne.csv` | Table 4 of [Mekonnen and Hoekstra (2011)](https://hess.copernicus.org/articles/15/1577/2011/). |
| `data/input/faostat/fmrsudan_qcl.csv` `data/input/faostat/fmrsudan_qv.csv` | FAOSTAT Data Download interface to download the [QCL](https://www.fao.org/faostat/en/#data/QCL) and [QV](https://www.fao.org/faostat/en/#data/QV) data series for the former Sudan before the secession of South Sudan in 2011. |
| `data/input/faostat/Prices_E_All_Data_(Normalized).csv` `data/input/faostat/Production_Crops_Livestock_E_All_Data_(Normalized).csv` `data/input/faostat/Value_of_Production_E_All_Data_(Normalized).csv` | FAOSTAT Data Download interface to download the [QCL](https://www.fao.org/faostat/en/#data/QCL) and [QV](https://www.fao.org/faostat/en/#data/QV) data series for all countries. |
| `data/input/gaez/gaez.csv` | Crosswalk between [GAEZ (v4) Agro-climatic Potential Yield](https://gaez.fao.org/pages/theme-details-theme-3) fields and GRACE cells from [Carleton, Crews and Nath (2024)](https://www.levicrews.com/files/p-wateruse_paper.pdf). |
| `data/input/grace/grace.dta` | GRACE data from [Carleton, Crews and Nath (2024)](https://www.levicrews.com/files/p-wateruse_paper.pdf). GRACE cells are merged with groundwater levels estimates from [Fan, Li and Miguez-Macho (2013)](https://www.science.org/doi/10.1126/science.1229881), gridded cropped area fraction data from [Monfreda et al. (2008)](https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2007GB002947) and from [Ramankutty et al. (2008)](https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2007GB002952), and cumulative precipitation from the Global Metorological Forcing Dataset . The croppped area fraction data was accessed through the [SAGE portal](https://sage.nelson.wisc.edu/data-and-models/datasets/#globaluse). |
| `data/hand/caf_gaezpy_crosswalk.csv` | Crosswalk of crop names between GAEZ v4 and cropped area fraction data. |
| `data/hand/fao_country_crosswalk.csv` | Obtained from [deprecated FAO link](https://www.fao.org/countryprofiles/iso3list/en/). |
| `data/hand/FCL_HS_mappings_2020-01-07.csv` | Downloaded from [deprecated FAO link](http://datalab.review.fao.org/datalab/caliper/web/sites/default/files/2020-01/FCL_HS_mappings_2020-01-07.csv). |
| `data/nra/AgIncentivesNRP.csv` `data/nra/UpdatedDistortions_to_AgriculturalIncentives_database_0613.xls` | Obtained through the [AgIncentives Database](agincentives.org). |

## Instructions for replication
The analysis for this project can be fully replicated (from start to end) using the bash script `code/run.sh`. To do so, the replicator must install the software requirements detailed above and place the path of their working directory on line 18 of the bash script before executing it.
However, if the replicator wishes to only run the code partially or script by script, the programs should be executed in the following order (after setting the correct working directory):
1. `code/1_cleaning/01_country_crosswalk.py` creates a country name crosswalk used in later scripts.
2. `code/1_cleaning/02_crop_crosswalk.py` creates a crop crosswalk used in later scripts.
3. `code/1_cleaning/03_build_tradedata.py` cleans trade data from BACI/COMTRADE.
4. `code/1_cleaning/04_build_proddata.py` cleans production data from the FAO.
5. `code/1_cleaning/05_fill_tradedata.do` fills trade data with auto-consumption.
6. `code/1_cleaning/06_virtualwater.py` creates the virtual water flows estimates.
7. `code/1_cleaning/07_crop_water_use.do` produces global water use estimates per crop.
8. `code/1_cleaning/08_merge_grace_gaez.R` generates analysis-ready data at the GRACE grid cell level by merging them with productivity data from GAEZ v4.
9. `code/1_cleaning/09_merge_grace_agemp.R` generates analysis-ready data at the GRACE grid cell level by merging them with World Bank agricultural employment share data.
10. `code/1_cleaning/10_merge_grace_virtwflows.R` generates analysis-ready data at the GRACE grid cell level by merging them with virtual water flows estimates.
11. `code/2_analysis/01_make_maps.R` produces all maps (Figures 1, 2a, 2c, 2e, 3a, and Appendix Figures A1a, A1c, A4a and A4c) in the paper.
12. `code/2_analysis/02_make_scatterplots.do` produces all scatterplots (Figures 2b, 2d, 2f, 3b, and Appendix Figures A1b, A1d, A2, A3, A4b, A4d, A5, A6, A7, A8) in the paper.
13. `code/2_analysis/03_intext_stats.do` produces all in-text statistics in the paper.
