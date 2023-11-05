//----------------------------------------------------------------------------//
//Project: Offshore financial wealth database - update 2023
//Title: 1b_rebuild_gravity_dataset.do
//Purpose: reproduce and extend the dataset "data_gravity.dta". It combines:
	* identifiable bilateral portfolio assets from IMF CPIS (2023)
	* gravity variables from  CEPII (Conte, Cotterlaz & Mayer, 2022) 
	* gravity variables from the GeoDist database (Mayer and Zignago 2011)
	* GDP from World Bank WDI / EWN / World Inequality Database / UN / extrapolation
//This version: 18 Oct 2023
//----------------------------------------------------------------------------//


//----------------------------------------------------------------------------//
// 1. bilateral portfolio assets from cpis
//----------------------------------------------------------------------------//

import delimited "$raw\CPIS_06-08-2023_11-40-56-69_timeSeries\CPIS_06-08-2023 11-40-56-69_timeSeries.csv", clear
// prepare dataset
 // keep total equity and total debt liabilities
 keep if indicatorcode == "I_L_D_T_T_BP6_DV_USD" | indicatorcode == "I_L_E_T_T_BP6_DV_USD"
 sort countryname counterpartcountryname
 replace indicatorname = "debt" if indicatorcode == "I_L_D_T_T_BP6_DV_USD"
 replace indicatorname = "equity" if indicatorcode == "I_L_E_T_T_BP6_DV_USD"
 keep if attribute == "Value"
 keep countryname countrycode indicatorname counterpartcountryname counterpartcountrycode v12-v32
 reshape long v, i(countrycode counterpartcountrycode indicatorname) j(year)
 drop if countrycode == 1 // world
 drop if countrycode == 31 // world minus 25 significant financial centers
 sort countryname counterpartcountryname year


 // year 12 = 2001
 replace year = year + 1989
 destring v, replace
 reshape wide v, i(countrycode counterpartcountrycode year) j(indicatorname) string

 // harmonise var names
 rename (countrycode countryname counterpartcountrycode counterpartcountryname vdebt vequity) (host hostname  source sourcename debtasset eqasset)
 
 // harmonise unit
 replace debtasset = debtasset / 1000000 // million USD
 replace eqasset = eqasset / 1000000
 
// cpis includes more host countries than source countries (reporting countries)
	// harmonise source and host jurisdictions (cpis includes host == 355 "Curacao and Sint Maarten"; source == 354 "Curacao, Kingdom of the Netherlands"; source == 352 "Sint Maarten, Kingdom of the Netherlands"

	preserve
		//collapse 2 host lines for Curacao and Sint Maarten into one
		keep if host == 354 | host == 352
		replace host = 355 /*Curacao and Sint Maarten*/
		collapse (first) hostname sourcename (sum) debtasset eqasset, by(host source year)
		replace hostname = "Curacao and Sint Maarten"
		tempfile cpis_curacao_bil_host
		save `cpis_curacao_bil_host'
	restore

	// drop individual lines for Curacao and Sint Maarten and append unified
	drop if host == 354 | host == 352
	append using `cpis_curacao_bil_host'
 
 // save cpis indicator variable for countries reporting to the cpis
 preserve
 sort source
 drop if source == source[_n-1]
 keep source
 gen cpis = 1
 save "$work\cpis_source.dta", replace
 restore

	// Duplicate all relationships that exist as host source also as source host
	preserve
		rename (host hostname) (help helpname)
		rename (source sourcename) (host hostname)
		rename (help helpname) (source sourcename)
		keep year source host sourcename hostname
		tempfile missing_relationships
		save `missing_relationships'
	restore
 
	//merge with the original dataset and keep one part of the not matched relationships
	preserve
		merge 1:1 year source host using `missing_relationships'
		keep if _merge == 2
		drop _merge
		tempfile missing_relationships_append
		save `missing_relationships_append'
	restore	
	append using `missing_relationships_append'

save "$work\cpis_merge.dta", replace



