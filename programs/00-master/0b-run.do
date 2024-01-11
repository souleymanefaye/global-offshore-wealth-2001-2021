* ==============================================================================
* Date: August 2023
* Paper: Global Offshore Wealth, 2001-2021
*
* This master file runs all programs, create data in work folder and figures.
*
*===============================================================================
clear all
set graphics off
set memory 1000m
set more off
cap log close

********************************************************************************
// 1. Import and merge data sources

// reproduce and extend the dataset "data_gravity.dta"
mkdir "$work"
do "$do/01-gravity-data-build\1a_import_EWN.do"
do "$do/01-gravity-data-build\1b_rebuild_gravity_dataset.do"
save "$work/data_gravity_update.dta", replace

// import other data sources
do "$do/01-gravity-data-build/1c_import_auxiliary_data.do"


// 2. Construct matrices of bilateral portfolio assets
use "$work/data_gravity_update.dta", clear
do "$do/02-bilateral-portfolio-assets-matrices/2_do_full_matrices.do"


// 3. Produce output tables

// produce output tables
mkdir "$tables"
do "$do/03-produce-output-tables/3_do_table_A1.do"
do "$do/03-produce-output-tables/3_do_table_A2.do"
do "$do/03-produce-output-tables/3_do_table_A3.do"

// 4. BIS bilateral deposits

// import bilateral deposits
do "$do/04-bis-deposits-build/4a-import-bis"

// construct bilateral deposits non-banks & all counterparty for 2001-2022
do "$do/04-bis-deposits-build/4b-build-bis-01-22.do"

// graph bilateral deposits non-banks
mkdir "$fig"
do "$do/04-bis-deposits-build/4c-graph-bis.do"

// 5. Swiss fiduciary accounts

// construct fiduciary accounts from SNB data
do "$do/05-swiss-fiduciary-build/5a-build-fiduciary-87-22.do"

// graph fiduciary accounts
do "$do/05-swiss-fiduciary-build/5b-graph-fiduciary.do"	

// 6. Merge BIS and Swiss data, Estimate countries offshore wealth amounts  

// build bilateral data on offshore wealth
do "$do/06-offshore-wealth-analysis/6a-build-offshore-01-22.do"

// build country offshore wealth data 
do "$do/06-offshore-wealth-analysis/6b-build-countries.do"

// graph offshore wealth estimates
do "$do/06-offshore-wealth-analysis/6c-graph-offshore.do" 	
