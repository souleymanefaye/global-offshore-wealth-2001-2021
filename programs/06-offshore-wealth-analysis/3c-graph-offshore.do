* ==============================================================================
* Date: October 2023
* Paper: Global Offshore Wealth, 2001-2021
*
* This program graphs the evolution of offshore wealth over GDP between 2001
* and 2022 for several countries.
*
* databases used: - offshore"year".dta files (files take 2001 to 2022 as "year")
*                 - FGZ-raw-data.xlsx
*                 - country_frame.dta
*
* outputs:        - offshore_gdpcountry.pdf (note: files take iso2 of USA, UK, 
*                 Argentina, Colombia, South Africa, Denmark, Taiwan, Israel, 
*                 Greece, Ireland, and Russia as "country")
*                 - offshore_gdpAJZvsSmoothEstimates.pdf
*                 - countries_offshore_gdp2007-2022
*                 - offshore_location_global_wealth
*                 - offshore_location_world_gdp
*                 - world_offshore_gdp2007-2022
*                 
*===============================================================================

**--------- I.1 - GRAPH: UNITED STATES OFFSHORE WEALTH/GDP--------------------**
use "$work/countries", clear
keep if iso3 == "USA" & indicator == "total"
gen ratio_offshore_GDP = (value/(gdp_current_dollars/1000000000))*100
#delimit;
twoway bar ratio_offshore_GDP year, 
bcolor(emerald) barw(0.7) scheme(s1color)
ytitle("share of United States GDP", size(small)) 
xtitle("") 
xlabel(2001(1)2022, angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
) 
ylabel(4 "4%" 6 "6%" 8 "8%" 10 "10%" 12 "12%" 14 "14%" 16 "16%", 
grid glcolor(black%5) labsize(small) 
angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor) labgap(1) 
) 
legend(off) || 
connected ratio_offshore_GDP year, msymbol(th) mcolor(black) msize(medium)
lcolor(black);
#delimit cr
graph export "$fig/offshore_gdpUSA.pdf", replace
 
**-----------GRAPH: UNITED KINGDOM OFFSHORE WEALTH/GDP------------------------** 
use "$work/countries", clear
keep if iso3 == "GBR" & indicator == "total"
gen ratio_offshore_GDP = (value/(gdp_current_dollars/1000000000))*100
#delimit;
twoway bar ratio_offshore_GDP year, bcolor(emerald) barw(0.7) scheme(s1color)
ytitle("share of United Kingdom GDP", size(small)) 
xtitle("") 
xlabel(2001(1)2022, angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
) 
ylabel(10 "10%" 15 "15%" 20 "20%" 25 "25%" 30 "30%" 35 "35%" 40 "40%" 45 "45%", 
grid glcolor(black%5) labsize(small) 
angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor) labgap(1) 
)  
legend(off) || 
connected ratio_offshore_GDP year, msymbol(o) mcolor(black) msize(medium)
lcolor(black);
#delimit cr
graph export "$fig/offshore_gdpGBR.pdf", replace
 
**----------------GRAPH: ARGENTINA OFFSHORE WEALTH/GDP------------------------**
use "$work/countries", clear
keep if iso3 == "ARG" & indicator == "total"
gen ratio_offshore_GDP = (value/(gdp_current_dollars/1000000000))*100
#delimit;
twoway bar ratio_offshore_GDP year, bcolor(emerald) barw(0.7) scheme(s1color) 
ytitle("share of Argentina GDP", size(small))  
xtitle("") 
xlabel(2001(1)2022, angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
) 
ylabel(0 "0%" 10 "10%" 20 "20%" 30 "30%" 40 "40%" 50 "50%" 60 "60%"
70 "70%" 80 "80%", 
grid glcolor(black%5) labsize(small) angle(horizontal) glpattern(line) 
glwidth(thin) tstyle(minor) labgap(1) 
) 
legend(off) || 
connected ratio_offshore_GDP year, msymbol(d) mcolor(black) msize(medium)
lcolor(black);
#delimit cr
graph export "$fig/offshore_gdpARG.pdf", replace
  
