//----------------------------------------------------------------------------//
// Project: Offshore financial wealth database - update 2023
// Title: 	2_do_full_matrices.do
// Purpose: This file constructs the exhaustive 238x238 (?) matrices of all identifiable
//			bilateral portfolio assets starting from the CPIS and using a gravity-
//			like model of bilateral portfolio holdings to derive the bilateral 
//			claims of non-CPIS countries
//
// This version: 18 Oct 2023
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
// Gravity-like Model
//----------------------------------------------------------------------------//


//----------------------------------------------------------------------------//
// Predicted shares from bilateral model
//----------------------------------------------------------------------------//


drop if host==source

// Fixed effects: host and year 
quietly tabulate year, generate(year_)
quietly tabulate host, generate(host_)

// My definition of OFC for the regressions: the 42 countries reported in Table 2 of IMF (2000), except Switzerland */
gen ofc_source=0
replace ofc_source=1 if sifc_source==1

// Add Anguilla, Liechtenstein, BVI, Monaco, Cook Islands, Niue, Ireland, Luxebourg, Hong Kong, Singapore, Cyprus to OFC list
replace ofc_source = 1 if source == 312 | source == 9006 | source == 1200 | source == 1003 | source == 815 | source == 1100 | source == 178 | source == 137 | source == 532 | source == 576 | source == 423
replace ofc_source = 1 if source == 355 // Curacao and Sint Maarten are new in the dataset (previously Netherlands Antilles)

// Remove British Indian Ocean Territory, Dominica, Grenada, Liberia, San Marino, Uruguay, Montserrat, Palau from OFC list
replace ofc_source = 0 if source == 372 | source == 321 | source == 328 | source == 668 | source == 135 | source==298 | source == 351 | source == 565
label variable ofc_source "Sce ctry OFC"

preserve
	drop if ofc_source == 0
	keep source ofc_source
	sort source
	tab source
	drop if source == source[_n-1]
	rename ofc_source ofc_host
	rename source host
	tempfile ofc
	save `ofc'
restore
sort host
merge m:1 host using `ofc'
drop _merge
replace ofc_host = 0 if ofc_host != 1
label variable ofc_host "Host ctry OFC"

replace logeqasset = 0 if eqasset == 0
replace logdebtasset = 0 if debtasset == 0

// Benchmark Regression: Lane & Shambaugh (2010), appendix p. 2
// i.e. same sample (CPIS excluding OFCs source and hosts)
// and same controls (except for capital controls; I could not find the data) */

// sum logeqasset logdebtasset logdist gap_lon comlang_off col45 industrial loggap_gdp loggap_gdppc lat_source landlocked_source logpop_source loggdppc_source ofc_source ofc_host
quietly eststo: reg logeqasset logdist gap_lon comlang_off col45 industrial loggap_gdp loggap_gdppc lat_source landlocked_source logpop_source loggdppc_source year_* host_* if ofc_source == 0 & ofc_host == 0
quietly eststo: reg logdebtasset logdist gap_lon comlang_off col45 industrial loggap_gdp loggap_gdppc lat_source landlocked_source logpop_source loggdppc_source year_* host_* if ofc_source == 0 & ofc_host == 0

/* Results: I get a somewhat smaller R2 than they do (0.76 instead of 0.79) and gap_long has the wrong sign.
So in what follows I drop it */

/* Regression augmented: Lane & Shambaugh, but full sample (ie including OFC) + interaction between OFC and host countries + drop gap_lon  */
xi I.ofc_source*I.host, prefix(_I)
set matsize 1000
quietly eststo: reg logeqasset logdist comlang_off col45 industrial loggap_gdp loggap_gdppc ofc_source lat_source landlocked_source logpop_source loggdppc_source  year_* host_* _IofcXhos_1_*
predict logeqp
quietly eststo: reg logdebtasset logdist comlang_off col45 industrial loggap_gdp loggap_gdppc ofc_source lat_source landlocked_source logpop_source loggdppc_source year_* host_* _IofcXhos_1_*
predict logdebtp

esttab, drop (_cons host_* year_* _IofcXhos_*) cells(b(star fmt(%9.3f)) se(par)) ar2 label legend

drop year_* host_* _Ihost_* _IofcXhos_* _Iofc_sourc_1


gen eqp=exp(logeqp)-1
gen debtp=exp(logdebtp)-1

// some predicted values are very very slightly negative, I replace them by zero
replace eqp=0 if eqp<0
replace debtp=0 if debtp<0


// Comparison of predicted shares and true shares
// First: computation of allocated shares (i.e. excluding not specified (including confidential) (983)
sort source year
by source year: egen toteqalloc=total(eqasset) if host!=983
by source year: egen totdebtalloc=total(debtasset) if host!=983

gen shareeqalloc=0
replace shareeqalloc=eqasset/toteqalloc
gen sharedebtalloc=0
replace sharedebtalloc=debtasset/totdebtalloc

// Second: computation of predicted shares
sort source year
by source year: egen toteqp=total(eqp)
by source year: egen totdebtp=total(debtp)
gen shareeqp=eqp/toteqp
gen sharedebtp=debtp/totdebtp


//----------------------------------------------------------------------------//
// Allocation of confidential + unallocated claims 
//----------------------------------------------------------------------------//

replace eqasset = 0 if eqasset == .
replace debtasset = 0 if debtasset == .


// First, I compute source-level aggregates, because these are bigger than total claims + unallocated claims 
// --> So I want to put the residual in unallocated, and allocate the residual too


// a) I compute the raw sums
sort source year
by source year: egen toteqasset=total(eqasset)
by source year: egen totdebtasset=total(debtasset)

// b) I compare the raw sums with aggregates from CPIS data
merge m:1 source year using "$work/data_toteq_update.dta" 
drop _merge cname
merge m:1 source year using "$work/data_totdebt_update.dta"
drop _merge cname


