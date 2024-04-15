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
// calculate weighted mean of rainfall by decile of delta_tws
xtile dec_tws = delta_wd_cm_yr, nq(10) // creates deciles
collapse (mean) rain_cm_yr [aw=areahec], by(dec_tws) // collapse by decile

// plot parameters
local ylabel "Annual average rainfall (cm/yr)"
local xlabel "Deciles of water change ({&rarr} gaining water)"

// decile plot
tw ///
	(scatter rain_cm_yr dec_tws), ///
	xlabel(2(2)10) ///
	ytitle("`ylabel'", size(medlarge)) ///
	xtitle("`xlabel')", size(medlarge)) ///
	graphregion(color(white)) plotregion(color(white))

// save plot
gr export "results/figA1b.png", replace width(2000) height(1500)