//----------------------------------------------------------------------------//
// 2. CEPII database gravity controls
//----------------------------------------------------------------------------//
use "$raw\Gravity_dta_V202211\Gravity_V202211.dta", clear
// prepare data
rename country_id_d country_id
merge m:1 country_id using "$raw\Gravity_dta_V202211\Countries_V202211.dta"
drop _merge
rename (country_id country) (country_id_d countryname_d)
drop if last_year<2001
keep year country_id_o country_id_d iso3_o iso3_d country_exists_o country_exists_d dist comlang_off col45 pop_o pop_d countryname*
rename country_id_o country_id
merge m:1 country_id using "$raw\Gravity_dta_V202211\Countries_V202211.dta"
drop _merge
rename country_id country_id_o
drop if last_year < 2001
rename country countryname_o
keep year country_id_o country_id_d iso3_o iso3_d countryname_o countryname_d country_exists* dist comlang_off col45 pop_o pop_d
keep if year > 2000

// remove iso code duplicates
// (in the gravity dataset the same iso codes for Indonesia and Sudan are assigned to two country ids respectively: 	e.g. IDN:  IDN.1 = "Indonesia + Timor Leste", IDN.2 = "Indonesia" -> use only the line for the country that is defined as "country exists" in a given year. As a result IDN stands for "Indonesia+Timor-Leste" in 2001 but only for Indonesia after 2001, "TLS" stands for Timor-Leste.

sort year iso3_d
drop if iso3_o == "IDN" & country_exists_o == 0 // Indonesia and Timor-Leste
drop if iso3_d == "IDN" & country_exists_d == 0

drop if iso3_o == "SDN" & country_exists_o == 0 // Sudan and South Sudan
drop if iso3_d == "SDN" & country_exists_d == 0

// Three different iso3 codes for Serbia and Montenegro: MNE = Montenegro; SCG = "Serbia and Montenegro"; SRB = "Serbia"; In IMF data there is no "Serbia and Montenegro" -> match "Serbia and Montenegro" in gravity dataset to "Serbia" in cpis before 2007 

drop if iso3_o == "SCG" & country_exists_o == 0 // Serbia and Montenegro
drop if iso3_d=="SCG" & country_exists_d == 0

drop if iso3_o=="SRB" & country_exists_o == 0 // Serbia
drop if iso3_d=="SRB" & country_exists_d == 0

// in 2006 both SCG and SRB "exist" -> drop one
drop if iso3_o == "SCG" & year == 2006
drop if iso3_d == "SCG" & year == 2006 
//replace Serbia and Montenegro by Serbia before 2007 to be able to match to IMF Serbia
replace iso3_o = "SRB" if iso3_o == "SCG" & year < 2007
replace iso3_d = "SRB" if iso3_d == "SCG" & year < 2007

tempfile gravity_vars_1
save `gravity_vars_1'


// more gravity variables: gap_lon lat_source landlocked_source
	// merge missing gravity variables to source countries
	use "$raw\cepii\geo_cepii.dta",clear
	keep iso3 country landlocked lat lon city_en cap
	rename (landlocked lat lon) (landlocked_source lat_source lon_source)
	// remove iso code duplicates
	by iso3, sort: gen nvals=_n
	by iso3, sort: egen help=mean(nvals)
	// drop latitude and longitude referring to other cities but the capital
	drop if help!=1&cap!=1
	drop nvals help city cap

	replace iso3 = "TLS" if iso3 == "TMP"
	replace iso3 = "PSE" if iso3 == "PAL"
	replace iso3 = "ROU" if iso3 == "ROM"
	replace iso3 = "SRB" if iso3 == "YUG"
	replace iso3 = "COD" if iso3 == "ZAR"
 	tempfile geo_cepi
	save `geo_cepi'
	rename iso3 iso3_o
	merge 1:m iso3_o using `gravity_vars_1'
	drop if _merge==1 // "French Southern Antarctic Territories"
	drop _merge
	drop country
	tempfile gravity_vars_2
	save `gravity_vars_2'


	// merge latitude and longitude to host countries
	use `geo_cepi',clear
	keep iso3 lat lon
	rename (lat lon) (lat_host lon_host)
	rename iso3 iso3_d
	merge 1:m iso3_d using `gravity_vars_2'
	drop if _merge==1 // "French Southern Antarctic Territories"
	drop _merge
	drop country_id* country_exists* countryname*