**-----------------GRAPH: COLOMBIA OFFSHORE WEALTH/GDP------------------------**
use "$work/countries", clear
keep if iso3 == "COL" & indicator == "total"
gen ratio_offshore_GDP = (value/(gdp/1000000000))*100
#delimit;
twoway bar ratio_offshore_GDP year, 
bcolor(emerald) barw(0.7) scheme(s1color) 
ytitle("share of Colombia GDP", size(small)) 
xtitle("") 
xlabel(2001(1)2022, angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
)
ylabel(0 "0%" 10 "10%" 20 "20%" 30 "30%" 40 "40%" 50 "50%", 
grid glcolor(black%5) labsize(small) 
angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor) labgap(1) 
) 
legend(off) || 
connected ratio_offshore_GDP year, msymbol(sh) mcolor(black) msize(medium)
lcolor(black);
#delimit cr
graph export "$fig/offshore_gdpCOL.pdf", replace
 
**-----------------GRAPH: DENMARK OFFSHORE WEALTH/GDP------------------------**
use "$work/countries", clear
keep if iso3 == "DNK" & indicator == "total"
gen ratio_offshore_GDP = (value/(gdp/1000000000))*100
#delimit;
twoway bar ratio_offshore_GDP year, 
bcolor(emerald) barw(0.7) scheme(s1color)
ytitle("share of Denmark GDP", size(small))  ///
xtitle("") ///
xlabel(2001(1)2022, angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
) 
ylabel(0 "0%" 5 "5%" 10 "10%" 15 "15%" 20 "20%" 25 "25%" 30 "30%", 
grid glcolor(black%5) labsize(small) 
angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor) labgap(1) 
) 
legend(off) || 
connected ratio_offshore_GDP year, msymbol(dh) mcolor(black) msize(medium)
lcolor(black);
#delimit cr
graph export "$fig/offshore_gdpDNK.pdf", replace
 
**-----------------GRAPH: SOUTH AFRICA OFFSHORE WEALTH/GDP--------------------**
use "$work/countries", clear
keep if iso3 == "ZAF" & indicator == "total"
gen ratio_offshore_GDP = (value/(gdp/1000000000))*100
#delimit;
twoway bar ratio_offshore_GDP year, 
bcolor(emerald) barw(0.7) scheme(s1color) 
ytitle("share of South Africa GDP", size(small)) 
xtitle("") 
xlabel(2001(1)2022, angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
) 
ylabel(0 "0%" 5 "5%" 10 "10%" 15 "15%" 20 "20%" 25 "25%", 
grid glcolor(black%5) labsize(small) 
angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor) labgap(1) 
) 
legend(off) || 
connected ratio_offshore_GDP year, msymbol(x) mcolor(black) msize(medium)
lcolor(black);
#delimit cr 
graph export "$fig/offshore_gdpZAF.pdf", replace 
 
**-------------------GRAPH: TAIWAN OFFSHORE WEALTH/GDP------------------------**
use "$work/countries", clear
keep if iso3 == "TWN" & indicator == "total"
gen ratio_offshore_GDP = (value/(gdp/1000000000))*100
#delimit;
twoway bar ratio_offshore_GDP year, 
bcolor(emerald) barw(0.7) scheme(s1color) 
ytitle("share of Taiwan GDP", size(small)) 
xtitle("") 
xlabel(2001(1)2022, angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
) 
ylabel(0 "0%" 20 "20%" 40 "40%" 60 "60%" 80 "80%" 100 "100%" 120 "120%", 
grid glcolor(black%5) labsize(small) 
angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor) labgap(1) 
) 
legend(off) || 
connected ratio_offshore_GDP year, msymbol(th) mcolor(black) msize(medium)
lcolor(black);
#delimit cr
graph export "$fig/offshore_gdpTWN.pdf", replace 

