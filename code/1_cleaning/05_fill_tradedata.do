clear all
set more off

*------------------------------
* Prepare ancillary dataframes
*------------------------------
*
* Prepare country crosswalk to merge
import delimited "data/intermediate/crosswalks/country_crosswalk.csv", clear
keep uni areacode shortname
rename uni i
tempfile country_crosswalk
save `country_crosswalk'
*
* Prepare crop crosswalk to merge
import delimited "data/intermediate/crosswalks/crop_crosswalk.csv", clear
keep fclcode fcllabel hscode description
rename hscode k
tempfile crop_crosswalk
save `crop_crosswalk'
*
* Prepare production value and quantities data
import delimited "data/intermediate/production/yields_baseline.csv", clear
keep areacode itemcode production_tonnes
rename production_tonnes prod_q
replace prod_q = 0 if prod_q == .
rename itemcode fclcode
tempfile quant
save `quant'
import delimited "data/intermediate/production/prodvalue_baseline.csv", clear
keep areacode itemcode gross_production_value_currentus
rename gross_production_value_currentus prod_v
replace prod_v = 0 if prod_v == .
rename itemcode fclcode
merge 1:1 areacode fclcode using `quant', nogen keep(3)
replace fclcode = 15 if fclcode == 16 | fclcode == 17 | fclcode == 23 | fclcode == 24 // Wheat
replace fclcode = 27 if fclcode == 28 | fclcode == 29 | fclcode == 31 | fclcode == 32 | fclcode == 34 | fclcode == 38 // Rice
replace fclcode = 56 if fclcode == 58 | fclcode == 59 | fclcode == 60 | fclcode == 64 | fclcode == 67 // Maize
replace fclcode = 507 if fclcode == 509 | fclcode == 510 // Grapefruit and pomelo
replace fclcode = 656 if fclcode == 657 | fclcode == 659 //  Coffee Green
collapse (sum) prod_v prod_q, by(fclcode areacode)
tempfile prod
save `prod'
*
*------------------------------
* Clean trade data
*------------------------------
*
import delimited "data/intermediate/trade/trade_baseline.csv", clear
*
* Implement sugar rule
preserve
gen sugarcrop = (k==121299 | k==170111 | k==170191 | k==170199 | k==121291 | k==170112)
keep if sugarcrop == 1 // Keep only sugar crops
gen caneid = (k==121299 | k==170111) // Identify baseline sugar cane codes and sugar beet codes
gen beetid = (k==121291 | k==170112)
egen canesum = sum(v) if caneid == 1, by(i) // Get total exports + own consumption for each country of sugar cane and sugar beet
egen beetsum = sum(v) if beetid == 1, by(i)
egen canemax = max(canesum), by(i) // Create column comparing sums for each country
egen beetmax = max(beetsum), by(i)
replace canemax = 0 if canemax == . // Fill in missing
replace beetmax = 0 if beetmax == .
gen sugarcane_country = (canemax > beetmax) // Country is a sugar cane country if sum(cane exports) > sum(beet exports), otherwise it is a sugar beet country.
gen collapse_rule = "sugar cane country" if sugarcane_country == 1 & (k == 121299 | k == 170111 | k == 170191 | k == 170199)
replace collapse_rule = "sugar beet country" if sugarcane_country == 0 & (k==121291 | k==170112 | k == 170191 | k == 170199)
drop if collapse_rule == ""
egen total_cane = sum(v), by(collapse_rule i j)
egen total_q = sum(q), by(collapse_rule i j)
gen hscode_collapse = 121299 if collapse_rule == "sugar cane country"
replace hscode_collapse = 121291 if collapse_rule == "sugar beet country"
collapse (max) hscode_collapse total_cane total_q, by(collapse_rule i j j_iso3 i_iso3)
gen description = "Aggregate sugar crop"
gen t = 2009
rename total_cane v
rename total_q q
rename hscode_collapse k
drop collapse_rule
tempfile sugarcrop
save `sugarcrop'
restore
*
drop if (k==121299 | k==170111 | k==170191 | k==170199 | k==121291 | k==170112)
append using `sugarcrop'
*
replace k = 100110 if k == 100190 | k == 110100 | k == 110311 | k == 230230 | k == 110811 | k == 110900 // Wheat fix
replace k = 100610 if k == 100620 | k == 100630 | k == 100640 | k == 100819 | k == 110290 | k == 110319 | k == 110320 // Rice fix
replace k = 100510 if k == 100590 | k == 100220 | k == 110313 | k == 230210 | k == 151521 | k == 151529 | k == 110812 // Maize fix
replace k = 80540 if k == 200921 | k == 200929 // Grapefruit fix
replace k = 90111 if k == 90122 | k == 90112 | k == 90121 | k == 210111 | k == 210112 // Coffee fix
*
collapse (sum) v q, by (i k j i_iso3 j_iso3 t)
tempfile trade
save `trade'
*
* Get ISO3 codes
preserve
keep i i_iso3
duplicates drop i i_iso3, force
tempfile filliso3
save `filliso3'
restore
*
collapse (sum) v q, by(i k) // Collapse to sum of export value and quantity for each country in each crop.
*
* Apply crosswalks
joinby k using `crop_crosswalk', unmatched(master)
drop if missing(fclcode)
drop _merge
joinby i using `country_crosswalk', unmatched(master)
drop _merge
drop if areacode == 0
*
*------------------------------
* Fill trade data with auto-consumption
*------------------------------
*
* Outer join of production and trade data
joinby fclcode areacode using `prod', unmatched(both)
gsort fclcode -fcllabel
by fclcode: replace fcllabel = fcllabel[_n-1] if missing(fcllabel)
drop if missing(areacode)
gsort areacode -shortname
by areacode: replace shortname = shortname[_n-1] if missing(shortname)
*
* Replace total exports as 0 if a country produces a good, but has a missing value for exports column.
replace v = 0 if v == . & prod_v != .
replace q = 0 if q == . & prod_q != .
*
* Generate auto-consumption (value and quantity)
foreach var of varlist v q {
    replace `var' = 0 if `var' == .
    replace prod_`var' = 0 if prod_`var' == .
    gen auto_consumption_`var' = prod_`var' - `var'
    * equivalent to setting total production = total exports if this value is negative (what CDS do)
    replace auto_consumption_`var' = 0 if auto_consumption_`var' < 0
    replace `var' = auto_consumption_`var'
    drop auto_consumption_`var'
}
*
drop k
merge m:m fclcode using `crop_crosswalk', nogen keep(3)
drop i
merge m:m areacode using `country_crosswalk', nogen keep(3)
keep i k v q
gen j = i
*
* Append to original trade data
append using `trade'
replace t = 2009 if t == .
drop i_iso3
merge m:1 i using `filliso3', nogen keep(3)
replace j_iso3 = i_iso3 if j_iso3 == ""
sort i j k
drop if v == .
replace q = 0 if v == 0 & q == .
*
sort i k j
order t i i_iso3 k j j_iso3 v q
export delimited "data/intermediate/trade/trade_baseline_filled.csv", replace