// merge matching table iso3 ifs_code
preserve
	use "$raw\dta\matching_iso_ifscode.dta", clear
	drop if iso3 == ""
	save "$work\iso_ifscode.dta", replace

	// source country
	restore 
	rename iso3_o iso3
	merge m:1 iso3 using "$work\iso_ifscode.dta"
 	drop if _merge==2 // not in geo cepii: French Southern Territories, Guernsey, Isle of Man, Jersey, US Virgin Islands, Kosovo
	drop _merge country
	rename iso3 iso3_source /*origin country = source country*/
	rename ifscode source
	rename our_code our_code_source

	// host country
	rename iso3_d iso3
	merge m:1 iso3 using "$work\iso_ifscode.dta"
	drop if _merge==2 // not in geo cepii: French Southern Territories, Guernsey, Isle of Man, Jersey, US Virgin Islands, Kosovo
	drop _merge country
	rename iso3 iso3_host /*destination country = host country*/
	rename (ifscode our_code) (host our_code_host)
	
// collapse Curacao and Sint Maarten into one line (as in CPIS)
	sort source host year
	// source country dimension
	replace source = 355 if source == 352 | source == 354 //"Curacao and Sint Maarten"
	collapse (first) iso3_source iso3_host pop_d comlang_off col45 lon_host lat_host landlocked_source our_code* (mean) dist lon_source lat_source (sum) pop_o, by(source host year)
	replace pop_o = . if pop_o == 0
	
	// host country dimension
	replace host = 355 if host == 352 | host == 354 //"Curacao and Sint Maarten"
	collapse (first) iso3_source iso3_host lat_source lon_source pop_o comlang_off col45  landlocked_source our_code* (mean) dist lon_host lat_host (sum) pop_d, by(source host year)
		replace pop_d = . if pop_d == 0
	replace our_code_source=355 if source==355
	replace our_code_host=355 if host==355
	
	
	// variables not needed for same country pair
	foreach var of varlist dist comlang_off col45 pop* lat* lon* landlocked{
		replace `var' = . if host == 355 & source == 355
		replace `var' = . if (source == 355 & year < 2010) | (host == 355 & year < 2010) //did not exist as independent jurisdictions before 2010
	}

save "$work\gravity_vars.dta", replace


// merge cpis and gravity vars
merge 1:1 year source host using "$work\cpis_merge.dta"
drop _merge
save "$work\data_gravity_update.dta", replace


/*check
by source, sort: gen nvals=_n==1
by host, sort: gen nvals2=_n==1
count if nvals
count if nvals2
drop nval*
*245x245*
*/


//----------------------------------------------------------------------------//
// 3. merge GDP
//----------------------------------------------------------------------------//
use "$work\iso_ifscode.dta", clear
replace iso3 = "XKX" if iso3 == "XXK"
merge 1:m iso3 using "$raw\dta\assembled_gdp_series_090623.dta"
keep if _merge == 3
drop _merge
keep ifscode gdp_current year iso3
rename (ifscode iso3) (source iso3_source)
drop if year == 2000 | year == 2022
replace source = 355 if source == 352 | source == 354 // Curacao + Sint Maarten
collapse (sum) gdp_current (first) iso3_source, by(year source)
replace gdp_current = gdp_current / 1000000
replace gdp_current = . if gdp_current == 0

// add GDP for Netherlands Antilles
preserve
	use "$work\ewn_gdp.dta", clear
	keep if source==353
	drop country
 	tempfile gdp_353
	save `gdp_353'
restore
 
append using `gdp_353'
replace gdp_current = gdp_us if source == 353 & gdp_current == .
replace iso3 = "ANT" if source == 353	
drop gdp_us
	
// merge GDP to source and host country
preserve
	rename (source iso3_source) (host iso3_host)
 	tempfile gdp_host
	save `gdp_host'
restore
merge 1:m source year using "$work\data_gravity_update.dta"
drop _merge
rename gdp_current gdp_source

merge m:1 host year using `gdp_host'
drop _merge
rename gdp_current gdp_host
save "$work\data_gravity_update.dta", replace



