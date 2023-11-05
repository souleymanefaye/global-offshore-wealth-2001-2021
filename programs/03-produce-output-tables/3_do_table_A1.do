//----------------------------------------------------------------------------//
// Project: Offshore financial wealth database - update 2023
// Title: 3_do_table_A1.do
// Purpose: produce TABLE A1 "Global Cross-Border Securities Assets" (total assets and corrections)
// This version: 18 Oct 2023
//----------------------------------------------------------------------------//

clear
set more off
global myexcel "$tables\FGZ_Appendix_Tables_A1-A3.xlsx"

// Build table A1

// Col. (1)
use "$work\data_toteq_update.dta", clear
replace sumeqasset = sumeqasset / 1000
tabstat sumeqasset, by(year) stat(sum)
return list

putexcel set "$myexcel", sheet(Table A1_update) modify
tabstat sumeqasset, by(year) stat(sum) save
return list
matrix sumeqasset = (r(Stat1) \ r(Stat2) \ r(Stat3)\ r(Stat4)\ r(Stat5) \ r(Stat6) \ r(Stat7)\ r(Stat8)\ r(Stat9) \ r(Stat10) \ r(Stat11) \ r(Stat12)\ r(Stat13)\r(Stat14) \ r(Stat15) \ r(Stat16)\ r(Stat17)\r(Stat18) \ r(Stat19) \ r(Stat20)\ r(Stat21))
putexcel C34 = matrix(sumeqasset)

use "$work\data_totdebt_update.dta", replace
collapse (sum) sumdebtasset, by(year)
replace sumdebtasset = sumdebtasset/1000
mkmat sumdebtasset
putexcel C57 = matrix(sumdebtasset)
clear matrix

// Col. (2), (3), (3b), (5), (6b), (7), (9), (10), (12)
use "$work\data_full_matrices.dta", clear
preserve
collapse (sum) eqasset debtasset augmeqasset augmdebtasset, by(year source)
keep if source == 9999 | source == 377 | source == 924 | source == 456 | source == 419 | source == 443 | source == 453 | source == 9994
reshape wide eqasset debtasset augmeqasset augmdebtasset, i(year) j(source)
foreach var of varlist eqasset* debtasset* augmeqasset* augmdebtasset*{
replace `var' = `var' / 1000
	mkmat `var'
	matrix list `var'
}

// SEFER & SSIO
putexcel D34 = matrix(eqasset9999)
putexcel D57 = matrix(debtasset9999)

// Cayman islands
putexcel E34 = matrix(augmeqasset377)
putexcel E57 = matrix(augmdebtasset377)

putexcel F34 = matrix(eqasset377)
putexcel F57 = matrix(debtasset377)

// China
putexcel H34 = matrix(augmeqasset924)
putexcel H57 = matrix(augmdebtasset924)

putexcel J34 = matrix(eqasset924)
putexcel J57 = matrix(debtasset924)

// Middle East
// of which in CPIS (Bahrain + Kuwait + Saudi Arabia)
gen eq_ME_cpis = eqasset419 + eqasset443 + eqasset456
gen debt_ME_cpis = debtasset419 + debtasset443 + debtasset456


// Correction including CPIS (memo: Qatar is parking slot for estimated Middle East assets as Qatar does not report to CPIS)
gen eq_ME = eq_ME_cpis + augmeqasset453
gen debt_ME = debt_ME_cpis + augmdebtasset453
	
	mkmat eq_ME_cpis	
	mkmat debt_ME_cpis
	mkmat eq_ME
	mkmat debt_ME
	
putexcel M34 = matrix(eq_ME_cpis)
putexcel M57 = matrix(debt_ME_cpis)
putexcel K34 = matrix(eq_ME)
putexcel K57 = matrix(debt_ME)

putexcel P34 = matrix(augmeqasset9994)
putexcel P57 = matrix(augmdebtasset9994)
restore

clear matrix

// Col. 4: Correction for CPIS reporting countries other than Cayman, China, Bahrain, Kuwait, Saudi Arabia
// original CPIS minus augmented assets for countries reporting to CPIS
preserve
keep if cpis == 1
collapse (sum) eqasset debtasset augmeqasset augmdebtasset, by(year)
gen eq_corr_cpis = augmeqasset-eqasset
gen debt_corr_cpis = augmdebtasset-debtasset
keep *cpis year
save "$work\cpis_correction.dta", replace
restore

// minus augmented assets for CPIS-reporting countries for which corrections are reported individually
keep if source == 377 | source == 924
*br source sourcename host hostname eqasset debtasset augmeqasset augmdebtasset if source==377&cpis!=1
*br source sourcename host hostname eqasset debtasset augmeqasset augmdebtasset if source==924&cpis!=1

collapse (sum) augmeqasset eqasset augmdebtasset debtasset, by(year)
gen corr_eq = augmeqasset - eqasset
gen corr_debt = augmdebtasset - debtasset
merge 1:1 year using "$work\cpis_correction.dta"
drop _merge


gen eq_othercpis = eq_corr_cpis-corr_eq
gen debt_othercpis = debt_corr_cpis - corr_debt
replace eq_othercpis = eq_othercpis / 1000
replace debt_othercpis = debt_othercpis / 1000
	mkmat eq_othercpis	
	mkmat debt_othercpis

putexcel G34 = matrix(eq_othercpis)
putexcel G57 = matrix(debt_othercpis)

// Col. (6): China reserves
use "$work\data_full_matrices.dta", clear
keep year totaleq_China_public totaldebt_China_public
collapse (mean) totaleq_China_public totaldebt_China_public, by(year)
replace totaleq_China_public = totaleq_China_public / 1000
replace totaldebt_China_public = totaldebt_China_public / 1000

	mkmat totaleq_China_public
	mkmat totaldebt_China_public

putexcel I34 = matrix(totaleq_China_public)
putexcel I57 = matrix(totaldebt_China_public)


use "$work\data_full_matrices.dta", clear

// Col. (11)
// private equity assets EWN

keep if cpis != 1 & source != 924 & source != 9994 & source != 449 & source != 453 & source != 456 & source != 466 & source != 429 & source != 433
gen help_aequity = 1 if aequity != .
replace help_aequity = 0 if aequity == .
collapse (sum) augmeqasset, by(year help_aequity)
reshape wide augmeqasset, i(year) j(help_aequity)
gen other_private_eq = augmeqasset0 + augmeqasset1
replace other_private_eq = other_private_eq / 1000
	mkmat other_private_eq
putexcel O34 = matrix(other_private_eq)


use "$work\data_full_matrices.dta", clear
// private debt assets EWN
keep if cpis != 1 & source != 924 & source != 9994 & source != 449 & source != 453 & source != 456 & source != 466 & source != 429 & source != 433

gen help_aportif = 1 if aportif_debt != .
replace help_aportif = 0 if aportif_debt == .
collapse (sum)augmdebtasset, by(year help_aportif)
reshape wide augmdebtasset, i(year) j(help_aportif)
gen other_private_debt = augmdebtasset0 + augmdebtasset1
replace other_private_debt = other_private_debt / 1000
	mkmat other_private_debt
putexcel O57 = matrix(other_private_debt)

//----------------------------------------------------------------------------//