**-------------------GRAPH: ISRAEL OFFSHORE WEALTH/GDP------------------------**
use "$work/countries", clear
keep if iso3 == "ISR" & indicator == "total"
gen ratio_offshore_GDP = (value/(gdp/1000000000))*100
#delimit;
twoway bar ratio_offshore_GDP year, 
bcolor(emerald) barw(0.7) scheme(s1color) 
ytitle("share of Israel GDP", size(small))  
xtitle("") 
xlabel(2001(1)2022, angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
) 
ylabel(0 "0%" 10 "10%" 20 "20%" 30 "30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%"
80 "80%", grid glcolor(black%5) labsize(small) angle(horizontal) 
glpattern(line) glwidth(thin) tstyle(minor) labgap(1) 
) 
legend(off) || 
connected ratio_offshore_GDP year, msymbol(sh) mcolor(black) msize(medium)
lcolor(black);
#delimit cr
graph export "$fig/offshore_gdpISR.pdf", replace 

**-------------------GRAPH: GREECE OFFSHORE WEALTH/GDP------------------------**
use "$work/countries", clear
keep if iso3 == "GRC" & indicator == "total"
gen ratio_offshore_GDP = (value/(gdp/1000000000))*100
#delimit;
twoway bar ratio_offshore_GDP year, 
bcolor(emerald) barw(0.7) scheme(s1color) 
ytitle("share of Greece GDP", size(small))  
xtitle("") 
xlabel(2001(1)2022, angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
) 
ylabel(0 "0%" 10 "10%" 20 "20%" 30 "30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%", 
grid glcolor(black%5) labsize(small) 
angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor) labgap(1) 
) 
legend(off) || 
connected ratio_offshore_GDP year, msymbol(th) mcolor(black) msize(medium)
lcolor(black);
#delimit cr 
graph export "$fig/offshore_gdpGRC.pdf", replace
 
**-------------------GRAPH: IRELAND OFFSHORE WEALTH/GDP-----------------------**
use "$work/countries", clear
keep if iso3 == "IRL" & indicator == "total"
gen ratio_offshore_GDP = (value/(gdp/1000000000))*100
#delimit;
twoway bar ratio_offshore_GDP year, 
bcolor(emerald) barw(0.7) scheme(s1color) 
ytitle("share of Ireland GDP", size(small)) 
xtitle("")
xlabel(2001(1)2022, angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
) 
ylabel(0 "0%" 5 "5%" 10 "10%" 15 "15%" 20 "20%" 25 "25%" 30 "30%" 35 "35%" 
40 "40%", 
grid glcolor(black%5) labsize(small) 
angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor) labgap(1) 
) 
legend(off) || 
connected ratio_offshore_GDP year, msymbol(dh) mcolor(black) msize(medium)
lcolor(black);
#delimit cr
graph export "$fig/offshore_gdpIRL.pdf", replace 

