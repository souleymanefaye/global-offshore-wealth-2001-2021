//----------------------------------------------------------------------------//
// Project: Offshore financial wealth database - update 2023
// Title: 3_do_table_A3.do
// Purpose: produce TABLE A3 
// This version: 18 Oct 2023
//----------------------------------------------------------------------------//

global myexcel "$tables\FGZ_Appendix_Tables_A1-A3.xlsx"
putexcel set "$myexcel", sheet(Table A3_update) modify

use "$work\data_full_matrices.dta", clear

sort host year source
collapse (first) hostname eqliab_host derivedeqliab_host gapeq_host debtliab_host deriveddebtliab_host gapdebt_host, by(host year)

/*
// Discrepancy control column
preserve
collapse (sum) gapeq_host gapdebt_host, by(year)

foreach var of varlist gapeq_host gapdebt_host{
	replace `var'=`var'/1000
}

mkmat gapeq_host
mkmat gapdebt_host

putexcel R33 = matrix(gapeq_host)
putexcel R56 = matrix(gapdebt_host)
clear matrix
restore
*/

// Col. (4) - (11)

collapse (first) gapeq_host gapdebt_host, by(host year)

foreach var of varlist gapeq_host gapdebt_host{
	replace `var' = `var' / 1000
}

reshape wide gapeq_host gapdebt_host, i(year) j(host)


// Luxembourg, host == 137
mkmat gapeq_host137
mkmat gapdebt_host137

putexcel F33 = matrix(gapeq_host137)
putexcel F56 = matrix(gapdebt_host137)

// Cayman, host == 377
mkmat gapeq_host377
mkmat gapdebt_host377

putexcel G33 = matrix(gapeq_host377)
putexcel G56 = matrix(gapdebt_host377)

// Ireland, host==178
mkmat gapeq_host178
mkmat gapdebt_host178

putexcel H33 = matrix(gapeq_host178)
putexcel H56 = matrix(gapdebt_host178)


// USA, host == 111
mkmat gapeq_host111
mkmat gapdebt_host111

putexcel I33 = matrix(gapeq_host111)
putexcel I56 = matrix(gapdebt_host111)

// Japan host == 158
mkmat gapeq_host158
mkmat gapdebt_host158

putexcel J33 = matrix(gapeq_host158)
putexcel J56 = matrix(gapdebt_host158)

// Switzerland, host == 146
mkmat gapeq_host146
mkmat gapdebt_host146

putexcel K33 = matrix(gapeq_host146)
putexcel K56 = matrix(gapdebt_host146)

clear matrix
//----------------------------------------------------------------------------//
