* ==============================================================================
* Date: October 2023
* Paper: Global Offshore Wealth, 2001-2021
*
* This program merge swiss fiduciary and bis bank deposits; construct country 
* shares (using a 5-year smoothing method) and value of offshore wealth in 
* Switzerland and several haven groups.
*
* databases used: - bis-deposits-all-01-22.dta
*                 - bis-interbank-all-01-22.dta
*                 - fiduciary-87-22.dta
*                 - gdp_current.csv
*                 - isocodes.xlsx
*
* outputs:        - offshore"year".dta files (files take 2001 to 2022 as "year")
*                 
*===============================================================================

********************************************************************************

**************** I ---- Load BIS locational banking stats -----*****************

********************************************************************************

**--------- I.1 - Adjustments to non-bank and bank deposit data---------------**
forvalues i = 2001/2022 { 
	use "$work/bis-deposits-all-01-22", clear
	merge 1:1 bank saver year using "$work/bis-interbank-all-01-22.dta", ///
	nogenerate
	replace totdep = totdep - dep
	rename totdep interbank
	replace interbank = 0 if bank == "1N" 
	replace interbank = 0 if bank == "5A"
	replace interbank = 0 if bank == "1R"
	replace saver = "AG" if saver == "1W" // british overseas 
	replace saver = "VG" if saver == "1Z" // british virgin islands
	
	* Countries that have disappeared, almost always 0 deposits 
	drop if saver == "DD" | saver=="YU" | saver=="SU" 
	drop if saver == "C9" 
	
	* we drop Serbia and Montenegro as a united jurisdiction from the analysis
	drop if saver == "CS"
	
	* All counterparty countries
	drop if saver == "5J"
	order bank saver year
	
	* Take year deposits
	keep if year == `i'
	collapse (mean) dep interbank OFC year, by(bank saver)
	
	* Transform 1N haven aggregate into Asian tax haven aggregate
	reshape wide dep interbank, i(saver) j(bank) string
	foreach deposit in dep interbank {
		foreach bank in CH KY MY PA GG IM JE LU CL MO BE AT US GB 1N 5A 1R CY {
			replace `deposit'`bank'= 0 if `deposit'`bank' == .
			}
			}
			gen depAS = dep1N + depMY - depKY - depGG - depIM - depJE - depPA
			label variable depAS ///
			"Deposit in Asian haven: HK, Singapore, Macao, Malaysia, Bahrain, Bahamas, Bermuda, Netherlands Antilles" 
			gen interbankAS = interbankMY
			label variable interbankAS ///
			"Interbank deposits in Asian havens: only country available is Malaysia"
			tempfile bisbilat`i'
			save `bisbilat`i'', replace
			* Fractions of non-bank deposits which are tax evading household
			import excel "$raw/FGZ-raw-data.xlsx", ///
			clear firstrow cellrange(A3:W25) sheet(sharehouseholddep)
			keep if year == `i' 
			merge 1:m year using `bisbilat`i'', nogenerate
			gen AS = 0.7
			foreach bank in CH AS GG IM JE PA LU CY MO MY KY BE AT BH BM BS ///
			HK SG GB US CL AN CW { 
				replace dep`bank' = `bank'*dep`bank' if year == `i' 
				drop `bank'
				}
				* Compute deposits in haven aggragetes: Caribbean havens, ///
				* European havens
				* Asian haven is done above from 1N
				foreach deposit in dep interbank {
					gen `deposit'CR = `deposit'KY + `deposit'PA + ///
					`deposit'CL + `deposit'US
					label variable `deposit'CR "Deposits in Caribbean havens"
					gen `deposit'EU =`deposit'GG + `deposit'IM + ///
					`deposit'JE + `deposit'LU + `deposit'AT + `deposit'BE ///
					+ `deposit'GB + `deposit'CY
					label variable `deposit'EU "Deposits in European havens"
					}
					reshape long dep interbank, i(saver) j(bank) string
					tempfile bisbilat`i'
					save `bisbilat`i'', replace
					
**-------------- I.2 - Merge to country codes iso-3 --------------------------** 
import excel "$raw/isocodes.xlsx", sheet(iso) firstrow clear
rename iso2 saver
merge 1:m saver using "`bisbilat`i''", update 
* US Pacific Islands now part of United States Minor Outlying Islands
replace iso3 = "UMI" if saver == "PU"
replace saver = "UM" if saver == "PU"
rename isoname namesaver
rename iso3 iso3saver
order namesaver saver iso3saver
drop if _merge==1
drop _merge
tempfile bisbilat`i'
save `bisbilat`i'', replace
  
 * Add GDP
import delimited using "$raw/gdp_current", clear
keep if year == `i'
rename gdp_current_dollars gdp`i'
rename iso3 iso3saver 
merge 1:m year iso3saver using `bisbilat`i'', nogenerate
su gdp`i' if bank=="5A"
local worldgdp=r(sum)
gen shgdp  =gdp`i'/`worldgdp'
tempfile bisbilat`i'
save `bisbilat`i'', replace
*
import excel "$raw/isocodes", sheet(iso) firstrow clear
rename iso2 bank
merge 1:m bank using `bisbilat`i'', update 
drop if _merge==1
drop _merge
rename isoname namebank
rename iso3 iso3bank
replace namebank="Caribbean havens" if bank=="CR"
replace namebank="Asian havens" if bank=="AS"
replace namebank="European havens" if bank=="EU"
replace namebank="Haven aggregate" if bank=="1N" 
replace namebank="All BIS-reporting banks" if bank=="5A"
replace namebank= "Residual countries" if bank == "1R"
format name* %20s
replace iso3bank="" if bank=="CR"|bank=="AS"|bank=="EU"|bank=="HA"|bank=="OC"
order namebank bank iso3bank
sort bank saver
compress
tempfile bisbilat`i'
save `bisbilat`i'', replace

********************************************************************************

********************* II ---- Load Fiduciary data -----*************************

********************************************************************************

**------------------ I.2 - Adjustments to fiduciary --------------------------** 
use "$work/fiduciary-87-22.dta", clear

* Collapse fiduciary to one year
keep if year==`i'
rename ccode iso3
drop if length(iso3)>3
* Homogeneize country grouping with those used in Zucman UCP 2015
cap drop continent group
rename ofc haven
* GCC states (excluding bahrain = haven): 0 capital tax 
gen gcc=0
replace gcc=1 if iso3=="SAU"|iso3=="ARE"|iso3=="KWT"|iso3=="QAT"|iso3=="OMN"
* EU members in 2005
gen eu=0
#delimit ;
replace eu=1 if 
iso3=="BEL" |
iso3=="FRA" |
iso3=="ITA" |
iso3=="LUX" |
iso3=="NLD" |
iso3=="DEU" |
iso3=="DNK" |
iso3=="IRL" |
iso3=="GBR" |
iso3=="GRC" |
iso3=="PRT" |
iso3=="ESP" |
iso3=="AUT" |
iso3=="FIN" |
iso3=="SWE" |
iso3=="HUN" |
iso3=="CYP" |
iso3=="CZE" |
iso3=="EST" |
iso3=="LVA" |
iso3=="LTU" |
iso3=="MLT" |
iso3=="POL" |
iso3=="SVK" |
iso3=="SVN";
#delimit cr
* Merge Middle East into Africa 
replace africa=1 if iso3=="EGY"|iso3=="IRN"|iso3=="IRQ"|iso3=="ISR"| ///
iso3=="JOR"|iso3=="SYR"|iso3=="YEM"
replace africa = 0 if iso3 == "DJI" | iso3 == "GMB" 
replace haven = 1 if iso3 == "DJI" | iso3 == "GMB" // 
* Gambia becoming tax haven: http://www.economist.com/news/finance-and-
* economics/21584019-gambia-looks-join-beleaguered-club-trawling-business. 
* Djibouti: http://www.lseg.com/sites/default/files/content/
* portogallo%20appendix%20A.pdf
drop middle_east
* Move Caribbean into Latin America
replace latin_am=1 if caribbean==1
drop caribbean
* Guyana http://www.lseg.com/sites/default/files/content/
* portogallo%20appendix%20A.pdf
replace latin_am=0 if iso3=="GUY" 
replace haven = 1 if iso3=="GUY" 
* Isolate Russia
replace asia=0 if iso3=="RUS"
gen russia=0
replace russia=1 if iso3=="RUS"
* Brunei and Maldives: tax havens (https://www.fas.org/sgp/crs/misc/R40623.pdf)
* ; Solomon islands and Papua New Guinea= unclear
replace asia = 0 if iso3 == "BRN" | iso3 == "MDV" | iso3 == "SLB" | ///
iso3 == "PNG" 
replace haven = 1 if iso3 == "BRN" | iso3 == "MDV" | iso3 == "SLB" | ///
iso3 == "PNG"
* Add Swiss fiduciary deposits (for consistency with BIS and HSBC): CHE = 55% of CHE+LIE
expand 2 if iso3=="LIE", gen(che)
replace iso3="CHE" if che==1
replace ifscode=146 if che==1 
replace cn="Switzerland" if che==1
drop che
local fiduvar "lfidu lfidudol lfidu2 lfidu2dol"
foreach var of local fiduvar {
	replace `var'=(1-0.45)/0.45*`var' if iso3 == "CHE"
	}
	rename iso3 iso3saver
	drop lfidu lfidudol lfidu2
	rename lfidu2dol amt_fidu
	collapse (mean) amt_fidu (first) euro16 rich developing haven north_am ///
	latin_am gcc russia asia africa europe eu, by(iso3)
	gen bank = "CH"
	tempfile fiduciary`i'
	save `fiduciary`i'', replace
	
**------------------ II.2 - Merge BIS and fiduciary --------------------------** 
	use `bisbilat`i'', clear
	merge 1:1 iso3saver bank using `fiduciary`i'', nogenerate
	sort bank saver
	replace namebank="Switzerland" if bank=="CH"
	replace iso3bank="CHE" if bank=="CH"
	drop if bank==""
	save "$work/offshore`i'.dta", replace
	merge m:1 iso3saver using `fiduciary`i'', ///
	keepusing(euro16 rich developing haven north_am latin_am gcc russia ///
	asia africa europe eu) update nogenerate 
	* Update saver continent dummies (saved in fiduciary87-22.dta) 
	* for all bank-saver pair
	rename dep amt_bis
	order bank iso3bank namebank saver iso3saver namesaver amt_bis ///
	interbank amt_fidu gdp shgdp rich developing haven OFC
	replace OFC=haven if haven!=.&OFC==.
	replace haven=OFC if OFC!=.&haven==.
	drop OFC
	replace europe = 1 if iso3saver == "MNE" | ///
	iso3saver == "GRL" 
	replace africa = 1 if iso3saver == "PSE"
	replace haven = 1 if iso3saver == "BLM" | iso3saver == "PUS" | ///
	iso3saver == "FRO" | iso3saver == "AIA"
	
	foreach var in europe developing africa rich euro16 north_am latin_am ///
	russia asia eu gcc {
		replace `var' = 0 if iso3saver == "ANT" | iso3saver == "CHE" | ///
		iso3saver == "ATG" | iso3saver == "KNA"
		}
		replace haven = 1 if iso3saver == "ANT" | iso3saver == "CHE" | ///
		iso3saver == "ATG" | iso3saver == "KNA"
		
		foreach var in africa rich euro16 north_am latin_am ///
		russia asia eu gcc haven {
			replace `var' = 0 if iso3saver == "SCG" 
			}
			replace europe = 1 if iso3saver == "SCG"
			replace developing = 1 if iso3saver == "SCG"
				
				sort bank saver
				rename interbank amt_inter
				sleep 3000
				save "$work/offshore`i'", replace
  
