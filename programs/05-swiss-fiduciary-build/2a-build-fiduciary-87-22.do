* ==============================================================================
* Date: October 2023
* Paper: Global Offshore Wealth, 2001-2021
*
* This program constructs foreign owned time series of swiss fiduciary deposits 
* spanning 1987 to 2022.
*
* databases used: - fiduciary_1976-2014.dta
*                 - Codes-ISO-IFS-Region.xlsx
*                 - country-codes-iso3-ifs.xlsx
*                 - exchange_rates.xlsx
*                 - Multiplicative_FactorSNB.xlsx
*                 - snbdatafiduciary.csv
*
* outputs:        - fiduciary-87-22.dta
*              
*===============================================================================
********************************************************************************
****** I ---- Cleaning and country code merge of SNB fiduciary data -----*******
********************************************************************************

*--------------I.1 - Adjust swiss fiduciary variables name---------------------*
import delimited "$raw/snbdatafiduciary.csv", clear
rename value lfidu
rename inlandausland iso3
rename date year
drop bankengruppe waehrung konsolidierungsstufe
tempfile fiduciary1
save `fiduciary1'
*---------------I.2 - Merge fiduciary accounts to ISO codes---------------------*
import excel "$raw/Codes-ISO-IFS-Region", ///
sheet(Stata-Regions) firstrow clear
duplicates drop
merge 1:m iso3 using `fiduciary1', nogenerate keep(2 3)
rename chart_name cn
rename iso3 ccode

*-----------------I.3 - Minor adjustements to the data-------------------------*	
drop if ccode=="A"
replace cn = "France" if ccode == "BIZ_FR"
replace cn = "United States Minor Outlying Islands" if ccode == "BIZ_PU"
replace cn = "West Indies UK" if ccode == "BIZ_1Z"
* drop various countries and not assignable
drop if ccode == "XVU"
replace ccode = "FRA" if cn == "France"
replace ccode = "UMI" if cn == "United States Minor Outlying Islands"
* west indies is BIZ_1Z in the BIS
replace ccode = "VGB" if ccode == "BIZ_1Z"
* British overseas territories is TAA
replace ccode = "IOT" if ccode == "TAA" 	
replace cn = "British Overseas Territories" if ccode == "IOT"
* Jersey
replace cn = "Jersey" if ccode == "JEY"
* congo
replace cn = "Congo" if ccode == "COG"
tempfile fiduciary2
save `fiduciary2'

*--------------------I.4 - MERGE TO CONVERSION RATES---------------------------*
import excel "$raw/exchange_rates", ///
sheet(usd_chf) firstrow clear
drop if year < 1987
merge 1:m year using `fiduciary2', nogenerate
rename DomesticCurrencyperUSDolla uschf_end
tempfile fiduciary3
save `fiduciary3'

*-----------I.5 - MERGE USD FIDUCIARY ACCOUNTS TO IFS COUNTRY CODES------------*
import excel "$raw/country-codes-iso3-ifs", ///
sheet(Meged-ISO-IFS) firstrow clear
keep ifscode ISO3
replace ifscode = 371 if ISO3 == "VGB"
rename ISO3 ccode
drop if ccode == "GLP"
drop if ifscode == 353 & ccode == "CUW"
drop if ccode == ""
drop if ifscode == .
merge 1:m ccode using `fiduciary3', nogenerate keep(2 3)
drop if ccode == "UMI" & year >= 2001 & year <= 2004
drop if ccode == "SRB" & year >= 2001 & year <= 2006
replace ifscode = 1017 if ccode == "JEY"
replace ifscode = 634 if ccode == "COG"
replace ifscode = 372 if ccode == "IOT"
drop region
drop region_name
sort ifs year
tempfile fiduciary4
save `fiduciary4'
********************************************************************************
*** II--- Append havens not present anymore in Swiss fiduciary data ************
********************************************************************************
*-----------------II.1 - Minor adjustements to the data------------------------*
* Append havens in the XXth century not present in current publicly 
* available version of Swiss fiduciary deposits
use "$raw/fiduciary_1976-2014.dta", clear
keep if cn == "Netherlands Antilles"| cn=="St. Kitts and Nevis" | ///
cn == "Monaco" | cn == "France" & year <= 2004 & year >=1987 | ///
cn == "Yugoslavia" | cn == "USSR" | cn == "British Antilles" | ///
cn == "Antigua and Barbuda" | cn == "German Democratic Republic" | ///
cn=="Tchecoslovakia" | cn=="Western Sahara" | ///
iso3 == "UMI" & year >= 2001 & year <= 2004 | ///
iso3 == "SRB" & year >= 2001 & year <= 2006
replace cn = "United States Minor Outlying Islands" if iso3 == "UMI"
append using `fiduciary4'
drop if year < 1987
drop lfidu_usd
replace ccode = iso3 if ccode == ""
drop iso3
drop if lfidu==. & ccode=="FRA"
drop if lfidu==. & cn=="West Indies UK"
foreach ctry in ANT KNA MCO YUG USSR ATG GDR Tcheco ESH {
	replace lfidu = lfidu*1000 if ccode == "`ctry'"
	}
