*********************************************************************
*Data: Firm Financial Data and TMT Data
*Date range: 1992 until 2021 (calendar year)
*Main Analyses - Table 2 and 3*
*********************************************************************
clear all
set more off
version 17

*Load data*
use ../00_data/merged_dataset_tmt.dta

*Start log*
log using data_analysis_main.txt, text replace name(data_analysis_main)

*Install User-written commands*
ssc install boottest, replace //user-written program for boottest
ssc install weakivtest, replace //user written program for Olea-Pflueger F-statistic

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

**************************************************
*****************Analysis 1997-2020***************
**************************************************

*Generate Instrument - Bartik shift-share instrument*
gen instrument_n2_3y_focal = shift_focal_3y_naics2*base1996_compwomexec_3y //3 year moving average for share and shift part
label variable instrument_n2_3y_focal "Shift-share instrument"

*Define Macros*
capture macro drop ind_variable instrument condition seed cluster_se bootstraps
global cluster_se naics_2digit
global seed 123456
global bootstraps 10000
global ind_variable womexec_perc
global condition "if instrument_n2_3y_focal != ." 
global instrument instrument_n2_3y_focal

**************************************************
************Fixed-Effects Regression**************
**************************************************
*Save standard deviation of dependent variables for calculation of economic significance*
foreach var of varlist net_income tsr cash_flow sales_growth {
	quietly sum `var'
	gen sd_`var' = r(sd)
}

xtset gvkey fyear

*Accounting-based Firm Performance Variables*
*ROA - Net income*
reghdfe net_income $ind_variable ln_total_assets $condition, a(gvkey fyear) cluster(gvkey)
estimates store model1
display as text "Adding one woman to a team of 6 top managers will increase a firm's net income by  = " as result _b[$ind_variable]*16.67
display as text "95% confidence interval (lower bound)  = " as result (_b[$ind_variable]*16.67) - invttail(e(df_r),0.025)*(_se[$ind_variable]*16.67)
display as text "95% confidence interval (upper bound)  = " as result (_b[$ind_variable]*16.67) + invttail(e(df_r),0.025)*(_se[$ind_variable]*16.67)
display as text "Adding one woman to a team of 6 top managers will increase a firm's net income by (as ratio of standard deviation) = " as result (_b[$ind_variable]*16.67)/sd_net_income

*Market-based measure*
reghdfe tsr $ind_variable ln_total_assets $condition, a(gvkey fyear) cluster(gvkey)
estimates store model2
display as text "Adding one woman to a team of 6 top managers will increase a firm's market value by  = " as result _b[$ind_variable]*16.67
display as text "95% confidence interval (lower bound)  = " as result (_b[$ind_variable]*16.67) - invttail(e(df_r),0.025)*(_se[$ind_variable]*16.67)
display as text "95% confidence interval (upper bound)  = " as result (_b[$ind_variable]*16.67) + invttail(e(df_r),0.025)*(_se[$ind_variable]*16.67)
display as text "Adding one woman to a team of 6 top managers will increase a firm's market value by (as ratio of standard deviation) = " as result (_b[$ind_variable]*16.67)/sd_tsr

*Liquidity*
reghdfe cash_flow $ind_variable ln_total_assets $condition, a(gvkey fyear)  cluster(gvkey)
estimates store model3
display as text "Adding one woman to a team of 6 top managers will increase a firm's cash flow by  = " as result _b[$ind_variable]*16.67
display as text "95% confidence interval (lower bound)  = " as result (_b[$ind_variable]*16.67) - invttail(e(df_r),0.025)*(_se[$ind_variable]*16.67)
display as text "95% confidence interval (upper bound)  = " as result (_b[$ind_variable]*16.67) + invttail(e(df_r),0.025)*(_se[$ind_variable]*16.67)
display as text "Adding one woman to a team of 6 top managers will increase a firm's cash flow by (as ratio of standard deviation) = " as result (_b[$ind_variable]*16.67)/sd_cash_flow

*Growth Measure*
reghdfe sales_growth $ind_variable ln_total_assets $condition, a(gvkey fyear)  cluster(gvkey)
estimates store model4
display as text "Adding one woman to a team of 6 top managers will increase a firm's sales growth by  = " as result _b[$ind_variable]*16.67
display as text "95% confidence interval (lower bound)  = " as result (_b[$ind_variable]*16.67) - invttail(e(df_r),0.025)*(_se[$ind_variable]*16.67)
display as text "95% confidence interval (upper bound)  = " as result (_b[$ind_variable]*16.67) + invttail(e(df_r),0.025)*(_se[$ind_variable]*16.67)
display as text "Adding one woman to a team of 6 top managers will increase a firm's sales growth by (as ratio of standard deviation) = " as result (_b[$ind_variable]*16.67)/sd_sales_growth

*Create Table 2: Results of the Fixed-Effects Regression*
esttab model1 model2 model3 model4, b(%10.2f) p(%10.2f) ///
label title(The Influence of TMT Gender Diversity on Firm Performance: Results of the Fixed-Effects Analysis) ///
mtitle("Profitability" "Market-based Performance" "Liquidity" "Growth") ///
drop(_cons) ///
addnote("Model 1-4 include time and firm fixed-effects")

**********************************************************************
**************Instrumental Variable Design****************************
**********************************************************************

*************Industry Definition: NAICS 2 Digit***********************