/* Check that sums of aggregate is different than sums of all bilateral claims : 
tabstat eqasset debtasset, stat(sum) by(year) format(%16.0f )
sort source year host
tabstat sumeqasset sumdebtasset if year!=year[_n-1], stat(sum) by(year) format(%16.0f )
*/

by year, sort: egen help_total_eq = total(sumeqasset)
by year, sort: egen help_total_debt = total(sumdebtasset)


// c) CONCLUSION = In the IMF CPIS raw datafiles (March 2023), the sum for each source country of its foreign claims is not always equal to the reported total, i.e. some unallocated claims are missing from the line "Not specified (inlcuding confidential)")
// I add them here >> this augments the line "not specified" 983) */

gen missingeq = 0
replace missingeq = sumeqasset - toteqasset
gen missingdebt = 0
replace missingdebt = sumdebtasset - totdebtasset
replace eqasset = eqasset + missingeq if host == 983 & missingeq != .
replace debtasset = debtasset + missingdebt if host == 983 & missingdebt != .
drop sumeqasset sumdebtass missingeq missingdebt



// Second: allocation of unallocated+confidential


// a) I assume that all unallocated + confidential claims are vis-a-vis countries for which A_{ij} is either missing or zero or Andorra, or Liechtenstein or Monaco (in most cases A_{ij} is zero for these countries but sometimes not, which introduces spurrious variation in the allocation of the unallocated claims. I also disregard San Marino, a clear outlier.
// (NB: I have replaced all missing values by zeros at the beginning of this section) */ 

gen confidentialeq = 0
gen ignore_jur=1 if host==353&year>2009|host==355&year<2010|host==357&year<2010
replace ignore_jur=1 if host==537&year<2002
replace ignore_jur=1 if host==733&year<2011
replace ignore_jur=1 if host==943&year<2006

replace confidentialeq = 1 if (eqasset == 0 | host == 1001 | host == 9006 | host == 1003) & toteqasset !=. & toteqasset != 0 & host != 135 & ignore_jur != 1 // 1001 "Andorra", 9006 "Liechtenstein", 1003 "Monaco", 135 "San Marino"

gen confidentialdebt=0
replace confidentialdebt=1 if (debtasset == 0 | host == 1001 | host == 9006 | host == 1003) & totdebtasset != . & totdebtasset !=0 & host != 135 & ignore_jur != 1 


// b): Prorate source-level confidential and unallocated totals, 
//using the predicted shares from the bilateral regression for missing A_{ij} pairs


// i) Generate predicted share of each missing country (rescaled such that sum of predicted shares = 1)
gen eqpconf = eqp * confidentialeq
gen debtpconf = debtp * confidentialdebt

sort source year
by source year: egen toteqpconf = total(eqpconf)
by source year: egen totdebtpconf = total(debtpconf)

gen shareeqpconf = eqpconf / toteqpconf
replace shareeqpconf = 0 if shareeqpconf == .
gen sharedebtpconf = debtpconf / totdebtpconf
replace sharedebtpconf = 0 if sharedebtpconf == .

// b) generate colums with amount of "not specified incl. confidential (983)" equity + debt claims 
preserve
	keep if host == 983
	keep source year host eqasset debtasset
	gen totunalloceq = eqasset
	gen totunallocdebt = debtasset
	drop host eqasset debtasset
	tempfile unalloc
	save `unalloc'
restore

// c) Merge these column with my dataset */
sort year source
merge m:1 year source using `unalloc'
drop _merge

// d) Now create predicted claims for all countries non SEFER
gen unalloceq = 0
replace unalloceq = shareeqpconf * totunalloceq if source != 9999
gen unallocdebt = 0
replace unallocdebt = sharedebtpconf * totunallocdebt if source != 9999
sort source year

// e) I create an augmented asset line, equal to the raw asset line + allocated confidential+unalloc
// I set the unallocated and confidential lines to zero

gen augmeqasset = eqasset
replace augmeqasset = eqasset + unalloceq if host != 983 & source != 9999
replace augmeqasset = 0 if host == 983

gen augmdebtasset = debtasset
replace augmdebtasset = debtasset + unallocdebt if host != 983 & source != 9999
replace augmdebtasset = 0 if host == 983

// f) For SEFER, I simply prorate unallocad+confidential claims following the allocated claims pattern*/
replace augmeqasset = augmeqasset + shareeqalloc * totunalloceq if source == 9999
replace augmdebtasset = augmdebtasset + sharedebtalloc * totunallocdebt if source == 9999

// Check that the sum of assets (incl. unallocated) equals sum of augmented assets (having allocated the unallocated)
sort source year host
tabstat eqasset augmeqasset debtasset augmdebtasset, stat(sum) by(year) format(%16.0f)

save "$work/temp.dta", replace
save "$work/temp_30.dta", replace
use "$work/temp_30.dta", clear


//----------------------------------------------------------------------------//
// Allocation of Cayman Islands non-bank sector
//----------------------------------------------------------------------------//


merge 1:1 year source host using "$work/Cayman_TIC_Dec.dta"
drop if _merge==2 // 2022
drop _merge

/* view
br source host year eq_KY_TIC debt_KY_TIC eqp debtp augmeqasset augmdebtasset if host==111&source==377
*/
replace augmeqasset = eq_KY_TIC if source == 377 & host == 111 & augmeqasset < eq_KY_TIC
replace augmdebtasset = debt_KY_TIC if source == 377 & host == 111 & year < 2015

// assume constant 2015 share of U.S. assets in total KY assets for pre-2015
egen help_toteq_KY = total(augmeqasset) if source == 377, by(year source)
gen share_US_KY = augmeqasset / help_toteq_KY if source == 377 & host == 111 & year > 2014
sort source host year
forvalues i = 1/14 {
	replace share_US_KY = share_US_KY[_n+1] if share_US_KY == . & year < 2015 & source == 377 & host == 111 
}
	
