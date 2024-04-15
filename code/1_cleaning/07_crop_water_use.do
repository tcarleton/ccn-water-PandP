/*******************************************************************************
Description: This file produces global water use estimates per crop.
*******************************************************************************/

clear all
set more off

* import country-level FAO datasets
import delim using "data/intermediate/production/yields_baseline.csv", clear

* save country-level FAO datasets of global avg. yield by crop
preserve
collapse (mean) yield_hgperha [aw = production_tonnes], by(item*)
rename yield_hgperha yield
label var yield "avg. yield (hg/ha)"
tempfile global_avg_yields
save `global_avg_yields', replace
restore

* save country-level FAO datasets of global total production by crop
preserve
collapse (sum) production_tonnes, by(item*)
rename production_tonnes production
label var production "total production (metric tonnes)"
tempfile global_total_production
save `global_total_production', replace
restore

* merge avg. yield and total prod. with water use per tonne
import delim using "data/input/crop_water_footprint/water_intensity_per_tonne.csv", clear
label var total "water use, total (cubic meters per metric tonne)"
drop if missing(itemcode)
merge 1:1 itemcode using `global_avg_yields', keep(match master) nogen
merge 1:1 itemcode using `global_total_production', keep(match master) nogen

* convert water use per tonne to per hectare
replace yield = yield/10000 // hg to metric tonne: divide by 10000
gen water_per_hectare = total * yield
gen global_total_water_use = total * production
gsort -water_per_hectare
export delim using "data/intermediate/production/crop_water_use.csv", replace
