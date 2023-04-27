*********************************************************************
*Data: Firm Financial Data and TMT Data
*Date range: 1992 until 2021 (calendar year)
*Analyses during Crises*
*********************************************************************
clear all
set more off
version 17

*Set directory*
cd "C:\Users\Jost Sieweke\Dropbox\Forschung\paper\Top management teams"
use ./00_data/merged_dataset_tmt.dta

*Start log*
log using data_analysis_crisis.txt, text replace name(data_analysis_crisis)

*Install User-written commands*
ssc install boottest, replace //user-written program for boottest

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
*Rename time dummy variables*
rename (dummy_year12 dummy_year13 dummy_year24) (dummy_2008 dummy_2009 dummy_2020)

*Generate Interaction between Crisis Variable and TMT Gender Diversity Variable*
gen gendiv_2008 = womexec_perc*dummy_2008
gen gendiv_2009 = womexec_perc*dummy_2009
gen gendiv_2020 = womexec_perc*dummy_2020

*Generate Instrument - Bartik shift-share instrument*
gen instrument_n2_3y_focal = shift_focal_3y_naics2*base1996_compwomexec_3y //3 year moving average for share and shift part
label variable instrument_n2_3y_focal "Shift-share instrument"

*Define local macro
capture macro drop ind_variable instrument condition seed cluster_se bootstraps interactions
global condition if instrument_n2_3y_focal != .
global cluster_se naics_2digit
global seed 123456
global bootstraps 10000
global ind_variable womexec_perc
global interactions gendiv_2008 gendiv_2009 gendiv_2020

**************************************************
************Fixed-Effects Regression**************
**************************************************
xtset gvkey fyear

*Accounting-based Firm Performance Variables*
*Net income*
reghdfe net_income $ind_variable $interactions ln_total_assets i.fyear $condition, a(gvkey) cluster(gvkey)
estimates store model10
boottest (gendiv_2008 gendiv_2009 gendiv_2020), seed($seed) cluster($cluster_se) reps($bootstraps) //test of join signficiance of the interaction terms

*Market-based measure*
reghdfe tsr $ind_variable $interactions ln_total_assets i.fyear $condition, a(gvkey) cluster(gvkey) 
estimates store model11
boottest (gendiv_2008 gendiv_2009 gendiv_2020), seed($seed) cluster($cluster_se) reps($bootstraps) //test of join signficiance of the interaction terms

*Liquidity*
reghdfe cash_flow $ind_variable $interactions ln_total_assets i.fyear $condition, a(gvkey) cluster(gvkey) 
estimates store model12
boottest (gendiv_2008 gendiv_2009 gendiv_2020), seed($seed) cluster($cluster_se) reps($bootstraps) //test of join signficiance of the interaction terms

*Growth Measure*
reghdfe sales_growth $ind_variable $interactions ln_total_assets i.fyear $condition, a(gvkey) cluster(gvkey) 
estimates store model13
boottest (gendiv_2008 gendiv_2009 gendiv_2020), seed($seed) cluster($cluster_se) reps($bootstraps) //test of join signficiance of the interaction terms

*Create Table 4: Results of the Fixed-Effects Regression*
esttab model10 model11 model12 model13, b(%10.2f) p(%10.2f) ///
label title(The Influence of TMT Gender Diversity on Firm Performance: Results of the Fixed-Effects Analysis) ///
mtitle("Profitability" "Market-based Performance" "Liquidity" "Growth") ///
drop(_cons) ///
addnote("Model 10-13 include time and firm fixed-effects")

**********************************************************************
**************Instrumental Variable Design****************************
**********************************************************************
xtset gvkey fyear

*Define macros*
global instrument instrument_n2_3y_focal

gen instr_2008 = $instrument * dummy_2008
gen instr_2009 = $instrument * dummy_2009
gen instr_2020 = $instrument * dummy_2020

global instr_interaction instr_2008 instr_2009 instr_2020

*************Industry Definition: NAICS 2 Digit***********************

*******************Analyses with Firm Fixed-Effects****************
*Save standard deviation of dependent variables for calculation of economic significance*
foreach var of varlist net_income tsr cash_flow sales_growth {
	quietly sum `var'
	gen sd_`var' = r(sd)
}

*Accounting-based Firm Performance: ROA - Net income
ivreghdfe net_income ($ind_variable $interactions = $instrument $instr_interaction) ln_total_assets i.fyear $condition, cluster($cluster_se) first a(gvkey)
boottest gendiv_2008 gendiv_2009 gendiv_2020, seed($seed) cluster($cluster_se) reps($bootstraps)
display as text "Adding one woman to a team of 6 top managers will increase a firm's net income by  = " as result _b[gendiv_2008]+_b[gendiv_2009]+_b[gendiv_2020]
display as text "Adding one woman to a team of 6 top managers will increase a firm's net income by (as ratio of standard deviation) = " as result (_b[$ind_variable]*16.67)/sd_net_income

*Market-based measure: Tobin's Q
ivreghdfe tsr ($ind_variable $interactions = $instrument $instr_interaction) ln_total_assets i.fyear `condition', cluster(naics_2digit)  first a(gvkey)
boottest gendiv_2008 gendiv_2009 gendiv_2020, seed($seed) cluster($cluster_se) reps($bootstraps)
display as text "Adding one woman to a team of 6 top managers will increase a firm's market value by  = " as result _b[$ind_variable]*16.67
display as text "Adding one woman to a team of 6 top managers will increase a firm's market value by (as ratio of standard deviation) = " as result (_b[$ind_variable]*16.67)/sd_tsr

*Liquidity: Cash flow
ivreghdfe cash_flow ($ind_variable $interactions = $instrument $instr_interaction) ln_total_assets i.fyear `condition', cluster(naics_2digit)  first a(gvkey)
boottest gendiv_2008 gendiv_2009 gendiv_2020, seed($seed) cluster($cluster_se) reps($bootstraps)
display as text "Adding one woman to a team of 6 top managers will increase a firm's cash flow by  = " as result _b[$ind_variable]*16.67
display as text "Adding one woman to a team of 6 top managers will increase a firm's cash flow by (as ratio of standard deviation) = " as result (_b[$ind_variable]*16.67)/sd_cash_flow

*Growth Measure: Sales growth
ivreghdfe sales_growth ($ind_variable $interactions = $instrument $instr_interaction) ln_total_assets i.fyear `condition', cluster(naics_2digit)  first a(gvkey)
boottest gendiv_2008 gendiv_2009 gendiv_2020, seed($seed) cluster($cluster_se) reps($bootstraps)
display as text "Adding one woman to a team of 6 top managers will increase a firm's sales growth by  = " as result _b[$ind_variable]*16.67
display as text "Adding one woman to a team of 6 top managers will increase a firm's sales growth by (as ratio of standard deviation) = " as result (_b[$ind_variable]*16.67)/sd_sales_growth
*******************************************************************************************************************************************************************************************************************

log close data_analysis_crisis