egen help_totdebt_KY=total(augmdebtasset) if source==377, by(year source) 
gen share_debt_US_KY = augmdebtasset / help_totdebt_KY if source == 377 & host == 111 & year > 2014  
sort source host year
forvalues i = 1/14{
	replace share_debt_US_KY = share_debt_US_KY[_n+1] if share_debt_US_KY == . & year < 2015 & source == 377 & host == 111
}
drop *_KY_*  help_tot*_KY


preserve
	forvalues t = 2001(1)2014 {
		gen caymantoteq`t' = augmeqasset / share_US_KY if year == `t' & source == 377 & host == 111
		gen caymantotdebt`t' = augmdebtasset / share_debt_US_KY if year == `t' & source == 377 & host == 111
	}

	keep if host == 111 & source == 377
	keep source caymantoteq* caymantotdebt*
	gen id=[_n]
	reshape long caymantoteq caymantotdebt, i(id) j(year)
	drop if caymantoteq == . | caymantotdebt == .
	drop id
	sort source year
	tempfile caymantot
	save `caymantot'
restore
merge m:1 source year using `caymantot'
drop _merge

/*browse
br source host year eqp debtp augmeqasset augmdebtasset shareeqp sharedebtp if host == 111 & source == 377
br source* host* year eqp debtp augmeqasset augmdebtasset shareeqp sharedebtp if host==111 & source == 377 | host == 112 & source == 377
*/

// rescale share of other countries because gravity model overestimates them:
egen test_shareeqp=total(shareeqp), by(year source)
drop test_shareeqp

egen share_nonus_eq_old = total(shareeqp) if host != 111, by(year source)
egen share_nonus_eq_new = mean(share_US_KY), by(year)
replace share_nonus_eq_new = 1 - share_nonus_eq_new
replace share_nonus_eq_new = . if host == 111
gen rescale_eq = share_nonus_eq_new / share_nonus_eq_old
gen shareeq_KY = shareeqp*rescale_eq if host != 111

egen share_nonus_debt_old = total(sharedebtp) if host! = 111, by(year source)
egen share_nonus_debt_new = mean(share_debt_US_KY), by(year)
replace share_nonus_debt_new = 1 - share_nonus_debt_new
replace share_nonus_debt_new = . if host == 111
gen rescale_debt = share_nonus_debt_new / share_nonus_debt_old
gen sharedebt_KY = sharedebtp * rescale_debt if host != 111

/*
egen test_sharedebt_KY = total(sharedebt_KY), by(year source)
*/

replace augmeqasset = caymantoteq * shareeq_KY if source == 377 & host != 111 & year < 2015
replace augmdebtasset = caymantotdebt * sharedebt_KY if source == 377 & host != 111 & year < 2015

// check
tabstat augmeqasset augmdebtasset  if source==377, stat(sum) by(year) format(%16.0f)
tabstat caymantoteq caymantotdebt  if source==377, stat(mean) by(year) format(%16.0f)
drop caymantotdebt caymantoteq

save "$work/temp.dta", replace
use "$work/temp.dta", clear


//----------------------------------------------------------------------------//
// Allocation of other CPIS countries 
//----------------------------------------------------------------------------//

// Filling the gap for CPIS countries that have not always reported their data

// to fill reporting gaps of countries that have not reported each year, use each country's share in total CPIS-countries' assets in reporting years and apply it to the totals in missing years

// eqassets
gen help_share_eq = toteqasset / help_total_eq

// debtassets
gen help_share_debt=totdebtasset / help_total_debt

