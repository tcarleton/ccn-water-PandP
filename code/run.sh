#!/bin/bash

# LOAD DEPENDENCIES AND MODULES --------------------------------------

# load necessary modules here (if necessary)
# module load ...

echo "install python packages"
pip install numpy
pip install pandas
pip install fuzzywuzzy
pip install xlrd
pip install openpyxl

# SET WORKING DIRECTORY HERE -----------------------------------------

# insert the path of your working directory after "cd"
cd /scratch/network/lcrews/ccn-water-PandP

# CLEAN VIRTUAL WATER DATA -------------------------------------------

echo "create country crosswalk"
python code/1_cleaning/01_country_crosswalk.py

echo "create crop crosswalk"
python code/1_cleaning/02_crop_crosswalk.py

echo "wrangle trade data from BACI/COMTRADE"
python code/1_cleaning/03_build_tradedata.py

echo "clean production data from the FAO"
python code/1_cleaning/04_build_proddata.py

echo "merge trade data"
stata -b do code/1_cleaning/05_fill_tradedata.do

echo "create virtual water flows estimates"
python code/1_cleaning/06_virtualwater.py

echo "create global water use estimates per crop"
stata -b do code/1_cleaning/07_crop_water_use.do

echo "merge grace and gaez"
Rscript code/1_cleaning/08_merge_grace_gaezpy.R

echo "merge grace and ag employment data"
Rscript code/1_cleaning/09_merge_grace_agemp.R

echo "merge grace and virtual water flows"
Rscript code/1_cleaning/10_merge_grace_virtwflows.R

# MAKE FIGURES --------------------------------------------------------

echo "make maps"
Rscript code/2_analysis/01_make_maps.R

echo "make scatterplots"
stata -b do code/2_analysis/02_make_scatterplots.do

echo "generate in-text statistics"
stata -b do code/2_analysis/03_intext_stats.do

echo "delete log files"
rm 02_make_scatterplots.log
rm 03_intext_stats.log
rm 05_fill_tradedata.log
rm 07_crop_water_use.log