**-------------------GRAPH: RUSSIA OFFSHORE WEALTH/GDP------------------------**
use "$work/countries", clear
keep if iso3 == "RUS" & indicator == "total"
gen ratio_offshore_GDP = (value/(gdp/1000000000))*100
#delimit;
twoway bar ratio_offshore_GDP year, 
bcolor(emerald) barw(0.7) scheme(s1color) 
ytitle("share of Russia GDP", size(small))  
xtitle("") 
xlabel(2001(1)2022, angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
) 
ylabel(0 "0%" 5 "5%" 10 "10%" 15 "15%" 20 "20%" 25 "25%" 30 "30%", 
grid glcolor(black%5) labsize(small) 
angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor) labgap(1) 
) 
legend(off) || 
connected ratio_offshore_GDP year, msymbol(oh) mcolor(black) msize(medium)
lcolor(black);
#delimit cr
graph export "$fig/offshore_gdpRUS.pdf", replace 
**--------------GRAPH AJZ2017 2007 estimates vs 2007 smooth estimates---------**
* Countries with > 200 billion USD in 2007 as in AJZ(2018) (except Nigeria)
use "$work/offshore2007", clear
keep if bank == "CH"
drop if saver == "NG"
keep if gdp > 200*1e+9 & gdp ~= .
gen global_offshore_wealth = 5623.66447457748
gen ofw_in_switzerland = 2666.95195303662
gen ofw_in_others_havens = 2956.71252154086
gen offshore_smoothed2007 = ///
sh_fidu_smthg2007*ofw_in_switzerland + sh_OC_smthg2007*ofw_in_others_havens
rename iso3saver iso3
drop if offshore_smoothed2007 == 0
tempfile offshore_gdp2007
save `offshore_gdp2007'
import excel "$raw/FGZ-raw-data.xlsx", clear firstrow cellrange(A6:F44) ///
sheet(offshoreGDP2007)
rename country namesaver
rename B country
drop Offshorewealthbn
drop if GDP == .
rename OffshorewealthGDP2007 offshore_gdp_ajz2007
merge 1:1 iso3 using "`offshore_gdp2007'", keep(match)
keep iso3 country GDP offshore_smoothed2007 offshore_gdp_ajz2007
gen offshore_gdp_smoothed2007 = offshore_smoothed2007/GDP
#delimit;
graph bar offshore_gdp_ajz2007 offshore_gdp_smoothed2007, 
over(country, sort(offshore_gdp_ajz2007) label(angle(90) labsize(small) ///
labgap(1))) 
graphregion(col(white)) 
ylabel(
0 "0%" 0.1 "10%" 0.2 "20%" 0.3 "30%" 0.4 "40%" 0.5 "50%" 0.6 "60%" 0.7 "70%" 
0.8 "80%" 0.9 "90%", grid 
glcolor(black%5) labsize(small) angle(horizontal) glpattern(line) glwidth(thin) 
tstyle(minor) labgap(1) 
)  
yline(0.098, lcolor(emerald))
ytitle("share of GDP", size(small))  
text(
0.2 35 "World Average in 2007, AJZ & FGZ: 9.8%", color(emerald) size(small)
)
bargap(15)
outergap(30)
bar(1, color() lcolor(black) lwidth(vthin))
bar(2, color(red*1.3) lcolor(black) lwidth(vthin))
legend(
nobox ring(0) position(9) cols(1) size(vsmall) 
label(1 "Alstadsæter, Johannesen, and Zucman (2018) Estimates") 
label(2 "Faye, Godar, and Zucman (2023) Weighted Moving Average Estimates")
);
#delimit cr
graph export "$fig/offshore-gdp-AJZvsFGZ.pdf", replace 
**---------------Graph: Offshore Wealth in % of GDP 2007-2021-----------------**
* Countries with > 200 billion USD in 2007 as in AJZ(2018)
use "$work/countries", clear
keep if year == 2007 & indicator == "total"
keep if gdp > 200*1e+9
drop if value == 0 | gdp == .
sort value
rename gdp_current_dollars gdp2007
rename value value2007
tempfile countries2007
save `countries2007'
use "$work/countries", clear
keep if year == 2021 & indicator == "total"
merge 1:1 iso3 using "`countries2007'", keep(match) nogenerate 
drop unit label indicator year
rename gdp_current_dollars gdp2021
rename value value2021
gen ratio_offshore_GDP2007 = value2007/(gdp2007/1e+9)
gen ratio_offshore_GDP2021 = value2021/(gdp2021/1e+9)
gen country = ""
replace country = "UAE" if iso3 == "ARE"
replace country = "UK" if iso3 == "GBR"
replace country = "Iran" if iso3 == "IRN"
replace country = "Korea" if iso3 == "KOR"
replace country = "Netherlands" if iso3 == "NLD"
replace country = "Russia" if iso3 == "RUS"
replace country = "Taiwan" if iso3 == "TWN"
replace country = "USA" if iso3 == "USA"
replace country = "Venezuela" if iso3 == "VEN"
replace country = country_name if country == ""
#delimit;
graph bar ratio_offshore_GDP2007 ratio_offshore_GDP2021,
over(country, sort(ratio_offshore_GDP2007) label(angle(90) labsize(small)
labgap(1))) 
graphregion(col(white)) 
ylabel(0 "0%" 0.1 "10%" 0.2 "20%" 0.3 "30%" 0.4 "40%" 0.5 "50%" 0.6 "60%" 
0.7 "70%" 0.8 "80%" 0.9 "90%" 1 "100%" 1.1 "110%" 1.2 "120%" 1.3 "130%" 
1.4 "140%" 1.5 "150%", tstyle(minor) grid angle(horizontal) glcolor(grey%10) 
labsize(small) labgap(1)) 
yline(.1164736, lcolor(blue*2)) 
yline(.1452904, lcolor(red*1.3)) 
ytitle("share of GDP", size(small))  
text(0.40 31.25 "World Average in 2007: 11.6%", color(blue*2) size(small))
text(0.30 31.25 "World Average in 2021: 14.5%", color(red*1.3) size(small))
bargap(15)
outergap(30)
bar(1, color() lcolor(black) lwidth(vthin))
bar(2, color(red*1.3) lcolor(black) lwidth(vthin))
legend(nobox ring(0) position(9) cols(1) size(vsmall) 
label(1 "Offshore wealth in 2007") label(2 "Offshore wealth in 2021"));
#delimit cr
graph export "$fig/countries-offshore-gdp-2007-2021.pdf", replace 
**-----------Graph: Evolution of Global Offshore Wealth 2007-2021-------------**
import excel "$raw/FGZ-raw-data.xlsx", clear firstrow cellrange(A7:C28) ///
sheet(T.A1)
rename A year
rename B world_gdp
rename C offshore_wealth
gen offshore_gdp = offshore_wealth*100/world_gdp
#delimit;
twoway connected offshore_gdp year, 
msymbol(circle) mcolor(black) mlcolor(black) mlwidth(medthick) lwidth(medium) 
msize(medsmall) plotregion(margin(none)) graphregion(col(white)) lcolor(black)
ylabel(
0 "0%" 2 "2%" 4 "4%" 6 "6%" 8 "8%" 10 "10%" 12 "12%" 14 "14%" 16 "16%", grid glcolor(black%20) labsize(small) 
angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor) labgap(1) 
) 
xlabel(
2001(1)2021, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
) 
xtitle("")
ytitle("% of world GDP", size(small))
yscale(range(17));
#delimit cr
graph export "$fig/world-offshore-gdp-2001-2021.pdf", replace 
**----Evolution of offshore wealth in Switzerland and other haven groups-----**
import excel "$raw/FGZ-raw-data.xlsx", clear firstrow cellrange(A4:G25) ///
sheet(T.A2)
rename A year
replace Switzerland = Switzerland*100
replace OfwhichAmericantaxhavens = OfwhichAmericantaxhavens*100
replace OfwhichAsiantaxhavens = OfwhichAsiantaxhavens*100
replace OfwhichEuropeantaxhavens = OfwhichEuropeantaxhavens*100

