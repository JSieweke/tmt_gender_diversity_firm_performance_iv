*********************************************************************
*Data: Firm Financial Data and TMT Data
*Date range: 1992-2021 (calendar year)
*Merging datasets (TMT, Firm Financials, Instrument)
*********************************************************************
clear all
set more off

*Set directory*
cd ..

*Merge datasets*
*1. Use Firm Financial Dataset
*2. Merge with TMT Dataset
*3. Merge with Data on Female Managers within an Industry

*********************************************************************
*1. Load Firm Financial Data
use ./00_data/sp_1500_firm_financials_1997_2020.dta //firm financials dataset
bysort gvkey year:  gen dup = cond(_N==1,0,_n)
drop if dup > 0 //drop two obervations from INTL Game Technology PLC (no data and no year) 
*********************************************************************

*2. Merge with TMT Dataset
merge 1:1 gvkey year using ./00_data/sp_1500_tmt_variables_1992_2021 //TMT dataset
drop if _merge == 2 //Delete all firms that were just used to calculate the industry average but that are not included in the S&P 1,500
drop if _merge == 1 //Delete all firms for which we lack TMT data 
drop _merge
*********************************************************************

*3. Merge with Data on Female Managers within an Industry*
rename year fyear

merge m:m naics_2digit fyear using ./00_data/female_exec_naics2.dta //data for shift-share instrument; female executives within an industry (focal firm is included in calculation)
drop if _merge == 2 //Delete observations from industries that are not represented among S&P 1,500
drop _merge

merge m:m gvkey fyear using ./00_data/female_exec_naics2_focal.dta //data for shift-share instrument; female executives within an industry (focal firm is subtracted)
drop if _merge == 2 //Delete observations from industries that are not represented among S&P 1,500
drop _merge
*********************************************************************

*********************************************************************
*************************Prepare Data for Analysis*******************
*********************************************************************
replace naics = "423830" if gvkey == 5256 //NAICS for Grainger Inc is wrong

*Delete observations*
drop if fyear > 2020 | fyear < 1997 //delete years that are not included in the analysis
drop if gvkey == .  //all observations without a gvkey code
drop if naics_2digit == 52 //drop financial service companies
drop if ln_total_assets == .

*Generate Dummy Variables for Time*
tab fyear, gen(dummy_year)

*Rename Variables*
rename(comp_womexec_perc net_incomeloss) (womexec_perc net_income)

save ./00_data/merged_dataset_tmt, replace