********************************************************************************

*********** III ---- COMPUTE AND MERGE SHARE OF DEPOSITS -----******************

********************************************************************************

**-------------------------------- III.1 - -----------------------------------**
* rawsh: share not taking into account shell companies
* sh: corrected share taking into account wealth held through shell companies
use "$work/offshore`i'", clear

* Deal with shell and financial companies incorporated in GB, US, NL, etc. 
foreach saver in GB CH BE NL IE US {
	if "`saver'" == "CH" local share_shell = 1.00 // treat Switzerland as tax haven
	if "`saver'" == "IE" local share_shell = 0.85 // financial companies
	if "`saver'" == "GB" local share_shell = 0.65 // shells + financial companies + non-doms
	if "`saver'" == "NL" local share_shell = 0.75 // shells + financial companies
	if "`saver'" == "BE" local share_shell = 0.5  // shells + financial companies
	if "`saver'" == "US" local share_shell = 0.2  // Delaware shell + financial companies
	expand 2 if saver=="`saver'", gen(new`saver')
	replace saver = "`saver'H" if new`saver' == 1 
	drop new`saver'
	replace namesaver = "Shell corp `saver'" if saver == "`saver'H"
	replace gdp = 0 if saver == "`saver'H"
	replace shgdp = 0 if saver == "`saver'H"
	replace haven = 1 if saver == "`saver'H"
	foreach var of varlist north_am europe rich {
		replace `var' = 0 if saver == "`saver'H"
		}
		replace iso3saver = "`saver'H" if saver == "`saver'H"
		foreach var of varlist amt* {
			replace `var' = `var' * `share_shell' if  saver == "`saver'H"
			replace `var' = `var' * (1 - `share_shell') if  saver == "`saver'"
			}
			}  
			* Create shares of deposits 
			foreach y in fidu bis inter {
				gen rawsh_`y'=0
				gen sh_`y'=0
				foreach b in 1N 5A 1R US GB CL GG IM JE KY LU MO MY PA CH ///
				AT BE EU CR AS HA OC CY {
					su amt_`y' if bank=="`b'"
					local tot`y'`b'=r(sum)
					su amt_`y' if haven==1 & bank=="`b'"
					local tothaven`y'`b'=r(sum)
					su amt_`y' if gcc==1 & bank=="`b'"
					local totgcc`y'`b'=r(sum)
					su amt_`y' if eu==1 & haven!=1 & bank=="`b'"
					local toteu`y'`b'=r(sum)
					replace rawsh_`y'=amt_`y'/`tot`y'`b'' if bank=="`b'"
					local stddep`y'`b'= 0
					if "`y'" != "fidu" {
						* Takes into account higher use of shell by Europeans 
						* with Swiss accounts post STD   
						if "`b'" == "CH" local stddep`y'`b'= ///
						0.35*`tothaven`y'`b''   
						}     
						* Assuming GCC use shell 
						replace sh_`y'= ///
						rawsh_`y'*(1+(`tothaven`y'`b''-`stddep`y'`b'')/ ///
						(`tot`y'`b''-`tothaven`y'`b'')+`stddep`y'`b''/ ///
						`toteu`y'`b'') ///
						if haven!=1 & eu==1 & bank=="`b'"
						replace sh_`y'= ///
						rawsh_`y'*(1+(`tothaven`y'`b''-`stddep`y'`b'')/ ///
						(`tot`y'`b''-`tothaven`y'`b'')) if /// 
						haven!=1 & eu!=1 & bank=="`b'"
						}
						}
						save "$work/offshore`i'", replace
						* Compute share BIS deposits in all tax havens 
						* (needs to be done post allocation of shell)
						tempfile total
						keep bank iso3saver sh_bis amt_bis amt_inter sh_inter
						drop if iso3saver == ""
						reshape wide sh_bis amt_bis amt_inter sh_inter, ///
						i(iso3saver) j(bank) string
						foreach var of varlist sh* amt* {
							replace `var' = 0 if `var'== .
							}
							gen sh_bisOC = (sh_bisAS * `totbisAS' + ///
							sh_bisCR * `totbisCR' + sh_bisEU * `totbisEU') ///
							/ (`totbisAS' + `totbisCR' + `totbisEU')
							gen sh_bisHA = (sh_bisOC * (`totbisAS' + ///
							`totbisCR' + `totbisEU') + sh_bisCH * ///
							`totbisCH') / (`totbisAS' + `totbisCR' + ///
							`totbisEU' + `totbisCH')
							* uncorrected amounts, just as memo item
							gen amt_bisOC = amt_bisAS + amt_bisCR + amt_bisEU 
							gen amt_bisHA = amt_bisOC + amt_bisCH
							*
							gen sh_interOC = (sh_interAS * `totbisAS' + ///
							sh_interCR* `totbisCR' + sh_interEU * ///
							`totbisEU') / (`totbisAS' + `totbisCR' + ///
							`totbisEU')
							reshape long sh_bis amt_bis sh_inter amt_inter, ///
							i(iso3saver) j(bank) string
							keep if bank == "OC" | bank == "HA"
							save `total', replace
							use "$work/offshore`i'", clear
							append using `total'
							keep if bank=="OC" | bank == "CH" | bank =="HA"
							replace namebank="All havens" if bank=="HA"
							replace namebank="Havens other than CH" ///
							if bank=="OC"
							sort iso3saver bank
							foreach var of varlist saver namesaver gdp ///
							shgdp rich developing gdp* north* lat* gcc ///
							russia asia africa europe eu* haven  {
								replace `var'=`var'[_n-1] if bank=="HA"
								replace `var'=`var'[_n-2] if bank=="OC"
								}
								save `total', replace
								use "$work/offshore`i'", clear
								merge 1:1 bank iso3saver using `total', ///
								update nogenerate
								replace namesaver = "US Minor Islands" ///
								if iso3saver == "UMI"
								drop if namesaver == ""
								replace year = `i'
								order bank iso3bank namebank saver ///
								iso3saver namesaver amt_bis amt_inter ///
								amt_fidu sh* raw* 
								gsort namesaver
								order saver iso3saver namesaver sh_fidu /// 
								shgdp gdp* 
								sort namesaver
								save "$work/offshore`i'", replace
 
**-------------------------------- III.2 - -----------------------------------**
preserve
keep if bank == "CH"
	gen continent = 1*africa + 2*europe + 3*gcc + 4*asia + 5*russia + ///
	6*latin_am + 7*north_am + 8*haven
	  replace continent=8 if continent==0
	  replace continent=9 if saver=="NO"
	  replace continent=10 if saver=="CR"
  keep saver iso3saver namesaver sh_fidu sh_inter shgdp gdp sh_bis continent
  tempfile countries1
  save `countries1', replace
  restore 
  preserve
  keep if bank=="OC" 
  keep iso3saver saver namesaver sh_bis 
  rename sh_bis sh_OC
  merge 1:1 iso3saver using  `countries1', nogenerate
  tempfile countries2
  save `countries2', replace
  restore 
  preserve
  keep if bank=="AS" 
  keep iso3saver saver namesaver sh_bis 
  rename sh_bis sh_AS
  merge 1:1 iso3saver using `countries2', nogenerate
  tempfile countries3
  save  `countries3', replace
  restore 
  preserve
  keep if bank=="EU" 
  keep iso3saver saver namesaver sh_bis 
  rename sh_bis sh_EU
  merge 1:1 iso3saver using `countries3', nogenerate
  tempfile countries4
  save  `countries4', replace
  restore 
  *preserve
  keep if bank=="CR" 
  keep iso3saver saver namesaver sh_bis 
  rename sh_bis sh_CR
  merge 1:1 iso3saver using  `countries4', nogenerate
  gsort namesaver
  order saver iso3saver namesaver sh_fidu sh_OC sh_CR sh_AS sh_EU shgdp ///
  gdp* continent 
  sort continent namesaver
  rename sh_fidu sh_fidu`i'
  rename sh_AS sh_AS`i'
  rename sh_CR sh_CR`i'
  rename sh_EU sh_EU`i'
  rename sh_OC sh_OC`i'
  rename sh_bis sh_bis`i'
  rename sh_inter sh_inter`i'
  tempfile countries`i'
  save `countries`i'', replace
 }
 
 *******************************************************************************

