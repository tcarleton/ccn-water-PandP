* load grace data
use "data/input/grace/grace.dta", clear

* restrict to arable land
drop if (past_area_frac == 0 & sage_crop_area_frac == 0) | ///
	(past_area_frac == . & sage_crop_area_frac == .) | ///
        (past_area_frac == . & sage_crop_area_frac == 0) | ///
        (past_area_frac == 0 & sage_crop_area_frac == .)

* restrict to cells with valid delta_tws
drop if delta_wd_cm_yr==.

* make scatterplot
local vars rain_cm_yr groundwater
foreach d of local vars {
	preserve
		// calculate weighted sum of population by decile of variables
		xtile dec_`d' = `d', nq(10) // creates deciles from variable
		gen pop_mills = population/1000000 // change population unit to millions
		collapse (sum) pop_mills [aw=areahec], by(dec_`d') // collapse by decile
		
		// axes labels and panel
		if "`d'" == "rain_cm_yr" {
			local xlabel "Deciles of annual average rainfall ({&rarr} more rain)"
			local panel "a"
		}
		if "`d'" == "groundwater"{
			local xlabel "Deciles of groundwater access ({&rarr} higher water table)"
			local panel "b"
		} 
		local ylabel "Population (millions)"
		
		//  decile plot
		tw ///
			(scatter pop_mills dec_`d'), ///
			xlabel(2(2)10) ///
			ytitle("`ylabel'", size(medlarge)) ///
			xtitle("`xlabel'", size(medlarge)) ///
			graphregion(color(white)) plotregion(color(white))
			
		// save plotregion
		gr export "results/figA2`panel'.png", replace width(2000) height(1500)
	restore
}

