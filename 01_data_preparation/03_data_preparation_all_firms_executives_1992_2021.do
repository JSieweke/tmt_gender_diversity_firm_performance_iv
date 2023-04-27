*********************************************************************
*Data: Download from WRDS (Compustat ExecuComp)
*Firms: All North American firms in ExecuComp
*Date range: 1992-2021
*Calculation of the shift-part of the shift-share instrument
*********************************************************************

*********************************************************************
****************************NAICS 2 DIGIT****************************
*********************************************************************

clear all
macro drop _all 
set more off

*Load data*
cd ..
use 00_data\compustat_all_firms_executives_1992-2021.dta

*Install User-written Stata commands*
net install panelstat, from("https://github.com/BPLIM/Tools/raw/master/ados/General/panelstat/") replace

*********************************************************************
**************************Sample Information*************************
*********************************************************************
*Rename variables*
rename *, lower //change variable name to lowercase

*Split NAICS variable*
gen naics_2digit = substr(naics, 1,2)
destring naics_2digit, replace

*Collapse data to the firm level*
collapse execdir naics_2digit, by(gvkey year)
drop if year < 1994 | year == 2021 //

panelstat gvkey year if naics_2digit != 52 //Information on the panel data without firms from the financial industry

*********************************************************************
clear all
use 00_data/compustat_all_firms_executives_1992-2021.dta //reload data


*********************************************************************
**********Prepare data to calculate instrument***********************
*********************************************************************
*Rename variables*
rename *, lower //change variable name to lowercase

*Transform to string variables*
tostring sic, replace

*Split NAICS variable*
gen naics_2digit = substr(naics, 1,2)
destring naics_2digit, replace

*Define macros*
global baseyear 1996 //base year
global industry naics_2digit

*Destring Variable*
destring gvkey, replace

*********************************************************************
**************************Generate Instrument************************
*********************************************************************
*Calculate number of executives and women executives within an Industry*
gen female = gender == "FEMALE" //female = 1; male = 0
bysort naics_2digit year: egen no_femaleexec_naics2 = total(female) //number of female executives per Industry and Year
label variable no_femaleexec_naics2 "No of Women Executives in an Industry in year t"
by naics_2digit year: gen no_executives_naics2  = _N //number of executives per Industry and Year
label variable no_executives_naics2 "No of Executives in an Industry in year t"

*Collapse data to the industry level*
collapse no_femaleexec_naics2 no_executives_naics2, by($industry year)

*Descriptive Statistics*
xtset $industry year
xtsum no_femaleexec_naics2 if naics_2digit != 52 | year > 1993 | year != 2021
display as text "Average Number of Women Top Managers =" as result r(mean)
display as text "Average Number of Women Top Managers - Standard Deviation =" as result r(sd)

xtsum no_executives_naics2 if naics_2digit != 52 | year > 1993 | year != 2021
display as text "Average Number of Top Managers =" as result r(mean)
display as text "Average Number of Top Managers - Standard Deviation =" as result r(sd)

*Calculate 3 Year Moving Average of Women Executives and Executives in NAICS 2 industry - Base year 1996 + t-1 and t-2*
xtset $industry year
by $industry: gen nofemexec_3y_naics2 = (no_femaleexec_naics2 + l1.no_femaleexec_naics2 + l2.no_femaleexec_naics2) 
label variable nofemexec_3y_naics2 "3 year moving average of number of women executives in an industry"
by $industry: gen noexec_3y_naics2 = (no_executives_naics2 + l1.no_executives_naics2 + l2.no_executives_naics2)
label variable noexec_3y_naics2 "3 year moving average of number of executives in an industry"

*Calculate the percentage of female executives per industry and year*
gen perc_femexec_naics2 = (no_femaleexec_naics2/no_executives_naics2)*100 //Percentage of female executives NAICS 2*
label variable perc_femexec_naics2 "% of female executives NAICS 2"
gen perc_femexec3y_naics2 = (nofemexec_3y_naics2/noexec_3y_naics2)*100 //Percentage of female executives NAICS 2 - 3 year moving average*
label variable perc_femexec3y_naics2 "% of female executives NAICS 2 - 3 year moving average"

