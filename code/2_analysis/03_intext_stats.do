/*******************************************************************************
Description: This file produces all in-text statistics in the paper.
*******************************************************************************/

clear all
set more off

/*********************
* WATER LOSS OVER ARABLE LAND
*********************/

* total water use in crop production
import delim "data/intermediate/production/crop_water_use.csv", clear
collapse (sum) tot_cropwateruse=global_total_water_use
local tot_cropwateruse=tot_cropwateruse[1]

* load grace data
use "data/input/grace/grace.dta",clear

* restrict to arable land
drop if (past_area_frac == 0 & sage_crop_area_frac == 0) | ///
	(past_area_frac == . & sage_crop_area_frac == .) | ///
        (past_area_frac == . & sage_crop_area_frac == 0) | ///
        (past_area_frac == 0 & sage_crop_area_frac == .)

* restrict to cells with valid delta_tws
drop if delta_wd_cm_yr==.

* indicator for water change (losing vs gaining water)
gen byte water_change=(delta_wd_cm_yr>0)
label define water_change_lab 0 "Losing Water" 1 "Gaining Water" 2 "Overall"
label values water_change water_change_lab

* program that makes water-stressed dummy variables
cap pro drop clean_water_stressed
pro define clean_water_stressed
	local water_vars rain_cm_yr groundwater delta_wd_cm_yr surface_water

	foreach water_var in `water_vars' {
		egen `water_var'_qtile = xtile(`water_var'), nq(4)
	}
	gen rainfall_stressed = rain_cm_yr_qtile==1 
	gen gwater_stressed = groundwater_qtile == 1
	gen beta_stressed = delta_wd_cm_yr_qtile==1
	gen surfwater_stressed = surface_water_qtile==1

	gen rainfall_gwater_only_stressed = rain_cm_yr_qtile==1 & groundwater_qtile == 1
	gen rainfall_beta_only_stressed = rain_cm_yr_qtile==1  & delta_wd_cm_yr_qtile==1
	gen gwater_beta_only_stressed = groundwater_qtile == 1 & delta_wd_cm_yr_qtile==1

	gen double_water_stressed = rainfall_gwater_only_stressed==1 | rainfall_beta_only_stressed==1 | gwater_beta_only_stressed==1
	gen triple_water_stressed = rain_cm_yr_qtile==1 & groundwater_qtile == 1 & delta_wd_cm_yr_qtile==1
	gen quadruple_water_stressed = rain_cm_yr_qtile==1 & groundwater_qtile == 1 & delta_wd_cm_yr_qtile==1 & surface_water_qtile==1
	
	gen water_stressed_level = 0 if (rainfall_stressed == 0 & gwater_stressed == 0 & beta_stressed == 0) 
	replace water_stressed_level = 1 if (rainfall_gwater_only_stressed == 1)
	replace water_stressed_level = 2 if (rainfall_beta_only_stressed == 1)
	replace water_stressed_level = 3 if (gwater_beta_only_stressed == 1)
	replace water_stressed_level = 4 if (triple_water_stressed == 1)
end

* total rainfall per ha
preserve
	gen rain_m3_ha=(areakm2*1000000) * (rain_cm_yr/100)
	collapse (sum) rain_m3_ha
	local tot_rain_vol=rain_m3_ha[1]
restore

* % of arable grid cells losing water
preserve
	gen freq=1
	collapse (sum) freq, by(water_change)
	egen tot = sum(freq)
	gen share = freq/tot
	drop tot
	
	* editing before exporting to excel
	ren water_change Status
	ren freq Count
	ren share Proportion
	
	* export to excel sheet
	export excel using "results/intext_stats.xlsx", sheet("% cells losing water", replace) firstrow(var)
restore

* number of arable grace cells that are water stressed
preserve
	* clean data
	clean_water_stressed // call data cleaning program
	gen freq=1
	collapse ///
		(rawsum) rainfall_beta_only_stressed gwater_beta_only_stressed quadruple_water_stressed ///
		(rawsum) tot=freq
	* calculate proportions
	foreach v of varlist rainfall_beta_only_stressed-quadruple_water_stressed {
		replace `v'=`v'/tot
	}
	drop tot
	* export to excel sheet
	export excel using "results/intext_stats.xlsx", sheet("% cells water stressed", replace) firstrow(var)
