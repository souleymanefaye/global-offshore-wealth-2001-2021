//----------------------------------------------------------------------------//
//Project: Offshore financial wealth database - update 2023
//Title: 1c_import_auxiliary_data.do
//Purpose: import from different sources and formats
//This version: 18 Oct 2023
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
// import aggregates from CPIS data
//----------------------------------------------------------------------------//

// total equity and total debt
foreach asset in "eq" "debt"{
import excel "$raw/IMF_2023_Table_15_All_Economies_Reported_Por_`asset'.xlsx", sheet("Table 15") clear
drop A
drop in 1
drop in 1
drop in 1

foreach v of varlist C - AG {
    replace `v' = subinstr(`v',". ","_",.) in 1
    rename `v' `=`v'[1]'
 }
drop in 1
format B %16s
drop JUN*
reshape long DEC_, i(B) j(year)
drop if B==""
rename B country
rename DEC_ `asset'
merge m:1 country using "$raw/dta/matching_iso_ifscode.dta" 
drop if _merge==2
drop _merge country_v2 ifscode
rename (our_code country) (our_code_orig country_v2)
merge m:1 country_v2 using "$raw/dta/matching_iso_ifscode.dta" 
drop if _merge == 2
drop _merge iso3
replace our_code_orig = our_code if our_code_orig == . & our_code != . 
replace our_code_orig = 9999 if country_v2=="SEFER + SSIO (**)"
drop if our_code_orig == . // rows with dataset notes
rename (our_code_orig country `asset') (source cname sum`asset'asset)
drop country_v2 our_code
destring sum`asset'asset, replace
save "$work/data_tot`asset'_update.dta", replace
 }
 
// gen adjustment factor for equity growth between June and December
import excel "$raw/IMF_2023_Table_15_All_Economies_Reported_Por_eq.xlsx", sheet("Table 15") clear
drop A
drop in 1
drop in 1
drop in 1

foreach v of varlist C - AG {
    replace `v' = subinstr(`v',". ","_",.) in 1
    rename `v' `=`v'[1]'
}
drop in 1
keep if B=="SEFER + SSIO (**)"|B=="Value of Total Investment"
drop DEC_200* 
drop DEC_2010 DEC_2011
drop DEC_2012

destring DEC* JUN*, replace
replace B="SEFER_SSIO" in 1
replace B="Total" in 2
forvalues j=2013(1)2021{
	gen adj_`j'=DEC_`j'/JUN_`j'
	}
keep B adj*
reshape long adj_, i(B) j(year) 
reshape wide adj_, i(year) j(B) string
save "$work/adjustfactor_cpis.dta", replace


// total liabilities
foreach liab in "eq" "debt"{
import excel "$raw/IMF_2023_International_Investment_Position_`liab'.xlsx", sheet("Annual") clear
*million USD
keep A-W
drop in 1
drop in 1
drop in 1
drop in 1
foreach v of varlist B - W {
	replace `v'="v_"+`v' in 1
       rename `v' `=`v'[1]'
}
drop in 1
reshape long v_, i(A) j(year)
drop if A==""
rename (A v_) (country `liab')
merge m:1 country using "$raw/dta/matching_iso_ifscode.dta" 
drop if _merge==2
drop _merge country_v2 ifscode iso3
rename (our_code country) (our_code_orig country_v2)
merge m:1 country_v2 using "$raw/dta/matching_iso_ifscode.dta" 
drop if _merge == 2
br if our_code == .
replace our_code = 355 if country_v2=="Curaçao, Kingdom of the Netherlands"
replace our_code=355 if country_v2=="Sint Maarten, Kingdom of the Netherlands"
replace our_code=186 if country_v2=="Türkiye, Rep. of"
replace our_code_orig = our_code if our_code != .
drop _merge our_code ifscode iso3 country
drop if our_code_orig == . // regions or non-existent countries
format country_v2 %12s
rename (our_code_orig country_v2 `liab') (host cname `liab'liab_IIP)
replace `liab'liab_IIP="" if `liab'liab_IIP=="..."
replace `liab'liab_IIP = subinstr(`liab'liab_IIP,"K", "", .)
replace `liab'liab_IIP= subinstr(`liab'liab_IIP,",", "", .)
sort `liab'liab_IIP
destring `liab'liab_IIP, replace
collapse (sum) `liab'liab_IIP, by(host year)
rename `liab'liab_IIP `liab'liab_IIP_host
save "$work\IIP_`liab'liab_host.dta", replace
collapse (sum) `liab'liab_IIP, by(year)
rename `liab'liab_IIP_host `liab'liab_IIP
save "$work/IIP_`liab'liab.dta", replace
}


//----------------------------------------------------------------------------//
// import U.S. data from TIC
//----------------------------------------------------------------------------//
// source: https://ticdata.treasury.gov/resource-center/data-chart-center/tic/Documents/slt_table1.txt
import delimited using "$raw\TIC_2022_foreign_portfolio_holdings_of_US_securities.csv", clear
keep v1-v5 v*3 v*4 v*5
gen nvals = _n
keep if nvals == 9 | nvals > 10
keep v1-v205

foreach var of varlist v*{
	replace `var' = subinstr(`var', "Total securities", "Total", .) in 2
		replace `var' = subinstr(`var', "Total long-term Debt", "Debtl", .) in 2
}
rename (v1 v2) (countryid country)
foreach v of varlist v* {
   local vname = strtoname(`v'[2])
   rename `v' `v'_`vname'
}

drop in 2

foreach var of varlist v*{
	replace `var' = subinstr(`var', "Jun ", "", .)
	replace `var' = subinstr(`var', "Mar ", "", .)
}


foreach v of varlist v* {
   local vname = strtoname(`v'[1])
   rename `v' `v'`vname'
}
drop in 1
drop if country == ""

rename v203_Total__1__2000 v203_Total_2000
tempfile TIC_sub
save `TIC_sub'

forvalues i = 2002/2021{
use `TIC_sub', clear
keep countryid country v*_`i'
gen group = `i'
rename v*_Total_`i' Total
rename v*_Equity_`i' Equity
rename v*_Debtl_`i' Debtl
tempfile TIC_sub_`i'
save `TIC_sub_`i''
}
use `TIC_sub', clear
keep countryid country v*_2000
gen group = 2000
rename v*_Total_2000 Total
rename v*_Equity_2000 Equity
rename v*_Debtl_2000 Debtl
*save "$temp\TIC_sub_2000.dta", replace
tempfile TIC_sub_2000
save `TIC_sub_2000'

forvalues i = 2002 / 2021{
append using `TIC_sub_`i''
}

generate str countryid_string = countryid
replace countryid = ""
compress countryid
replace countryid = countryid_string
drop countryid_string
replace Equity = subinstr(Equity,",", "", .)
replace Debt = subinstr(Debt,",", "", .)
replace Total = subinstr(Total,",", "", .)
destring Equity Debt Total, replace force
reshape wide Total Equity Debt, i(countryid country) j(group)

// 2001 is missing: take average of 2000 and 2002
gen Equity2001 = (Equity2000 + Equity2002) / 2
gen Debtl2001 = (Debtl2000 + Debtl2002) / 2
gen Total2001 = (Total2000 + Total2002) / 2
reshape long
gen flag_TIC = "2001 is estimated as the mean of 2000 and 2002" if group == 2001
rename group year
save "$work/data_TIC_update.dta", replace



//----------------------------------------------------------------------------//
// import China's assets
//----------------------------------------------------------------------------//
// 1. Public assets: est. 85-95% of foreign exchange reserves
import excel using "$raw/IMF_IIP_China.xlsx", sheet("Annual") clear
keep if A == "Other reserve assets" | B == "2004" | A == "Equity and investment fund shares" & A[_n-1] == "Portfolio investment" & A[_n-11] == "Assets" | A == "Debt securities" & A[_n-7] == "Portfolio investment" & A[_n-17] == "Assets"
keep A -S

foreach v of varlist B - S {
	forvalues k = 2004/2021{
		replace `v' = subinstr(`v',"`k'","v_`k'",.) in 1
	}
}

foreach v of varlist B - S {
   local vname = strtoname(`v'[1])
   rename `v' `vname'
}
drop in 1
replace A = "Equity" if A == "Equity and investment fund shares"
replace A = "Debt" if A == "Debt securities"
replace A = "Reserves" if A == "Other reserve assets"

reshape long v_, i(A) j(year)
replace v_=subinstr(v_,",","",.)
replace v_=subinstr(v_,"K ","",.)
destring v_, replace
reshape wide v_, i(year) j(A) string
rename v_* *_IMF

// foreign exchange reserves pre-2004
preserve
import excel using "$raw/IMF_2023_IFS_China_reserves.xlsx", clear
drop in 1
foreach v of varlist C-X{
   local vname = strtoname(`v'[1])
   rename `v' v`vname'
}
drop in 1
reshape long v_, i(A) j(year) string
drop A B
destring v_ year, replace
rename v_ reserves_2001
tempfile reserves_2001
save `reserves_2001'
restore
merge 1:1 year using `reserves_2001'
replace Reserves_IMF = reserves_2001 if year < 2004
drop *2001 _merge
drop if year > 2021
save "$work/data_IMF_China.dta", replace

//----------------------------------------------------------------------------//
// import foreign exchange data
//----------------------------------------------------------------------------//
import excel using "$raw/IMF_2023_IFS_Foreign_exchange.xlsx", clear
// International Reserves and Liquidity, Liquidity, Total Reserves excluding Gold, Foreign Exchange, US Dollar
drop B
drop in 1

foreach v of varlist C-X{
   local vname = strtoname(`v'[1])
   rename `v' v`vname'
}
drop in 1
reshape long v_, i(A) j(year) string
destring year v_, replace
rename v_ reserveIFS
rename A country

merge m:1 country using "$raw/dta/matching_iso_ifscode.dta" 
drop if _merge == 2
drop _merge country_v2 ifscode
rename (our_code country) (our_code_orig country_v2)
merge m:1 country_v2 using "$raw/dta/matching_iso_ifscode.dta" 
drop if _merge == 2
drop _merge iso3
replace our_code_orig = our_code if our_code_orig == . & our_code != . 
drop if our_code_orig == . // drop Bank Central Africa States (BEAC)
rename our_code_orig source
drop ifs* country*
drop if year>2021
save "$work/data_foreignexchange_update.dta", replace


//----------------------------------------------------------------------------//
// import TIC U.S. cross-border securities positions 
// (Bertaut and Judson 2001-2020 
// + new monthly TIC data for 2021f)
//----------------------------------------------------------------------------//

// link: https://www.federalreserve.gov/econres/ifdp/estimating-us-cross-border-securities-positions-new-data-and-new-methods.htm

	// U.S. long-term securities held by foreign residents
		// most recent
		import delimited "https://ticdata.treasury.gov/resource-center/data-chart-center/tic/Documents/slt_table1.txt", clear
		keep v1-v4 v7 v10 v13 v16 /*Holdings*/
		// for_lt_total_pos  "Total U.S. Securities"
		// for_lt_treas_pos "U.S. Treasuries"
		// for_lt_agcy_pos "U.S. Agency Bonds"
		// for_lt_corp_pos "U.S. Corp. & Other Bonds"
		// for_lt_eqty_pos "U.S. Corp. Equity"
		gen nvals = _n
		keep if nvals > 8
		drop nvals

		foreach v of varlist v* {
			local vname = strtoname(`v'[1])
			rename `v' `vname'
		}
		drop in 1
		split date, p(-)
		rename (date1 date2) (year month)
		drop date
		destring year month, replace
		keep if month == 6 | month == 12
		foreach var of varlist for_lt_*_pos {
			replace `var' = "." if `var' == "n.a."
		}
		destring for* country_code, replace
		drop if country_code == 72907 | country_code == 76929 // already included in 79995 "Total IROs"
		drop if country_code > 79995 & country_code < 99996
		rename country country_name
		tempfile TIC_liab_monthly_2020f
		save `TIC_liab_monthly_2020f'

		// 2011-2020
		import delimited "$raw/ifdp1113_data/bertaut_judson_positions_liabs_2021.csv", clear
		split date, p(/)
		drop date date2
		rename (date1 date3) (month year)
		destring month year, replace
		keep year month country_code country_name *est_pos month year
		rename ftot_* *
		keep if month == 6 | month == 12
		merge 1:1 country_code month year using `TIC_liab_monthly_2020f'
		sort country_code year month
		drop _merge
		tempfile TIC_liab_monthly_2011f
		save `TIC_liab_monthly_2011f'

		// 2001-2011
		import delimited "$raw/ticdata/ticdata.liabilities.ftot.txt", clear
		split date, p(/)
		drop date date2
		rename (date1 date3) (month year)
		destring month year, replace
		keep if month == 12 | month == 6
		keep if year > 2000
		keep countrycode countryname *est_pos month year
		foreach var of varlist ftot_agcy_est_pos ftot_corp_est_pos ftot_stk_est_pos ftot_treas_est_pos{
			replace `var' = "." if `var' == "        ND"
			destring `var', replace
		}
		rename (countryname countrycode) (country_name country_code)
		rename ftot_* *
		drop if year == 2011
		append using `TIC_liab_monthly_2011f'
		sort country_code year month

		replace for_lt_treas_pos=treas_est_pos if for_lt_treas_pos==.
		replace for_lt_agcy_pos=agcy_est_pos if for_lt_agcy_pos==.
		replace for_lt_corp_pos=corp_est_pos if for_lt_corp_pos==.
		replace for_lt_eqty_pos=stk_est_pos if for_lt_eqty_pos==.
		drop *_est_* for_lt_tot*
		rename for_lt_*_pos *
		gen debtl = treas + agcy + corp
		rename eqty equity
		label var debtl "long-term debt"
		keep country_code country_name year month equity debtl
		save "$work/TIC_liab_monthly_complete.dta", replace



//----------------------------------------------------------------------------//
// Cayman Islands
//----------------------------------------------------------------------------//

// TIC
use "$work/TIC_liab_monthly_complete.dta", clear
keep if country_code==36137 // Cayman Islands
keep if month==12
gen source=377
gen host=111
drop country_code country_name month
tempfile TIC_lt_monthly_Cayman_complete
save `TIC_lt_monthly_Cayman_complete'

// import TIC short-term debt for Cayman Islands
// source: https://ticdata.treasury.gov/resource-center/data-chart-center/tic/Documents/lb_36137.txt
import excel "$raw/TIC_US_Financial_Firms_Liabilities_Cayman.xlsx", clear
keep A B I J
rename (A B I J) (countrycode date shortterm_official shortterm_other)
drop in 1
drop in 1
split date, p(-)
keep if date2 == "12"
rename date1 year
keep shortterm* year
destring *, replace
egen shortterm_debt = rowtotal (shortterm_official  shortterm_other)
keep year shortterm_debt
merge 1:1 year using `TIC_lt_monthly_Cayman_complete'
drop _merge

// Data are unavailable prior to 2003, so for 2001 and 2002 Zucman (2013) uses the 2003 figure and the percent change of U.S. long term debt liabilities vis-a-vis the Cayman Islands.
replace shortterm_debt = 4712 if year == 2001
replace shortterm_debt = 11018 if year == 2002
gen debt = shortterm + debtl
sort year
rename (shortterm_debt debtl equity debt) (debts_KY_TIC debtl_KY_TIC eq_KY_TIC debt_KY_TIC)
save "$work/Cayman_TIC_Dec.dta", replace

// CPIS banking and insurance holdings
import excel "$raw/IMF_2023_assets_Cayman_banking.xlsx", clear
drop in 1
drop in 1
foreach v of varlist B - R {
 forvalues k = 2004/2021{
 replace `v' = subinstr(`v',"Dec. `k'","v_`k'",.) in 1
 }
}
foreach v of varlist B - R {
   local vname = strtoname(`v'[1])
   rename `v' `vname'
}
drop in 1
reshape long v_, i(A) j(year)
destring v_, replace
rename v_ bank
tempfile KY_banks
save `KY_banks'

import excel "$raw/IMF_2023_assets_Cayman_ins.xlsx", clear
drop in 1
drop in 1
foreach v of varlist B - G {
 forvalues k = 2016/2021{
 replace `v' = subinstr(`v',"Dec. `k'","v_`k'",.) in 1
 }
}
foreach v of varlist B - G {
   local vname = strtoname(`v'[1])
   rename `v' `vname'
}
drop in 1
reshape long v_, i(A) j(year)
destring v_, replace
rename v_ ins
merge 1:1 year using `KY_banks'
drop _merge
sort year
gen KY_assets_bank = ins + bank
replace KY_assets = bank if ins==.
keep year KY_assets
gen host = 377
save "$work/KY_banks.dta", replace


// estimate equity liabilities of non-financial corporations located in Cayman islands
use "$raw/dta/xrates.dta", clear

gen currency = ""
replace c = "USD" if B == "United States"
replace c = "AUD" if B == "Australia"
replace c = "BRL" if B == "Brazil"
replace c = "CNY" if B == "China, P.R.: Mainland"
replace c = "EUR" if B == "Euro Area"
replace c = "GBP" if B == "United Kingdom"
replace c = "HKD" if B == "China, P.R.: Hong Kong"
replace c = "ILS" if B == "Israel"
replace c = "JPY" if B == "Japan"
replace c = "KRW" if B == "Korea, Rep. of"
replace c = "MXN" if B == "Mexico"
replace c = "NOK" if B == "Norway"
replace c = "SGD" if B == "Singapore"
replace c = "TWD" if B == "Taiwan Province of China"
drop if c == ""
tempfile xrates
save `xrates'


import delimited "$raw/compustat_cayman.csv", parselocale(en_US) clear 	

// loc = hedquarter
// cshoc = number of common shares outstanding
// prccd = end-of-day price
// curcdd = currency of price
// gvkey = identifier of company
// iid = identifier of stock issue (multiple issues per stock)
	
// Create market value	
gen mktcap = cshoc * prccd

// Keep one issue per share
gen issue = substr(iid, 1, 2)
destring issue, replace
tab issue
// Note: >= 90 = ADR: we drop them
drop if issue >= 90
// Keep only first issue of each stock
gsort gvkey datadate issue 
duplicates drop  gvkey datadate, force

// Keep only end-of-year observations
gen year = substr(datadate, 1, 4)
destring year, replace
gen month = substr(datadate, 6, 2)
destring month, replace
keep if month == 12

// Number of firms per year: rising from <100 in 2001 to 1750 in 2022
tab year

// Merge with year-end exchange rates to US$ and compute total US$ market cap at year-end
tab curcdd
rename curcdd currency
drop if currency == "" & cshoc == . & prccd == .
merge m:1 currency year using `xrates'
drop if _merge == 2
drop _merge
gen mktcap_usd = mktcap / xrate
collapse (sum) mktcap_usd , by(year)
gen eqliab_nfc = 0.75 * mktcap_usd
save "$work/KY_liab_nfc.dta", replace


//----------------------------------------------------------------------------//
// China's liabilities
//----------------------------------------------------------------------------//

// long-term
use "$work/TIC_liab_monthly_complete.dta", clear
keep if country_code == 41408
keep if month == 12
tempfile TIC_longterm_monthly_China
save `TIC_longterm_monthly_China'

// short term
 // short-term 2003-2023
	import excel "$raw/TIC_US_Financial_Firms_Liabilities_China.xlsx", clear
	keep A B I J
	rename (A B I J) (countrycode date shortterm_official shortterm_other)
	drop in 1
	drop in 1
	split date, p(-)
	keep if date2=="12"
	rename date1 year
	keep shortterm* year
	destring *, replace
	egen shortterm_debt = rowtotal (shortterm_official  shortterm_other)
	keep year shortterm_debt
	tempfile TIC_China_short
	save `TIC_China_short'

	// short term 2001-2003
	import excel "$raw/TIC_US_Financial_Firms_Liabilities_China.xlsx", sheet("before2003") clear
	keep A B I J
	rename (A B I J) (countrycode date shortterm_official shortterm_other)
	drop in 1
	drop in 1
	split date, p(-)
	keep if date2=="12"
	rename date1 year
	keep shortterm* year
	destring year, replace
	keep if year > 2000
	destring *, replace
	egen shortterm_debt = rowtotal(shortterm_official  shortterm_other)
	keep year shortterm_debt
	append using `TIC_China_short'
	sort year

// merge
merge 1:1 year using `TIC_longterm_monthly_China'
drop _merge
gen source = 924 // ifs country code for China
gen host = 111 // ifs country code for USA

// total liabilities
gen total_China_TIC = equity + debtl + shortterm_debt
label var total_China_TIC "total securities est. based on TIC"
gen total_lt_China_TIC = equity + debtl
label var total_lt_China_TIC "total long term securities -TIC"
rename equity eq_China_TIC 
label var eq_China "equity TIC"
rename debtl debtl_China_TIC
label var debtl_China_TIC "long-term debt securities - TIC"
rename shortterm_debt debts_China_TIC
label var debts_China_TIC "short-term debt securities - TIC"
gen debt_China_TIC = debtl_China_TIC + debts_China_TIC
save "$work/TIC_China_Dec.dta", replace


//----------------------------------------------------------------------------//
// Assets of Middle Eastern Oil Exporters
//----------------------------------------------------------------------------//

// Note: Bertaut & Judson report for "Middle Eastern Oil Exporters" on aggregate. In 2010 reporting switches to country-level but comprises only Kuwait and Saudi Arabia -> we switch to TIC June series after 2010 to include all Middle East oil exporters and need to make an adjustment for equity growth between June and December)
use "$work/data_TIC_update.dta", clear
keep if country == " Middle Eastern Oil Exporters" | country == "Kuwait" | country == "Saudi Arabia" | country == "Bahrain" | country == "Iran" | country == "Iraq" | country == "Oman" | country == "Qatar" |country == "United Arab Emirates"
save "$work/TIC_update_middleast.dta", replace
collapse (sum) Total (sum) Equity (sum) Debtl, by(year)
tempfile TIC_update_middleeast_total
save `TIC_update_middleeast_total'

// calculate short-term long-term ratio of foreign official institutions' holdings of U.S. securities
	//import short-term liabilities of foreign official institutions
	// source: https://ticdata.treasury.gov/resource-center/data-chart-center/tic/Documents/bltype_history.txt
	import delimited "$raw/tic_historic/bltype_history.csv", clear
	keep v1 v6 v7 // ST Treas securities held by FOI [5] + Oth ST Neg secs held by FOI [6]
	split v1, p(-)
	drop v1
	destring v11, replace
	rename v11 year
	drop if year == .
	rename v12 month
	keep if month == "Dec" | month == "Jun"
	destring v6, replace
	destring v7, replace
	egen shortterm_FOI = rowtotal (v6 v7)
	keep year month shortterm_FOI
	keep if year > 2000
	replace month = "12" if month == "Dec"
	replace month = "6" if month == "Jun"
	destring month, replace
	save "$work/TIC_shortterm_FOI.dta", replace

	// import long-term liabilities of foreign official institutions (FOI) -> from Bertaut & Judson 
		// 2001-2011
		import delimited "$raw/ticdata/ticdata.liabilities.foiadj.txt", clear
		keep date foi_*_est_pos
		egen longterm_debt_FOI=rowtotal(foi_agcy* foi_corp* foi_treas*)
		egen longterm_FOI = rowtotal(foi_agcy* foi_corp* foi_treas* foi_stk)
		split date, p(/)
		keep if date1 == "12" | date1 == "06"
		replace date1 = "6" if date1 == "06"
		rename date3 year
		rename date1 month
		destring year, replace
		keep if year > 2000
		drop date date2
		rename *_est_pos *
		tempfile TIC_longterm_FOI_2001_11
		save `TIC_longterm_FOI_2001_11'

		// 2011f
		import delimited "$raw/tic_historic/slt2d_history.csv", clear
		keep v1 v3 v6 v9 v14 v27 /*Holdings of foreign official institutions*/
		rename (v3 v6 v9 v14 v27) (foi_total foi_treas foi_agcy foi_corp foi_stk)
		gen nvals = _n
		keep if nvals > 17
		drop nvals
		split v1, p(-)
		drop v1
		rename (v11 v12) (year month)
		destring year, replace
		drop if year==.
		keep if month == "Jun" | month == "Dec"
		replace month = "6" if month == "Jun"
		replace month = "12" if month == "Dec"
		destring foi*, replace
		append using `TIC_longterm_FOI_2001_11'
		destring month, replace
		sort year month
		replace longterm_FOI = foi_total if longterm_FOI == .
		drop foi_total longterm_debt
		merge 1:1 year month using "$work/TIC_shortterm_FOI.dta"
		drop _merge
		tempfile TIC_liabs_monthly_FOIs
		save `TIC_liabs_monthly_FOIs'


	// gen short_long_ratio=shortterm/longterm_debt
	gen short_long_ratio = shortterm / longterm_FOI
	keep if month == 12
	keep year month longterm_FOI short_long_ratio
	save "$work/shortterm_ratio_FOI.dta", replace


	// compute adjustment ratio based on TIC reporting for Saudi Arabia & Kuwait to uprate June values to December (because we switch from December to June reporting for Middle Eastern Oil Exporters after 2010)
	use "$work/TIC_liab_monthly_complete.dta", clear
	keep if country_code == 46612 | country_code == 45608 | country_code == 43109 | country_code == 46604
	gen help = 1 if country_code == 46612 /*Middle East aggregate*/
	replace help = 0 if help == .
	collapse (sum) equity, by(year month help)
	reshape wide equity, i(year help) j(month)
	gen adj_eq = equity12 / equity6
	keep if help == 0 //drop Middle East aggregate available only before 2011
	keep year adj*
	tempfile adjustfactor
	save `adjustfactor'

	// generate adjustment ratio based on International Organisations' assets to uprate June values to December because data for Saudi Arabia and Kuwait starts only in 2012
	use `TIC_liabs_monthly_FOIs', clear
	keep year month foi_stk
	reshape wide foi_stk, i(year) j(month)
	gen adj_eq=foi_stk12/foi_stk6
	keep year adj*
	label var adj_eq "adjusts reporting period from 6 to 12 based on US liabilities to FOIs"
	rename adj_eq adj_eq_foiUS
	merge 1:1 year using `adjustfactor'
	replace adj_eq = adj_eq_foiUS if year == 2011
	keep year adj_eq
	save "$work/adjust_period.dta", replace


// extract middle east aggregate from Bertaut & Judson
// Zucman (2013) uses December values for 2001-2010 and switches to June afterwards because Bertaut & Judson middle east aggregate is discontinued
use "$work/TIC_liab_monthly_complete.dta", clear
keep if country_name==" Middle Eastern Oil Exporters"
keep if month==12
rename country_name country
rename eq Equity
rename debtl Debtl
gen Total = Equity + Debtl
save "$work/Bertaut_Judson_middleeast_Dec.dta", replace



//----------------------------------------------------------------------------//
// BIS securities of international organizations
//----------------------------------------------------------------------------//

import delimited using "$raw/BIS_2023_table-c1.csv", clear
keep v2 v4 v6 v234-v321
keep if v6=="Issue market"|v6=="C:International markets"
keep if v4=="Issuer sector - immediate borrower"|v4=="1:All issuers"
keep if v2=="Issuer residence"|v2=="1C:International organisations"|v2=="KY:Cayman Islands"|v2=="BS:Bahamas"|v2=="BM:Bermuda"|v2=="CW:Curacao"|v2=="LI:Liechtenstein"

rename v2 A
drop v4 v6

foreach var of varlist v*{
	replace `var'="v_"+`var' in 1
}

foreach v of varlist v* {
	   local vname = strtoname(`v'[1])
   rename `v' `vname'
}
drop in 1


reshape long v, i(A) j(date) string
split date, p(_)
drop date date1 date2
keep if date3=="12"
drop date3
rename date4 year
destring year, replace
rename v total_debt_BIS
replace total_debt_BIS="." if total_debt_BIS==""
replace total_debt_BIS="." if total_debt_BIS=="..."

destring total_debt_BIS, replace
gen host=9998 if A=="1C:International organisations"
replace host=377 if A=="KY:Cayman Islands"
replace host=313 if A=="BS:Bahamas"
replace host=319 if A=="BM:Bermuda"
replace host=355 if A=="CW:Curacao"
replace host=9006 if A=="LI:Liechtenstein"
drop A
tempfile BIS_total_debt
save `BIS_total_debt'
keep if host==9998
save "$work/BIS_total_debt_IO.dta", replace
use `BIS_total_debt'
drop if host==9998
save "$work/BIS_total_debt_ofc.dta", replace

//----------------------------------------------------------------------------//
// Dutch SFIs
//----------------------------------------------------------------------------//

// assets
import delimited "$raw/DNB_2023_Cross-border_securities_holdings_(Quarter).csv", clear
keep if hoofdpost == "Dutch portfolio investment in foreign securities "
keep if subpost1 == "Foreign equity and shares in foreign investment funds "| subpost1=="Foreign debt securities "

preserve
	keep if subpost2 == "Total " | subpost2 == "Long term foreign debt securities " | subpost2 == "Short term foreign debt securities "
	sort subpost2 sector
	keep if sector == "Total " & subpost1 == "Foreign equity and shares in foreign investment funds " | sector != "Total " & subpost1 =="Foreign debt securities "
	drop if sector == "Other sectors " & subsector == "Total "
	drop if label7 == "Of which SFIs "
	collapse (sum) waarde (first) subpost1, by(subpost2 period)
	split period, p(Q)
	rename (period1 period2) (year quarter)
	destring year, replace
	drop period
	collapse (sum) waarde , by(subpost1 year quarter)
	replace subpost1 = "debt" if subpost1 == "Foreign debt securities "
	replace subpost1 = "equity" if subpost1 != "debt"
	reshape wide waarde, i(year quarter) j(subpost1) string
	rename (waardedebt waardeequity) (debt equity)
	keep if quarter == "4"
	tempfile DNB
	save `DNB'
restore

// SFIs
keep if subpost2 == "Foreign equity " | subpost2 == "Long term foreign debt securities " | subpost2 == "Short term foreign debt securities "
keep if label7 == "Of which SFIs "
split period, p(Q)
rename (period1 period2) (year quarter)
destring year, replace
drop period
collapse (first) label7  (sum) waarde, by(subpost1 year quarter)
gen var = "equity_SFI" if subpost1 == "Foreign equity and shares in foreign investment funds "
replace var = "debt_SFI" if subpost1 == "Foreign debt securities "
drop subpost1 label7
reshape wide waarde, i(year quarter) j(var) string
rename (waardedebt_SFI waardeequity_SFI) (debt_SFI equity_SFI)
keep if quarter == "4"
merge 1:1 year using `DNB'
drop _merge

preserve
	use "$raw/dta/xrates.dta", clear
	keep if B == "Euro Area"
	tempfile eur
	save `eur'
restore
	merge 1:1 year using `eur'
	drop _merge
save "$work/DNB_assets.dta", replace
rename (debt equity) (debt_NL equity_NL)
foreach var of varlist debt_SFI debt_NL equity_SFI equity_NL{
	replace `var'=`var'/xrate
}
keep year *SFI *NL
keep if year < 2015
gen source = 138
save "$work/DNB_assets.dta", replace


//----------------------------------------------------------------------------//
