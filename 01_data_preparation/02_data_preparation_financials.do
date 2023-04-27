*********************************************************************
*Data: Download from WRDS (Compustat North America Fundamentals Annual)
*Firms: All firms in the S&P 1500 in the year 1997 (12/31/1997)
*Date range: 1996-2020
*********************************************************************
clear all
set more off

*Set directory*
cd ..
use 00_data/sp_1500_financials_1996_2020_compustat.dta //firm financial data downloaded from Compustat using TIC
append using 00_data/sp_1500_financials_1996_2020_compustat_gvkey.dta //firm financial data downloaded from Compustat using hand-collected GVKEY

*Installing user-written programs*
ssc install mdesc, replace

*********************************************************************
*****************************Prepare data****************************
*********************************************************************

*Rename variables*
rename *, lower //change variable name to lowercase
rename (at ni prcc_c csho ceq sale ib dp fyear conm revt xrd capx xad dlc dltt dvpsp_f) /// 
(total_assets net_incomeloss priceclosecalendar commonsharesoutstanding commonandordinaryequitytotal salesturnovernet incomebeforeextraordinaryitem depreciationandamortization year company_name total_revenue r_d_expenditures capital_expenditures advertising_expenses debt_currentliabilities debt_longterm dividends_share)

gen debt = debt_currentliabilities + debt_longterm

*Transform Variables*
replace total_assets = total_assets + 1 //4 observations have total assets of 0; yet, logarithm of 0 is undefined
gen ln_total_assets = ln(total_assets)

*Destring variables*
destring gvkey, replace

*Identify and drop duplicate observations
sort gvkey year indfmt
by gvkey year: drop if indfmt == "FS" & indfmt[_n+1] == "INDL"


*********************************************************************
*************************Generate Variables**************************
*********************************************************************
*Firm performance variables*
xtset gvkey year
gen tsr = (((priceclosecalendar-l1.priceclosecalendar)+dividends_share)/l1.priceclosecalendar)*100
gen market_value = priceclosecalendar*commonsharesoutstanding
gen sales_growth = ((salesturnovernet-l1.salesturnovernet)/l1.salesturnovernet)*100
gen cash_flow = incomebeforeextraordinaryitem + depreciationandamortization
gen tobinsq = ((priceclosecalendar*commonsharesoutstanding) + total_assets - commonandordinaryequitytotal)/total_assets

drop if year == 1996 //delete observations from 1996 which were only used to calculate tsr and sales_growth

keep total_assets market_value salesturnovernet sales_growth cash_flow net_incomeloss total_revenue r_d_expenditures capital_expenditures depreciationandamortization ///
advertising_expenses debt_currentliabilities debt_longterm debt tobinsq ln_total_assets gvkey year state company_name sic naics tic tsr ///
priceclosecalendar dividends_share

*Split NAICS variable*
gen naics_2digit = substr(naics, 1,2)
destring naics_2digit, replace

*Calculating missing values per variable*
mdesc total_assets cash_flow tsr net_incomeloss sales_growth total_revenue r_d_expenditures capital_expenditures depreciationandamortization ///
advertising_expenses debt_currentliabilities debt_longterm debt if naics_2digit != 52

save 00_data/sp_1500_firm_financials_1997_2020, replace