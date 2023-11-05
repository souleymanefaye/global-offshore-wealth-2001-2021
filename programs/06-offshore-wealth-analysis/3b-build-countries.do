* ==============================================================================
* Date: October 2023
* Paper: Global Offshore Wealth, 2001-2021
*
* This program build a simpler dataset of each country offshore wealth in total, 
* in haven groups (american, european, caribbean, asian and swiss), and the 
* total wealth attracted by each haven
*
* databases used: - offshore'i' (i taking years from 2001 to 2022)
*                 - AJZ2017DataUpdated.xlsx
*
* outputs:        - countries
*                 
*===============================================================================

********************************************************************************

*************************** I -- Countries -------******************************

*******************************************************************************


forvalues i = 2001/2022 {
	import excel "$raw/FGZ-raw-data.xlsx", clear firstrow ///
	cellrange(H4:N26) sheet(T.A2)
	rename H year
	rename Totaloffshorewealth global_offshore_wealth
	rename Switzerland switzerland_offshore_wealth
	rename TaxhavensotherthanSwitzerlan other_havens_offshore_wealth
	rename OfwhichAmericantaxhavens american_havens_offshore_wealth
	rename OfwhichAsiantaxhavens asian_havens_offshore_wealth
	rename OfwhichEuropeantaxhavens european_havens_offshore_wealth
	keep if year == `i'
	merge 1:m year using "$work/offshore`i'", nogenerate
	replace year = `i'
	gen offshore_switzerland = (switzerland_offshore_wealth*sh_fidu_smthg`i')
	gen offshore_EU_Havens = (european_havens_offshore_wealth*sh_EU_smthg`i')
	gen offshore_AS_Havens = (asian_havens_offshore_wealth*sh_AS_smthg`i')
	gen offshore_CR_Havens = (american_havens_offshore_wealth*sh_CR_smthg`i')
	egen offshore_total = rowtotal(offshore_switzerland offshore_EU_Havens ///
	offshore_AS_Havens offshore_CR_Havens), missing
	gen ratio_offshore_GDP = offshore_total/(gdp`i'/1000000000)
	keep if bank == "CH"
	keep iso3saver year offshore_total offshore_switzerland ///
	offshore_EU_Havens offshore_AS_Havens offshore_CR_Havens latin_am ///
	europe asia africa
	tempfile countries
	save `countries', replace
	import excel "$raw/FGZ-raw-data.xlsx", clear firstrow ///
	cellrange(A29:W51) sheet(T.A2b)
	rename A year
	keep if year == `i'
	merge 1:m year using `countries', nogenerate
	gen off6 = .
	replace off6 = Switzerland if iso3saver == "CHE"
	replace off6 = CaymanIslands if iso3saver == "CYM"
	replace off6 = Panama if iso3saver == "PAN"
	replace off6 = US if iso3saver == "USA"
	replace off6 = HongKong if iso3saver == "HKG"
	replace off6 = Singapore if iso3saver == "SGP"
	replace off6 = Macao if iso3saver == "MAC"
	replace off6 = Malaysia if iso3saver == "MYS"
	replace off6 = Bahrain if iso3saver == "BHR"
	replace off6 = Bahamas if iso3saver == "BHS"
	replace off6 = Bermuda if iso3saver == "BMU"
	replace off6 = Guernsey if iso3saver == "GGY"
	replace off6 = Jersey if iso3saver == "JEY"
	replace off6 = IsleofMan if iso3saver == "IMN"
	replace off6 = Luxembourg if iso3saver == "LUX"
	replace off6 = Cyprus if iso3saver == "CYP"
	replace off6 = UK if iso3saver == "GBR"
	replace off6 = Austria if iso3saver == "AUT"
	replace off6 = Belgium if iso3saver == "BEL"
	replace off6 = NetherlandsAntillesthenCuraç ///
	if iso3saver == "ANT" & year <= 2009
	replace off6 = NetherlandsAntillesthenCuraç ///
	if iso3saver == "CUW" & year > 2009
	rename offshore_total off5
	rename offshore_switzerland off4
	rename offshore_EU_Havens off3
	rename offshore_AS_Havens off2
	rename offshore_CR_Havens off1
	reshape long off, i(iso3saver) j(haven_group)
	gen haven_group1 = "total" if haven_group == 5
	replace haven_group1 = "total_attracted" if haven_group == 6
	replace haven_group1 = "swiss" if haven_group == 4
	replace haven_group1 = "europe" if haven_group == 3
	replace haven_group1 = "asian" if haven_group == 2
	replace haven_group1 = "americ" if haven_group == 1
	gen unit = "USD Bn"
	gen label = ""
	replace label = "offshore wealth in American tax havens" ///
	if haven_group1 == "americ"
	replace label = "offshore wealth in Asian tax havens" ///
	if haven_group1 == "asian"
	replace label = "offshore wealth in European tax havens" ///
	if haven_group1 == "europe"
	replace label = "total offshore wealth" if haven_group1 == "total"
	replace label = "offshore wealth in Switzerland" if haven_group1 == "swiss"
	replace label = "total offshore wealth attracted by this jurisdiction" ///
	if haven_group1 == "total_attracted"
	drop haven_group
	rename off value
	keep iso3saver value haven_group1 year unit label latin_am ///
	europe asia africa 
	rename haven_group1 indicator
	rename iso3saver iso3
	drop if iso3 == "BEH" | iso3 == "CHH" | iso3 == "GBH" | ///
	iso3 == "IEH" | iso3 == "NLH" | iso3 == "USH" 
	if year == 2001 {
		save "$work/countries", replace
		}
		if year ~= 2001 {
			append using "$work/countries"
			save "$work/countries", replace
			}
			}
			import delimited "$raw/gdp_current.csv", clear
			merge 1:m year iso3 using "$work/countries", keep(2 3) nogenerate
			merge m:1 iso3 using "$raw/country_frame", keepusing(country_name incomelevel regionname) keep(1 3) nogenerate
			* give to Netherlands Antilles the incomelevelgroup and region of curaçao
			replace country_name = "Netherlands Antilles" if iso3 == "ANT"
			replace incomelevelname = "High income" if iso3 == "ANT"
			replace regionname = "Latin America & Carribean" if iso3 == "ANT"
			* labels
			label var value "Offshore wealth, in bn USD"
			label var gdp "GDP, current prices"
			label var year "Year"
			label var country_name "Country"
			label var iso3 "Country ISO alpha-3 code"
			label var unit "Unit and currency"
			label var indicator "Abbr. of location of offshore wealth"
			label var label "Location of offshore wealth"
			drop europe asia latin_am africa
			order year iso3 country_name indicator label unit value gdp regionname incomelevelname
			sort year iso3 indicator
			export excel using "$raw/FGZ-raw-data.xlsx", ///
			sheet(ctrybyctry01-22) firstrow(variables) sheetreplace
			save "$work/countries", replace
