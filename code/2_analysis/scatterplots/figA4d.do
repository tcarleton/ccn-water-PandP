* load crop productivity data
use "data/intermediate/grace_merged/crop_spec_pot_yld.dta", clear

* make scatterplot
// calculate weighted mean of rice productivity by decile of delta_tws
xtile dec_tws = delta_wd_cm_yr, nq(10) // creates deciles
collapse (mean) whea_aei_yld [aw=areahec], by(dec_tws) // collapse by decile

// plot parameters
local ylabel "Average wheat potential yield"
local xlabel "Deciles of water change ({&rarr} gaining water)"

// decile plot
tw ///
	(scatter whea_aei_yld dec_tws), ///
	xlabel(2(2)10) ///
	ytitle("`ylabel'", size(medlarge)) ///
	xtitle("`xlabel')", size(medlarge)) ///
	graphregion(color(white)) plotregion(color(white))

// save plot
gr export "results/figA4d.png", replace width(2000) height(1500)