//----------------------------------------------------------------------------//
// 4. merge population from world bank WDI
//----------------------------------------------------------------------------//
import delimited "$raw\API_SP.POP.TOTL_DS2_en_csv_v2_4902028\API_SP.POP.TOTL_DS2_en_csv_v2_4902028.csv", clear
keep v1 v2 v46-v66
rename (v1 v2) (country_wdi iso3)
drop in 1
drop in 1


reshape long v, i(country_wdi iso3) j(year)
replace year = year + 1955
rename v pop_wdi
label var pop_wdi "population (from World Bank WDI)"
replace pop_wdi = pop_wdi * 1000
replace iso3 = "XXK" if iso3 =="XKX"
merge m:1 iso3 using "$work\iso_ifscode.dta"
keep if _merge == 3
drop _merge
drop iso3 country
rename ifscode source

// collapse Curacao and Sint Maarten into one row
preserve
	keep if source == 354 | source == 352
	collapse (sum) pop_wdi, by(year)
	gen source = 355
	tempfile pop_355
	save `pop_355'
restore
append using `pop_355'
drop if source == 354 | source == 352
rename pop_wdi pop_wdi_source
drop country_wdi
tempfile pop_source
save `pop_source'
	
use "$work\data_gravity_update.dta", clear
merge m:1 year source using `pop_source'
drop _merge

// harmonize
replace pop_wdi_source = pop_wdi_source / 1000000

// replace pop by wdi if not included in gravity data but in wdi
replace pop_o = pop_wdi_source if pop_o == .
rename pop_o pop_source
drop pop_d pop_wdi*

// complete population data for jurs with available gdp -> Anguilla, Cook Islands, Guernsey, Jersey, Montserrat, Taiwan

	// Anguilla
	replace pop_source = 15 if source==312 // source: https://data.un.org/en/iso/ai.html

	// Cook Islands
	replace pop_source = 18 if source == 815 & year == 2021 // source: https://data.un.org/en/iso/ck.html
	
	// Montserrat
	replace pop_source = 5 if source == 351 // source: https://data.un.org/en/iso/ms.html

	// Guernsey - https://www.gov.gg/census
	preserve
		import excel "$raw\Guernsey_Historic_population_and_employment_data_(for_website).xlsx", clear
		keep A B
		drop if B == ""
		destring A, replace
		keep if A > 2000 & A < .
		destring B, replace
		replace B = B / 1000000
		rename (A B) (year pop_guernsey)
		gen source = 113
		tempfile pop_guernsey
		save `pop_guernsey'
	restore
	merge m:1 year source using `pop_guernsey'
	replace pop_source=pop_guernsey if source == 113
	bysort source: ipolate pop_source year, generate(pop_epo) epolate
	replace pop_source=pop_epo if source == 113
	drop pop_guernsey _merge
	
	// Fill gaps for Cook Islands
	replace pop_source = pop_epo if source == 815 & pop_source == .
	
	// Taiwan (only 2020 and 2021 missing)
	replace pop_source=pop_epo if source==528 & pop_source==.
	drop pop_epo
	
	// Jersey
	preserve
		import delimited "$raw\Jersey_total-population-annual-change-natural-growth-net-migration-per-year-with-midyear.csv", clear
		keep year endofyearpopulationestimate
		keep if year > 2000
		rename endofyearpopulationestimate pop_jersey
		replace pop_jersey = pop_jersey/1000000
		gen source = 117
		tempfile pop_jersey
		save `pop_jersey'
	restore
	merge m:1 year source using `pop_jersey'
	replace pop_source=pop_jersey if source == 117
	drop pop_jersey _merge

// merge population to host country
preserve
	keep year source pop_source
	rename (source pop_source) (host pop_host)
	by year host, sort: gen help = _n
	keep if help == 1
	drop help
	tempfile pop_host
	save `pop_host'
restore
merge m:1 host year using `pop_host'
drop _merge