*Replace values of 0 with minimum value > 0*
foreach var of varlist perc_femexec_naics2 perc_femexec3y_naics2 {
	by $industry: egen min`var' = min(`var') if `var' > 0
	by $industry: egen min`var'_2 = max(min`var')
	drop min`var'
	rename min`var'_2 min`var'
}

*Generate new variables: Growth of Women in Management Positions over Time*
*Shift part of the shift-share instrument*

*Set baseyear percentage, which is required to calculate the growth rate*
gen base_exec_naics2 = perc_femexec_naics2 if year == $baseyear
gen base_exec3y_naics2 = perc_femexec3y_naics2 if year == $baseyear

*If baseyear percentage = 0, I replace the "0" with the lowest observed value to be able to calculate a growth rate*
by $industry: replace base_exec_naics2 = minperc_femexec_naics2 if base_exec_naics2 == 0
by $industry: replace base_exec3y_naics2 = minperc_femexec3y_naics2 if base_exec3y_naics2 == 0

*Assign baseyear values to all years*
foreach var of varlist base_exec_naics2 base_exec3y_naics2 {
	by $industry: egen `var'_2 = max(`var')
	drop `var'
	rename `var'_2 `var'
}

*Generate the Shift part of the Shift-Share Instrument*
gen shift_naics2 = perc_femexec_naics2/base_exec_naics2
gen shift_3y_naics2 = perc_femexec3y_naics2/base_exec3y_naics2

rename year fyear

keep fyear naics_2digit perc_femexec_naics2 perc_femexec3y_naics2 base_exec_naics2 base_exec3y_naics2 shift_naics2 shift_3y_naics2

save 00_data/female_exec_naics2.dta, replace

*********************************************************************
******Calculation of Shift Instrument without Focal Firm*************
*********************************************************************

clear all

use 00_data/compustat_all_firms_executives_1992-2021.dta

*********************************************************************
*****************************Prepare data****************************
*********************************************************************
*Rename variables*
rename *, lower //change variable name to lowercase

*Transform to string variables*
tostring sic, replace

*Split NAICS variable*
gen naics_2digit = substr(naics, 1,2)
destring naics_2digit, replace
destring gvkey, replace

*Define macros*
global baseyear 1996 //base year
global industry naics_2digit

*********************************************************************
**************************Generate Instrument************************
*********************************************************************
*Calculate number of women executives within an Industry and Firm*
gen female = gender == "FEMALE" //female = 1; male = 0
bysort gvkey year: egen no_womenexec_firm = total(female) //number of female executives per Firm and Year
label variable no_womenexec_firm "No of Women Executives per Firm and Year"
bysort $industry year: egen no_femaleexec_naics2 = total(female) //number of female executives per Industry and Year
label variable no_femaleexec_naics2 "No of Women Executives per Industry and Year"
gen no_femaleexec_naics2_focal = no_femaleexec_naics2 - no_womenexec_firm //Number of female executives NAICS 2 without managers from focal firm*
label variable no_femaleexec_naics2_focal "No of Women Executives per Industry and Year without managers from focal firm"

*Calculate number of executives within an industry and firm*
bysort gvkey year: gen tmt_size = _N //number of executives per Firm and Year
label variable tmt_size "No of Executives per Firm and Year"
bysort naics_2digit year: gen no_executives_naics2  = _N //number of executives per Industry and Year
label variable no_executives_naics2 "No of Executives per Industry and Year"
gen no_executives_naics2_focal = no_executives_naics2 - tmt_size //Number of executives NAICS 2 without managers from focal firm*
label variable no_executives_naics2_focal "No of Executives per Industry and Year without executives from focal firm"