*
label var OfwhichAmericantaxhavens "American tax havens"
label var OfwhichAsiantaxhavens "Asian tax havens"
label var OfwhichEuropeantaxhavens "Other European tax havens"
* in % of global offshore household financial wealth
#delimit;
twoway connected Switzerland OfwhichAmericantaxhavens OfwhichAsiantaxhavens
OfwhichEuropeantaxhavens year, 
msymbol(circle triangle square plus) msize(small small small small) 
mcolor(red*1.5 lavender*1.5 midblue*1.5 emerald*1.5) mlcolor() mlwidth(thin thin thin thin) 
lwidth(vthin vthin vthin vthin) lcolor(red*1.5 lavender*1.5 midblue*1.5 emerald*1.5)
graphregion(col(white)) plotregion(margin(none))
legend(nobox ring(0) position(5) cols(1) size(vsmall) region(lstyle(none))) 
xlabel(2001(1)2021, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) nogmin labgap(1) tstyle(minor)
)
ylabel(0 "0%" 5 "5%" 10 "10%" 15 "15%" 20 "20%" 25 "25%" 30 "30%" 35 "35%" 40 "40%" 45 "45%", grid 
glcolor(black%5) labsize(small) angle(horizontal) glpattern(line) glwidth(thin) 
tstyle(minor) labgap(1)
)
xtitle("")
ytitle("% of the wealth held in all tax havens", size(small));
#delimit cr
graph export "$fig/offshore-location-global-wealth.pdf", replace 



