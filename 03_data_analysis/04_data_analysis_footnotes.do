*********************************************************************
*Data: Firm Financial Data and TMT Data
*Date range: 1992 until 2020 (calendar year)
*Analyses in Footnotes*
*********************************************************************
clear all
set more off
version 17

*Load data*
use ../00_data/merged_dataset_tmt.dta

*Start log*
log using data_analysis_footnotes.txt, text replace name(data_analysis_footnotes)

*Install User-written commands*
ssc install boottest, replace
ssc install mdesc, replace

*Install ftools (remove program if it existed previously)
cap ado uninstall ftools
net install ftools, from("https://raw.githubusercontent.com/sergiocorreia/ftools/master/src/")

*Install reghdfe
cap ado uninstall reghdfe
net install reghdfe, from("https://raw.githubusercontent.com/sergiocorreia/reghdfe/master/src/")

*Install ivreg2, the core package
cap ado uninstall ivreg2
ssc install ivreg2

*Install ivreghdfe
cap ado uninstall ivreghdfe
net install ivreghdfe, from("https://raw.githubusercontent.com/sergiocorreia/ivreghdfe/master/src/")

*********************************************************************
*************************Prepare Data********************************
*********************************************************************

*Generate Instrument - Bartik shift-share instrument*
gen instrument_n2_3y_focal = shift_focal_3y_naics2*base1996_compwomexec_3y //3 year moving average for share and shift part
label variable instrument_n2_3y_focal "Shift-share instrument"

*********************************************************************************************************************************
*Define local macro
capture macro drop ind_variable instrument condition seed cluster_se bootstraps
global cluster_se naics_2digit
global seed 123456
global bootstraps 10000
global ind_variable womexec_perc
global condition "if instrument_n2_3y_focal != ." 
global instrument instrument_n2_3y_focal

**************************************************
*****************Footnote 7***********************
**********Amount of Missing Data******************
**************************************************
mdesc market_value sales_growth tsr ln_total_assets cash_flow womexec_perc instrument_n2_3y_focal 

**************************************************
*****************Footnote 13**********************
****Run Main Analyses without Crisis Year*********
**************************************************

drop if fyear == 2008 | fyear == 2009| fyear == 2020

*Accounting-based Firm Performance: ROA - Net income
asdoc ivreghdfe net_income ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable) 
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)


*Market-based measure: Market Value
asdoc ivreghdfe tsr ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable)
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)

*Liquidity: Cash flow
asdoc ivreghdfe cash_flow ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable)
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)

*Growth Measure: Sales growth
asdoc ivreghdfe sales_growth ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable)
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)

**************************************************************************************************************************************************************************************************

log close data_analysis_footnotes