sort source host year

	//Bahrain
	/* br year source sourcename host totdebtasset help_total_debt help_share_debt if source == 419 & host == 111*/

	foreach x in "eq" "debt"{
		forvalue i = 1/2{
		replace help_share_`x'= help_share_`x'[_n+1] if help_share_`x' == 0 & source == 419
		}
	replace tot`x'asset=help_share_`x'*help_total_`x' if source == 419 & year == 2002 | source == 419 & year == 2003 | source == 419 & year == 2016
	replace augm`x'asset = tot`x'asset * share`x'p if source == 419 & year == 2002 | source == 419 & year == 2003 | source == 419 & year == 2016
	}

	// Barbados
	foreach x in "eq" "debt"{
		forvalue i = 1/2{
			replace help_share_`x'= help_share_`x'[_n+1] if help_share_`x' == 0 & source == 316
		}
		replace help_share_`x'= help_share_`x'[_n-1] if help_share_`x' == 0 & source == 316
		replace tot`x'asset=help_share_`x'*help_total_`x' if source == 316 & (year < 2003 | year > 2015)
		replace augm`x'asset = tot`x'asset * share`x'p if source == 316 & (year < 2003 | year > 2015)
	}
	
	// Gibraltar
	/* br year source sourcename host toteqasset help_share* if source == 823 & host == 111*/
		foreach x in "eq" "debt"{
			forvalue i = 1/3{
				replace help_share_`x'= help_share_`x'[_n+1] if help_share_`x' == 0 & source == 823
			}
			replace tot`x'asset=help_share_`x'*help_total_`x' if source == 823 & toteqasset == 0 
			replace augm`x'asset = tot`x'asset * share`x'p if source == 823 & augmeqasset == 0 
		}

	// India
	br year source sourcename host toteqasset totdebtasset help_share* if source==534&host==111
	foreach x in "eq" "debt"{
		forvalue i = 1/3{
			replace help_share_`x' = help_share_`x'[_n+1] if help_share_`x' == 0 & source == 534
		}
		replace tot`x'asset = help_share_`x' * help_total_`x' if tot`x'asset == 0 & source == 534
		replace augm`x'asset = tot`x'asset * share`x'p if augm`x'asset == 0 & source == 534
	}

	// Kuwait
	/* br year source sourcename host toteqasset help_share* if source == 443 & host == 111*/
	foreach x in "eq" "debt"{
		forvalue i = 1/2{
			replace help_share_`x' = help_share_`x'[_n+1] if help_share_`x' == 0 & source == 443
		}
		replace tot`x'asset = help_share_`x' * help_total_`x' if tot`x'asset == 0 & source == 443
		replace augm`x'asset = tot`x'asset * share`x'p if augm`x'asset == 0 & source == 443
	}

	// Latvia
	/* br year source sourcename host totdebtasset toteqasset help_share* if source == 941 & host == 111 */
	foreach x in "eq" "debt"{
		forvalue i = 1/5{
			replace help_share_`x' = help_share_`x'[_n+1] if help_share_`x' == 0 & source == 941
		}
		replace tot`x'asset = help_share_`x' * help_total_`x' if tot`x'asset == 0 & source == 941
		replace augm`x'asset = tot`x'asset * share`x'p if augm`x'asset == 0 & source == 941
	}

	// Mexico
	/* br year source sourcename host totdebtasset toteqasset help_share* if source == 273 & host == 111 */
	foreach x in "eq" "debt"{
		forvalue i = 1/2{
			replace help_share_`x' = help_share_`x'[_n+1] if help_share_`x' == 0 & source == 273
		}
		replace tot`x'asset = help_share_`x' * help_total_`x' if tot`x'asset == 0 & source == 273
		replace augm`x'asset = tot`x'asset * share`x'p if augm`x'asset == 0 & source == 273
	}

	// Cayman
	/* br year source sourcename host  totdebtasset toteqasset help_share* if source == 377 & host == 111*/
	foreach x in "eq" "debt"{
		replace help_share_`x'=help_share_`x'[_n+1] if help_share_`x'==0&source==377
		replace tot`x'asset=help_share_`x'*help_total_`x' if tot`x'asset==0 &source==377
	} // no replace augmeqasset because already estimated


	// Panama 2021
	/* br year source sourcename host  totdebtasset toteqasset help_share* if source == 283 & host == 111 */
	foreach x in "eq" "debt"{
		replace help_share_`x' = help_share_`x'[_n-1] if help_share_`x' == 0 & source == 283
		replace tot`x'asset = help_share_`x' * help_total_`x' if tot`x'asset == 0 & source == 283
		replace augm`x'asset = tot`x'asset * share`x'p if augm`x'asset == 0 & source == 283
	}

	// Venezuela 2018-2021
	/* br year source sourcename host  totdebtasset toteqasset help_share* if source == 299 & host == 111 */
	foreach x in "eq" "debt"{
		replace help_share_`x' = help_share_`x'[_n-1] if help_share_`x' == 0 & source == 299
		replace tot`x'asset = help_share_`x' * help_total_`x' if tot`x'asset == 0 & source == 299
		replace augm`x'asset = tot`x'asset * share`x'p if augm`x'asset == 0 & source == 299
	}

	// Bahamas 2015-2017
	/* br year source sourcename host  totdebtasset toteqasset help_share* if source == 313 & host == 111 */
	foreach x in "eq" "debt"{
		replace help_share_`x' = help_share_`x'[_n-1] if help_share_`x' == 0 &source == 313
		replace tot`x'asset = help_share_`x' * help_total_`x' if tot`x'asset == 0 & source == 313
		replace augm`x'asset = tot`x'asset * share`x'p if augm`x'asset == 0 & source == 313
	}

	// Pakistan 2001
	/* br year source sourcename host  totdebtasset toteqasset help_share* if source == 564 & host == 111 */
	foreach x in "eq" "debt"{
		replace help_share_`x' = help_share_`x'[_n+1] if help_share_`x' == 0 & source == 564
		replace tot`x'asset = help_share_`x' * help_total_`x' if tot`x'asset == 0 & source == 564
		replace augm`x'asset = tot`x'asset * share`x'p if augm`x'asset == 0 & source == 564
	}

	// Isle of Man 2019-2021
	/* br year source sourcename host  totdebtasset toteqasset help_share* if source == 1012 & host == 111 */
	foreach x in "eq" "debt"{
		replace help_share_`x'=help_share_`x'[_n-1] if help_share_`x' == 0 & source == 1012
		replace tot`x'asset = help_share_`x' * help_total_`x' if tot`x'asset == 0 & source == 1012
		replace augm`x'asset = tot`x'asset * share`x'p if augm`x'asset == 0 & source == 1012
	}

	/*other countries? -> too long periods missing
	by source, sort: egen help=total(toteqasset)
	br source sourcename year toteqasset help_share_eq help_total_eq if toteqasset==0&host==111&help!=0
	version 16: table sourcename if toteqasset==0&host==111&help!=0
	drop help
	Bolivia 2001-2010 source==218
	El Salvador 2001-2018 source==253
	Honduras 2001-2013 source==268
	Peru 2001-2014, 2018-2021 source==293
	Netherlands Antilles after 2009
	Saudi Arabia 2001-2012 source==456
	West Bank and Gaza 2001-2014 source==487
	Bangladesh 2001-2013 source==513
	Liberia (reported only 2012-2015) source==668
	Namibia reported only 2020 source==728
	Vanuatu reported only 2001-2003, and 2005-2006 source==846
	Belarus 2001-2013 source 913 
	Albania 2001- 2014 source==914
	China 2001- 2014 source==924
	Lithuania 2001-2008 source==946
	Mongolia 2001-2009, 2021 source==948
	Slovenia 2001-2008 source==961 
	North Macedonia 2001-2015 source==962
	Kosovo 2001-2009 source==967
	Vanuatu 2007-2021
	*/


//----------------------------------------------------------------------------//
// The missing Netherlands SFIs 
//----------------------------------------------------------------------------//
// "With the introduction of BPM6 in September 2014 the Dutch data includes the 
// figures of the SFIs sector" (IMF BoP Metadata Responses by country")
// In 2001 and 2002, CPIS did not include SFIs -> add those values from Zucman (2013)
replace toteqasset = toteqasset + 3286 if source == 138 & year == 2001 
replace toteqasset = toteqasset + 2601 if source == 138 & year == 2002
replace totdebtasset = totdebtasset + 20984 if source == 138 & year == 2001 
replace totdebtasset = totdebtasset + 16611 if source == 138 & year == 2002

replace augmeqasset = toteqasset * shareeqalloc if source == 138
replace augmdebtasset = totdebtasset*sharedebtalloc if source == 138
save "$work/temp.dta", replace


//----------------------------------------------------------------------------//
// Allocation of CHINA
//----------------------------------------------------------------------------//
// Total Chinese assets given by private portfolios + 85% of reserves
// U.S. assets owned by China given by TIC survey hence U.S. share
// I assume that Non-US shares given by share of each individual country in 
// total SEFER+SSIO investments in non-US countries

preserve
	use "$work/TIC_China_Dec.dta", clear
	merge 1:1 year using "$work/data_IMF_China.dta"
	drop _merge

	// Equity from IIP China only reliable starting from 2008 -> extrapolate backwards
	// using the proportional change of U.S. equity liabilities vis-a-vis China
	// (source: Betraut and Tyron)
	// Equity
	gen growth_equity = eq_China_TIC / eq_China_TIC[_n+1]
	replace Equity_IMF = . if year < 2007
	forvalue i = 1/6{
		replace Equity_IMF = Equity_IMF[_n+1] * growth_equity if Equity_IMF == .
	}

	// For debt figures -> use IMF IIP 2004-2008 and extrapolate backwards similarly
	// estimate missing CPIS values for 2001-2003 based on TIC
	gen growth_Debt = debt_China_TIC / debt_China_TIC[_n+1]
	forvalue i = 1/3 {
		replace Debt_IMF = Debt_IMF[_n+1]*growth_Debt if Debt_IMF == .
	}
	drop growth*

	// Assumption: share of foreign exchange reserves held in securities 85%-95%
	gen share = 0.85
	replace share = 0.87 if year == 2009
	replace share = 0.89 if year == 2010
	replace share = 0.91 if year == 2011
	replace share = 0.93 if year == 2012
	replace share = 0.95 if year > 2012

	gen reserves_China = share * Reserves_IMF
	gen equity_ratio_TIC = eq_China_TIC / total_China_TIC
	gen totaleq_China_public = equity_ratio * reserves_China
	gen totaldebt_China_public = (1 - equity_ratio) * reserves_China
	gen totaleq_China = equity_ratio_TIC * (reserves_China + Equity_IMF + Debt_IMF)
	gen totaldebt_China = (1 - equity_ratio_TIC) * (share * Reserves_IMF + Equity_IMF + Debt_IMF)
	keep year source host eq_China_TIC debt_China_TIC share equity_ratio_TIC totaleq_China* totaldebt_China* reserves
	tempfile china
	save `china'
	
restore

merge m:1 year source using `china'
drop if _merge == 2 // 2022
drop _merge
replace toteqasset = totaleq_China if source == 924
replace totdebtasset = totaldebt_China if source == 924


// Total and U.S. assets

gen useqassetchina = eq_China_TIC if source == 924
gen usdebtassetchina = debt_China_TIC if source == 924
/* br year useqasset usdebtasset if source == 924 & host == 111 */

// Total non U.S. assets of China

gen nonuseqassetchina = toteqasset - useqassetchina if source == 924
gen nonusdebtassetchina = totdebtasset - usdebtassetchina if source == 924


// Share of SEFER+SSIO in each non-US non-China country
preserve
	drop if source != 9999
	drop if host == 111 | host == 924 // USA:China
	keep source year host augmeqasset augmdebtasset
	sort year
	by year: egen toteqnonus = total(augmeqasset)
	by year: egen totdebtnonus = total(augmdebtasset)
	gen shareeqsefernonus = augmeqasset / toteqnonus
	gen sharedebtsefernonus = augmdebtasset / totdebtnonus
	keep year host shareeqsefernonus sharedebtsefernonus
	sort host year
	tempfile sefernonus
	save `sefernonus'
restore
sort host year
merge m:1 host year using `sefernonus'
drop _merge

// Computation of China's bilateral assets
/* br year augmeqasset useqassetchina if source == 924 & host == 111 */
replace augmeqasset = useqassetchina if source == 924 & host == 111
/* br year augmdebtasset usdebtassetchina if source == 924 & host == 111 */
sort source host year
replace augmdebtasset = usdebtassetchina if source == 924 & host == 111
replace shareeqalloc = augmeqasset / toteqasset if source == 924 & host == 111
replace sharedebtalloc = augmdebtasset / totdebtasset if source == 924 & host == 111

replace augmeqasset = shareeqsefernonus * nonuseqassetchina if source == 924 & host != 111
replace augmdebtasset = sharedebtsefernonus * nonusdebtassetchina if source == 924 & host != 111

/* CHECK 
tabstat eqasset augmeqasset debtasset augmdebtasset if source == 924, by(year) stats(sum)
*/
drop nonusdebtassetchina nonuseqassetchina usdebtassetchina useqassetchina shareeqsefernonus sharedebtsefernonus
drop *_TIC share

//----------------------------------------------------------------------------//
// Allocation of ME OIL
//----------------------------------------------------------------------------//

// Total U.S. (onshore) assets given by TIC survey
// Following literature assumptions on U.S. share (70% in 2002 and declining 
// 2 pct points per year >> 48% in 2011
// For non-US shares: bilateral model (because probably invested differently 
// than reserve assets) 

/* br year source host eqasset toteqasset shareeqp if source == 456 */
// Saudi Arabia now available starting from 2013
preserve
	use "$work/TIC_update_middleast.dta", clear
	append using "$work/Bertaut_Judson_middleeast_Dec.dta" // to be consistent with Zucman (2013)
	drop flag country_code month // memo: Bertaut & Judson December
	gen source = 4566 if country == " Middle Eastern Oil Exporters"
	replace source = 419 if country == "Bahrain" & year > 2010 
	replace source = 429 if country == "Iran" & year > 2010
	replace source = 433 if country == "Iraq" & year > 2010
	replace source = 443 if country == "Kuwait" & year > 2010
	replace source = 449 if country == "Oman" & year > 2010
	replace source = 453 if country == "Qatar" & year > 2010
	replace source = 466 if country == "United Arab Emirates" & year > 2010
	replace source = . if country == " Middle Eastern Oil Exporters" & year > 2010
	replace source = 456 if country == "Saudi Arabia" & year > 2010
	
	// collapse all Middle East countries into one aggregate
	drop if source == .
	collapse (sum) Total Equity Debtl, by(year)
	// values correspond to rows [8] and [9] in Table A8, Zucman2015MissingWealth.xslx

	// adjust because of switch in reporting period from December (until 2010) to June (after 2010)
	merge 1:1 year using "$work/adjust_period.dta"
	drop if _merge == 2 // > 2021
	drop _merge
	replace Equity = Equity * adj_eq if year > 2010
	drop adj

	// estimate short-term debt based on short-term long-term ratio of international organisations
	merge m:1 year using "$work/shortterm_ratio_FOI.dta"
	drop if _merge == 2 // 2022
	drop _merge
	rename short_long_ratio ratio_shortlong
	gen Debt_est = Debtl + (ratio_shortlong * (Debtl + Equity))
	gen Total_est = Equity + Debt_est
	// values correspond to lines [12] and [13] Table A8, Zucman2015MissingWealth.xlsx

	rename (Total Equity Debtl Debt_est Total_est) (Total_TIC Equity_TIC Debtl_TIC Debt_est_TIC Total_est_TIC) 

	// US share in total assets of Middle Eastern oil exporters
	gen USshare=0.7 if year==2001
	replace USshare = USshare[_n-1] - 0.02 if USshare == . & year < 2013
	replace USshare = round(USshare,0.01)
	replace USshare = USshare[_n-1] if USshare == .

	keep year Equity_TIC Debt_est_TIC Total_est_TIC ratio_shortlong USshare
	rename (Equity_TIC Debt_est_TIC Total_est) (Equity_TIC_ME Debt_TIC_ME Total_TIC_ME)
	gen toteqasset_ME = Equity_TIC / USshare
	gen totasset_ME = (Total_TIC_ME) / USshare
	gen totdebtasset_ME = totasset_ME - toteqasset_ME
	keep year totasset_ME toteqasset_ME totdebtasset_ME USshare 
	// values correspond to lines [15] and [16] Table A8, Zucman2015MissingWealth.xlsx
	
	tempfile middle_east
	save `middle_east'

restore

// extract Bahrain & Kuwait private assets
// assets reported to CPIS need to be subtracted from correction, 
// CPIS now also includes Saudi Arabia from 2013 onwards
preserve
	keep year source sourcename host toteqasset totdebtasset
	keep if source == 419 | source == 443 | source == 456 // Bahrain, Kuwait, Saudi Arabia
	by source year, sort: gen help = _n
	keep if help == 1
	drop help
	collapse (sum) toteqasset (sum) totdebtasset, by(year)
	rename (toteqasset totdebtasset) (toteqasset_reported totdebtasset_reported)
	tempfile cpis_reported_ME_assets
	save `cpis_reported_ME_assets'

	// subtract CPIS reported Middle East assets from estimated total Middle East assets
	merge 1:1 year using `middle_east'
	replace toteqasset_ME = toteqasset_ME - toteqasset_reported
	replace totdebtasset_ME = totdebtasset_ME - totdebtasset_reported
	// values correspond to lines [22] and [23] in Table A8, Zucman2015MissingWealth.xlsx
	drop _merge *_reported
	gen source = 453 // Use Qatar country code as parking slot for total ME assets missed by CPIS
	tempfile middle_east2
	save `middle_east2'
restore
merge m:1 source year using `middle_east2'
br if _merge==3
drop _merge
br year source host eqasset debtasset toteqasset totdebtasset toteqasset_ME totdebtasset_ME if source==453&host==111

// replace Qatar's assets by total implied onshore portfolio missed by CPIS (lines 22 & 23)
replace toteqasset = toteqasset_ME if source == 453
replace totdebtasset = totdebtasset_ME if source == 453

gen usoileqasset = USshare * toteqasset if source == 453
gen usoildebtasset = USshare * totdebtasset if source == 453
gen nonusoileqasset = toteqasset - usoileqasset if source == 453
gen nonusoildebtasset = totdebtasset - usoildebtasset if source == 453

// Total and U.S. assets
	// non-US shares
	// I rescale the predicted shares
	preserve
		keep if host == 111
		keep source year shareeqp sharedebtp
		rename (shareeqp sharedebtp) (shareequsp sharedebtusp)
		sort source year
		/* br if source == 453 */
		tempfile shareusp
		save `shareusp'
	restore
	sort source year
	merge m:1 source year using `shareusp'
	drop _merge
	gen shareeqpnonus = shareeqp / (1 - shareequsp)
	gen sharedebtpnonus = sharedebtp / (1 - sharedebtusp)
	/* br toteqasset augmeqasset shareeqpnonus nonusoileqasset if source == 453 &host != 111 */
	replace augmeqasset = shareeqpnonus * nonusoileqasset if source == 453 & host != 111
	replace augmdebtasset = sharedebtpnonus * nonusoildebtasset if source == 453 & host != 111
	replace augmeqasset = USshare * toteqasset if source == 453 & host == 111
	replace augmdebtasset = USshare * totdebtasset if source == 453 & host == 111
	drop USshare usoileqasset usoildebtasset nonusoileqasset nonusoildebtasset

/*CHECK 
tabstat augmeqasset augmdebtasset if source == 453, by(year) stats(sum) format(%16.0f)
*/



//----------------------------------------------------------------------------//
// Allocation of other non CPIS
//----------------------------------------------------------------------------//


// I -- Private assets 

/// Total portfolio assets of non-CPIS countries are given
// a) by Lane and Milesi-Ferretti (2018) EWNII database updated in 2022
// b) When aportif_debt is missing, I take 20% of adebt (20% = unweighted mean value of aportif_debt/adebt 
// for the sample of countries that have both data in the EWNII August 2009. NB: slight upward trend over 2001-2007)
// c) for countries not in the database: augmented CPIS-derived liabilities
// d) Bilateral allocation = gravity model 

// External Wealth of Nations database 2022 (EWN22)
preserve
	use "$work/data_ewn_update.dta", clear
	rename source ifscode
	merge m:1 ifscode using "$work/iso_ifscode.dta"
	drop if _merge == 2
	drop _merge
	replace our_code = 355 if ifscode == 355
	rename our_code source
	save "$work/data_ewn_update_ifs.dta", replace
restore
merge m:1 source year using "$work/data_ewn_update_ifs.dta"
drop lequity lportif_debt _merge
// ewn22 = dummy for country in EWN22
rename ewn22 ewn22_source

// When aportif_debt missing, use 0.2 x adebt
replace aportif_debt = 0.2 * adebt if aportif_debt == . & adebt != . 
replace toteqasset = aequity if cpis != 1 & source != 924 & source != 449 & source != 453 & source != 456 & source != 466 & source != 429 & source != 433 // China, Oman, Qatar, Saudi Arabia, UAE, Iran, Iraq
replace totdebtasset = aportif_debt  if cpis !=1 & source != 924 & source != 449 & source != 453 & source != 456 & source != 466 & source != 429 & source != 433

// Derived liabilities from (augmented) CPIS 
preserve
	sort host year
	by host year: egen augmeqliab = total(augmeqasset)
	by host year: egen augmdebtliab = total(augmdebtasset)
	keep host year augmeqliab augmdebtliab
	drop if augmeqliab[_n] == augmeqliab[_n-1]
	rename host source
	sort source year
	tempfile derived
	save `derived'
restore

sort source year
merge m:1 source year using `derived'
drop _merge

// NB: important to subtract IOs (9998) which have derived liab, but whose assets are already counted in SEFER 9999
// China, Oman, Qatar, Saudi Arabia, UAE, Iran, Iraq
replace toteqasset = augmeqliab if cpis != 1 & source != 924 & source != 449 & source != 453 & source != 456 & source != 429 & source != 433 & source != 466 & source != 9998 & aequity == .
replace totdebtasset = augmdebtliab if cpis != 1 & source != 924 & source != 449 & source != 453 & source != 456 & source != 466 & source != 429 & source != 433 & source != 9998 & aportif_debt == .

// Bilateral estimates: for private holdings, gravity model
replace augmeqasset = shareeqp * toteqasset if cpis != 1 & source != 924 & source != 449 & source != 453 & source != 456 & source != 466 & source != 429 & source != 433
replace augmdebtasset = sharedebtp * totdebtasset if cpis != 1 & source != 924 & source != 449 & source != 453 & source != 456 & source != 466 & source != 429 & source ! = 433


// II - Reserve of non-CPIS countries: I use IFS data and assume 75% invested in securities
// (74% in debt and 1% in equity) 
preserve
	use "$work\data_foreignexchange_update.dta", clear
	drop if source == 163 | source == 309 | source == 758 | source == 759 | source == 967 // Regional organizations
	sort source year
	tempfile missingreserve
	save `missingreserve'
restore

sort source year
merge m:1 source year using `missingreserve'
drop _merge

// Create the total missing reserves 
gen debtreserveIFS = 0.74 * reserveIFS
gen eqreserveIFS = 0.01 * reserveIFS

preserve
	sort source year
	drop if year == year[_n-1]
	// Assume that all CPIS countries participate in SEFER, so missing reserves = non CPIS non oil non China
	// China and Saudi Arabia participate in recent years, but no jump in SEFER 
	// (and initial sum still same as in Zucman 2013) so their reserves are probably still missing
	drop if cpis == 1 | source == 924 | source == 449 | source == 453 | source == 456 | source == 466 | source == 433 | source == 429 | source == 429 | source == 433
	sort year
	by year: egen missingeqres=total(eqreserveIFS)
	by year: egen missingdebtres=total(debtreserveIFS)
	keep year missingeqres missingdebtres
	sort year
	drop if year == year[_n-1]
	tempfile missingreserve2
	save `missingreserve2'
restore
sort year
merge m:1 year using `missingreserve2'
drop _merge

// Assume that they all follow the same SEFER-SSIO pattern
preserve
	drop if source != 9999
	keep year host augmeqasset augmdebtasset
	sort year
	by year: egen toteq = total(augmeqasset)
	by year: egen totdebt = total(augmdebtasset)
	gen shareeqsefer = augmeqasset / toteq
	gen sharedebtsefer = augmdebtasset / totdebt
	keep year host shareeqsefer sharedebtsefer
	sort host year
	tempfile sefer
	save `sefer'
restore
sort host year
merge m:1 host year using `sefer'
drop _merge

// Create a new "source" country 9994 corresponding to the missing SEFER (non-oil and non China)
gen othereqreserve = shareeqsefer * missingeqres
gen otherdebtreserve = sharedebtsefer * missingdebtres
preserve
	keep host year othereqreserve otherdebtreserve
	sort host year
	drop if year == year[_n-1]
	drop if host == .
	gen source = 9994
	rename othereqreserve augmeqasset
	rename otherdebtreserve augmdebtasset
	sort source host year
	tempfile otherreserve
	save `otherreserve'
restore
sort source host year
append using `otherreserve'


//----------------------------------------------------------------------------//
// EWNII and derived liabilities
//----------------------------------------------------------------------------//


/// Three methods for liabilities: 1) for EWNII countries, use data from EWNII 
// 1) Correction to EWNII data: Netherlands, CPIS<liab; Cayman Islands fund industry CPIS<liab]
// 2) use BIS data for total debt of international organizations
// 3) for non EWNII countries, use CPIS-augmented derived liab


// A - Bringing back liabilities for host countries

// 1) EWNII
preserve
	use "$work/data_ewn_update_ifs.dta", clear
	rename source host
	sort host year
	keep year host lequity lportif_debt ewn22
	tempfile ewn22
	save `ewn22'
restore

sort host year
merge m:1 host year using `ewn22'
rename ewn22 ewn22_host
sort host source year
drop _merge

rename lequity lequity_host
rename lportif_debt lportif_debt_host


// 1bis) Correction for EWNII data

	// Correction for Netherlands SFIs */
	gen eqliab_host = lequity_host
	gen debtliab_host = lportif_debt_host
	// SFIs were included in CPIS starting from 2003 -> add only 2001 and 2002 from Zucman (2013)
	gen lequity_SFI = 6635 if host == 138 & year == 2001
	replace lequity_SFI = 8177 if host == 138 & year == 2002
	replace eqliab_host = lequity_host + lequity_SFI if host == 138 & year < 2003 
	gen ldebt_SFI = 258296 if host == 138 & year == 2001
	replace ldebt_SFI = 318308 if host == 138 & year == 2002
	replace debtliab_host = lportif_debt_host + ldebt_SFI if host == 138 & year < 2003

	// Correction of Cayman Islands' liabilities
	// KY debt liabilities = KY debt liabilities in EWN
	// KY equity liabilities = total debt + equity portfolio assets of KY - portfolio assets of Cayman banks and insurance companies + equity assets of non-financial corporations
	/* br source host eqasset debtasset if source==377 */
	preserve
		keep if source==377
		collapse (sum) augmeqasset augmdebtasset eqasset debtasset (first) source, by(year)
		gen eqliab_KY = augmeqasset + augmdebtasset
		gen totliab_banks = eqasset + debtasset if year < 2015
		rename source host
		keep year host eqliab totliab_banks
		merge m:1 year host using "$work\KY_banks.dta"
		drop _merge
		replace totliab_banks = KY_assets_bank if year > 2014
		replace eqliab_KY = eqliab_KY - totliab_banks
		merge 1:1 year using "$work\KY_liab_nfc.dta"
		drop if _merge == 2
		drop _merge
		replace eqliab_nfc = eqliab_nfc / 1000000
		replace eqliab_KY = eqliab_KY + eqliab_nfc
		keep year host eqliab_KY
		tempfile KY_eqliab
		save `KY_eqliab'
	restore
	merge m:1 year host using `KY_eqliab'
	drop _merge
	/* br source host year eqliab* debtliab* if host == 377 */
	sort source host year
	replace eqliab_host = eqliab_KY if host == 377

	// correction for EWN22 reported liab < raw CPIS derived liab */
	sort host year
	by host year: egen rawderivedeq = total(eqasset)
	by host year: egen rawderiveddebt = total(debtasset)
	gen missingliabeq = 0
	replace missingliabeq = rawderivedeq - eqliab_host if rawderivedeq > eqliab_host
	gen missingliabdebt = 0
	replace missingliabdebt = rawderiveddebt - debtliab_host if rawderiveddebt > debtliab_host
	replace eqliab_host = eqliab_host + missingliabeq
	replace debtliab_host = debtliab_host + missingliabdebt

// 2) Add liabilities for international organizations
	// Debt = BIS data
	// Equity = raw CPIS derived */
	merge m:1 year host using "$work/BIS_total_debt_IO.dta"
	drop if _merge==2
	drop _merge
	/* br year source host eqasset debtasset debtliab_host eqliab_host total_debt_BIS if host == 9998 */
	replace eqliab_host = rawderivedeq if host == 9998
	replace debtliab_host = total_debt_BIS if host == 9998
	drop total_debt_BIS

// 3) Augmented derived liabilities for non EWN22 nations 
	sort host year
	by host year: egen derivedeqliab_host = total(augmeqasset) 
	by host year: egen deriveddebtliab_host = total(augmdebtasset)
	replace eqliab_host = derivedeqliab_host if eqliab_host == . & host != 983 & host != 9998 & host != 9999
	replace debtliab_host = deriveddebtliab_host if debtliab_host == . & host != 983 & host != 9998 & host != 9999


// B - Liability data for source countries
preserve
	keep host year lequity_host lportif_debt_host derivedeqliab_host deriveddebtliab_host eqliab_host debtliab_host
	rename (host lequity_host lportif_debt_host derivedeqliab_host) (source lequity_source lportif_debt_source derivedeqliab_source)
	rename (deriveddebtliab_host eqliab_host debtliab_host) (deriveddebtliab_source eqliab_source debtliab_source)
	collapse (first) lequity_source lportif_debt_source derivedeqliab_source deriveddebtliab_source eqliab_source debtliab_source, by(year source)
	tempfile liab
	save `liab'
restore
merge m:1 source year using `liab'
drop _merge

// C - Generate gap reported liab - derived liab
gen gapeq_host = eqliab_host - derivedeqliab_host
gen gapdebt_host = debtliab_host - deriveddebtliab_host

gen gapeq_source = eqliab_source - derivedeqliab_source
gen gapdebt_source = debtliab_source - deriveddebtliab_source
save "$work/data_full_matrices.dta", replace


// Check that the gap computed on source countries is the same as computed on host countries 
collapse (first) hostname eqliab_host derivedeqliab_host gapeq_host debtliab_host deriveddebtliab_host gapdebt_host, by(host year)
tabstat gapeq_host gapdebt_host, by(year) stats(sum) format(%12.0g)

use "$work/data_full_matrices.dta", clear
collapse (first) sourcename eqliab_source derivedeqliab_source gapeq_source debtliab_source deriveddebtliab_source gapdebt_source, by(source year)
tabstat gapeq_source gapdebt_source, by(year) stats(sum) format(%12.0g)
save "$work/gap_source_update.dta", replace
//----------------------------------------------------------------------------//



