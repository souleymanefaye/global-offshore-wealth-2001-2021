* ==============================================================================
* Date: October 2023
* Paper: Global Offshore Wealth, 2001-2021
*
* This program creates working directories macros necessary to run all programs.
*
*===============================================================================

**------------------------------PATHS-----------------------------------------**
// main directory
global root "C:\Users\s.faye\Dropbox\global-offshore-wealth-2001-2021-main"

// code files macro
global do "$root\programs"

// data created macro
global work "$root\work-data"

// raw data macro
global raw "$root\raw-data"

// figures
global fig "$root\figures"

// tables
global tables "$root\tables"

**-----------------------EXTRACT ZIPPED DATA FILE------------------------------**
cd "$raw\Zucman"
unzipfile "$raw\Zucman\data_gravity.zip", replace
erase "$raw\Zucman\data_gravity.zip"
cd "$raw\Gravity_dta_V202211"
unzipfile "$raw\Gravity_dta_V202211\Gravity_V202211.zip", replace
erase "$raw\Gravity_dta_V202211\Gravity_V202211.zip"

