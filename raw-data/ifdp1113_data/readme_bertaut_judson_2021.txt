------------------------------------------------------------------------------------------------------------
Introduction
------------------------------------------------------------------------------------------------------------
These data files provide comprehensive time series estimates of cross-border securities holdings, 
by security type and country, for December 1984 through December 2020 for liabilities (foreign holdings of US securities) 
and for December 1994 through December 2020 for claims (US holdings of foreign securities)
as constructed in Carol Bertaut and Ruth Judson (2014) 
"Estimating U.S. Cross-Border Securities Positions: New Data and New Methods."

These files were last updated in July 2021.

NOTE: This release will be the final update to this work. 
We now recommend that data users work directly with SLT positions, which are reported on the Treasury's TIC website:
https://home.treasury.gov/data/treasury-international-capital-tic-system

See especially entries under "B" and "C" on this page:
https://home.treasury.gov/data/treasury-international-capital-tic-system-home-page/tic-forms-instructions/securities-b-portfolio-holdings-of-us-and-foreign-securities

In addition, we are working to provide data updated monthly on the SLT positions.
(as reported at the Treasury website, above) along with estimated valuation change and estimated transactions.

Please contact the authors if you wish to be notified:
Ruth Judson: rjudson@frb.gov
Carol Bertaut: cbertaut@frb.gov
 
------------------------------------------------------------------------------------------------------------
List of files
------------------------------------------------------------------------------------------------------------
readme_bertaut_judson_2021.txt [this file]

ticdata.liabilities.ftot.txt
ticdata.liabilities.foiadj.txt
bertaut_judson_positions_liabs_2021.csv 
bertaut_judson_covgchg_liabs_2014.csv
bertaut_judson_liabs_covg_2021.csv

bertaut_tryon_claims_thru2011.csv
bertaut_judson_positions_claims_2021.csv
TIC_2011_covchg_claims.csv 
bertaut_judson_claims_covg_2021.csv
------------------------------------------------------------------------------------------------------------
File descriptions
------------------------------------------------------------------------------------------------------------
1.  For liabilities, the files 
ticdata.liabilities.ftot.txt (all foreign investors, by county)
and 
ticdata.liabilities.foiadj.txt (official foreigners, grand total only)
provide estimates using the original Bertaut-Tryon 2007 methodology from December 1984 through the June 2011 liabilities survey.
These files have NOT been changed since the original issuance of this paper.

The file bertaut_judson_positions_liabs_2021.csv provides liabilities estimates using the new 
SLT-based methodology for June 2011 through December 2020. 
These files can be combined with the Bertaut-Tryon estimtes to generate the full time series of estimated securities holdings.
Estimates for total foreign official investors are included in the bertaut_judson_positions_liabs_2021.csv file under code 99990.
This file also uses updated methodology for estimating valuation change for US corporate bonds. 
This file is updated as of March 2021.

The file bertaut_judson_covgchg_liabs_2014.csv contains estimates of the change in coverage resulting from the expansion 
in the liabilities reporting panel with the introduction of the SLT in September 2011. 
This file can be used in connection with the bertaut_judson_positions_liabs_2021.csv to identify how much of the 
September 2011 monthly gap for each country and security type can be attributed to change in coverage.
This file has NOT been changed since the original issuance of this paper.

2. For claims, the file
bertaut_tryon_claims_thru2011.csv
provides estimates using the original Bertaut-Tryon 2007 methodology from December 1994 through December 2011.  
In this file, the values for December 2011 claims survey are exclusive of the change in coverage 
resulting from the reporter panel expansion effective with the 2011 survey, 
and thus the monthly gap estimates for December 2011 in this file do not reflect any change in coverage.
This file has NOT been changed since the original issuance of this paper.

The file TIC_2011_covchg_claims.csv provides estimates of expansion in coverage, by country and security type, 
in the December 2011 claims survey, and also lists the full December 2011 survey values 
(including the additional reporting from the expanded reporter panel).
This file has NOT been changed since the original issuance of this paper.

The file 
bertaut_judson_positions_claims_2021.csv
covers claims estimates using the new SLT-based methodology for December 2011 through December 2020 using 
the expanded panel definition. 
This file can be combined with the Bertaut-Tryon estimates to generate the full time series of estimated securities holdings.
This file also includes data for a group of emerging-market economies.  
The country code is 66666, and the group includes the following:
49999 Asia excluding Japan (42609)
59994 Africa
39942 Latin America
12807 Turkey
13218 SerbiaMontenegro 
14109 BosniaHerzegovina
14214 Croatia
14338 Slovenia
14419 Macedonia
15105 Albania
15202 Bulgaria
15288 CzechRep
15318 Slovakia
15407 Estonia
15504 Hungary
15601 Latvia
15709 Lithuania
15768 Poland
15806 Romania
16101 Russia
16209 Belarus
16306 Moldova
16403 Ukraine
16519 Armenia
16527 Azerbaijan
16535 Georgia
16543 Kazakhstan
16551 Kyrgyzstan
16578 Tajikistan
16616 Turkmenistan
16705 Uzbekistan
This file is updated as of March 2021.  

------------------------------------------------------------------------------------------------------------
Changes in countries included in these files
------------------------------------------------------------------------------------------------------------
The files bertaut_judson_claims_covg_2021.csv and bertaut_judson_liabs_covg_2021.csv summarize country 
coverage in these files.  Country coverage is now the same for the full period from 2012 to 2020.  
Country data are shown if the S and SLT data are reported over the full period for both total claims/liabilities 
and their components (for liabilities: Treasuries, agencies, corporate bonds, and corporate stocks; for claims: 
bonds and stocks).

There is one exception: data for Netherlands Antilles are shown through November 2013, and thereafter data
for Curacao only are shown. This shift results a change in the set of countries for which TIC data are collected.
Beginning in December 2013, data for Netherlands Antilles were not collected and data for the constituent countries 
of Netherlands Antilles, including Curacao, were collected separately.  Of these countries, only data for Curacao
are published on the S and SLT by security type.
------------------------------------------------------------------------------------------------------------
Other changes and notes
------------------------------------------------------------------------------------------------------------
In these files, values are reported in millions of dollars and have been rounded to the nearest $ million. 
Components may therefore not sum to the total because of this rounding.
In addition, a few countries occasionally show missing data.  In all cases, missing data correspond to years 
when TIC survey (SHL/SHC) and/or SLT positions were reported as 0.  
For such observations, our recommended practice would be to either omit the observations from any analysis, 
and/or to simply use raw SLT data.
------------------------------------------------------------------------------------------------------------
Disclaimer
------------------------------------------------------------------------------------------------------------
Please note that these data are provided only to facilitate further research. 
These data come with no guarantee (implied or otherwise) that they are as intended or described. 
This material is solely the responsibility of the authors and not the responsibility of the Board of Governors 
of the Federal Reserve System or of other members of its staff.
