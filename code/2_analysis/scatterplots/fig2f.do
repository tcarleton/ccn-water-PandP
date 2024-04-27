* load across-crop productivity data
use "data/intermediate/grace_merged/across_crop_avg_pot_yld.dta", clear

* make scatterplot
// calculate weighted mean of across-crop productivity by decile of delta_tws
xtile dec_tws = delta_wd_cm_yr, nq(10) // creates deciles
collapse (mean) py_z_wmean [aw=areahec], by(dec_tws) // collapse by decile

// plot parameters
local ylabel "Across-crop productivity z-score"
local mcol "187 54 85"
local xlabel "Deciles of water change ({&rarr} gaining water)"

// decile plot
tw ///
	(scatter py_z_wmean dec_tws, mcolor("`mcol'")), ///
	xlabel(2(2)10) ///
	ylabel(, nogrid) ///
	ytitle("`ylabel'", size(medlarge)) ///
	xtitle("`xlabel')", size(medlarge)) ///
	graphregion(color(white)) plotregion(color(white))

// save plot
gr export "results/fig2f.png", replace width(2000) height(1500)
