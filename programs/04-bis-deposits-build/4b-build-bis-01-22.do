* ==============================================================================
* Date: October 2023
* Paper: Global Offshore Wealth, 2001-2021
*
* This program constructs bilateral non-bank and interbank deposits 
* spanning 2001 to 2022.
*
* databases used: - locational.dta
*                 - FGZ-raw-data.xlsx
*
* outputs:        - bis-deposits-all-01-22.dta
*                 - bis-interbank-all-01-22.dta      
*
* ==============================================================================

********************************************************************************
**** I - Creating BIS vis-a-vis non-bank counterparties only, 2001-2023 --*****
********************************************************************************

use "$work/locational.dta", clear
rename counter saver
rename value dep

* Keep non bank, liabilities, all instruments, all parent countries
keep if sector == "N" & position == "L" & instrument == "A" & ///
		parent == "5J" & year >= 2001 
	
* mean amount unstanding over quarters
collapse (mean) dep, by(bank year saver)

* drop BIS aggregates
drop if ///
saver == "5R" | saver == "4W" | saver == "4Y" | saver == "3C" | ///
saver == "4U" | saver == "4T" | saver == "2D" | saver == "2C" | ///
saver == "2T" | saver == "2S" | saver == "5M" | saver == "2T" | ///
saver == "2R" | saver == "5C" | saver == "2R" | saver == "5K" | ///
saver == "4L" | saver == "2B" | saver == "2H" | saver == "2O" | ///
saver == "2W" | saver == "2N" | saver == "1C" | saver == "2U" | ///
saver == "2Z"

* We add French Southern Territories to France,
* Greenland to Denmark, Montserrat and Anguilla to British Overseas
reshape wide dep, i(year bank) j(saver) string
egen depFRX = rowtotal(depFR depTF), missing
replace depFR = depFRX 
drop depFRX depTF
egen dep1WX = rowtotal(depAI dep1W depMS), missing
replace dep1W = dep1WX 
drop dep1WX depAI depMS
egen depDKX = rowtotal(depGL depDK), missing
replace depDK = depDKX
drop depDKX depGL 
reshape long dep, i(year bank) j(saver) string

* Create 1R residual countries (all reporting - countries with bilateral data)
reshape wide dep, i(year saver) j(bank) string 
egen negative1R = rowtotal(depAT depAU depBE depBR depCA depCH depCL ///
depDE depDK depES depFI depFR depGB depGG depGR depHK depIE depIM depIT ///
depJE depJP depKR depLU depMO depMX depNL depPH depSE depTW depUS depZA), missing
gen dep1R = dep5A - negative1R

* Some countries don't disclose bilateral deposits for some years
replace dep1R = dep1R + depHK if year <= 2014 & saver == "5J"
replace dep1R = dep1R + depES if year == 2013 & saver == "5J"
replace dep1R = dep1R + depIT if year <= 2009 & saver == "5J"
replace dep1R = dep1R + depAT + depCA if year <= 2006 & saver == "5J"
drop negative1R
replace dep1R = 0 if dep1R < 0

* Compute shares in the residual aggregate
gen share = 0
forvalues y = 2001/2023 {
sum(dep1R) if saver ~= "5J" & year == `y'
local dep_sum1R`y' = r(sum)
replace share = dep1R/`dep_sum1R`y'' if year == `y'
replace share = 1 if saver == "5J" & year == `y'	
}

*Shares seen in the residual to allocate amount of havens without bilateral data
forvalues i=2001/2023 {
foreach ctry in AN PA MY BH BM BS CW SG {
	preserve
	keep dep`ctry' year saver
	keep if year == `i' & saver == "5J"
	local Alldep`ctry'`i' = dep`ctry'
	restore 
	}
	}

forvalues i = 2001/2014{
	preserve
	keep depHK year saver
	keep if year == `i' & saver == "5J"
	local AlldepHK`i' = depHK
	restore 
}

forvalues i = 2001/2002 {
 	preserve
	keep depMO year saver
	keep if year == `i' & saver == "5J"
	local AlldepMO`i' = depMO
	restore 
}
	
