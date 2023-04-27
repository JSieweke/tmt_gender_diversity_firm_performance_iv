*********************************************************************
*Data: Firm Financial Data and TMT Data
*Date range: 1992 until 2021 (calendar year)
*Robustness Checks*
*Appendix B: Different Measures for Independent Variable
*********************************************************************

clear all
set more off
version 17

*Load data*
use ../00_data/merged_dataset_tmt.dta

*Start log file*
log using appendix_b.txt, text replace name(appendix_b)

*********************************************************************
*************************Prepare Data********************************
*********************************************************************

*Generate Instrument - Bartik shift-share instrument*
gen instrument_n2_3y_focal = shift_focal_3y_naics2*base1996_compwomexec_3y //3 year moving average for share and shift part

*Define macros*
capture macro drop ind_variable instrument condition seed cluster_se bootstraps //delete macros
global condition if instrument_n2_3y_focal != .
global instrument instrument_n2_3y_focal
global cluster_se naics_2digit
global seed 123456
global bootstraps 10000

**********************************************************************
**************Instrumental Variable Design****************************
**********************************************************************

*1. Number of Women as Independent Variable*
global ind_variable number_women

xtset gvkey fyear

*************Industry Definition: NAICS 2 Digit***********************

*******************Analyses with Firm Fixed-Effects - Industry-Level Standard Errors****************
ivreghdfe net_income ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se) a(gvkey) endog($ind_variable) first
gen used_observations_1 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 net_income ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_1 == 1, cluster($cluster_se)  first
weakivtest

ivreghdfe tsr ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se) a(gvkey) endog($ind_variable) first
gen used_observations_2 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 tsr ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_2 == 1, cluster($cluster_se)  first
weakivtest

ivreghdfe cash_flow ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se) a(gvkey) endog($ind_variable) first
gen used_observations_3 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 cash_flow ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_3 == 1, cluster($cluster_se)  first
weakivtest

ivreghdfe sales_growth ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se) a(gvkey) endog($ind_variable) first
gen used_observations_4 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 sales_growth ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_4 == 1, cluster($cluster_se)  first
weakivtest

drop used_observations_*
**************************************************************************************************************************************************************************************************

*2. Gender Diversity measured by Blau index*

*Define macros*
capture macro drop ind_variable //delete macros
global ind_variable blau_gendiv

**********************************************************************
**************Instrumental Variable Design****************************
**********************************************************************
xtset gvkey fyear

*************Industry Definition: NAICS 2 Digit***********************

*******************Analyses with Firm Fixed-Effects - Industry-Level Standard Errors****************
ivreghdfe net_income ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se) a(gvkey) endog($ind_variable) first
gen used_observations_1 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 net_income ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_1 == 1, cluster($cluster_se)  first
weakivtest

ivreghdfe tsr ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se) a(gvkey) endog($ind_variable) first
gen used_observations_2 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 tsr ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_2 == 1, cluster($cluster_se)  first
weakivtest

ivreghdfe cash_flow ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se) a(gvkey) endog($ind_variable) first
gen used_observations_3 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 cash_flow ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_3 == 1, cluster($cluster_se)  first
weakivtest

ivreghdfe sales_growth ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se) a(gvkey) endog($ind_variable) first
gen used_observations_4 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 sales_growth ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_4 == 1, cluster($cluster_se)  first
weakivtest
**************************************************************************************************************************************************************************************************

log close appendix_b