//----------------------------------------------------------------------------//
// 5. compute gravity variables
//----------------------------------------------------------------------------//

	// latitude source country
	label variable lat_source "latitude of source ctry"
	
	// source country landlocked
	label variable landlocked_source "sce ctry landlocked"

	// distance
	gen logdist=ln(dist)
	label variable logdist "log distance"


	// longitude gap
	gen gap_lon=lon_host-lon_source
	replace gap_lon = gap_lon * -1 if gap_lon < 0
	label variable gap_lon "longitude gap"


	// calculate gdp variables
	gen gdppc_source=gdp_source/pop_source*1000
	gen gdppc_host=gdp_host/pop_host*1000
	label var gdppc_source "gdp per capita, current USD"
	label var gdppc_host "gdp per capita, current USD"

	gen gap_gdp=gdp_source-gdp_host
	replace gap_gdp=-1*gap_gdp if gap_gdp<0
	gen gap_gdppc=gdppc_source-gdppc_host
	replace gap_gdppc =-1*gap_gdppc if gap_gdppc<0

	// take logs
	foreach var of varlist eqasset debtasset pop_source gdppc_source gap_gdp gap_gdppc{
		gen log`var'=ln(`var')
	}

//----------------------------------------------------------------------------//
// 6. complete gravity dataset
//----------------------------------------------------------------------------//

// balance panel
tab host
fillin source host year

// recycle missing gravity vars from Zucman 2013 -> "industrial pair" and "sifc" for all jurisdictions and all gravity vars for Guernsey, Isle of Man, Jersey, Liechtenstein, Monaco

	// harmonise country codes with Zucman (2013)
	foreach var of varlist host source {
		replace `var' = 9998 if `var' == 91 // International Organizations
		replace `var' = 9999 if `var' == 93 // SSIO & SEFER
		replace `var' = 1006 if `var' == 113 // Guernsey
		replace `var' = 1012 if `var' == 118 // Isle of Man
		replace `var' = 1017 if `var' == 117 // Jersey
		replace `var' = 9006 if `var' == 147 // Liechtenstein
		replace `var' = 1001 if `var' == 171 // Andorra
		replace `var' = 1003 if `var' == 183 // Monaco
		replace `var' = 139 if `var' == 187 // Vatican City / Holy See
		replace `var' = 1103 if `var' == 359 // Puerto Rico
		replace `var' = 1200 if `var' == 371 // BVI
		replace `var' = 1201 if `var' == 373 // U.S. Virgin Islands
		replace `var' = 372 if `var' == 585 // British Indian Ocean Territorry
		replace `var' = 687 if `var' == 793 // Western Sahara
		replace `var' = 1007 if `var' == 814 // Christmas Island
		replace `var' = 1104 if `var' == 818 // Tokelau
		replace `var' = 1101 if `var' == 849 // Norfolk Islands
		replace `var' = 1100 if `var' == 851 // Niue
		replace `var' = 889 if `var' == 857 // Wallis and Futuna Islands
		replace `var' = 1102 if `var' == 863 // Pitcairn Islands*/
		replace `var' = 1008 if `var' == 865 // Cocos (Keeling) Islands
		replace `var' = 1009 if `var' == 876 // French Southern Territorries
		replace `var' = 1005 if `var' == 920 // Mayotte
	}
	// note: in CPIS (2023) 983 is "not specified incl. confidential", Zucman (2013) uses previous codes: 9996 for "other countries (confidential data)" and 9997 for "other countries (not allocated)"
	
	// merge missing gravity variables
	preserve
		use "$raw\Zucman\data_gravity.dta", clear
		by source host, sort: gen nvals=_n==1
		keep if nvals==1
		drop nvals
		foreach var of varlist gap_lon logdist col45 comlang_off lat_source landlocked {
			rename `var' `var'_2013
		}
		keep source host industrial *2013 sifc
		tempfile missing_gravity_vars
		save `missing_gravity_vars'
	restore
	
	merge m:1 source host using `missing_gravity_vars'
	drop if _merge == 2 //international organizations, SEFER, and Untied States Minor Outlying Islands -> no data
	drop _merge

	/*check 
	sum comlang_off comlang_off_2013 col45 col45_2013 lat_source lat_source_2013 gap_lon gap_lon_2013 landlocked_source landlocked_source_2013
	*/
	foreach var of varlist comlang_off col45 gap_lon logdist {
		replace `var' = `var'_2013 if source == 1003 | host == 1003 // Monaco
		replace `var' = `var'_2013 if source == 1006 | host == 1006 // Guernsey
		replace `var' = `var'_2013 if source == 1012 | host == 1012 // Isle of Man
		replace `var' = `var'_2013 if source == 1017 | host == 1017 // Jersey
		replace `var' = `var'_2013 if source == 9006 | host == 9006 // Liechtenstein
	}
	foreach var of varlist landlocked_source lat_source {
		replace `var' = `var'_2013 if source == 1003 // Monaco
		replace `var' = `var'_2013 if source == 1006 // Guernsey
		replace `var' = `var'_2013 if source == 1012 // Isle of Man
		replace `var' = `var'_2013 if source == 1017 // Jersey
		replace `var' = `var'_2013 if source == 9006 // Liechtenstein
}
	/*check
	sum comlang_off comlang_off_2013 col45 col45_2013 lat_source lat_source_2013 gap_lon gap_lon_2013 landlocked_source landlocked_source_2013 industrial*/

