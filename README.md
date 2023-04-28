# tmt_gender_diversity_firm_performance_iv
In this repository, you will find the repliction files for the paper "The influence of top management team gender diversity on firm performance during stable periods and economic crises: an instrumental variable analysis" (Jost Sieweke, Denefa Bostandzic and Svenja Smolinski). 

For copy-right reasons, we are not allowed to share our datasets. What we can share, however, are (a) the data sources and (b) the queries. We hope that this allows other researchers to replicate our results. 

The paper uses three types of datasets, which are described below:

1. Data on all executives
Data source: Compustat ExecuComp (via WRDS)
Time period: 1992-2021
Variables: All available variables (108 variables in total)
Companies: All available companies

2. Data on S&P 1500 Companies: Financials
Data source: Compustat North America: Compustat Daily Updates - Fundamentals Annual (via WRDS)
Time period: 1997-2021
Variables: All available variables (974 variables in total)
Consolidation level: C
Industry Format: INDL and FS
Population Sources: D
Currency: USD and CAD
Company Status: A and I
Companies: S&P 1500 companies (as of December 1997)

3. Data on S&P 1500 Companies: Executives
Data source: Compustat ExecuComp (via WRDS)
Time period: 1992-2021
Variables: All available variables (108 variables in total)
Companies: S&P 1500 companies (as of December 1997)

Unfortunately, we are not allowed to share the list of S&P 1500 companies from December 1997. This list can be bought from Siblis Research (https://siblisresearch.com/data/historical-component-changes/). If you have bought the list, we are of course happy to check whether your sample is similar to ours (please note that we struggled to collect information from all 1500 firms from Compustat because of incorrect TIC).

After downloading the data, you can import them into Stata and run our do-files to replicate all steps in the paper including merging and data analysis. Please follow this order:

1. Run all do-files in the folder "01_data_preparation"
2. Run all do-files in the folder "02_merge_data"
3. In the folder "03_data_analysis", you will find nine do-files. Below, please find an overview of the focus of each do-file:

"01_descriptivestatistics_correlations": Allows you to replicate Table 1 (descriptive statistics and correlations).

"02_data_analsis": Allows you to replicate Table 2 (The Influence of TMT Gender Diversity on Firm Performance: Results of the Fixed-Effects Analysis) and Table 3 (The Influence of TMT Gender Diversity on Firm Performance: Results of the Instrumental Variable Analysis).

"03_data_analysis_crisis": Allows you to replicate Table 4 (The Influence of TMT Gender Diversity on Firm Performance during Crises: Results of the Fixed-Effects Analysis) and Table 5 (The Influence of TMT Gender Diversity on Firm Performance during Crises: Results of the Instrumental Variable Analysis).

"04_data_analysis_footnotes": Allows you to replicate the results reported in the footnotes.

"a_appendix": Allows you to replicate the results reported in Appendix A (results for non-log tranformed total assets variable). 

"b_appendix": Allows you to replicate the results reported in Appendix B (results for alternative measures of TMT gender diversity). 

"c_appendix": Allows you to replicate the results reported in Appendix C (results for alternative clustering of standard errors).

"d_appendix": Allows you to replicate the results reported in Appendix D (results for winsorized variables).

"e_appendix": Allows you to replicate the results reported in Appendix E (results for IV regression with additional control variables).  

To replicate the results from Appendix F (first-stage results of the analyses in Table 5), please use the file "03_data_analysis_crisis"
 
Before running the analyses, please check that you have installed the required user-written Stata commands (the installation routine is included in the do-files). The do-files are based on Stata Version 17.

If you have any questions or struggled with replicating the results, please contact me [j.sieweke@vu.nl]  
