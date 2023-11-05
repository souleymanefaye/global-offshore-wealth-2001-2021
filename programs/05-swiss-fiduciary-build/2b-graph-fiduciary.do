* ==============================================================================
* Date: August 2023
* Paper: Global Offshore Wealth, 2001-2021
*
* This program graphs country groups shares of fiduciary deposits in 
* Swiss banks spanning 1987 to 2022.
*
* databases used: - fiduciary-87-22
* outputs:        - update-swiss-fiduciary87-22.pdf
*              
*===============================================================================

********************************************************************************
******************************  I----Graph *************************************
********************************************************************************

use "$work/fiduciary-87-22.dta", clear

* create share of fiduciary deposits in Swiss Banks
rename ofc haven
gen tot_haven = .
gen tot_europe= .
gen tot_middle_east = .
gen tot_latin_am = .
gen tot_asia = .
gen tot_africa = .
gen tot_north_am = .
gen tot_caribbean = .
gen all = 1
gen tot_rich = .
gen tot_developing = .


* total fiduciary deposits, by country
foreach countryg in haven europe middle_east latin_am asia africa north_am ///
caribbean rich developing {
	forval i = 1987/2022  {
		sum(lfidudol) if `countryg' == 1 & year == `i'
		replace tot_`countryg' = r(sum) if year == `i' & `countryg' == 1
		}
		}

* total fiduciary deposits
gen tot_all = .
forval i = 1987/2022 {
	sum(lfidudol) if year == `i' 
	replace tot_all = r(sum) if year == `i'
	}

* compute share fiduciary deposits
gen sh_haven = .
gen sh_europe= .
gen sh_middle_east = .
gen sh_latin_am = .
gen sh_asia = .
gen sh_africa = .
gen sh_north_am = .
gen sh_caribbean = .
gen sh_all = .
foreach countryg in haven europe middle_east latin_am asia africa north_am ///
caribbean all {
	forval i = 1987/2022  {
		replace sh_`countryg' = tot_`countryg'/tot_all if year == `i' & ///
		`countryg' == 1
		}
		}

* in percentage
gen pct_haven = .
gen pct_europe = .
gen pct_middle_east = .
gen pct_latin_am = .
gen pct_asia = .
gen pct_africa = .
gen pct_north_am = .
gen pct_caribbean = .
gen pct_all = .
foreach countryg in haven europe middle_east latin_am asia africa north_am ///
caribbean all {
	forval i = 1987/2022  {
		replace pct_`countryg' = sh_`countryg'*100 if year == `i' & ///
		`countryg' == 1
		}
		}

label var pct_haven "Tax Havens"
label var pct_europe "Europe"
label var pct_middle_east "Middle East"
label var pct_latin_am "Latin and South America"
label var pct_asia "Asia"
label var pct_africa "Africa"
label var pct_north_am "North America"

#delimit;
twoway connected pct_haven pct_europe pct_middle_east pct_latin_am
pct_asia pct_africa pct_north_am year, sort msymbol(S dh sh th i i Oh) msize(medsmall medsmall medsmall medsmall medsmall medsmall medsmall) 
lpattern(solid solid dash solid dash solid solid) scheme(s1mono) lwidth(medium medium medium medium medium medium medium) plotregion(margin(none))
ylabel(0 "0%" 10 "10%" 20 "20%" 30 "30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%" 80 "80%", 
grid labsize(small) angle(horizontal) labgap(1) tstyle(minor)
) 
xlabel(1984(4)2024, grid angle(90) labsize(small) labgap(1) tstyle(minor)
) 
legend(nobox ring(0) position(10) cols(1) size(vsmall) region(lstyle(none))) 
xtitle("") ytitle("% of total foreign-owned Swiss bank deposits", size(small));
#delimit cr
graph export "$fig/update-swiss-fiduciary-87-22.pdf", replace

* 
gen pct_rich = .
gen pct_developing = .

foreach g in rich developing {
forval i = 1987/2022  {
	replace pct_`g' = (tot_`g'/tot_all)*100 if year == `i' & `g' == 1
}
}

sum(lfidudol) if rich == 1 & euro16 ==1
gen tot_rich_euro16 = r(sum)
gen pct_rich_euro16 = (tot_rich_euro16/tot_rich)
gen pct_excl_middle_east = pct_developing - pct_middle_east

preserve

gen tot_rich_eu16 = .
forval i = 1987/2022 {
	sum(lfidudol) if year == `i' & rich == 1 & euro16 == 1
	replace tot_rich_eu16 = r(sum) if year == `i' 
	}
gen tot_excl_middle_east = tot_developing - tot_middle_east
collapse (mean) tot_haven tot_europe tot_middle_east tot_latin_am tot_asia ///
tot_africa tot_north_am tot_caribbean tot_all tot_rich tot_rich_eu16 ///
tot_developing tot_excl_middle_east, by(year)

export excel using "$raw/FGZ-raw-data.xls", ///
sheet(TableB1) firstrow(varlabels) sheetreplace

restore 

collapse (mean) pct_haven pct_europe pct_middle_east pct_latin_am pct_asia ///
pct_africa pct_north_am pct_caribbean pct_all pct_rich pct_rich_euro16 ///
pct_developing pct_excl_middle_east, by(year)
gen pct_ex_havens = pct_all - pct_haven
foreach pct in pct_haven pct_europe pct_middle_east pct_latin_am pct_asia ///
pct_africa pct_north_am pct_caribbean pct_all pct_ex_havens pct_rich ///
pct_rich_euro16 pct_developing pct_excl_middle_east {
	forval i = 1987/2022 {
		replace `pct' = round(`pct') if year == `i' 
		}
		}
		
* label
label var pct_ex_havens "Total ex-tax havens"
label var pct_all "Total"
label var pct_rich "Rich countries"
label var pct_rich_euro16 "Of which: Euro area 16"
label var pct_developing "Developing countries"
label var pct_excl_middle_east "Excl. Middle East"

* graph 
label var pct_haven "Tax Havens"
label var pct_europe "Europe"
label var pct_middle_east "Middle East"
label var pct_latin_am "Latin and South America"
label var pct_asia "Asia"
label var pct_africa "Africa"
label var pct_north_am "North America"
label var pct_caribbean "Caribbean"

export excel using "$raw/FGZ-raw-data.xls", ///
sheet(TableB2) firstrow(varlabels) sheetreplace