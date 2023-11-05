* ==============================================================================
* Date: August 2023
* Paper: Global Offshore Wealth, 2001-2021
*
* This program scraps BIS locational banking statistics (October 2023)
*
* databases used: - WS_LBS_D_PUB_csv_col.csv
*                 - isocodes.xlsx
*
* outputs:        - locational.dta      
*
* ==============================================================================

********************************************************************************
****** I ---- Scrapping and cleaning of BIS locational banking stats -----******
********************************************************************************

// import online BIS banking statistics
copy "https://www.bis.org/statistics/full_lbs_d_pub_csv.zip" ///
"$raw/locational.zip", replace
cd "$raw"
unzipfile "$raw/locational.zip", replace
erase "$raw/locational.zip"
insheet using "$raw/WS_LBS_D_PUB_csv_col.csv", clear

// note:  Q:S:C:D:USD:F:GB:A:DE:N:FR:N
// refers to quarterly (Q) outstanding (S) claims (C) of debt securities
// (D) denominated in USD (USD) as a foreign currency (F) 
// by British (GB) banks (A) in Germany (DE) vis-a-vis non-banks (N) 
// in France (FR), which are cross border positions (N).

// harmonize deposits value variables names
rename q3 v35
rename q2 v34 
rename q1 v33 
rename q4 v32


// transform value variables names in the following form "value'quarter''year'"
local q=4
local y=1977
foreach var of varlist v* {
rename `var' value`q'_`y'
if `q'<4 {
local q=`q'+1
}
else {
local q=1
local y=`y'+1
}
}

// keep only quarterly, outstanding, all currency, in bank, hold by non-bank 
keep if freq == "Q"
drop freq
keep if l_measure == "S"
drop l_measure
keep if l_denom == "TO1"
drop l_denom
keep if l_curr_type == "A"
drop l_curr_type
keep if l_rep_bank_type == "A"
drop l_rep_bank_type
keep if l_pos_type == "N"
drop l_pos_type

// reshape the data to one deposit value line per quarter 
fastreshape long value, i(series) j(quarter) string

// adjustments
gen year = substr(quarter,-4,4)
replace quarter=substr(quarter,1,2)
replace quarter=substr(quarter,1,1) if quarter!="12"
destring(quarter year), replace
destring(value), replace  i(NaN)
sort year quarter position l_rep_cty l_cp_country
rename l_rep_cty bank
rename l_cp_country counter
rename series code
rename l_cp_sector sector 
rename l_parent_cty parent 
rename l_position position 
rename l_instr instrument
order quarter year instrument position parent bank sector counter value code

format position instrument position bank sector counter parent  %5s
compress
save "$work/locational.dta", replace

// Add iso-3 to BIS locational banking stats counterparty countries
import excel "$raw/isocodes.xlsx", sheet(iso) firstrow clear
rename iso2 counter
merge 1:m counter using "$work/locational.dta", nogenerate keep(2 3)
rename isoname namecounter
rename iso3 iso3counter
order namecounter counter iso3counter
save "$work/locational.dta", replace

// Add iso-3 to BIS locational banking stats reporting countries
import excel "$raw/isocodes.xlsx", sheet(iso) firstrow clear
rename iso2 bank
merge 1:m bank using "$work/locational.dta", nogenerate keep(2 3)
rename isoname namebank
rename iso3 iso3bank
order namebank bank iso3bank
format name* %20s
replace namebank = "All BIS-reporting banks" if bank == "5A"
replace namecounter = "All" if counter == "5J"
save "$work/locational.dta", replace