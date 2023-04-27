*********************************************************************
*Data: Firm Financial Data and TMT Data
*Date range: 1997 until 2020 (calendar year)
*Correlations and Descriptive Statistics
*********************************************************************
clear all
set more off
version 17

*Set directory*
use ../00_data/merged_dataset_tmt.dta

*Start log*
log using descstat_correlation.txt, text replace name(descstat_correlation)

*Install User-written commands*
net install panelstat, from("https://github.com/pguimaraes99/panelstat/raw/master/") replace
ssc install asdoc, replace 

*********************************************************************
*************************Prepare Data********************************
*********************************************************************

*Rename Variables*
rename(dummy_year12 dummy_year13 dummy_year24) (y2008 y2009 y2020)

*Generate Instrument - Bartik shift-share instrument*
gen instrument_n2_3y_focal = shift_focal_3y_naics2*base1996_compwomexec_3y //3 year moving average for share and shift part

*Generate Interaction Terms*
*Instrument x Year Dummy*
gen inst_2008 = instrument_n2_3y_focal*y2008
gen inst_2009 = instrument_n2_3y_focal*y2009
gen inst_2020 = instrument_n2_3y_focal*y2020

*Gender Diversity x Year Dummy*
gen gendiv_2008 = womexec_perc*y2008
gen gendiv_2009 = womexec_perc*y2009
gen gendiv_2020 = womexec_perc*y2020

*Generate Cluster Means*
bysort gvkey: egen clmean_lnassets = mean(ln_total_assets)
by gvkey: egen clmean_womexecperc = mean(womexec_perc)
by gvkey: egen clmean_netincome = mean(net_income)
by gvkey: egen clmean_tsr = mean(tsr)
by gvkey: egen clmean_cashflow = mean(cash_flow)
by gvkey: egen clmean_salesgrowth = mean(sales_growth)
by gvkey: egen clmean_instrument = mean(instrument_n2_3y_focal)

****************************Descriptive Statistics and Correlations******************************************
*Define local macro
capture macro drop ind_variable instrument condition seed cluster_se bootstraps
global ind_variable womexec_perc
global condition if instrument_n2_3y_focal != .
global dvs net_income tsr cash_flow sales_growth
global instrument instrument_n2_3y_focal
global crisis_years y20*
global interactions gendiv_* inst_*
global cluster_means clmean_*

*Descriptive Statistics and Correlations
asdoc sum $dvs $ind_variable $instrument  ln_total_assets $crisis_years $interactions $cluster_means  $condition, dec(2) label replace save(descriptives.doc)
asdoc pwcorr $dvs $ind_variable $instrument ln_total_assets $crisis_years $interactions $cluster_means $condition, obs dec(2) replace save(correlations.doc)

*Sample Characteristics*
clear all

use ../00_data/merged_dataset_tmt.dta

panelstat gvkey fyear
xtsum teamsize
display as text "Average TMT size = " as result r(mean)
display as text "Average TMT size - Standard Deviation = " as result r(sd)
xtsum womexec_perc
display as text "Average Percentage of Women in the TMT = " as result r(mean)
display as text "Average Percentage of Women in the TMT - Standard Deviation = " as result r(sd)
******************************************************************************************************************

log close descstat_correlation