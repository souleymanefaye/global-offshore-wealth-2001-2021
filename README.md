# Global Offshore Wealth, 2001 - 2021 
### *Work in Progress*

Replication package for "Global Offshore Wealth, 2001 - 2021", by Souleymane Faye, Sarah Godar, and Gabriel Zucman.

## Overview 
This replication package includes a collection of code designed to generate country-level data files. These files facilitate the reproduction of data accessible on the [Atlas of the Offshore World](https://atlas-offshore.world/) website, and are integral to the paper "Global Offshore Wealth, 2001 - 2021" (Faye, Godar, and Zucman, 2023). This code compiles information from various sources, which are detailed in the following sections. All code files are intended for use within the Stata programming environment.

The companion paper seeks to construct consistent time series data, capturing the global household offshore financial wealth in over 200 countries from 2001 to 2021. This period is noteworthy for substantial international efforts to curtail offshore tax evasion. The study reproduces and extends the analysis made by Zucman (2013) and Alstadsaeter, Johannesen & Zucman (2018). It examines shifts in both the geographic location and ownership of offshore wealth. Subsequently, the paper delves into the impact of the Common Reporting Standard (CRS) and other forms of automatic exchange of information, drawing their implications for the global economy. The research elucidates notable trends, such as the increasing participation of middle- and lower-income countries in offshore wealth, in contrast to a decline among high-income nations. Additionally, it highlights the shift in preferred locations for offshore wealth, moving from Switzerland to Asian financial centers.

## Data

**CEPII Gravity database**

Variables used in the prediction of the distribution of bilateral portfolio assets are taken from the [CEPII Gravity database](http://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele_item.asp?id=8).

**Compustat Global – Security Daily**

We compute the equity value of firms incorporated in the Cayman Islands using data from [Compustat Global – Security Daily](https://www.marketplace.spglobal.com/en/datasets/compustat-financials-(8))

**Coordinated Portfolio Investment Survey (CPIS)**

For the computation of global assets we use data for 2001-2021 from the June 2023 wave of the [CPIS data](https://data.imf.org/?sk=b981b4e3-4e58-467e-9b90-9de0c3367363). It is imported in `programs/01-gravity-data-build/1c_import_auxiliary_data.do`.

**Country Breakdown of Fiduciary Liabilities in *Annual Banking Statistics* from the Swiss National Bank (SNB)**

We utilize the country breakdown of fiduciary deposits on the liability side from the *Annual Banking Statistics*. The data is publicly available on the [Swiss National Bank (SNB) website](https://data.snb.ch/en/warehouse/BSTA/cube/BSTA@SNB.JAHR_UL.ABI.TRE.PAS?fromDate=1987&toDate=2022&dimSel=KONSOLIDIERUNGSSTUFE(U),INLANDAUSLAND(A,ABW,AFG,AGO,ALB,AND,ARE,ARG,ARM,AUS,AUT,AZE,BDI,BEL,BEN,BES,BFA,BGD,BGR,BHR,BHS,BIH,BLR,BLZ,BMU,BOL,BRA,BRB,BRN,BTN,BWA,CAF,CAN,CHL,CHN,CIV,CMR,COD,COG,COL,COM,CPV,CRI,CUB,CUW,CYM,CYP,CZE,DEU,DJI,DMA,DNK,DOM,DZA,ECU,EGY,ERI,ESP,EST,ETH,FIN,FJI,FLK,FRO,FSM,GAB,GBR,GEO,GGY,GHA,GIB,GIN,GMB,GNB,GNQ,GRC,GRD,GRL,GTM,GUY,HKG,HND,HRV,HTI,HUN,IDN,IMN,IND,IRL,IRN,IRQ,ISL,ISR,ITA,JAM,JEY,JOR,JPN,KAZ,KEN,KGZ,KHM,KIR,KOR,KWT,LAO,LBN,LBR,LBY,LCA,LKA,LSO,LTU,LUX,LVA,MAC,MAR,MDA,MDG,MDV,MEX,MHL,MKD,MLI,MLT,MMR,MNE,MNG,MOZ,MRT,MUS,MWI,MYS,NAM,NCL,NER,NGA,NIC,NLD,NOR,NPL,NRU,NZL,OMN,PAK,PAN,PER,PHL,PLW,PNG,POL,PRK,PRT,PRY,PSE,PYF,QAT,ROU,RUS,RWA,SAU,SDN,SEN,SGP,SHN,SLB,SLE,SLV,SMR,SOM,SRB,SSD,STP,SUR,SVK,SVN,SWE,SWZ,SXM,SYC,SYR,TAA,TCA,TCD,TGO,THA,TJK,TKM,TLS,TON,TTO,TUN,TUR,TUV,TWN,TZA,UGA,UKR,URY,USA,UZB,VAT,VCT,VEN,VNM,VUT,WLF,WSM,XVU,YEM,ZAF,ZMB,ZWE,BIZ_FR,BIZ_PU,BIZ_1Z),WAEHRUNG(U),BANKENGRUPPE(A30)). We provide a copy of this data in `raw-data/snbdatafiduciary.csv`. It is imported by the stata program `programs/05-swiss-fiduciary-build/5a-build-fiduciary-87-22.do` which returns a stata data file stored in `work-data/fiduciary-87-22`. 

**External Wealth of Nations Database (EWN)**

For the computations of global liabilities, we use the December 2022 wave of the [EWN dataset](https://www.brookings.edu/articles/the-external-wealth-of-nations-database/). We provide a copy of this data in `raw-data/snbdatafiduciary.csv`. It is imported in the program `programs/01-gravity-data-build/1a_import_EWN.do`

**Fiduciary Deposits in Swiss National Bank’s *Monthly Banking Statistics***

For fiduciary deposits, we use the Swiss National Bank’s Monthly Banking Statistics which discloses comprehensive monthly amounts of fiduciary liabilities in Swiss franc (CHF) at the bank-office level.

**GeoDist database**

For time-constant variables landlocked, industrial pair, and latitude and longitude, we use the [GeoDist database](http://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele_item.asp?id=6) (Mayer and Zignago 2011).


***Locational Banking Statistics* from the Bank for International Settlements (BIS)**

Data on the country breakdown of cross-border positions by nationality of reporting banks are publicly available in the [Bank for International Settlements (BIS) website](https://www.bis.org/statistics/full_data_sets.htm). The data is downloaded by the file `4a-import-bis.do` and stored as a stata data file `work-data/locational.dta`.     
From January 2024 on, the data will not longer appear in the link provided above, as it will be disseminated through the [BIS data portal](https://data.bis.org/bulkdownload).   


**Treasury International Capital (TIC) System**

We take Historic tables on U.S. Cross-Border Securities Positions from Bertaut and Tyron (2007) and Bertaut and Judson (2014) available in this [website](https://www.federalreserve.gov/econres/ifdp/estimating-us-cross-border-securities-positions-new-data-and-new-methods.htm). We import the most recent long-term liabilities from the [TIC resource center](https://ticdata.treasury.gov/resource-center/data-chart-center/tic/Documents/slt_table1.html). Finally, to correct for Middle Eastern oil exporters, we use the [
U.S. Liabilities to Foreigners from Holdings of U.S. Securities](https://home.treasury.gov/data/treasury-international-capital-tic-system/us-liabilities-to-foreigners-from-holdings-of-us-securities).

**Securities holdings in bank custody accounts in *Annual Banking Statistics* from the Swiss National Bank (SNB)**

For Switzerland securities, we take year-end amounts of securities holdings in bank custody accounts (non-resident custody account holders and foreign issuers) in the [SNB website](https://data.snb.ch/en/topics/banken/cube/bawebedomsecwja)))

**Swiss National Bank's *Monthly Foreign Exchange Rates***

We convert fiduciary deposits from Swiss francs to dollars using [SNB’s monthly foreign exchange rates](https://data.snb.ch/fr/topics/ziredev/doc/explanations_ziredev).

**World Development Indicators (WDI)**

The GDP variables and population [WDI](https://databank.worldbank.org/source/world-development-indicators).

## Computational requirements

- Stata 17
  - `fastreshape` (version 0.2)
  - `grstyle` (version 1.1.1)

## Description of programs

- The `raw-data` folder  contains all input data, which includes publicly available datasets either downloaded or scrapped from the Internet.
- The `work-data` folder stores intermediate files produced during the analysis process of the raw data.
- The `figures` folder  is dedicated to all visual representations created by the code.
- The `tables` folder encompasses the tables generated by the code.
- The `programs` folder holds all the code required to perform the analysis. We delineate it subsequently:
  - `programs/00-master`, which initializes the project's directories and executes all codes.
  - `programs/01-gravity-data-build`, which uses and extends the CEPII gravity dataset (Conte, M., P. Cotterlaz and T. Mayer, 2022).
  - `programs/02-bilateral-portfolio-assets-matrices`, which constructs the exhaustive matrices of all identifiable bilateral portfolio assets starting from the CPIS and using a gravity-like model of bilateral portfolio holdings to derive the bilateral claims of non-CPIS countries.
  - `programs/03-produce-output-tables`, which creates Table A1 "Global Cross-Border Securities Assets" (total assets and corrections), Table A2 "Global Cross-Border Securities Liabilities", and Table A3 "Global Discrepancy Between Cross-Border Securities Assets and Liabilities" (Zucman, 2013).
  - `programs/04-bis-deposits-build`, develops a comprehensive dataset on bilateral bank deposits using data from the Bank for International Settlements.
  - `programs/05-swiss-fiduciary-build`, forms a homogeneous dataset of foreign-owned Swiss fiduciary deposits based on data from the Swiss National Bank.
  - `programs/06-offshore-wealth-analysis`, merges BIS and SNB sources and generates estimates, figures, and tables on the country-level analysis of offshore wealth.

## Instructions for replicators

### Programs features

## List of tables and programs

## References

 Alstadsæter, Annette, Niels Johannesen, and Gabriel Zucman. 2018. “Who Owns the Wealth in Tax Havens? Macro Evidence and Implications for Global Inequality”. Journal of Public Economics, 162: 89–100.

 Bertaut, Carol C. and Tryon, Ralph, Monthly Estimates of U.S. Cross-Border Securities Positions (November 2007). FRB International Finance Discussion Paper No. 910.  
 
 Carol C. Bertaut & Ruth A. Judson, 2014. "Estimating U.S. Cross-Border Securities Positions: New Data and New Methods". International Finance Discussion Papers 1113, Board of Governors of the Federal Reserve System (U.S.).   

 Conte, M., P. Cotterlaz and T. Mayer (2022), "The CEPII Gravity database". CEPII Working Paper N°2022-05, July 2022. 

 Thierry Mayer & Soledad Zignago , 2011. "Notes on CEPII’s distances measures: The GeoDist database". CEPII Working Paper 2011- 25 , December 2011 , CEPII.
 
 Zucman, Gabriel. 2013. “The Missing Wealth of Nations: Are Europe and the US net Debtors or net Creditors?” Quarterly Journal of Economics, 128(3), 1321–1364. 
