# Global Offshore Wealth, 2001 - 2021
Replication package for "Global Offshore Wealth, 2001 - 2021", by Souleymane Faye, Sarah Godar, and Gabriel Zucman.

## Overview 
Contained within this replication package is a collection of code designed to generate country-level data files for the purpose of reproducing the data accessible on the [Atlas of the Offshore World](https://atlas-offshore.world/) website, alongside the paper "Global Offshore Wealth, 2001 - 2021" authored by Faye, Godar, and Zucman in 2023. This code amalgamates information from a diverse set of origins (which will be delineated subsequently). All code files are intended for execution within the Stata environment.

The paper aims to construct homogeneous time series that capture global household offshore financial wealth across more than 200 countries, from 2001 to 2021, a period marked by substantial international efforts to combat offshore tax evasion. It then examines the shifts in both the geographical location and ownership of offshore wealth. Furthermore, the study investigates the Common Reporting Standard (CRS) and the automatic exchange of information, drawing implications for the global economy. The research also elucidates the observed trends, particularly the transition toward increased ownership by middle- and lower-income countries, while high-income nations experience a corresponding decline. Additionally, it highlights the shift from Switzerland to Asian financial centers as the preferred offshore wealth locations.

## Data

**Locational Banking Statistics from the Bank for International Settlements (BIS)**

Data on the country breakdown of cross-border positions by nationality of reporting banks are publicly available in the BIS website at https://www.bis.org/statistics/full_data_sets.htm. The data are downloaded by the file `4a-import-bis.do` and stored as a stata data file `work-data/locational.dta`.     
From January 2024 on, the data will not longer appear in the link provided above, as it will be disseminated through the [BIS data portal](https://data.bis.org/bulkdownload).   

**Annual Banking Statistics from the Swiss National Bank (SNB)**

We utilize the country breakdown of fiduciary deposits on the liability side from the *Annual Banking Statistics*. The data is publicly available on the [Swiss National Bank (SNB) website](https://data.snb.ch/en/warehouse/BSTA/cube/BSTA@SNB.JAHR_UL.ABI.TRE.PAS?fromDate=1987&toDate=2022&dimSel=KONSOLIDIERUNGSSTUFE(U),INLANDAUSLAND(A,ABW,AFG,AGO,ALB,AND,ARE,ARG,ARM,AUS,AUT,AZE,BDI,BEL,BEN,BES,BFA,BGD,BGR,BHR,BHS,BIH,BLR,BLZ,BMU,BOL,BRA,BRB,BRN,BTN,BWA,CAF,CAN,CHL,CHN,CIV,CMR,COD,COG,COL,COM,CPV,CRI,CUB,CUW,CYM,CYP,CZE,DEU,DJI,DMA,DNK,DOM,DZA,ECU,EGY,ERI,ESP,EST,ETH,FIN,FJI,FLK,FRO,FSM,GAB,GBR,GEO,GGY,GHA,GIB,GIN,GMB,GNB,GNQ,GRC,GRD,GRL,GTM,GUY,HKG,HND,HRV,HTI,HUN,IDN,IMN,IND,IRL,IRN,IRQ,ISL,ISR,ITA,JAM,JEY,JOR,JPN,KAZ,KEN,KGZ,KHM,KIR,KOR,KWT,LAO,LBN,LBR,LBY,LCA,LKA,LSO,LTU,LUX,LVA,MAC,MAR,MDA,MDG,MDV,MEX,MHL,MKD,MLI,MLT,MMR,MNE,MNG,MOZ,MRT,MUS,MWI,MYS,NAM,NCL,NER,NGA,NIC,NLD,NOR,NPL,NRU,NZL,OMN,PAK,PAN,PER,PHL,PLW,PNG,POL,PRK,PRT,PRY,PSE,PYF,QAT,ROU,RUS,RWA,SAU,SDN,SEN,SGP,SHN,SLB,SLE,SLV,SMR,SOM,SRB,SSD,STP,SUR,SVK,SVN,SWE,SWZ,SXM,SYC,SYR,TAA,TCA,TCD,TGO,THA,TJK,TKM,TLS,TON,TTO,TUN,TUR,TUV,TWN,TZA,UGA,UKR,URY,USA,UZB,VAT,VCT,VEN,VNM,VUT,WLF,WSM,XVU,YEM,ZAF,ZMB,ZWE,BIZ_FR,BIZ_PU,BIZ_1Z),WAEHRUNG(U),BANKENGRUPPE(A30)). This data

## Computational requirements

## Description of programs

## Instructions for replicators

## List of tables and programs

## References