// Complete gravity variables for cpis-reporting jurisdictions (Curacao and Sint Maarten; Kosovo) 

	// Curacao and Sint Maarten - > recycle time-constant variables from Netherlands Antilles
	// comlang_off col45 lat_source landlocked industrial gap_lon
	
		// ensure consistency of dist and latitude and longitude variables
		replace dist = . if source == 355 | host == 355
		replace logdist = . if source == 355 | host == 355
	
		// extract source country vars
		preserve
			keep if source == 353
			keep source host year comlang_off col45 lon_source lat_source landlocked_source industrial dist logdist gap_lon
			drop if year>2010
			by source host, sort: gen nvals=_n
			keep if nvals==1
			drop nvals year
			replace source = 355
			foreach var of varlist comlang_off col45 lon_source lat_source landlocked_source industrial dist logdist gap_lon{
				rename `var' `var'_355_source
			}
			tempfile gravity_355_source
			save `gravity_355_source'
		restore
		
		// extract host country vars
		preserve
			keep if host == 353
			keep source host year comlang_off col45 industrial dist logdist gap_lon
			drop if year > 2010
			by source host, sort: gen nvals=_n
			keep if nvals == 1
			drop nvals year
			replace host = 355
			foreach var of varlist comlang_off col45 industrial dist logdist gap_lon{
				rename `var' `var'_355_host
			}
			tempfile gravity_355_host
			save `gravity_355_host'
		
		// merge to main dataset
		restore
		merge m:1 source host using `gravity_355_source'
		drop _merge
		foreach var of varlist comlang_off col45 lon_source lat_source landlocked_source industrial dist logdist gap_lon{
			replace `var' = `var'_355_source if `var' == . & `var'_355_source != . & year > 2009
			drop `var'_355_source
		}
		merge m:1 source host using `gravity_355_host'
		drop _merge
		foreach var of varlist comlang_off col45 industrial dist logdist gap_lon{
			replace `var' = `var'_355_host if `var' == . & `var'_355_host != .  & year > 2009
			drop `var'_355_host
		}
	
		// set to missing if country pair does not exist
		foreach var of varlist comlang_off col45 dist logdist gdp* pop* landlocked_source lat_source lon_source gap_lon industrial{
			replace `var' = . if source == 353 & year > 2009 | host == 353 & year > 2009
			replace `var' = . if source == 355 & year < 2010 | host == 355 & year < 2010
		}
		/*check compare update to original dataset
		sum comlang_off comlang_off_2013 col45 col45_2013 lat_source lat_source_2013 gap_lon gap_lon_2013 landlocked_source landlocked_source_2013 
		*/

		drop *2013

		
	// Kosovo -> recycle time-constant variables from Serbia
		// extract source country variables
		preserve
			keep if source == 942
			keep source host year comlang_off col45 lon_source lat_source landlocked_source industrial dist logdist gap_lon
			drop if year < 2010
			by source host, sort: gen nvals=_n
			keep if nvals == 1
			drop nvals year
			replace source = 967
			foreach var of varlist comlang_off col45 lon_source lat_source landlocked_source industrial dist logdist gap_lon{
				rename `var' `var'_967_source
			}
			tempfile gravity_967_source
			save `gravity_967_source'
		restore
		// extract host country variables
		preserve
			keep if host == 942
			keep source host year comlang_off col45 industrial dist logdist gap_lon
			drop if year < 2010
			by source host, sort: gen nvals=_n
			keep if nvals == 1
			drop nvals year
			replace host = 967
			foreach var of varlist comlang_off col45 industrial dist logdist gap_lon{
				rename `var' `var'_967_host
			}
			tempfile gravity_967_host
			save `gravity_967_host'
		restore
		// merge to main dataset
		merge m:1 source host using `gravity_967_source'
		drop _merge
		foreach var of varlist comlang_off col45 lon_source lat_source landlocked_source industrial dist logdist gap_lon{
			replace `var' = `var'_967_source if `var' == . & `var'_967_source != . & year > 2009
			drop `var'_967_source
		}
		merge m:1 source host using `gravity_967_host'
		drop _merge

		foreach var of varlist comlang_off col45 industrial dist logdist gap_lon{
			replace `var' = `var'_967_host if `var' == . & `var'_967_host != .  & year > 2009
			drop `var'_967_host
		}
		// set to missing if country pair does not exist
		foreach var of varlist comlang_off col45 dist logdist gdp* pop* landlocked_source lat_source lon_source gap_lon industrial{
			replace `var'=. if source==967&year<2010|host==967&year<2010
		}

