* ==============================================================================
* Date: August 2023
* Paper: Global Offshore Wealth, 2001-2021
*
* This program graphs the evolution of bis bank deposits in selected countries 
*
* databases used: - locational.dta
*
* outputs:        - shche-06-07.pdf
*                 - shche-22.pdf
*
* ==============================================================================

********************************************************************************
********** I - TABLE: DEPOSITS IN EACH BIS-REPORTING COUNTRY ----**************
********************************************************************************
use "$work/locational.dta", clear
keep if position=="L" & instrument=="A" & sector=="N" ///
/* N=non bank; P=non-bank nonfinancial */ & parent=="5J" & quarter == 4
keep if bank == "AN" | bank == "AT" | bank == "BE" | bank == "BH" | ///
bank == "BM" | bank == "BS" | bank == "CH" | bank == "CL" | bank == "CW" | ///
bank == "CY" | bank == "KY" | bank == "GB" | bank == "GG" | bank == "IM" | ///
bank == "JE" | bank == "LU" | bank == "MO" | bank == "MY" | bank == "PA" | ///
bank == "HK" | bank == "SG" | bank == "US"
keep if counter == "5J"
collapse (mean) value, by(bank year)
reshape wide value, i(year) j(bank) string 
sort year 
export excel using "$raw/FGZ-raw-data.xlsx", sheet(bisdepbyhaven) ///
firstrow(variables) sheetreplace

********************************************************************************
***************** II - GRAPHS USING AGGREGATE BIS DATA ----**********************
********************************************************************************

*------------II.1 - Switzerland vs. other havens in BIS data, 06-07-------------*
use "$work/locational.dta", clear
keep if year==2006 | year==2007
keep if position=="L" & instrument=="A" & sector=="N" ///
/* N=non bank; P=non-bank nonfinancial */ & parent=="5J"
keep if counter == "5J" 
collapse (mean) value (first) namebank iso3bank year, ///
by(bank sector instrument position)
local haven "AN AT BE BM BH BS CH CL CW CY KY GB GG IM JE LU MO MC MY PA HK SG US"
cap drop haven
gen haven=0
foreach var of local haven {
replace haven=1 if bank=="`var'"
}

* Fraction of non-bank deposits which are tax evading household, by OFC
tempfile bis0607
save `bis0607', replace
import excel "$raw/FGZ-raw-data.xlsx", ///
clear firstrow cellrange(A3:W25) sheet(sharehouseholddep)
keep if year == 2006 | year == 2007
merge 1:m year using "`bis0607'"
drop _merge
foreach bank in BE CH GG IM JE PA LU CY MO MY KY AT AN CW BH BM BS HK SG GB ///
US CL {
		replace value = `bank'*value if bank == "`bank'" & haven == 1
		drop `bank'
}

*
drop if iso3bank==""
gen shvalue=0
su value if haven==1
local tothaven=r(sum)
replace shvalue=value/`tothaven' if haven==1
replace namebank = "United Kingdom" ///
if namebank == "United Kingdom of Great Britain and Northern Ireland" 
drop if value == .
#delimit;
graph bar shvalue if haven==1, over(namebank, axis(off) sort(1)) scheme(s1mono) 
blabel(group, pos(outside) orientation(vertical) size(medium)) 
title("Cross-border household deposits in BIS-reporting tax havens, 2006-07") 
ytitle( "% of deposits in BIS-reporting tax havens" )
xsize(8)
yscale(range(0.5))
note("Data source:  BIS" 
"Note: We assume that in Switzerland 100% of deposits belong to households, 
and only a fraction in the other tax haven.") ;
#delimit cr
graph export "$fig/shche-06-07.pdf", replace

*------------II.2 - Switzerland vs. other havens in BIS data, 2022--------------*
use "$work/locational.dta", clear
keep if year == 2022
keep if position=="L" & instrument=="A" & sector=="N" ///
 /* N=non bank; P=non-bank nonfinancial */ & parent=="5J"
keep if counter == "5J" 
collapse (mean) value (first) namebank iso3bank year, ///
by(bank sector instrument position)
local haven "AN AT BE BM BH BS CH CL CW CY KY GB GG IM JE LU MO MC MY PA HK SG US"
cap drop haven
gen haven=0
foreach var of local haven {
replace haven=1 if bank=="`var'"
}

* Fraction of non-bank deposits which are tax evading household, by OFC
tempfile bis22
save `bis22', replace
import excel "$raw/FGZ-raw-data.xlsx", /// 
clear firstrow cellrange(A3:W25) sheet(sharehouseholddep)
keep if year == 2022
merge 1:m year using "`bis22'"
drop _merge
foreach bank in BE CH CW AN GG IM JE PA LU CY MO MY KY AT BH BM BS HK SG GB ///
US CL {
		replace value = `bank'*value if bank == "`bank'" & haven == 1
		drop `bank'
}

*
drop if iso3bank==""
gen shvalue=0
su value if haven==1
local tothaven=r(sum)
replace shvalue=value/`tothaven' if haven==1
replace namebank = "United Kingdom" ///
if namebank == "United Kingdom of Great Britain and Northern Ireland" 
drop if value == .
#delimit;	
graph bar shvalue if haven==1, over(namebank, axis(off) sort(1)) scheme(s1mono) 
blabel(group, pos(outside) orientation(vertical) size(medium)) 
title("Cross-border household deposits in BIS-reporting tax havens, 2022") 
ytitle( "% of deposits in BIS-reporting tax havens" )
xsize(8)
yscale(range(0.5))
note("Data source:  BIS" 
"Note: We assume that in Switzerland 100% of deposits belong to households, 
and only a fraction in the other tax haven.") ;
#delimit cr
graph export "$fig/shche-22.pdf", replace