*******************Analyses with Firm Fixed-Effects - Industry-Level Standard Errors****************
global instrument instrument_n2_3y_focal

*Accounting-based Firm Performance: ROA - Net income
ivreghdfe net_income ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se)  first a(gvkey) endog(womexec_perc) 
display as text "Adding one woman to a team of 6 top managers will increase a firm's net income by  = " as result _b[$ind_variable]*16.67
display as text "95% confidence interval (lower bound)  = " as result (_b[$ind_variable]*16.67) - invttail(e(df_r),0.025)*(_se[$ind_variable]*16.67)
display as text "95% confidence interval (upper bound)  = " as result (_b[$ind_variable]*16.67) + invttail(e(df_r),0.025)*(_se[$ind_variable]*16.67)
display as text "Adding one woman to a team of 6 top managers will increase a firm's net income by (as ratio of standard deviation) = " as result (_b[$ind_variable]*16.67)/sd_net_income
gen used_observations_1 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 net_income ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_1 == 1, cluster($cluster_se)  first endog($ind_variable)
weakivtest

*Market-based measure: Market Value
ivreghdfe tsr ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable)
display as text "Adding one woman to a team of 6 top managers will increase a firm's market value by  = " as result _b[$ind_variable]*16.67
display as text "95% confidence interval (lower bound)  = " as result (_b[$ind_variable]*16.67) - invttail(e(df_r),0.025)*(_se[$ind_variable]*16.67)
display as text "95% confidence interval (upper bound)  = " as result (_b[$ind_variable]*16.67) + invttail(e(df_r),0.025)*(_se[$ind_variable]*16.67)
display as text "Adding one woman to a team of 6 top managers will increase a firm's market value by (as ratio of standard deviation) = " as result (_b[$ind_variable]*16.67)/sd_tsr
gen used_observations_2 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 tsr ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_2 == 1, cluster($cluster_se)  first endog($ind_variable)
weakivtest

*Liquidity: Cash flow
ivreghdfe cash_flow ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable) 
display as text "Adding one woman to a team of 6 top managers will increase a firm's cash flow by  = " as result _b[$ind_variable]*16.67
display as text "95% confidence interval (lower bound)  = " as result (_b[$ind_variable]*16.67) - invttail(e(df_r),0.025)*(_se[$ind_variable]*16.67)
display as text "95% confidence interval (upper bound)  = " as result (_b[$ind_variable]*16.67) + invttail(e(df_r),0.025)*(_se[$ind_variable]*16.67)
display as text "Adding one woman to a team of 6 top managers will increase a firm's cash flow by (as ratio of standard deviation) = " as result (_b[$ind_variable]*16.67)/sd_cash_flow
gen used_observations_3 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 cash_flow ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_3 == 1, cluster($cluster_se)  first endog($ind_variable)
weakivtest

*Growth Measure: Sales growth
ivreghdfe sales_growth ($ind_variable = $instrument) ln_total_assets i.fyear $condition, cluster($cluster_se)  first a(gvkey) endog($ind_variable) 
display as text "Adding one woman to a team of 6 top managers will increase a firm's sales growth by  = " as result _b[$ind_variable]*16.67
display as text "95% confidence interval (lower bound)  = " as result (_b[$ind_variable]*16.67) - invttail(e(df_r),0.025)*(_se[$ind_variable]*16.67)
display as text "95% confidence interval (upper bound)  = " as result (_b[$ind_variable]*16.67) + invttail(e(df_r),0.025)*(_se[$ind_variable]*16.67)
display as text "Adding one woman to a team of 6 top managers will increase a firm's sales growth by (as ratio of standard deviation) = " as result (_b[$ind_variable]*16.67)/sd_sales_growth
gen used_observations_4 = e(sample) //required to drop singleton observations in the ivreg2 command
boottest $ind_variable, reps($bootstraps) seed($seed) cluster($cluster_se) ptype(equaltail)
qui ivreg2 sales_growth ($ind_variable = $instrument) ln_total_assets i.gvkey i.fyear $condition & used_observations_4 == 1, cluster($cluster_se)  first endog($ind_variable)
weakivtest

****************************************************************************************************************************************************************************************************

*Test for Endogeneity of Independent Variable*
*Use of Durbin-Wu-Hausman Test*
ivreghdfe net_income ($ind_variable = $instrument) ln_total_assets $condition, cluster($cluster_se)  first a(gvkey fyear) endog($ind_variable) 
di as text "The result of the C test is " e(estat)
di as text "with a p-value of " e(estatp)
ivreghdfe tsr ($ind_variable = $instrument) ln_total_assets $condition, cluster($cluster_se)  first a(gvkey fyear) endog($ind_variable) 
di as text "The result of the C test is " e(estat)
di as text "with a p-value of " e(estatp)
ivreghdfe cash_flow ($ind_variable = $instrument) ln_total_assets $condition, cluster($cluster_se)  first a(gvkey fyear) endog($ind_variable) 
di as text "The result of the C test is " e(estat)
di as text "with a p-value of " e(estatp)
ivreghdfe sales_growth ($ind_variable = $instrument) ln_total_assets $condition, cluster($cluster_se)  first a(gvkey fyear) endog($ind_variable)
di as text "The result of the C test is " e(estat)
di as text "with a p-value of " e(estatp) 

**************************************************************************************************************************************************************************************************

log close data_analysis_main
