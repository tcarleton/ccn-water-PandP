* load grace data
use "data/input/grace/grace.dta", clear

* restrict to arable land
drop if (past_area_frac == 0 & sage_crop_area_frac == 0) | ///
	(past_area_frac == . & sage_crop_area_frac == .) | ///
        (past_area_frac == . & sage_crop_area_frac == 0) | ///
        (past_area_frac == 0 & sage_crop_area_frac == .)

* restrict to cells with valid delta_tws
drop if delta_wd_cm_yr==.

* program that makes water-stressed dummy variables
cap pro drop clean_water_stressed
pro define clean_water_stressed
	local water_vars rain_cm_yr groundwater delta_wd_cm_yr

	foreach water_var in `water_vars' {
		egen `water_var'_qtile = xtile(`water_var'), nq(4)
	}
	gen rainfall_stressed = rain_cm_yr_qtile==1 
	gen gwater_stressed = groundwater_qtile == 1
	gen beta_stressed = delta_wd_cm_yr_qtile==1

	gen rainfall_gwater_only_stressed = rain_cm_yr_qtile==1 & groundwater_qtile == 1
	gen rainfall_beta_only_stressed = rain_cm_yr_qtile==1  & delta_wd_cm_yr_qtile==1
	gen gwater_beta_only_stressed = groundwater_qtile == 1 & delta_wd_cm_yr_qtile==1

	gen double_water_stressed = rainfall_gwater_only_stressed==1 | rainfall_beta_only_stressed==1 | gwater_beta_only_stressed==1
	gen triple_water_stressed = rain_cm_yr_qtile==1 & groundwater_qtile == 1 & delta_wd_cm_yr_qtile==1

	gen water_stressed_level = 0 if (rainfall_stressed == 0 & gwater_stressed == 0 & beta_stressed == 0) 
	replace water_stressed_level = 1 if (rainfall_gwater_only_stressed == 1)
	replace water_stressed_level = 2 if (rainfall_beta_only_stressed == 1)
	replace water_stressed_level = 3 if (gwater_beta_only_stressed == 1)
	replace water_stressed_level = 4 if (triple_water_stressed == 1)
end

* water-stress and population
// clean data
clean_water_stressed // call data cleaning program
gen pop_mills = population/1000000 // change population unit to millions
collapse (sum) pop_mills, by(water_stressed_level)
label var pop_mills "Population (millions)" 
label var water_stressed_level "Regions in the Bottom Quartile of Water Availability, By Variable"

//make plot
scatter pop_mills water_stressed_level, ///
	xlabel(0 `"None"' 1 `""Rainfall&" "Groundwater""' 2 `""Rainfall&" "{&Delta} TWS""' 3 `""Groundwater&" "{&Delta} TWS""' 4 `""All" "Three""') ///
	msymbol(circle) msize(medlarge) mcolor(gs1) graphregion(color(white))
	
// export the plot
gr export "results/figA3.png", replace