* % of World GDP
import excel "$raw/FGZ-raw-data.xlsx", clear firstrow cellrange(H4:N26) ///
sheet(T.A2)
rename H year
tempfile offshore_haven_groups
save `offshore_haven_groups'
import excel "$raw/FGZ-raw-data.xlsx", clear firstrow cellrange(A7:B29) ///
sheet(T.A1)
rename A year
rename B world_gdp
merge 1:1 year using `offshore_haven_groups'
drop _merge
gen swiss_havens = Switzerland*100/world_gdp
gen other_european_havens = OfwhichEuropeantaxhavens*100/world_gdp
gen american_havens = OfwhichAmericantaxhavens*100/world_gdp
gen asian_havens = OfwhichAsiantaxhavens*100/world_gdp 
*
label var american_havens "American tax havens"
label var asian_havens "Asian tax havens"
label var other_european_havens "Other European tax havens"
label var swiss_havens "Switzerland"
#delimit;
twoway connected swiss_havens american_havens asian_havens other_european_havens
year, 
msymbol(circle triangle square plus) msize(small small small small) 
mcolor(red*1.5 lavender*1.5 midblue*1.5 emerald*1.5) mlwidth(thin thin thin thin) 
lwidth(vthin vthin vthin vthin) 
lcolor(red*1.5 lavender*1.5 midblue*1.5 emerald*1.5)
graphregion(col(white)) plotregion(margin(none))
legend(nobox ring(0) position(12) cols(1) size(vsmall) region(lstyle(none))) 
xlabel(2001(1)2021, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) nogmin labgap(1) tstyle(minor)
)
ylabel(0 "0%" 1 "1%" 2 "2%" 3 "3%" 4 "4%" 5 "5%" 6 "6%" 7 "7%", grid 
glcolor(black%5) labsize(small) angle(horizontal) glpattern(line) glwidth(thin) 
tstyle(minor) labgap(1)
) 
ytitle("% of world GDP", size(small)) 
graphregion(col(white)) xtitle("");
#delimit cr
graph export "$fig/offshore_location_world_gdp.pdf", replace 

**------Fraction of global household ofw owned by income country groups--------*
use "$work/countries", clear

* compute the % owned by each income level countries
keep if indicator == "total"
*
drop if year == 2022
gen world_gdp = 0
forvalues j = 2001/2021 {
	su gdp if year == `j'
	replace world_gdp = r(sum) if year == `j' 
}

collapse (sum) gdp value, by(year incomelevelname world_gdp)
replace incomelevelname = "upper_middle" if incomelevelname == "Upper middle income"
replace incomelevelname = "high" if incomelevelname == "High income"
replace incomelevelname = "low" if incomelevelname == "Low income"
replace incomelevelname = "lower_middle" if incomelevelname == "Lower middle income"
replace incomelevelname = "unclassified" if incomelevelname == "Unclassified"
gen sh_ofw_total = 0
gen sh_ofw_gdp = 0
gen sh_world_gdp = 0
forvalues i = 2001/2021 {
	sum value if year == `i'
	local ofw`i' r(sum)
	replace sh_ofw_total = value*100/`ofw`i'' if year == `i'
	replace sh_ofw_gdp = value*100/(world_gdp/1e+9) if year == `i'
	replace sh_world_gdp = gdp*100/(world_gdp) if year == `i'
}  
drop value gdp
reshape wide sh_ofw_total sh_ofw_gdp sh_world_gdp, i(year) j(incomelevelname) string
foreach var in sh_ofw_gdp sh_ofw_total sh_world_gdp {
gen `var'_low_middle_inc = `var'low + `var'lower_middle + `var'upper_middle + `var'unclassified
}