**************** IV ---- COMPUTE 5-YEARS SMOOTHED ESTIMATES -----***************

********************************************************************************
 forvalues x=2003/2020 {
 	local x_1 = `x' - 2
	local x_2 = `x' - 1
	local x_3 = `x' + 1
	local x_4 = `x' + 2
 	use `countries`x'', replace
	merge 1:1 iso3saver using `countries`x_1'', nogenerate
	merge 1:1 iso3saver using `countries`x_2'', nogenerate
	merge 1:1 iso3saver using `countries`x_3'', nogenerate
	merge 1:1 iso3saver using `countries`x_4'', nogenerate
	foreach b in fidu CR EU AS OC bis inter {
	gen sh_`b'_smthg`x' = (sh_`b'`x_1' + sh_`b'`x_4')*0.1 + ///
	(sh_`b'`x_2'+ sh_`b'`x_3')*0.2 + sh_`b'`x'*0.4
	replace sh_`b'_smthg`x' = sh_`b'`x' if sh_`b'_smthg`x' == .
	drop sh_`b'`x_1' sh_`b'`x_4' sh_`b'`x_2' sh_`b'`x_3' sh_`b'`x'
	}
	merge 1:m namesaver using "$work/offshore`x'", nogenerate
	drop gdp`x_1' gdp`x_2' gdp`x_3' gdp`x_4' 
	
	* labels
	label var year "Year"
	label var namesaver "Counterparty country name"
	label var iso3saver "Counterparty ISO alpha-3 code"
	label var saver "Counterparty ISO alpha-2 code"
	label var year ""
	label var bank "Reporting country ISO alpha-2 code"
	label var iso3bank "Reporting country ISO alpha-3 code"
	label var namebank "Reporting country name"
	label var amt_bis "Bank deposits owned by counterparty households in reporting country"
	label var amt_inter "Bank deposits owned by counterparty banks in reporting country"
	label var amt_fidu "Fiduciary deposits owned by counterparty households in reporting country"
	label var rawsh_bis "Share of total deposits owned by counterparty households"
	label var rawsh_inter "Share of total deposits owned by counterparty banks"
	label var rawsh_fidu "Share of total fiduciary deposits owned by counterparty households"
	label var sh_bis "Corrected share of deposits owned by counter households in reporting country"
	label var sh_fidu "Corrected share of Swiss fiduciary deposits owned by counterparty households"
	label var sh_inter "Corrected share of total deposits owned by counterparty banks"
	label var sh_bis_smthg "Weighted moving avg sh. of deposits owned by counter households in rep. country"
	label var sh_inter_smthg "Weighted moving avg sh. of deposits owned by counter banks in rep. country"
	label var sh_AS_smthg "Weighted moving avg sh. of deposits owned by counter households in Asian havens"
	label var sh_CR_smthg "Weighted mov. avg sh. of deposits owned by count. households in Caribbean havens"
	label var sh_EU_smthg "Weighted mov. avg sh. of deposits owned by count. households in European havens"
	label var sh_OC_smthg "Weight. mov. avg sh. of dep. owned by count. households in havens ex Switzerland"
	label var sh_fidu_smthg "Weighted moving avg sh. of deposits owned by counter households in Switzerland"
	label var gdp "Counterparty country GDP, various sources"
	label var shgdp "Share of counterparty in World GDP"
	label var continent "Continent of counterparty country"
	label define cont_label 1 "africa" 2 "europe" 3 "gcc" 4 "asia" ///
	5 "russia" 6 "latin_am" 7 "north_am" 8 "haven" 
	label values continent cont_label
	label var rich "High income countries"
	label var developing "Developing countries"
	label var haven "Countries that exhibit a salient activity in financial wealth managed offshore"
	label var europe "European countries"
	label var asia "Asian countries"
	label var russia "Russia"
	label var north_am "North American countries"
	label var latin_am "Latin American countries"
	label var gcc "Gulf countries"
	label var africa "African and Middle-Eastern countries"
	drop eu euro16
	gsort namesaver
    order year saver iso3saver namesaver bank iso3bank namebank amt_bis amt_inter ///
	amt_fidu rawsh_bis rawsh_inter rawsh_fidu sh_bis sh_inter sh_fidu ///
	sh_bis_smthg sh_inter_smthg sh_AS_smthg sh_CR_smthg ///
	sh_EU_smthg sh_OC_smthg sh_fidu_smthg gdp shgdp continent rich developing haven ///
	europe asia russia north_am latin_am gcc africa  
    sort namesaver
	save "$work/offshore`x'", replace 
 }
 
 	use `countries2001', replace
	merge 1:1 iso3saver using `countries2002', nogenerate
	merge 1:1 iso3saver using `countries2003', nogenerate
	merge 1:1 iso3saver using `countries2004', nogenerate
	merge 1:1 iso3saver using `countries2021', nogenerate
	merge 1:1 iso3saver using `countries2022', nogenerate
	merge 1:1 iso3saver using `countries2019', nogenerate
	merge 1:1 iso3saver using `countries2020', nogenerate
	foreach b in fidu CR EU AS OC bis inter {
	gen sh_`b'_smthg2001 = ///
	((sh_`b'2003)*0.1 + (sh_`b'2002)*0.2 + sh_`b'2001*0.4) / 0.7
	gen sh_`b'_smthg2002 = ///
	((sh_`b'2004)*0.1 + (sh_`b'2003 + sh_`b'2001)*0.2 + sh_`b'2002*0.4) / 0.9
	gen sh_`b'_smthg2021 = ///
	(sh_`b'2019*0.1 + (sh_`b'2022 + sh_`b'2020)*0.2 + sh_`b'2021*0.4) / 0.9
	gen sh_`b'_smthg2022 = ///
	(sh_`b'2020*0.1 + 0.2*sh_`b'2021 + 0.4*sh_`b'2022) / 0.7
	replace sh_`b'_smthg2001 = ///
	sh_`b'2001 if sh_`b'_smthg2001 == . 
	replace sh_`b'_smthg2002 = ///
	(sh_`b'2002*0.4 + sh_`b'2004*0.1) / 0.5 if sh_`b'_smthg2002 == . 
	replace sh_`b'_smthg2002 = ///
	sh_`b'2002 if sh_`b'_smthg2002 == . 
	drop sh_`b'2002 sh_`b'2003 sh_`b'2004 sh_`b'2021 sh_`b'2022 sh_`b'2019 ///
	sh_`b'2020 
	}
	
	* 
	forvalues i = 2001/2022 {
	if inlist(`i', 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, ///
	2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020) continue
	preserve
	keep namesaver saver sh_fidu_smthg`i' sh_CR_smthg`i' sh_EU_smthg`i' ///
	sh_AS_smthg`i' sh_OC_smthg`i' sh_bis_smthg`i' sh_inter_smthg`i' gdp`i' shgdp continent
	merge 1:m namesaver using "$work/offshore`i'", nogenerate
	
	* labels
	label var year "Year"
	label var namesaver "Counterparty country name"
	label var iso3saver "Counterparty ISO alpha-3 code"
	label var saver "Counterparty ISO alpha-2 code"
	label var year ""
	label var bank "Reporting country ISO alpha-2 code"
	label var iso3bank "Reporting country ISO alpha-3 code"
	label var namebank "Reporting country name"
	label var amt_bis "Bank deposits owned by counterparty households in reporting country"
	label var amt_inter "Bank deposits owned by counterparty banks in reporting country"
	label var amt_fidu "Fiduciary deposits owned by counterparty households in reporting country"
	label var rawsh_bis "Share of total deposits owned by counterparty households"
	label var rawsh_inter "Share of total deposits owned by counterparty banks"
	label var rawsh_fidu "Share of total fiduciary deposits owned by counterparty households"
	label var sh_bis "Corrected share of deposits owned by counter households in reporting country"
	label var sh_fidu "Corrected share of Swiss fiduciary deposits owned by counterparty households"
	label var sh_inter "Corrected share of total deposits owned by counterparty banks"
	label var sh_bis_smthg "Weighted moving avg sh. of deposits owned by counter households in rep. country"
	label var sh_inter_smthg "Weighted moving avg sh. of deposits owned by counter banks in rep. country"
	label var sh_AS_smthg "Weighted moving avg sh. of deposits owned by counter households in Asian havens"
	label var sh_CR_smthg "Weighted mov. avg sh. of deposits owned by count. households in Caribbean havens"
	label var sh_EU_smthg "Weighted mov. avg sh. of deposits owned by count. households in European havens"
	label var sh_OC_smthg "Weight. mov. avg sh. of dep. owned by count. households in havens ex Switzerland"
	label var sh_fidu_smthg "Weighted moving avg sh. of deposits owned by counter households in Switzerland"
	label var gdp "Counterparty country GDP, various sources"
	label var shgdp "Share of counterparty in World GDP"
	label var continent "Continent of counterparty country"
	label define cont_label 1 "africa" 2 "europe" 3 "gcc" 4 "asia" ///
	5 "russia" 6 "latin_am" 7 "north_am" 8 "haven" 
	label values continent cont_label
	label var rich "High income countries"
	label var developing "Developing countries"
	label var haven "Countries that exhibit a salient activity in financial wealth managed offshore"
	label var europe "European countries"
	label var asia "Asian countries"
	label var russia "Russia"
	label var north_am "North American countries"
	label var latin_am "Latin American countries"
	label var gcc "Gulf countries"
	label var africa "African and Middle-Eastern countries"
	drop eu euro16
	gsort namesaver
    order year saver iso3saver namesaver bank iso3bank namebank amt_bis amt_inter ///
	amt_fidu rawsh_bis rawsh_inter rawsh_fidu sh_bis sh_inter sh_fidu ///
	sh_bis_smthg sh_inter_smthg sh_AS_smthg sh_CR_smthg ///
	sh_EU_smthg sh_OC_smthg sh_fidu_smthg gdp shgdp continent rich developing haven ///
    europe asia russia north_am latin_am gcc africa  
    sort namesaver
	save "$work/offshore`i'", replace 
	restore
	}
	
