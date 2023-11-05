//----------------------------------------------------------------------------//
// Project: Offshore financial wealth database - update 2023
// Title: 3_do_table_A2.do
// Purpose: produce TABLE A2 "Global Cross-Border Securities Liabilities" 
// (total liabilities and corrections)
// This version: 18 Oct 2023
//----------------------------------------------------------------------------//

global myexcel "$tables/FGZ_Appendix_Tables_A1-A3.xlsx"

putexcel set "$myexcel", sheet(Table A2_update) modify
use "$work/data_full_matrices.dta", clear

sort host year source
collapse (first) hostname ewn22_host lequity_host lportif_debt_host eqliab_host derivedeqliab_host  deriveddebtliab_host debtliab_host gapeq_host gapdebt_host missingliabeq missingliabdebt, by(host year)


// Col. (1)
preserve
collapse (sum) lequity_host lportif_debt_host, by(year)
foreach var of varlist lequity_host lportif_debt_host{
	replace `var'=`var' / 1000
}
mkmat lequity_host 
mkmat lportif_debt_host
putexcel C33 = matrix(lequity_host)
putexcel C56 = matrix(lportif_debt_host)
clear matrix
restore

// Col. (3): no portfolio debt data in EWNII, but data in IMF IIP or derived debt liab 
preserve
keep if ewn22_host == 1 & lportif_debt_host == .
collapse (sum) debtliab_host, by(year)
foreach var of varlist debtliab_host{
	replace `var' = `var' / 1000
}
mkmat debtliab_host
putexcel E56 = matrix(debtliab_host)
clear matrix
restore

keep if ewn22_host == 1 & lequity_host == .
collapse (sum) eqliab_host, by(year)
foreach var of varlist eqliab_host{
	replace `var' = `var' / 1000
}
mkmat eqliab_host
putexcel E33 = matrix(eqliab_host)
clear matrix


// Col. (4): Dutch SFIs
use "$work/data_full_matrices.dta", clear

keep if host == 138
collapse (mean) lequity_SFI ldebt_SFI, by(year)
foreach var of varlist lequity_SFI ldebt_SFI{
	replace `var' = `var' / 1000
}
mkmat lequity_SFI 
mkmat ldebt_SFI
putexcel F33 = matrix(lequity_SFI )
putexcel F56 = matrix(ldebt_SFI)
clear matrix


// col. (5): raw cpis derived liabilities > reported liabilities
use "$work/data_full_matrices.dta", clear
sort host year source
collapse (first) hostname ewn22_host lequity_host lportif_debt_host eqliab_host derivedeqliab_host  deriveddebtliab_host debtliab_host gapeq_host gapdebt_host missingliabeq missingliabdebt ofc_host, by(host year)
preserve
version 16: table year, c(sum missingliabeq sum missingliabdebt) format(%12.0fc)
version 16: table year if host != 377, c(sum missingliabeq sum missingliabdebt) format(%12.0fc)
keep if host != 377
collapse (sum) missingliabeq missingliabdebt, by(year)
foreach var of varlist missingliabeq missingliabdebt{
	replace `var' = `var' / 1000
}
mkmat missingliabeq 
mkmat missingliabdebt
putexcel G33 = matrix(missingliabeq)
putexcel G56 = matrix(missingliabdebt)
restore

// Col. (6), (6b): Cayman Islands
preserve
keep if host == 377

collapse (sum) eqliab_host debtliab_host lequity_host lportif_debt_host, by(year)
foreach var of varlist eqliab_host debtliab_host lequity_host lportif_debt_host{
	replace `var' = `var' / 1000
}
mkmat eqliab_host 
mkmat debtliab_host
mkmat lequity_host
mkmat lportif_debt_host
putexcel H33 = matrix(eqliab_host)
putexcel H56 = matrix(debtliab_host)
putexcel I33 = matrix(lequity_host)
putexcel I56 = matrix(lportif_debt_host)
clear matrix
restore

// Col (7): Small OFCs
preserve
keep if ewn22_host != 1 & host != 377 & ofc_host == 1
collapse (sum) eqliab_host debtliab_host, by(year)
foreach var of varlist eqliab_host debtliab_host{
	replace `var' = `var' / 1000
}
mkmat eqliab_host 
mkmat debtliab_host
putexcel J33 = matrix(eqliab_host)
putexcel J56 = matrix(debtliab_host)
clear matrix
restore

// Col. (9): Other Non EWN22 countries
preserve
keep if ewn22_host != 1 & host != 9998 & ofc_host != 1
collapse (sum) eqliab_host debtliab_host, by(year)
foreach var of varlist eqliab_host debtliab_host{
	replace `var' = `var' / 1000
}
mkmat eqliab_host 
mkmat debtliab_host
putexcel L33 = matrix(eqliab_host)
putexcel L56 = matrix(debtliab_host)
clear matrix
restore

// Col. (10): International Organizations
preserve
keep if host == 9998
collapse (sum) eqliab_host debtliab_host, by(year)
foreach var of varlist eqliab_host debtliab_host{
	replace `var' = `var' / 1000
}
mkmat eqliab_host 
mkmat debtliab_host
putexcel M33 = matrix(eqliab_host)
putexcel M56 = matrix(debtliab_host)
clear matrix
restore

// Col. (11): Total
preserve
collapse (sum) eqliab_host debtliab_host, by(year)
foreach var of varlist eqliab_host debtliab_host{
	replace `var' = `var' / 1000
}
mkmat eqliab_host 
mkmat debtliab_host
putexcel N33 = matrix(eqliab_host)
putexcel N56 = matrix(debtliab_host)
clear matrix
restore

// Col (2): IMF IIPs
use "$work/IIP_eqliab.dta", clear
replace eqliab_IIP = eqliab_IIP / 1000
mkmat eqliab_IIP
putexcel D33 = matrix(eqliab_IIP)

use "$work/IIP_debtliab.dta", clear
replace debtliab_IIP = debtliab_IIP / 1000
mkmat debtliab_IIP
putexcel D56 = matrix(debtliab_IIP)

//----------------------------------------------------------------------------//