replace lfidu = lfidu*1000 if cn == "British Antilles"
replace lfidu = lfidu*1000 if ccode == "FRA" & year <=2004
drop if cn=="British Antilles" & year>=2005
replace lfidu = lfidu*1000 if ccode == "UMI" & year >=2001 & year <= 2004
replace lfidu = lfidu*1000 if ccode == "SRB" & year >=2001 & year <= 2006
* The file "data_fiduciary_accounts87-21" contains the raw data on Swiss 
* fiduciary deposits coming from the 1987-2022 editions of the Swiss National 
* Bank's "Banks in Switzerland" lfidu = fiduciary deposits as recorded in 
* "Banks in Switzerland" 

*-----------------II.2 - Minor adjustements to the data------------------------*
* Fill some missing  country names
replace cn="St Helen" if ccode=="SHN"
drop if cn == ""
tempfile fiduciary5
save `fiduciary5'

********************************************************************************
************** III ------- The case of Liechtenstein  **************************
********************************************************************************
* Before 1984, Liechtenstein is considered as a foreign country (and it is the 
* biggest foreign holder of deposits). After 1984, deposits from Liechenstein 
* are considered to be Swiss deposits For the post 1984 period, I compute 
* deposits from Liechtenstein as 45% of Swiss-owned fiduciary deposits 
* (45%=share of Liechtenstein deposits in (Liechtenstein + Switzerland) 
* deposits in 1983) (NB: virtually 100% of the "Swiss-owned" fiduciary deposits 
* may have foreign beneficial owners)
import delimited "$raw/snbdomesticfiduciary.csv", ///
clear rowrange(5:40)
rename v7 lfidu
gen ccode = "LIE"
rename cubeid year
rename v8 uschf_end
keep year ccode lfidu uschf_end
forvalues i = 1987/2022 {
	preserve
	keep if year == `i'
	local fiduLIE`i' = lfidu
	restore
}
forvalues y = 1987/2022 {
replace lfidu = 0.45*`fiduLIE`y'' if year == `y' 
}
gen cn = "Liechtenstein"
gen ifscode = 9006
append using "`fiduciary5'"

********************************************************************************
************** IV ------ Bank-office level fiduciary deposits ******************
********************************************************************************
label variable lfidu ///
"Fiduciary liabilities at the parent company level, millions of CHF" 
gen lfidudol=lfidu/uschf_end
label variable lfidudol ///
"Fiduciary liabilities at the parent company level, millions of US$ (end of p. exch)" 
sort year
tempfile fiduciary6
save `fiduciary6'
import excel "$raw/Multiplicative_FactorSNB.xlsx", ///
clear firstrow cellrange(A26:D62) 
keep year factor
destring year, replace
destring factor, replace
merge 1:m year using `fiduciary6', nogenerate
label variable factor ///
"Aggregate scale-up factor for deposits, from Parent Company to Bank Office level"
gen lfidu2 = lfidu*factor
label variable lfidu2 ///
"Fiduciary liabilities at the bank office level, millions of CHF"
gen lfidu2dol=lfidu2/uschf_end
label variable lfidu2dol ///
"Fiduciary liabilities at the bank office level, millions of US$ (end of p. exch)"
drop factor uschf_end