forvalues i=2001/2023 {
	foreach ctry in AN PA MY BH BM BS CW SG {
		replace dep`ctry' =  `Alldep`ctry'`i''*share ///
		if year == `i' & saver ~= "5J"
		}
		}

forvalues i =2001/2014{
	replace depHK =  `AlldepHK`i''*share ///
	if year == `i' & saver ~= "5J"
}

forvalues i =2001/2002{
replace depMO =  `AlldepMO`i''*share ///
if year == `i' & saver ~= "5J"
}

reshape long dep, i(year saver) j(bank) string
order year bank saver dep
sort bank saver year 
drop share

* Add Cayman Islands, assumes 100% is held in the US
gen share_KY = 0
replace share_KY = 1 if saver == "US" & bank == "KY" & saver ~= "5J"

forvalues i=2001/2023 {
preserve 
keep if bank == "KY" & year == `i' & saver == "5J"
local AlldepKY`i' = dep
restore
}

forvalues i=2001/2023 {
replace dep = share_KY* `AlldepKY`i'' ///
if bank == "KY" & saver ~= "5J" & year == `i'
}
drop share_KY

* Assume Bermuda, Chile and Panama deposits in 2001 equal those in 2002 
foreach b in CL PA BM {
drop if bank == "`b'" & year == 2001
preserve 
keep if bank == "`b'" & year == 2002
replace year = 2001
tempfile deposits`b'
save "`deposits`b''", replace
restore
append using "`deposits`b''"
}

* Construct Haven aggregate 1N (Bahamas, Bahrain, Bermuda, Cayman, Guernsey, 
* HK, Isle of Man, Jersey, Macao, Neth Antilles, Panama, Singapore) 
reshape wide dep, i(year saver) j(bank) string
egen dep1N = rowtotal(depAN depBH depBM depBS depCW depKY depGG  ///
depHK depIM depJE depMO depPA depSG), missing
tempfile bis
save `bis'
import excel "$raw/FGZ-raw-data.xlsx", ///
clear firstrow cellrange(A3:W25) sheet(sharehouseholddep)
merge 1:m year using "`bis'", nogenerate
foreach bank in GG IM JE LU AT BE GB AN CW {
		gen adjusted_dep`bank' = `bank'*dep`bank' 
		drop `bank'
}
egen depEU = rowtotal(adjusted_depGG adjusted_depIM adjusted_depJE ///
adjusted_depLU adjusted_depAT adjusted_depBE adjusted_depGB depCY), missing
drop adjusted*

* Cyprus started reporting in 2008; assumes follows EU havens backwards
forvalues y= 2007(-1)2001 {
	local y_1 = `y' + 1
	preserve
	keep if saver == "5J" & year == `y_1'
	keep depEU 
	local EUdeposits = depEU
	restore
	preserve
	keep if saver == "5J" & year == `y_1'
	keep depCY
	local CYdeposits = depCY
	restore
	replace depCY = (`CYdeposits'*depEU)/`EUdeposits' ///
	if saver == "5J" & year == `y'
	}
drop depEU BH BM CH CL BS CY HK KY MO MY PA SG US

reshape long dep, i(year saver) j(bank) string

* Allocate Cyprus; assumes Russia = 90%, Greece = 10%
gen share_CY = 0
replace share_CY = 0.9 if saver == "RU" & bank == "CY"
replace share_CY = 0.1 if saver == "GR" & bank == "CY"

forvalues i=2001/2023 {
preserve 
keep if bank == "CY" & year == `i' & saver == "5J"
local AlldepCY`i' = dep
restore
}

forvalues i=2001/2023 {
replace dep = share_CY* `AlldepCY`i'' ///
if bank == "CY" & year == `i' & saver ~= "5J"
}
drop share_CY

* offshore financial center binary
gen OFC = 0
replace OFC = 1 if ///
saver == "1Z" | saver == "AD" | saver == "1W" | saver == "AN" | ///
saver == "AW" | saver == "BB" | saver == "BH" | saver == "BM" | ///
saver == "BQ" | saver == "BS" | saver == "BZ" | saver == "CH" | ///
saver == "CR" | saver == "CW" | saver == "CY" | saver == "DM" | ///
saver == "GD" | saver == "GG" | saver == "GI" | saver == "HK" | ///
saver == "IE" | saver == "IM" | saver == "JE" | saver == "KN" | ///
saver == "KY" | saver == "LB" | saver == "LC" | saver == "LI" | ///
saver == "LR" | saver == "LU" | saver == "MH" | saver == "MO" | ///
saver == "MS" | saver == "MT" | saver == "MU" | saver == "MY" | ///
saver == "NR" | saver == "PA" | saver == "PW" | saver == "SC" | ///
saver == "SG" | saver == "SX" | saver == "TC" | saver == "VC" | ///
saver == "VU" | saver == "WS"

* drop deposits held by household in the same country
drop if bank == saver

* labels
label var bank "Reporting country"
label var saver "Counterparty country"
label var dep "Non-bank deposits, liabilities side"
label var OFC "Offshore financial centres"

order year bank saver dep OFC
sort bank saver year 	
save "$work/bis-deposits-all-01-22.dta", replace

********************************************************************************
****** II - Creating BIS vis-a-vis all counterpart sectors, 2001-2023 --*******
********************************************************************************

use "$work/locational.dta", clear
rename counter saver
rename value totdep

* Keep non bank, liabilities, all instruments, all parent countries
keep if sector == "A" & position == "L" & instrument == "A" & parent=="5J" ///
& year >= 2001

* mean amount unstanding over quarters
collapse (mean) totdep, by(bank year saver)

* drop BIS aggregates
drop if ///
saver == "5R" | saver == "4W" | saver == "4Y" | saver == "3C" | ///
saver == "4U" | saver == "4T" | saver == "2D" | saver == "2C" | ///
saver == "2T" | saver == "2S" | saver == "5M" | saver == "2T" | ///
saver == "2R" | saver == "5C" | saver == "2R" | saver == "5K" | ///
saver == "4L" | saver == "2B" | saver == "2H" | saver == "2O" | ///
saver == "2W" | saver == "2N" | saver == "1C" | saver == "2U" | ///
saver == "2Z"

* We add French Southern Terriotories to France
reshape wide totdep, i(year bank) j(saver) string
egen totdepFRX = rowtotal(totdepFR totdepTF), missing 
replace totdepFR = totdepFRX 
drop totdepFRX
drop totdepTF
egen totdep1WX = rowtotal(totdepAI totdep1W totdepMS), missing
replace totdep1W = totdep1WX 
drop totdep1WX totdepAI totdepMS
egen totdepDKX = rowtotal(totdepGL totdepDK), missing
replace totdepDK = totdepDKX
drop totdepDKX totdepGL 
reshape long totdep, i(year bank) j(saver) string

* Create 1R residual countries (all reporting - countries with bilateral data)
reshape wide totdep, i(year saver) j(bank) string 
egen negative1R = rowtotal(totdepAT totdepAU totdepBE totdepBR totdepCA /// 
totdepCH totdepCL totdepDE totdepDK totdepES totdepFI totdepFR totdepGB /// 
totdepGG totdepGR totdepHK totdepIE totdepIM totdepIT totdepJE totdepJP ///
totdepKR totdepLU totdepMO totdepNL totdepPH totdepSE totdepTW totdepUS ///
totdepZA), missing
gen totdep1R = totdep5A - negative1R

* Some countries don't disclose bilateral deposits for some years
replace totdep1R = totdep1R + totdepHK if year <= 2014 & saver == "5J"
replace totdep1R = totdep1R + totdepES if year == 2013 & saver == "5J"
replace totdep1R = totdep1R + totdepIT if year <= 2009 & saver == "5J"
replace totdep1R = totdep1R + totdepAT + totdepCA ///
if year <= 2006 & saver == "5J"
drop negative1R
replace totdep1R = 0 if totdep1R < 0

* Compute shares in the residual aggregate
gen share = 0
forvalues y = 2001/2023 {
sum(totdep1R) if saver ~= "5J" & year == `y'
local totdep_sum1R`y' = r(sum)
replace share = totdep1R/`totdep_sum1R`y'' if year == `y'
replace share = 1 if saver == "5J" & year == `y'	
}

*Shares seen in the residual to allocate amount of havens without bilateral data
forvalues i=2001/2023 {
foreach ctry in AN PA MY BH BM BS CW SG {
	preserve
	keep totdep`ctry' year saver
	keep if year == `i' & saver == "5J"
	local Alltotdep`ctry'`i' = totdep`ctry'
	restore 
}
}


forvalues i = 2001/2014 {
		preserve
		keep totdepHK year saver
		keep if year == `i' & saver == "5J"
		local AlltotdepHK`i' = totdepHK
		restore 
}

forvalues i = 2001/2002 {
 	preserve
	keep totdepMO year saver
	keep if year == `i' & saver == "5J"
	local AlltotdepMO`i' = totdepMO
	restore 
}	

forvalues i=2001/2023 {
foreach ctry in AN PA MY BH BM BS CW SG {
replace totdep`ctry' =  `Alltotdep`ctry'`i''*share ///
if year == `i' & saver ~= "5J"
}
}

forvalues i =2001/2014{
	replace totdepHK =  `AlltotdepHK`i''*share ///
	if year == `i' & saver ~= "5J"
}

forvalues i =2001/2002{
replace totdepMO =  `AlltotdepMO`i''*share ///
if year == `i' & saver ~= "5J"
}

reshape long totdep, i(year saver) j(bank) string
order year bank saver totdep
sort bank saver year 
drop share

* Allocate Cayman Islands, assumes 100% is held in the US
gen share_KY = 0
replace share_KY = 1 if saver == "US" & bank == "KY"

forvalues i=2001/2023 {
preserve 
keep if bank == "KY" & year == `i' & saver == "5J"
local AlltotdepKY`i' = totdep
restore
}

forvalues i=2001/2023 {
replace totdep = share_KY* `AlltotdepKY`i'' ///
if bank == "KY" & saver ~= "5J" & year == `i'
}
drop share_KY

* Assume Bermuda, Chile and Panama deposits in 2001 equal those in 2002
foreach b in CL PA BM {
drop if bank == "`b'" & year == 2001
preserve 
keep if bank == "`b'" & year == 2002
replace year = 2001
tempfile share`b'
save "`share`b''", replace
restore
append using "`share`b''"
}

* Construct Haven aggregate 1N (Bahamas, Bahrain, Bermuda, Cayman, Guernsey, 
* HK, Isle of Man, Jersey, Macao, Neth Antilles, Panama, Singapore) 
reshape wide totdep, i(year saver) j(bank) string
egen totdep1N = rowtotal(totdepAN totdepBH totdepBM totdepBS totdepCW ///
totdepKY totdepGG totdepHK totdepIM totdepJE totdepMO totdepPA totdepSG ///
), missing

* gen EU havens
egen totdepEU = rowtotal(totdepGG totdepIM totdepJE totdepLU totdepAT ///
totdepBE totdepGB totdepCY), missing

* Cyprus started reporting in 2008; assumes follows EU havens backwards
forvalues y= 2007(-1)2001 {
local y_1 = `y' + 1
preserve
keep if saver == "5J" & year == `y_1'
keep totdepEU 
local EUdeposits = totdepEU
restore
preserve
keep if saver == "5J" & year == `y_1'
keep totdepCY
local CYdeposits = totdepCY
restore
replace totdepCY = (`CYdeposits'*totdepEU)/`EUdeposits' ///
if saver == "5J" & year == `y'
}
drop totdepEU 

reshape long totdep, i(year saver) j(bank) string

* Allocate Cyprus; assumes Russia = 90%, Greece = 10%
gen share_CY = 0
replace share_CY = 0.9 if saver == "RU" & bank == "CY"
replace share_CY = 0.1 if saver == "GR" & bank == "CY"

forvalues i=2001/2023 {
preserve 
keep if bank == "CY" & year == `i' & saver == "5J"
local AlltotdepCY`i' = totdep
restore
}

forvalues i=2001/2023 {
replace totdep = share_CY* `AlltotdepCY`i'' ///
if bank == "CY" & year == `i' & saver ~= "5J"
}
drop share_CY

* offshore financial center binary
gen OFC = 0
replace OFC = 1 if ///
saver == "1Z" | saver == "AD" | saver == "1W" | saver == "AN" | ///
saver == "AW" | saver == "BB" | saver == "BH" | saver == "BM" | ///
saver == "BQ" | saver == "BS" | saver == "BZ" | saver == "CH" | ///
saver == "CR" | saver == "CW" | saver == "CY" | saver == "DM" | ///
saver == "GD" | saver == "GG" | saver == "GI" | saver == "HK" | ///
saver == "IE" | saver == "IM" | saver == "JE" | saver == "KN" | ///
saver == "KY" | saver == "LB" | saver == "LC" | saver == "LI" | ///
saver == "LR" | saver == "LU" | saver == "MH" | saver == "MO" | ///
saver == "MS" | saver == "MT" | saver == "MU" | saver == "MY" | ///
saver == "NR" | saver == "PA" | saver == "PW" | saver == "SC" | ///
saver == "SG" | saver == "SX" | saver == "TC" | saver == "VC" | ///
saver == "VU" | saver == "WS"


* drop deposits held by household in the same country
drop if bank == saver

* labels
label var bank "Reporting country"
label var saver "Counterparty country"
label var totdep "Total deposits, liabilities side"
label var OFC "Offshore financial centres"

order year bank saver totdep OFC
sort bank saver year 	
save "$work/bis-interbank-all-01-22.dta", replace
