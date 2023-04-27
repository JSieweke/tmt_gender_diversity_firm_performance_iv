*********************************************************************
*Data: Download from WRDS (Compustat ExecuComp)
*Firms: All firms in the S&P 1500 in the year 1997 (12/31/1997)
*Index constituents bought from Siblis Research
*Date range: 1997 until 2021
*********************************************************************
clear all
set more off

*Load data*
cd ..
use 00_data/sp_1500_executives_1992_2021_compustat.dta //firm financial data downloaded from Compustat using TIC
append using 00_data/sp_1500_executives_1992_2021_compustat_gvkey.dta //firm financial data downloaded from Compustat using hand-collected GVKEY

*Installing user-written programs*
net install panelstat, from("https://github.com/pguimaraes99/panelstat/raw/master/") replace

*********************************************************************
*****************************Prepare data****************************
*********************************************************************

*Rename variables*
rename *, lower //change variable name to lowercase

*Destring variables*
destring gvkey execid, replace

*Create new variables*
bysort gvkey year: egen tmt_mean_age = mean(age) // TMT Average Age
bysort gvkey year: gen teamsize= _N // TMT size

*TMT Gender Diversity
gen female = gender=="FEMALE"
bysort gvkey year: egen number_women = sum(female) //total number of women in TMT in year t
bysort gvkey year: gen number_men=teamsize-number_women
bysort gvkey year: gen blau_gendiv = 1-((number_men/teamsize)^2+(number_women/teamsize)^2) //Blau's index Gender Diversity
bysort gvkey year: gen dummy_women = number_women>0 //dummy variable if at least one women in in the TMT
bysort gvkey year: gen ceo_female = gender == "FEMALE" & ceoann == "CEO" //dummy variable if at least one women in in the TMT

*Split NAICS variable*
gen naics_2digit = substr(naics, 1,2)
destring naics_2digit, replace

*Collapse data by firm/year*
collapse naics_2digit teamsize tmt_mean_age number_women dummy_women blau_gendiv (max) ceo_female, by(gvkey year)

*Information on Firms in the Sample
xtset gvkey year
xtdescribe if year>1996 & year != 2021
panelstat gvkey year if year>1996 & year != 2021 & naics_2digit != 52 // Panel structure for firms in our sample (NAICS 52 = firms in financial industry; excluded in this study)

*********************************************************************
*****************************Bartik Instrument***********************
******************Share Part of Shift-Share Instrument***************
*********************************************************************

*Generate share part of the shift-share instrument*
gen comp_womexec_perc = (number_women/teamsize)*100 // percentage of women in TMT
by gvkey: gen comp_womexec_3year = (comp_womexec_perc + l1.comp_womexec_perc + l2.comp_womexec_perc) / 3 // 3-year moving average of the percentage of women in TMT

*3 Year Moving Average - Base year 1996*
by gvkey: gen base1996_compwomexec_3y = comp_womexec_3year if year == 1996
replace base1996_compwomexec_3y = comp_womexec_perc if base1996_compwomexec_3y == . & year == 1996 // We replace the 3-year moving average with the women executive percentage in 1996 if the 3-year moving average is missing

foreach var of varlist base1996_compwomexec_3y {
	by gvkey: egen `var'_2 = max(`var')
	drop `var'
	rename `var'_2 `var'
}

label variable base1996_compwomexec_3y "Share WomExec for each Company in the year 1996 (three year moving average)"

save 00_data/sp_1500_tmt_variables_1992_2021, replace