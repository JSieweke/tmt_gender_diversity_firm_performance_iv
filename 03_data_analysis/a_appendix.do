*********************************************************************
*Data: Firm Financial Data and TMT Data
*Date range: 1992 until 2021 (calendar year)
*Robustness Checks*
*Appendix A: Log- and non-log transformed Total Assets Variable
*********************************************************************

clear all
set more off
version 17

*Load data*
use ../00_data/merged_dataset_tmt.dta

*Start log file*
log using appendix_a.txt, text replace name(appendix_a)

*********************************************************************
*************************Prepare Data********************************
*********************************************************************

*Generate Instrument - Bartik shift-share instrument*
gen instrument_n2_3y_focal = shift_focal_3y_naics2*base1996_compwomexec_3y //3 year moving average for share and shift part

*Define macros*
capture macro drop ind_variable instrument condition cluster_se
global condition if instrument_n2_3y_focal != .
global ind_variable womexec_perc
global instrument instrument_n2_3y_focal
global cluster_se naics_2digit
global seed 123456
global bootstraps 10000

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

*Accounting-based Firm Performance: ROA - Net income
ivreghdfe net_income ($ind_variable = $instrument) total_assets i.fyear $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable) 
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
ivreghdfe net_income ($ind_variable = $instrument) ln_total_assets i.fyear  $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable)
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)

*Market-based measure: Tobin's Q
ivreghdfe tsr ($ind_variable = $instrument) total_assets i.fyear  $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable) 
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
ivreghdfe tsr ($ind_variable = $instrument) ln_total_assets i.fyear  $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable)
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)

*Liquidity: Cash flow
ivreghdfe cash_flow ($ind_variable = $instrument) total_assets i.fyear  $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable) 
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
ivreghdfe cash_flow ($ind_variable = $instrument) ln_total_assets i.fyear  $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable)
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)

*Growth Measure: Sales growth
ivreghdfe sales_growth ($ind_variable = $instrument) total_assets i.fyear  $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable) 
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
ivreghdfe sales_growth ($ind_variable = $instrument) ln_total_assets i.fyear  $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable)
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
**************************************************************************************************************************************************************************************************

log close appendix_a