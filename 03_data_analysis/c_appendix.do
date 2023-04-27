*********************************************************************
*Data: Firm Financial Data and TMT Data
*Date range: 1992 until 2021 (calendar year)
*Robustness Checks*
*Appendix C: Clustering of Standard Errors
*********************************************************************

clear all
set more off
version 17

*Load data*
use ../00_data/merged_dataset_tmt.dta

*Install user-written programs*
ssc install weakivtest, replace
ssc install boottest, replace

* Install ftools (remove program if it existed previously)
cap ado uninstall ftools
net install ftools, from("https://raw.githubusercontent.com/sergiocorreia/ftools/master/src/")

* Install reghdfe
cap ado uninstall reghdfe
net install reghdfe, from("https://raw.githubusercontent.com/sergiocorreia/reghdfe/master/src/")

* Install ivreg2, the core package
cap ado uninstall ivreg2
ssc install ivreg2

* Finally, install this package
cap ado uninstall ivreghdfe
net install ivreghdfe, from("https://raw.githubusercontent.com/sergiocorreia/ivreghdfe/master/src/")

*Start log file*
log using appendix_c.txt, text replace name(appendix_c)

*********************************************************************
*************************Prepare Data********************************
*********************************************************************

*Generate Instrument - Bartik shift-share instrument*
gen instrument_n2_3y_focal = shift_focal_3y_naics2*base1996_compwomexec_3y //3 year moving average for share and shift part
label variable instrument_n2_3y_focal "Shift-Share Instrument"

**********************************************************************
**************Instrumental Variable Design****************************
**********************************************************************
xtset gvkey fyear

*************Industry Definition: NAICS 2 Digit***********************

**********************Standard Errors Clustered By Firm*********************
*Define macros*
capture macro drop ind_variable instrument condition seed cluster_se bootstraps
global condition if instrument_n2_3y_focal != .
global ind_variable womexec_perc
global instrument instrument_n2_3y_focal
global bootstraps 10000
global seed 123456
global cluster_se gvkey

*Accounting-based Firm Performance: ROA - Net income
ivreghdfe net_income ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se)  first a(gvkey) 
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
gen used_observations_1 = e(sample) //required to drop singleton observations in the ivreg2 command
qui ivreg2 net_income ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_1 == 1, cluster($cluster_se) first partial(i.gvkey)
weakivtest

*Market-based measure: Tobin's Q
ivreghdfe tsr ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se)  first a(gvkey) 
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
gen used_observations_2 = e(sample) //required to drop singleton observations in the ivreg2 command
qui ivreg2 tsr ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_2 == 1, cluster($cluster_se) first partial(i.gvkey)
weakivtest

*Liquidity: Cash flow
ivreghdfe cash_flow ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se)  first a(gvkey)
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
gen used_observations_3 = e(sample) //required to drop singleton observations in the ivreg2 command
qui ivreg2 cash_flow ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_3 == 1, cluster($cluster_se)  first partial(i.gvkey)
weakivtest

*Growth Measure: Sales growth
ivreghdfe sales_growth ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se)  first a(gvkey)
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
gen used_observations_4 = e(sample) //required to drop singleton observations in the ivreg2 command
qui ivreg2 sales_growth ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_4 == 1, cluster($cluster_se)  first partial(i.gvkey)
weakivtest

drop used_*
**********************************************************************************************************************************************************************************

**********************Standard Errors Clustered By Industry and Year*********************
capture macro drop ind_variable instrument condition seed cluster_se bootstraps
global condition if instrument_n2_3y_focal != .
global ind_variable womexec_perc
global instrument instrument_n2_3y_focal
global bootstraps 10000
global seed 123456
global cluster_se naics_2digit fyear

*Accounting-based Firm Performance: ROA - Net income
ivreghdfe net_income ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se)  first a(gvkey)
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
gen used_observations_1 = e(sample) //required to drop singleton observations in the ivreg2 command
qui ivreg2 net_income ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_1 == 1, cluster($cluster_se) first partial(i.gvkey)
weakivtest

*Market-based measure: Tobin's Q
ivreghdfe tsr ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se)  first a(gvkey)
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
gen used_observations_2 = e(sample) //required to drop singleton observations in the ivreg2 command
qui ivreg2 tsr ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_2 == 1, cluster($cluster_se) first partial(i.gvkey)
weakivtest

*Liquidity: Cash flow
ivreghdfe cash_flow ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se)  first a(gvkey)
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
gen used_observations_3 = e(sample) //required to drop singleton observations in the ivreg2 command
qui ivreg2 cash_flow ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_3 == 1, cluster($cluster_se)  first partial(i.gvkey)
weakivtest

*Growth Measure: Sales growth
ivreghdfe sales_growth ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se)  first a(gvkey)
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
gen used_observations_4 = e(sample) //required to drop singleton observations in the ivreg2 command
qui ivreg2 sales_growth ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_4 == 1, cluster($cluster_se)  first partial(i.gvkey)
weakivtest
**********************************************************************************************************************************************************************************

log close appendix_c