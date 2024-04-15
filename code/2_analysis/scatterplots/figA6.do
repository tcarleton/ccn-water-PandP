* load crop productivity data
use "data/intermediate/grace_merged/across_crop_avg_pot_yld.dta", clear

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
collapse (mean) py_z_wmean, by(water_stressed_level)
label var py_z_wmean "Across-crop productivity z-score" 
label var water_stressed_level "Regions in the Bottom Quartile of Water Availability, By Variable"

//make plot
scatter py_z_wmean water_stressed_level, ///
	xlabel(0 `"None"' 1 `""Rainfall&" "Groundwater""' 2 `""Rainfall&" "{&Delta} TWS""' 3 `""Groundwater&" "{&Delta} TWS""' 4 `""All" "Three""') ///
	msymbol(circle) msize(medlarge) mcolor(gs1) graphregion(color(white))
	
// export the plot
gr export "results/figA6.png", replace
