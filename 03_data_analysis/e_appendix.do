*********************************************************************
*Data: Merged Firm Financial and TMT Data from Compustat (WRDS)
*Date range: 1992-2020
*Robustness Checks*
*Appendix E: Additional Control Variables
*********************************************************************

clear all
set more off
version 17

*Set directory*
use ../00_data/merged_dataset_tmt.dta

*Start log file*
log using appendix_f.txt, text replace name(appendix_f)

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

*Define macros*
capture macro drop ind_variable instrument condition seed cluster_se bootstraps
global condition if instrument_n2_3y_focal != .
global ind_variable womexec_perc
global instrument instrument_n2_3y_focal
global control_tmt teamsize tmt_mean_age ceo_female
global control_firm ln_total_assets capital_expenditures debt depreciationandamortization
global bootstraps 10000
global seed 123456
global cluster_se naics_2digit

**********************************************************************
**************Instrumental Variable Design****************************
**********************************************************************
xtset gvkey fyear

*************Industry Definition: NAICS 2 Digit***********************

*******************Analyses with Firm Fixed-Effects - Industry-Level Standard Errors****************
*Dependent variables:
*1. Accounting-based Firm Performance: ROA - Net income
*2. Market-based measure: Total Shareholder Return
*3. Liquidity: Cash flow
*4. Growth Measure: Sales growth

*Accounting-based Performance
ivreghdfe net_income ($ind_variable = $instrument) $control_tmt $control_firm i.fyear $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable) 
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
gen used_observations_1 = e(sample) //required to drop singleton observations in the ivreg2 command
qui ivreg2 net_income ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_1 == 1, cluster($cluster_se)  first endog($ind_variable)
weakivtest

*Market-based Performance
ivreghdfe tsr ($ind_variable = $instrument) $control_tmt $control_firm i.fyear $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable)
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
gen used_observations_2 = e(sample) //required to drop singleton observations in the ivreg2 command
qui ivreg2 tsr ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_2 == 1, cluster($cluster_se)  first endog($ind_variable)
weakivtest

*Liquidity
ivreghdfe cash_flow ($ind_variable = $instrument) $control_tmt $control_firm i.fyear $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable)
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
gen used_observations_3 = e(sample) //required to drop singleton observations in the ivreg2 command
qui ivreg2 cash_flow ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_3 == 1, cluster($cluster_se)  first endog($ind_variable)
weakivtest

*Growth Measure
ivreghdfe sales_growth ($ind_variable = $instrument) $control_tmt $control_firm i.fyear $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable)
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
gen used_observations_4 = e(sample) //required to drop singleton observations in the ivreg2 command
qui ivreg2 sales_growth ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_4 == 1, cluster($cluster_se)  first endog($ind_variable)
weakivtest
**************************************************************************************************************************************************************************************************

log close appendix_f