********************************************************************************
************** V----- Definition of Geographical areas *************************
********************************************************************************
/* Euro area members as of December 31st, 2010 */
/* 11 initial members of the euro area */
gen euro11 = 0 
#delimit;
replace euro11 = 1 if cn == "Austria" | cn == "Belgium" | cn == "Finland" | ///
cn == "France" | cn == "Germany" | cn == "Ireland" | cn == "Italy" | ///
cn == "Luxembourg"| cn == "Netherlands" | cn == "Portugal" | cn == "Spain";
/* All members as of July, 2011 */
gen euro17 = euro11;
replace euro17 = 1 if cn == "Cyprus" | cn == "Estonia" | cn == "Greece" | ///
cn == "Malta" | cn == "Slovak Republic" | cn == "Slovenia" ;
#delimit cr
/* All members as of December 31st, 2010 */
gene euro16 = euro17
replace euro16 = 0 if cn == "Estonia"
drop euro11 euro17
/* Set of rich countries */
gen rich = 0
replace rich = 1 if ifscode<200 | euro16 == 1
replace rich = 0 if cn == "San Marino" | cn == "South Africa" | ///
cn == "Turkey" | cn == "Vatican"
gen developing = 0
replace developing = 1 if rich == 0
/* Set of offshore financial centers where sham wealth-holding entities 
are incorporated */
gen ofc = 0
#delimit;
replace ofc = 1 if cn == "San Marino" | cn == "Luxembourg" | cn == "Malta" 
| cn == "Costa Rica" | cn == "Panama" | cn == "Uruguay"    | 
cn == "Antigua and Barbuda" | cn == "Bahamas" | cn == "Barbados" | 
cn == "Dominica" | cn == "Grenada" | cn == "Belize" |
cn == "Netherlands Antilles" | cn == "Saint Lucia" | 
cn == "Saint Vincent and the Grenadines" | cn == "British Antilles" | 
cn == "British Overseas Territories" | cn == "Cayman Islands" | 
cn == "Turks and Caicos Islands" | cn == "Bahrain" | cn == "Cyprus" | 
cn == "Lebanon" | ccode == "HKG" | cn == "Malaysia" | cn == "Palau" | 
cn == "Singapore" | cn == "Liberia" | cn == "Mauritius" | 
cn == "Seychelles" | cn == "Gibraltar" | cn == "Nauru" | cn == "Vanuatu" | 
cn == "Samoa" | cn == "Marshall Islands" | cn == "Andorra" | cn == "Guernsey" | 
cn == "Isle of Man" | cn == "Jersey" | cn == "West Indies UK" | cn == "Macao" | 
cn == "Curacao" | cn == "Bonaire, Sint Eustatius and Saba" | 
cn == "St. Kitts and Nevis" | cn == "Monaco" | 
cn == "Sint Maarten (Dutch part)" | cn == "Aruba" | cn == "Liechtenstein" | 
cn == "Bermuda" |ccode == "FRO" ;
#delimit cr
/* Continents */
gen north_am=0
replace north_am=1 if cn=="United States of America"|cn=="Canada"
gen latin_am=0
replace latin_am=1 if ifscode>=200&ifscode<300 | cn=="Falkland Islands"
replace latin_am = 0 if ccode == "PSE" | cn=="Yugoslavia"
gen caribbean=0
replace caribbean=1 if ifscode>=300&ifscode<400
replace caribbean=1 if cn=="Cuba"
replace caribbean = 0 if cn == "Curacao"|cn=="Netherlands Antilles" | ///
cn=="St. Kitts and Nevis"| cn=="British Antilles"|cn=="Falkland Islands"| ///
cn=="Aruba" 
gen middle_east=0
replace middle_east=1 if ifscode>=400&ifscode<500 | ccode == "PSE"
replace middle_east=0 if cn=="Cyprus" /* euro area */
gen asia=0
replace asia=1 if ifscode>=500&ifscode<600
replace asia=1 if cn=="Australia"|cn=="New Zealand"|cn=="Japan"| ///
cn=="China"| cn=="Korea, Dem. Rep." 
replace asia=1 if cn=="Mongolia"|cn=="Tuvalu"|cn=="French Polynesia" | ///
ccode=="UMI"
replace asia=1 if cn=="Vanuatu"|cn=="Tonga"|cn=="Papua New Guinea"|cn=="Nauru"
replace asia=1 if cn=="New Caledonia"|cn=="Wallis et Futuna"| ///
cn=="St Helena"|cn=="Kiribati"|cn=="Solomon Islands"|cn=="Fiji"| ///
cn=="Wallis and Futuna Islands"
replace asia=1 if cn=="Ouzbekistan"|cn=="Kyrgyz Republic"| ///
cn=="Turkmenistan"|cn=="Tajikistan"|cn=="Uzbekistan"| ///
cn=="Korea (Democratic People's Republic of)"| cn =="USSR"
/* Countries at the frontier between Europe and Asia: */
replace asia=1 if cn=="Georgia"|cn=="Russian Federation"|cn=="Armenia"| ///
cn=="Azerbaijan"|cn=="Kazakhstan"|cn=="Turkey" | cn =="Kyrgyzstan" ///
| cn =="St Helen"
replace asia=0 if cn=="Macao" | cn =="Bonaire, Sint Eustatius and Saba"| ///
cn=="Sint Maarten (Dutch part)"
gen africa=0
replace africa=1 if (ifscode>=600&ifscode<700)|(ifscode>=700&ifscode<800)
replace africa=1 if cn=="South Africa" | cn == "Western Sahara"
gen europe=0
replace europe=1 if ifscode<200&north_am!=1&asia!=1&africa!=1&cn!="Turkey"
replace europe=1 if euro16==1
replace europe=0 if cn=="Luxembourg"
#delimit;
replace europe=1 if cn=="Croatia"|cn=="Estonia"|cn=="Ukraine"|cn=="Moldova"
|cn=="Serbia"| cn == "Montenegro" |cn=="Czech Republic"|cn=="Romania"| 
cn=="Belarus"|cn=="Bosnia and Herzegovina"
|cn=="Bulgaria"|cn=="Lithuania"|cn=="Latvia"| cn=="Slovakia"| 
cn=="Moldova (Republic of)"|
cn=="Albania"|cn=="Poland"|cn=="Hungary"|cn=="Macedonia (former Yugoslav)"| 
cn=="Yugoslavia" |cn=="Tchecoslovakia"| cn=="German Democratic Republic";
#delimit cr
/* Drop offshore financial centers from continents and groups */
replace rich=0 if rich==1&ofc==1
replace developing=0 if developing==1&ofc==1
replace europe=0 if europe==1&ofc==1
replace middle_east=0 if middle_east==1&ofc==1
replace africa=0 if africa==1&ofc==1
replace asia=0 if asia==1&ofc==1
replace caribbean=0 if caribbean==1&ofc==1
replace latin_am=0 if latin_am==1&ofc==1
/* Define labels */
gen continent = ///
	1*africa + 2*europe + 3*middle_east + 4*asia + 5*caribbean + ///
	6*latin_am + 7*north_am + 8*ofc
label variable continent "Continent"
label define continentlbl ///
	1 "Africa" 2 "Europe" 3 "Middle East" 4 "Asia" ///
	5 "Caribbean" 6 "Latin and South America" 7 "North America" 8 "OFC"
label values continent continentlbl
gen group = 1*rich + 2*developing + 3*ofc
label variable group "Country groups"
label define grouplbl 1 "Rich" 2 "Developing" 3 "OFC"
label values group grouplbl
label var cn "Counterparty country name"
label var ccode "Counterparty country ISO alpha-2"
label var ofc "Offshore financial centre"
label var ifscode "Counterparty country international financial statistics code"

sort ifscode year
save "$work/fiduciary-87-22.dta", replace