keep year sh_ofw_gdphigh sh_ofw_totalhigh sh_ofw_gdp_low_middle_inc ///
sh_ofw_total_low_middle_inc sh_world_gdphigh sh_world_gdp_low_middle_inc

label var sh_ofw_totalhigh "High income countries"
label var sh_ofw_total_low_middle_inc "Middle- and low-income countries"

#delimit;
twoway connected sh_ofw_totalhigh sh_ofw_total_low_middle_inc year, 
msymbol(circle circle) msize(small small) mcolor(midblue*2.5 red*1.5) 
mlwidth(thin thin)
lcolor(midblue*2.5 red*1.5) lwidth(medthick medthick)
plotregion(margin(none)) graphregion(col(white))
legend(nobox ring(0) position(5) cols(1) size(vsmall) region(lstyle(none)))
xlabel(2001(1)2021, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
)
ylabel(0 "0%" 20 "20%" 40 "40%" 60 "60%" 80 "80%", 
grid glcolor(black%20) 
labsize(small) angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor)
labgap(1) 
) 
xtitle("")
ytitle("% of total offshore wealth", size(small));
#delimit cr
graph export "$fig/ofw-owned-income-level-total-ofw.pdf", replace 

label var sh_ofw_gdphigh "High income countries"
label var sh_ofw_gdp_low_middle_inc "Middle and low income countries"
#delimit;
twoway connected sh_ofw_gdphigh sh_ofw_gdp_low_middle_inc year, 
msymbol(circle circle) msize(small small) mcolor(midblue*2.5 red*1.5) 
mlwidth(thin thin)
lcolor(midblue*2.5 red*1.5) lwidth(medthick medthick)
plotregion(margin(none)) graphregion(col(white))
legend(nobox ring(0) position(5) cols(1) size(vsmall) region(lstyle(none)))
ylabel(0 "0%" 2 "2%" 4 "4%" 6 "6%" 8 "8%" 10 "10%" 12 "12%", 
grid glcolor(black%20) 
labsize(small) angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor)
labgap(1) 
)
xlabel(2000(1)2021, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
)
ytitle("% of world GDP", size(small)) 
xtitle("");
#delimit cr
graph export "$fig/ofw_owned_incomelevel_gdp.pdf", replace 

label var sh_world_gdphigh "High income countries"
label var sh_world_gdp_low_middle_inc "Middle and low income countries"
#delimit;
twoway connected sh_world_gdphigh sh_world_gdp_low_middle_inc year, 
msymbol(circle circle) msize(small small) mcolor(midblue*2.5 red*1.5) 
mlwidth(thin thin)
lcolor(midblue*2.5 red*1.5) lwidth(medthick medthick)
plotregion(margin(none)) graphregion(col(white))
legend(nobox ring(0) position(5) cols(1) size(vsmall) region(lstyle(none)))
ylabel(0 "0%" 20 "20%" 40 "40%" 60 "60%" 80 "80%" 100 "100%", 
grid glcolor(black%20) 
labsize(small) angle(horizontal) glpattern(line) glwidth(thin) tstyle(minor)
labgap(1) 
)
xlabel(2000(1)2021, grid glcolor(black%20) glpattern(vshortdash) glwidth(thin) 
angle(90) labsize(small) tstyle(minor) nogmin labgap(1)
)
ytitle("% of world GDP", size(small)) 
xtitle("");
#delimit cr
graph export "$fig/share-gdp-income-country-groups.pdf", replace 