*Collapse data to the firm level*
collapse no_femaleexec_naics2_focal no_executives_naics2_focal (max) $industry, by(gvkey year)

*Calculate 3 Year Moving Average of Executives in NAICS 2 industry - Base year + t-1 and t-2*
xtset gvkey year
by gvkey: gen noexec_3y_naics2_focal = (no_executives_naics2_focal + l1.no_executives_naics2_focal + l2.no_executives_naics2_focal)
replace noexec_3y_naics2_focal = no_executives_naics2_focal if noexec_3y_naics2_focal == . //If the 3-year moving average is not available, then I use the data from year t only
by gvkey: gen nofemexec_3y_naics2_focal = (no_femaleexec_naics2_focal + l1.no_femaleexec_naics2_focal + l2.no_femaleexec_naics2_focal)
replace nofemexec_3y_naics2_focal = no_femaleexec_naics2_focal if nofemexec_3y_naics2_focal == . //If the 3-year moving average is not available, then I use the data from year t only

*Calculate the percentage of female executives per industry and year*
gen perc_femexec_naics2_focal = (no_femaleexec_naics2_focal/no_executives_naics2_focal)*100 //Percentage of female executives NAICS 2 without focal firm*
label variable perc_femexec_naics2_focal "% of female executives NAICS 2 without focal firm"
gen perc_femexec3y_naics2_focal = (nofemexec_3y_naics2_focal/noexec_3y_naics2_focal)*100 //Percentage of female executives NAICS 2 without focal firm - 3 year moving average*
label variable perc_femexec3y_naics2_focal "% of female executives NAICS 2 without focal firm - 3 year moving average"

*Replace values of 0 with minimum value > 0*
foreach var of varlist perc_femexec_naics2_focal perc_femexec3y_naics2_focal {
	by gvkey: egen min`var' = min(`var') if `var' > 0
	by gvkey: egen min`var'_2 = max(min`var')
	drop min`var'
	rename min`var'_2 min`var'
}

*Generate new variables: Growth of Women in Management Positions over Time*
*Shift part of the shift-share instrument*

*Set baseyear percentage, which is required to calculate the growth rate*
gen base_exec_naics2_focal = perc_femexec_naics2_focal if year == $baseyear
gen base_exec3y_naics2_focal = perc_femexec3y_naics2_focal if year == $baseyear

*If baseyear percentage = 0, I replace the "0" with the lowest observed value to be able to calculate a growth rate*
by gvkey: replace base_exec_naics2_focal = minperc_femexec_naics2_focal if base_exec_naics2_focal == 0
by gvkey: replace base_exec3y_naics2_focal = minperc_femexec3y_naics2_focal if base_exec3y_naics2_focal == 0

*Assign baseyear values to all years*
foreach var of varlist base_exec_naics2_focal base_exec3y_naics2_focal {
	by gvkey: egen `var'_2 = max(`var')
	drop `var'
	rename `var'_2 `var'
}

label variable base_exec_naics2_focal "% of female executives NAICS 2 without focal firm in Baseyear"
label variable base_exec3y_naics2_focal "% of female executives NAICS 2 without focal firm in Baseyear - 3 year moving average"

*Generate the Shift part of the Shift-Share Instrument*
gen shift_focal_naics2 = perc_femexec_naics2_focal/base_exec_naics2_focal
label variable shift_focal_naics2 "Shift part without focal firm"
gen shift_focal_3y_naics2 = perc_femexec3y_naics2_focal/base_exec3y_naics2_focal
label variable shift_focal_3y_naics2 "Shift part without focal firm - 3 year moving average"

rename year fyear

keep gvkey naics_2digit fyear perc_femexec_naics2_focal perc_femexec3y_naics2_focal base_exec_naics2_focal base_exec3y_naics2_focal shift_focal_naics2 shift_focal_3y_naics2 

save 00_data/female_exec_naics2_focal.dta, replace