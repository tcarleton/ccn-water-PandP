#!/bin/bash

# LOAD DEPENDENCIES AND MODULES --------------------------------------

module load base-env
module load proxy
module load conda
conda activate R4.2.3
module load stata/17.0

# python packages
pip install numpy
pip install pandas
pip install fuzzywuzzy
pip install xlrd
pip install openpyxl

# SET PATH HERE ------------------------------------------------------
cd /win/l1werpfile2/shared/Cheikh/Research/Ishan/Water/pp_replication

# CLEAN VIRTUAL WATER DATA -------------------------------------------

# create country crosswalk
python code/1_cleaning/01_country_crosswalk.py

# create crop crosswalk
python code/1_cleaning/02_crop_crosswalk.py

# wrangle trade data from BACI/COMTRADE
python code/1_cleaning/03_build_tradedata.py

# clean production data from the FAO
python code/1_cleaning/04_build_proddata.py

# merge trade data
stata -b do code/1_cleaning/05_fill_tradedata.do

# create virtual water flows estimates
python code/1_cleaning/06_virtualwater.py

# create global water use estimates per crop
stata -b do code/1_cleaning/07_crop_water_use.do

# merge grace and gaez
Rscript code/1_cleaning/08_merge_grace_gaezpy.R

# merge grace and ag employment data
Rscript code/1_cleaning/09_merge_grace_agemp.R

# merge grace and virtual water flows
Rscript code/1_cleaning/10_merge_grace_virtwflows.R

# MAKE FIGURES --------------------------------------------------------

# make maps
Rscript code/2_analysis/01_make_maps.R

# make scatterplots
stata -b do code/2_analysis/02_make_scatterplots.do

# generate in-text statistics
stata -b do code/2_analysis/03_intext_stats.do

# delete log files
rm 02_make_scatterplots.log
rm 03_intext_stats.log
rm 05_fill_tradedata.log
rm 07_crop_water_use.log