// fill gaps in blank country rows

	// source-level variables
	foreach var of varlist landlocked_source gdp_source loggdppc_source logpop_source pop_source gdppc_source lat_source  sifc_source gdppc_source{
		by source year, sort: egen help_`var' = mean(`var')
		replace `var' = help_`var' if `var' == .
		drop help_`var'
	}


	// host-level variables
 	foreach var of varlist gdppc_host gdp_host pop_host lon_host lat_host{
		by host year, sort: egen help_`var' = mean(`var')
		replace `var' = help_`var' if `var' == .
		drop help_`var'
	}

	// for bilateral variables
	foreach var of varlist comlang_off col45 gap_lon logdist dist industrial loggap_gdp loggap_gdppc{
		by source host year, sort: egen help_`var' = mean(`var')
		replace `var' = help_`var' if `var' == .
		drop help_`var'
	}

// merge indicator for cpis-reporting countries
preserve
	use "$work\cpis_source.dta", clear
	rename source ifscode
	merge 1:1 ifscode using "$raw\dta\matching_iso_ifscode.dta"
	drop if _merge == 2
	keep our_code cpis
	rename our_code source
	tempfile cpis_source
	save `cpis_source'
restore
merge m:1 source using `cpis_source'
drop _merge

/// harmonise country names 
	// source countries
	drop our_code
	rename source our_code
	merge m:1 our_code using "$raw\dta\matching_iso_ifscode.dta"
	drop if _merge == 2 // Curacao; Sint Maarten
	rename our_code source
	replace sourcename = country
	drop country
	drop _merge

	// host countries
	rename host our_code 
	merge m:1 our_code using "$raw\dta\matching_iso_ifscode.dta"
	drop if _merge==2 // Curacao; Sint Maarten
	rename our_code host
	replace hostname=country
	drop country iso3 _merge
	
// keep final variables
keep year source host sourcename eqasset debtasset hostname comlang_off col45 landlocked_source lat_source lat_host lon_host sifc_source cpis gdp_source gdppc_host gap_lon industrial logeqasset logdebtasset logdist loggap_gdp loggap_gdppc loggdppc_source logpop_source

label var logeqasset "Log equities"
label var logdebtasset "Log debt"
label var comlang_off "Common language"
label var col45 "Colony dummy"
label var logdist "Log distance"
label var logpop_source "Log of sce ctry population"
label var loggdppc_source "log gdp per capita sce ctry"
label var loggap_gdp "Log of GDP gap"
label var loggap_gdppc "Log of GDP p.c. gap"
label var industrial "industrial pair"
label var lon_host "longitude host ctry"
label var lat_source "latitude sce ctry"
label var cpis "cpis reporter"

order year source host sourcename eqasset debtasset hostname comlang_off col45 landlocked_source lat_source lat_host lon_host sifc_source gdp_source cpis gdppc_host gap_lon industrial logeqasset logdebtasset logdist loggap_gdp loggap_gdppc loggdppc_source logpop_source
save "$work\data_gravity_update.dta", replace

//----------------------------------------------------------------------------//






