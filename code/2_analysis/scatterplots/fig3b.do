* load  merged virtual water trade data
use "data/intermediate/grace_merged/grace_virtwflows.dta", clear

* make scatterplot
// calculate sum of virtual water net imports by decile of rainfall
xtile dec_rain = rain_cm_yr, nq(10) // creates deciles
collapse (sum) virt_w_netimp_km3 [aw=areahec], by(dec_rain) // collapse by decile

// plot parameters
local xlabel "Deciles of annual average rainfall ({&rarr} more rain)"
local ylabel "Net Virtual Water Imports (km{sup:3})"
local col1 "0 98 40"
local col2 "204 225 212"

// decile plot
tw ///
	(scatter virt_w_netimp_km3 dec_rain, mcolor("`col1'")), ///
	xlabel(2(2)10) ///
	yline(0, lcolor("`col2'")) ///
	ylabel(, nogrid) ///
	ytitle("`ylabel'", size(medlarge)) ///
	xtitle("`xlabel'", size(medlarge)) ///
	graphregion(color(white)) plotregion(color(white))

// save plot
gr export "results/fig3b.png", replace width(2000) height(1500)
