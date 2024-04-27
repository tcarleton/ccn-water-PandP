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
collapse (mean) rain_cm_yr neg_gwater_depth [aw=areahec], by(dec_tws) // collapse by decile

// axes labels
local ylabel1 "Groundwater depth (m)"
local ylabel2 "Rainfall (cm/yr)"
local col1 "187 54 85"
local col2 "115 115 117"
local xlabel "Deciles of water change ({&rarr} gaining water)"

// scatterplot
tw ///
	(scatter neg_gwater_depth dec_tws, yaxis(1) mcolor("`col1'")) ///
	(scatter rain_cm_yr dec_tws, yaxis(2) mcolor("`col2'")), /// 
	xlabel(2(2)10) ///
	ylabel(10(5)25, tlcolor("`col1'") labcolor("`col1'") axis(1)) ///
	ylabel(70(10)110, tlcolor("`col2'") labcolor("`col2'") axis(2) angle(90)) ///
	ytitle("`ylabel1'", color("`col1'") size(medlarge) axis(1)) ///
	ytitle("`ylabel2'", color("`col2'") size(medlarge) axis(2)) ///
	xtitle("`xlabel'", size(medlarge)) ///
	yscale(lc("`col1'") axis(1)) ///
	yscale(lc("`col2'") axis(2)) ///
	graphregion(color(white)) plotregion(color(white)) leg(off)
		
// save plot
gr export "results/fig2b.png", replace width(2000) height(1500)
