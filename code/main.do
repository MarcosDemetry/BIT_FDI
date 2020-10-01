* General housekeeping
clear all
set more off
capture log close

* Global paths
if `"`c(os)'"' == "MacOSX" global stem `"/Users/marcosdemetry/Dropbox/IFN/Programming/Stata_projects/BIT_FDI/"'
if `"`c(os)'"' == "Windows" global stem `"C:/Users/marcos.demetry/Dropbox/IFN/Programming/Stata_projects/BIT_FDI/"'

gl excel_country "${stem}/data/unctd_excel"
gl stata_country "${stem}/data/unctd_stata"
gl stata_country_clean "${stem}/data/unctd_stata_clean"
gl stata_country_wide "${stem}/data/unctd_wide"
gl unctd_final "${stem}/data/unctd_final"

gl datadir "${stem}/data"
gl outputdir "${stem}/output"


* Create BIT-FDI data
do "${stem}/code/creating_bit_fdi.do"

* Analyze BIT-FDI data
do "${stem}/code/analysing_bit_fdi.do"

