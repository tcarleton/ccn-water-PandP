* load crop productivity data
use "data/intermediate/grace_merged/crop_spec_pot_yld.dta", clear

* make scatterplots (rice productivity)
local vars rain_cm_yr groundwater
foreach d of local vars {
	preserve
		// calculate weighted mean of rice productivity by decile of variables
		xtile dec_`d' = `d', nq(10) // creates deciles from variable
		collapse (mean) rice_aei_yld [aw=areahec], by(dec_`d') // collapse by decile
		
		// axes labels and panel
		if "`d'" == "rain_cm_yr" {
			local xlabel "Deciles of annual average rainfall ({&rarr} more rain)"
			local panel "c"
		}
		if "`d'" == "groundwater"{
			local xlabel "Deciles of groundwater access ({&rarr} higher water table)"
			local panel "a"
		} 
		local ylabel "Average rice potential yield"
		
		//  decile plot
		tw ///
			(scatter rice_aei_yld dec_`d'), ///
			xlabel(2(2)10) ///
			ytitle("`ylabel'", size(medlarge)) ///
			xtitle("`xlabel'", size(medlarge)) ///
			graphregion(color(white)) plotregion(color(white))
			
		// save plotregion
		gr export "results/figA5`panel'.png", replace width(2000) height(1500)
	restore
}

* make scatterplots (wheat productivity)
local vars rain_cm_yr groundwater
foreach d of local vars {
	preserve
		// calculate weighted mean of wheat productivity by decile of variables
		xtile dec_`d' = `d', nq(10) // creates deciles from variable
		collapse (mean) whea_aei_yld [aw=areahec], by(dec_`d') // collapse by decile
		
		// axes labels and panel
		if "`d'" == "rain_cm_yr" {
			local xlabel "Deciles of annual average rainfall ({&rarr} more rain)"
			local panel "d"
		}
		if "`d'" == "groundwater"{
			local xlabel "Deciles of groundwater access ({&rarr} higher water table)"
			local panel "b"
		} 
		local ylabel "Average wheat potential yield"
		
		//  decile plot
		tw ///
			(scatter whea_aei_yld dec_`d'), ///
			xlabel(2(2)10) ///
			ytitle("`ylabel'", size(medlarge)) ///
			xtitle("`xlabel'", size(medlarge)) ///
			graphregion(color(white)) plotregion(color(white))
			
		// save plotregion
		gr export "results/figA5`panel'.png", replace width(2000) height(1500)
	restore
}
