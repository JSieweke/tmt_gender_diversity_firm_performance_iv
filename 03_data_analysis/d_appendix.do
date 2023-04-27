*********************************************************************
*Data: Firm Financial Data and TMT Data
*Date range: 1992 until 2021 (calendar year)
*Robustness Checks*
*Appendix D: Winsorizing Variables
*********************************************************************

clear all
set more off

*Load dataset*
use ../00_data/merged_dataset_tmt.dta

*********************************************************************
*************************APPENDIX D**********************************
*************************Winsorizing*********************************
*********************************************************************

*Start log file*
log using appendix_d.txt, text replace name(appendix_d)

*Install User-written commands*
ssc install boottest, replace //user-written program for boottest
ssc install weakivtest, replace //user written program for Olea-Pflueger F-statistic
ssc install winsor2, replace //user-written program for winsorizing

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
label variable instrument_n2_3y_focal "Shift-Share Instrument"

*Winsorize Variables*
winsor2 net_income tsr cash_flow sales_growth ln_total_assets womexec_perc, cuts(1 99) suffix(w1) //Winsorize 1 percent level
winsor2 net_income tsr cash_flow sales_growth ln_total_assets womexec_perc, cuts(3 97) suffix(w3) //Winsorize 3 percent level
winsor2 net_income tsr cash_flow sales_growth ln_total_assets womexec_perc, cuts(5 95) suffix(w5) //Winsorize 5 percent level


**********************************************************************
**************Instrumental Variable Design****************************
**********************************************************************
xtset gvkey fyear

*************Industry Definition: NAICS 2 Digit***********************

*******************Analyses with Firm Fixed-Effects - Industry-Level Standard Errors****************
*Dependent variables:
*1. Accounting-based Firm Performance: ROA - Net income
*2. Market-based measure: Tobin's Q
*3. Liquidity: Cash flow
*4. Growth Measure: Sales growth

**********************Winsorize 1%*********************
*Define macros*
capture macro drop ind_variable instrument condition seed cluster_se bootstraps
global condition if instrument_n2_3y_focal != .
global ind_variable womexec_percw1
global instrument instrument_n2_3y_focal
global bootstraps 10000
global seed 123456
global cluster_se naics_2digit


*Accounting-based Firm Performance: ROA - Net income
ivreghdfe net_incomew1 ($ind_variable = $instrument) ln_total_assetsw1 i.fyear $condition, cluster($cluster_se)  first a(gvkey)
gen used_observations_1 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 net_incomew1 ($ind_variable = $instrument) ln_total_assetsw1 i.gvkey i.fyear $condition & used_observations_1 == 1, cluster($cluster_se)  first
weakivtest

*Market-based measure: Tobin's Q
ivreghdfe tsrw1 ($ind_variable = $instrument) ln_total_assetsw1 i.fyear $condition, cluster($cluster_se)  first a(gvkey) 
gen used_observations_2 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 tsrw1 ($ind_variable = $instrument) ln_total_assetsw1 i.gvkey i.fyear $condition & used_observations_2 == 1, cluster($cluster_se)  first
weakivtest

*Liquidity: Cash flow
ivreghdfe cash_floww1 ($ind_variable = $instrument) ln_total_assetsw1 i.fyear $condition, cluster($cluster_se)  first a(gvkey) 
gen used_observations_3 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 cash_floww1 ($ind_variable = $instrument) ln_total_assetsw1 i.gvkey i.fyear $condition & used_observations_3 == 1, cluster($cluster_se)  first
weakivtest

*Growth Measure: Sales growth
ivreghdfe sales_growthw1 ($ind_variable = $instrument) ln_total_assetsw1 i.fyear $condition, cluster($cluster_se)  first a(gvkey)
gen used_observations_4 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 sales_growthw1 ($ind_variable = $instrument) ln_total_assetsw1 i.gvkey i.fyear $condition & used_observations_4 == 1, cluster($cluster_se)  first
weakivtest