restore

* summary of total water storage volume changes by water change status
preserve
	* calculate volume changes for each arable grid cell // units = m^3/year
	gen delta_vol_m3 = (areakm2*1000000) * (delta_wd_cm_yr/100) // formula delta_vol = area*delta_height
	
	* total arable area (in hectare) in the world
	egen tot_wrld_areahec = sum(areahec)
	
	* collapse to get the sum of all water changes
	collapse (sum) delta_vol_m3 (mean) tot_wrld_areahec (sum) areahec, by(water_change)
	
	* adding overall water storage change to dataset
	egen ovr_delta_vol_m3 = sum(delta_vol_m3)
	
	* overall water storage change by hectare (m^3/ha)
	gen ovr_delta_vol_by_ha = ovr_delta_vol_m3/tot_wrld_areahec
	
	* water storage change by hectare (m^3/ha), by water change status
	gen delta_vol_by_ha = delta_vol_m3/areahec
	
	* adding one row for overall changes
	local new = _N+1
	set obs `new'
	replace water_change=2 if _n==`new'
	label values water_change water_change_lab
	replace delta_vol_m3=ovr_delta_vol_m3[1] if water_change==2
	replace delta_vol_by_ha=ovr_delta_vol_by_ha[1] if water_change==2
	
	* editing column names
	ren water_change Status
	ren delta_vol_m3 TWS_Change_m3
	ren delta_vol_by_ha TWS_Change_m3_by_ha
	keep Status TWS_Change_m3 TWS_Change_m3_by_ha
	
	* overall water loss as a percent of annual rainfall/crop water use
	gen Perc_Rainfall=TWS_Change_m3/`tot_rain_vol' if Status==2
	gen Perc_CropWaterUse=TWS_Change_m3/`tot_cropwateruse' if Status==2
	
	* export to excel sheet
	export excel using "results/intext_stats.xlsx", sheet("total volume changes", replace) firstrow(var)
restore

* 1st and 10th percentile of water loss per hectare per year over arable grid cells
preserve
	gen delta_vol_per_ha_m3 = (areakm2*1000000) * (delta_wd_cm_yr/100) / areahec
	collapse (p1) p1_deltavol=delta_vol_per_ha_m3 (p10) p10_detavol=delta_vol_per_ha_m3
	
	* export to excel sheet
	export excel using "results/intext_stats.xlsx", sheet("p1-p10 water loss", replace) firstrow(var)
restore

* water loss in the lowest decile of arable grid cells
preserve
	* calculate volume changes for each arable grid cell // units = m^3/year
	gen delta_vol_m3 = (areakm2*1000000) * (delta_wd_cm_yr/100) // formula delta_vol = area*delta_height
	
	* summarize by decile of water loss
	xtile dec_tws = delta_wd_cm_yr, nq(10) 
	collapse (sum) tot_delta_vol_m3=delta_vol_m3 (mean) avg_delta_vol_m3=delta_vol_m3, by(dec_tws)
	
	* export to excel sheet
	export excel using "results/intext_stats.xlsx", sheet("average-sum water loss", replace) firstrow(var)
restore

/*********************
* POPULATION AND WATER LOSS
*********************/

* proportion of population in each decile of water change
preserve
	* summarize by decile of water loss
	xtile dec_tws = delta_wd_cm_yr, nq(10) 
	collapse (sum) pop=population, by(dec_tws)
	egen tot_pop = sum(pop)
	local tot_pop=tot_pop[1]
	drop tot_pop
	gen prop_pop=pop/`tot_pop'
	
	* export to excel sheet
	export excel using "results/intext_stats.xlsx", sheet("population and water loss", replace) firstrow(var)
restore

* employment in agriculture and water loss
preserve
	use "data/intermediate/grace_merged/grace_ag_emp_share.dta", clear
	xtile dec_tws = delta_wd_cm_yr, nq(10) 
	collapse (mean) ag_emp_share, by(dec_tws)
	export excel using "results/intext_stats.xlsx", sheet("ag employment and water loss", replace) firstrow(var)
restore
