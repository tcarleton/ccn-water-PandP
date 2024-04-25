* load  merged virtual water trade data
use "data/intermediate/grace_merged/grace_virtwflows.dta", clear

* make scatterplots
local vars groundwater delta_wd_cm_yr
foreach d of local vars {
	preserve
		// calculate weighted sum of virtual water imports by decile of variables
		xtile dec_`d' = `d', nq(10) // creates deciles from variable
		collapse (sum) virt_w_netimp_km3 [aw=areahec], by(dec_`d') // collapse by decile
		
		// axes labels and panel
		if "`d'" == "groundwater"{
			local xlabel "Deciles of groundwater access ({&rarr} higher water table)"
			local panel "a"
		} 
		if "`d'" == "delta_wd_cm_yr" {
			local xlabel "Deciles of water change ({&rarr} gaining water)"
			local panel "b"
		}
		local ylabel "Net Virtual Water Imports (km{sup:3})"
		
		//  decile plot
		tw ///
			(scatter virt_w_netimp_km3 dec_`d'), ///
			xlabel(2(2)10) ///
			ytitle("`ylabel'", size(medlarge)) ///
			xtitle("`xlabel'", size(medlarge)) ///
			graphregion(color(white)) plotregion(color(white))
			
		// save plotregion
		gr export "results/figA8`panel'.png", replace width(2000) height(1500)
	restore
}