drop used_*
**********************Winsorize 3%*********************
*Define macros*
capture macro drop ind_variable instrument condition seed cluster_se bootstraps
global condition if instrument_n2_3y_focal != .
global ind_variable womexec_percw3
global instrument instrument_n2_3y_focal
global bootstraps 10000
global seed 123456
global cluster_se naics_2digit

*Accounting-based Firm Performance: ROA - Net income
ivreghdfe net_incomew3 ($ind_variable = $instrument) ln_total_assetsw3 i.fyear $condition, cluster($cluster_se)  first a(gvkey) 
gen used_observations_1 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 net_incomew3 ($ind_variable = $instrument) ln_total_assetsw3 i.gvkey i.fyear $condition & used_observations_1 == 1, cluster($cluster_se)  first
weakivtest

*Market-based measure: Tobin's Q
ivreghdfe tsrw3 ($ind_variable = $instrument) ln_total_assetsw3 i.fyear $condition, cluster($cluster_se)  first a(gvkey) 
gen used_observations_2 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 tsrw3 ($ind_variable = $instrument) ln_total_assetsw3 i.gvkey i.fyear $condition & used_observations_2 == 1, cluster($cluster_se)  first
weakivtest

*Liquidity: Cash flow
ivreghdfe cash_floww3 ($ind_variable = $instrument) ln_total_assetsw3 i.fyear $condition, cluster($cluster_se)  first a(gvkey) 
gen used_observations_3 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 cash_floww3 ($ind_variable = $instrument) ln_total_assetsw3 i.gvkey i.fyear $condition & used_observations_3 == 1, cluster($cluster_se)  first
weakivtest

*Growth Measure: Sales growth
ivreghdfe sales_growthw3 ($ind_variable = $instrument) ln_total_assetsw3 i.fyear $condition, cluster($cluster_se)  first a(gvkey) 
gen used_observations_4 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 sales_growthw3 ($ind_variable = $instrument) ln_total_assetsw3 i.gvkey i.fyear $condition & used_observations_4 == 1, cluster($cluster_se)  first
weakivtest

drop used_*
**********************Winsorize 5%*********************
*Define macros*
capture macro drop ind_variable instrument condition seed cluster_se bootstraps
global condition if instrument_n2_3y_focal != .
global ind_variable womexec_percw5
global instrument instrument_n2_3y_focal
global bootstraps 10000
global seed 123456
global cluster_se naics_2digit

*Accounting-based Firm Performance: ROA - Net income
ivreghdfe net_incomew5 ($ind_variable = $instrument) ln_total_assetsw5 i.fyear $condition, cluster($cluster_se)  first a(gvkey) 
gen used_observations_1 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 net_incomew5 ($ind_variable = $instrument) ln_total_assetsw5 i.gvkey i.fyear $condition & used_observations_1 == 1, cluster($cluster_se)  first
weakivtest

*Market-based measure: Tobin's Q
ivreghdfe tsrw5 ($ind_variable = $instrument) ln_total_assetsw5 i.fyear $condition, cluster($cluster_se)  first a(gvkey)
gen used_observations_2 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 tsrw5 ($ind_variable = $instrument) ln_total_assetsw5 i.gvkey i.fyear $condition & used_observations_2 == 1, cluster($cluster_se)  first
weakivtest

*Liquidity: Cash flow
ivreghdfe cash_floww5 ($ind_variable = $instrument) ln_total_assetsw5 i.fyear $condition, cluster($cluster_se)  first a(gvkey)
gen used_observations_3 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 cash_floww5 ($ind_variable = $instrument) ln_total_assetsw5 i.gvkey i.fyear $condition & used_observations_3 == 1, cluster($cluster_se)  first
weakivtest

*Growth Measure: Sales growth
ivreghdfe sales_growthw5 ($ind_variable = $instrument) ln_total_assetsw5 i.fyear $condition, cluster($cluster_se)  first a(gvkey) 
gen used_observations_4 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 sales_growthw5 ($ind_variable = $instrument) ln_total_assetsw5 i.gvkey i.fyear $condition & used_observations_4 == 1, cluster($cluster_se)  first
weakivtest

drop used_*

**********************************************************************************************************************************************************************************

log close appendix_d