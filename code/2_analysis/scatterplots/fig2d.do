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
// calculate weighted sum of population by decile of delta_tws
xtile dec_tws = delta_wd_cm_yr, nq(10) // creates deciles
gen pop_mills = population/1000000 // change population unit to millions
collapse (sum) pop_mills [aw=areahec], by(dec_tws) // collapse by decile

// plot parameters
local ylabel "Population (millions)"
local mcol "187 54 85"
local xlabel "Deciles of water change ({&rarr} gaining water)"

// scatterplot
tw ///
	(scatter pop_mills dec_tws, mcolor("`mcol'")), ///
	xlabel(2(2)10) ///
	ylabel(, nogrid) ///
	ytitle("`ylabel'", size(medlarge)) ///
	xtitle("`xlabel'", size(medlarge)) ///
	graphregion(color(white)) plotregion(color(white)) 
		
// save plot
gr export "results/fig2d.png", replace width(2000) height(1500)
