********************************************************************************
****** Importing, cleaning and merging FDI data (from UNCTAD) and BIT data *****
********************************************************************************

cd "${excel_country}"

log using "${outputdir}/logs/cleaning_bit_fdi.log", replace

** Importing FDI sheets **
local excel_files `" "AUT" "BEL" "BGR" "CYP" "CZE" "DEU" "DNK" "ESP" "EST" "FIN" "FRA" "GBR" "GRC" "HRV" "HUN" "IRL" "ITA" "LTU" "LUX" "LVA" "MLT" "NLD" "POL" "PRT" "ROU" "SVK" "SVN" "SWE""'

foreach x of local excel_files {

import excel using "`x'", describe

forvalues sheet = 1/`= r(N_worksheet)' {
	local sheetname = r(worksheet_`sheet')
	
	import excel using "`x'", clear sheet("`sheetname'")
	save "${stata_country}/`x'_`sheetname'", replace
}
}

** Cleaning FDI sheets **
local files: dir "${stata_country}" files "*.dta", respectcase
display `files'

cd "${stata_country}"

local counter = 1
foreach file of local files {

	use "`file'", clear
	
	tostring _all, replace force
	
	* Filling out & reordering columns
	replace A = A[1]

	replace C = B if C == ""
	replace D = C if D == ""
	replace E = D if E == ""
	
	replace B = B[_n - 1] if B[_n] == "" 
	replace C = C[_n - 1] if C[_n] == ""
	replace D = D[_n - 1] if D[_n] == "" & E != ""
	
	* Removing blank observations
	drop if E == ""
	
	capture drop S
	*drop if _n == 1

	
	* Naming columns
	rename (G H I J K L M N O P Q R) ///
	(yr2001 yr2002 yr2003 yr2004 yr2005 yr2006 yr2007 yr2008 yr2009 yr2010 yr2011 yr2012)
	rename(A B C D E) (host economy continent region destination)
	
	replace F = "`c(filename)'"
	rename F FDI
	
	* Removing leading/trailing blanks in names
	gen host_temp = strtrim(host)
	replace host = host_temp
	drop host_temp
	
	* Special cases, names
	replace continent = "CIS" if destination == "Georgia" ///
	| destination == "Russian Federation" | destination == "Ukraine"
	
	replace region = "North America" if destination == "United States" | destination == "Canada"
	
	drop if destination == "European Union" | destination == "Other developed Europe" ///
	| destination == "North America" | destination == "Other Africa" | destination == "Africa" ///
	| destination == "North Africa" | destination == "Asia" | destination == "East Asia" /// 
	| destination == "South-East Asia" | destination == "South Asia" ///
	| destination == "West Asia" | destination == "South America" ///
	| destination == "Central America" | destination == "Caribean" ///
	| destination == "CIS" | destination == "Oceania" | destination == "Latin America and the Caribbean" ///
	| destination == "Other developed countries" | destination == "Developing economies" ///
	| destination == "South-East Europe" | destination == "Transition economies" | destination == "Unspecified" ///
	| destination == "Developed economies" | destination == "Europe" 

	drop if destination == "."
	drop if host == ""
	
	* Special characters in year variables	
	forvalues v = 2001/2012 {
	replace yr`v' = subinstr(yr`v', "..","",.)
	replace yr`v' = "." if yr`v' == ""
	destring yr`v', replace 
	}

	destring yr2005, replace force

	* Stripping FDI variable
	gen FDI_temp = ""
	local b inflows outflows instock outstock
	foreach var of local b {
	replace FDI_temp = "`var'" if strpos(FDI, "`var'")
	}
	
	drop FDI
	rename FDI_temp FDI
	
	* Correcting for potential miscoding of region
	local a `" "Austria" "Belgium" "Bulgaria" "Croatia" "Czech Republic" "Denmark" "Estonia" "Finland" "France" "Germany" "Greece" "Hungary" "Ireland" "Italy" "Latvia" "Lithuania" "Luxembourg" "Malta" "Portugal" "Poland" "Romania" "Slovakia" "Slovenia" "Spain" "Sweden" "Netherlands" "United Kingdom" "'
	foreach v of local a {
	replace region = "European Union" if destination == "`v'"
	}
	
	save "${stata_country_clean}/`file'", replace
	
	* Saving files
	if `counter' == 1 {
	
		sort host FDI economy continent region destination
		order host FDI

		save "${stata_country_clean}/all_files", replace
	
	}
	
	if `counter' != 1 {
	
		append using "${stata_country_clean}/all_files"
	
		duplicates drop host destination, force	
		
		sort host FDI economy continent region destination
		order host FDI

		save "${stata_country_clean}/all_files", replace
	}
	
	local counter = `counter' + 1
	
}


** Reshaping FDI data **

cd "${stata_country_clean}"

* All countries
local files `" "AUT" "BEL" "BGR" "CYP" "CZE" "DEU" "DNK" "ESP" "EST" "FIN" "FRA" "GBR" "GRC" "HRV" "HUN" "IRL" "ITA" "LTU" "LUX" "LVA" "MLT" "NLD" "POL" "PRT" "ROU" "SVK" "SVN" "SWE""'

local counter = 1
foreach file of local files {

	use "`file'_inflows", clear

	drop FDI
	rename yr2012 inflows

	local b instock outflows outstock
	foreach v of local b {
	
		merge 1:1 host destination using "`file'_`v'", keep(match master using) keepusing(yr2012) nogen
	
		rename yr2012 `v'
	}

	drop if destination == continent

	drop if destination == "European Union" | destination == "Other developed Europe" ///
	| destination == "North America" | destination == "Other Africa" | destination == "Africa" ///
	| destination == "North Africa" | destination == "Asia" | destination == "East Asia" /// 
	| destination == "South-East Asia" | destination == "South Asia" ///
	| destination == "West Asia" | destination == "South America" ///
	| destination == "Central America" | destination == "Caribean" ///
	| destination == "CIS" | destination == "Oceania" | destination == "Latin America and the Caribbean" ///
	| destination == "Other developed countries" | destination == "Developing economies" ///
	| destination == "South-East Europe" | destination == "Transition economies" | destination == "Unspecified" ///
	| destination == "Developed economies" | destination == "Europe" 


	drop yr2001-yr2011
	drop economy continent

	replace region = "Non-EU" if region != "European Union" 

	sort host region destination
	order host region destination

	* Saving each a wide file for each country
	save "${stata_country_wide}/`file'_wide", replace
	

	* Saving all files
	if `counter' == 1 {
	
		duplicates drop host destination, force	
	
		drop if region == ""
	
		save "${unctd_final}/all_files_wide", replace
	
	}
	
	if `counter' != 1 {
	
		append using "${unctd_final}/all_files_wide"
	
		duplicates drop host destination, force	
	
		drop if region == ""
	
		save "${unctd_final}/all_files_wide", replace
	}
	
	local counter = `counter' + 1
}

* Removing leading & trailing blanks in names
gen host_temp = strtrim(host)
drop host
rename host_temp host

* Correcting for potential miscoding of region
local a `" "Austria" "Belgium" "Bulgaria" "Croatia" "Czech Republic" "Denmark" "Estonia" "Finland" "France" "Germany" "Greece" "Hungary" "Ireland" "Italy" "Latvia" "Lithuania" "Luxembourg" "Malta" "Portugal" "Poland" "Romania" "Slovakia" "Slovenia" "Spain" "Sweden" "Netherlands" "United Kingdom" "'
foreach v of local a {
	
	replace region = "European Union" if destination == "`v'"

}

* Structuring & saving
order host region destination
sort host region destination

save "${unctd_final}/all_files_wide", replace


** Importing BIT file **
clear

import excel using "${datadir}/CountryBITs"

foreach j in `c(ALPHA)' {



	ds
	local a = r(varlist)

	foreach j of local a {

		local heading = strtoname(`j'[1])

		rename `j' `heading'

		replace `heading' = subinstr(`heading', ".", "/",.)
	
		replace `heading' = "" if `heading' == "N/A"
	}

}

drop if _n == 1

rename country host
rename partner destination

* Keeping latest year 
gen date_entry = date(date_of_entry_into_force, "DMY")
gen year_entry = year(date_entry)
bysort host destination: egen max_year_entry = max(year_entry)
drop date_entry

gen date_signed = date(date_of_signature, "DMY")
gen year_signed = year(date_signed)
bysort host destination: egen max_year_signed = max(year_signed)
drop date_signed

bysort host destination: keep if year_entry == max_year_entry | year_signed == max_year_signed

gen year = max_year_entry
replace year = max_year_signed if max_year_entry == .

keep if year == year_entry

drop max* year_entry year_signed Note

* Dealing with terminated BIT
drop if status == "terminated"

** Merging BIT with FDI **
merge 1:1 host destination using "${unctd_final}/all_files_wide", keep(match using)

* Labeling & renaming
recode _merge (3 = 1) (2 = 0)

label define bit_label 0 "No BIT" 1 "BIT"
la val _merge bit_label

rename _merge bit

* Correcting for potential miscoding of region
local a `" "Austria" "Belgium" "Bulgaria" "Croatia" "Czech Republic" "Denmark" "Estonia" "Finland" "France" "Germany" "Greece" "Hungary" "Italy" "Latvia" "Lithuania" "Luxembourg" "Malta" "Portugal" "Poland" "Romania" "Slovakia" "Slovenia" "Spain" "Sweden" "Netherlands" "United Kingdom" "'
foreach v of local a {
	
	replace region = "European Union" if destination == "`v'"

}

* Austria both as host and destination
drop if host == destination

replace region = "Non-EU" if region == ""

* Structuring & saving
gsort host region -bit destination
order host region destination inflows instock outflows outstock bit year

save "${unctd_final}/bit_fdi", replace

log close


********************************************************************************
************************ Calculations on BIT and FDI ***************************
********************************************************************************

log using "${outputdir}/logs/calculating_bit_fdi.log", replace

use "${unctd_final}/bit_fdi", clear

** Outstock **
* Total
bysort host: egen total_out = total(outstock)

* Outstock no BIT & EU
bysort host: egen total_out_no_bit_eu = total(outstock) if bit == 0 & region == "European Union"

bysort host: egen max_total_out_no_bit_eu = max(total_out_no_bit_eu)
drop total_out_no_bit_eu
rename max_total_out_no_bit_eu total_out_no_bit_eu

bysort host: gen share_out_no_bit_eu = total_out_no_bit_eu / total_out

* Outstock BIT & EU
bysort host: egen total_out_bit_eu = total(outstock) if bit == 1 & region == "European Union"

bysort host: egen max_total_out_bit_eu = max(total_out_bit_eu)
drop total_out_bit_eu
rename max_total_out_bit_eu total_out_bit_eu

bysort host: gen share_out_bit_eu = total_out_bit_eu / total_out

* Outstock no BIT & Non-EU
bysort host: egen total_out_no_bit_non_eu = total(outstock) if bit == 0 & region == "Non-EU"

bysort host: egen max_total_out_no_bit_non_eu = max(total_out_no_bit_non_eu)
drop total_out_no_bit_non_eu
rename max_total_out_no_bit_non_eu total_out_no_bit_non_eu

bysort host: gen share_out_no_bit_non_eu = total_out_no_bit_non_eu / total_out

* Outstock BIT & Non-EU
bysort host: egen total_out_bit_non_eu = total(outstock) if bit == 1 & region == "Non-EU"

bysort host: egen max_total_out_bit_non_eu = max(total_out_bit_non_eu)
drop total_out_bit_non_eu
rename max_total_out_bit_non_eu total_out_bit_non_eu

bysort host: gen share_out_bit_non_eu = total_out_bit_non_eu / total_out

* Outstock table by host
table host, c(mean share_out_no_bit_eu mean share_out_bit_eu mean share_out_no_bit_non_eu mean share_out_bit_non_eu) format(%9.4f) center

** Instock **
* Total
bysort host: egen total_in = total(instock)

* Instock no BIT & EU
bysort host: egen total_in_no_bit_eu = total(instock) if bit == 0 & region == "European Union"

bysort host: egen max_total_in_no_bit_eu = max(total_in_no_bit_eu)
drop total_in_no_bit_eu
rename max_total_in_no_bit_eu total_in_no_bit_eu

bysort host: gen share_in_no_bit_eu = total_in_no_bit_eu / total_in

* Instock BIT & EU
bysort host: egen total_in_bit_eu = total(instock) if bit == 1 & region == "European Union"

bysort host: egen max_total_in_bit_eu = max(total_in_bit_eu)
drop total_in_bit_eu
rename max_total_in_bit_eu total_in_bit_eu

bysort host: gen share_in_bit_eu = total_in_bit_eu / total_in

* Instock no BIT & Non-EU
bysort host: egen total_in_no_bit_non_eu = total(instock) if bit == 0 & region == "Non-EU"

bysort host: egen max_total_in_no_bit_non_eu = max(total_in_no_bit_non_eu)
drop total_in_no_bit_non_eu
rename max_total_in_no_bit_non_eu total_in_no_bit_non_eu

bysort host: gen share_in_no_bit_non_eu = total_in_no_bit_non_eu / total_in

* Instock BIT & Non-EU
bysort host: egen total_in_bit_non_eu = total(instock) if bit == 1 & region == "Non-EU"

bysort host: egen max_total_in_bit_non_eu = max(total_in_bit_non_eu)
drop total_in_bit_non_eu
rename max_total_in_bit_non_eu total_in_bit_non_eu

bysort host: gen share_in_bit_non_eu = total_in_bit_non_eu / total_in

* Instock table by host
table host, c(mean share_in_no_bit_eu mean share_in_bit_eu mean share_in_no_bit_non_eu mean share_in_bit_non_eu) format(%9.4f) center


** Outstock EU **
	* NOTE: EU variable names begin with uppercase 

gen EU = "EU"
	
* Total
egen Total_outstock = total(outstock)

* Outstock no BIT & EU
egen Total_out_no_bit_eu = total(outstock) if bit == 0 & region == "European Union"

egen max_total_out_no_bit_eu = max(Total_out_no_bit_eu)
drop Total_out_no_bit_eu
rename max_total_out_no_bit_eu Total_out_no_bit_eu

gen Share_out_no_bit_eu = Total_out_no_bit_eu / Total_outstock

* Outstock BIT & EU
egen Total_out_bit_eu = total(outstock) if bit == 1 & region == "European Union"

egen max_total_out_bit_eu = max(Total_out_bit_eu)
drop Total_out_bit_eu
rename max_total_out_bit_eu Total_out_bit_eu

gen Share_out_bit_eu = Total_out_bit_eu / Total_outstock

* Outstock no BIT & Non-EU
egen Total_out_no_bit_non_eu = total(outstock) if bit == 0 & region == "Non-EU"

egen max_total_out_no_bit_non_eu = max(Total_out_no_bit_non_eu)
drop Total_out_no_bit_non_eu
rename max_total_out_no_bit_non_eu Total_out_no_bit_non_eu

gen Share_out_no_bit_non_eu = Total_out_no_bit_non_eu / Total_outstock

* Outstock BIT & Non-EU
egen Total_out_bit_non_eu = total(outstock) if bit == 1 & region == "Non-EU"

egen max_total_out_bit_non_eu = max(Total_out_bit_non_eu)
drop Total_out_bit_non_eu
rename max_total_out_bit_non_eu Total_out_bit_non_eu

gen Share_out_bit_non_eu = Total_out_bit_non_eu / Total_outstock

* Outstock table for EU
table EU, c(mean Share_out_no_bit_eu mean Share_out_bit_eu mean Share_out_no_bit_non_eu mean Share_out_bit_non_eu) format(%9.4f) center


** Instock EU **
	* NOTE: EU variable names begin with uppercase

* Total
egen Total_instock = total(instock)

* Instock no BIT & EU
egen Total_in_no_bit_eu = total(instock) if bit == 0 & region == "European Union"

egen max_total_in_no_bit_eu = max(Total_in_no_bit_eu)
drop Total_in_no_bit_eu
rename max_total_in_no_bit_eu Total_in_no_bit_eu

gen Share_in_no_bit_eu = Total_in_no_bit_eu / Total_instock

* Instock BIT & EU
egen Total_in_bit_eu = total(instock) if bit == 1 & region == "European Union"

egen max_total_in_bit_eu = max(Total_in_bit_eu)
drop Total_in_bit_eu
rename max_total_in_bit_eu Total_in_bit_eu

gen Share_in_bit_eu = Total_in_bit_eu / Total_instock

* Instock no BIT & Non-EU
egen Total_in_no_bit_non_eu = total(instock) if bit == 0 & region == "Non-EU"

egen max_total_in_no_bit_non_eu = max(Total_in_no_bit_non_eu)
drop Total_in_no_bit_non_eu
rename max_total_in_no_bit_non_eu Total_in_no_bit_non_eu

gen Share_in_no_bit_non_eu = Total_in_no_bit_non_eu / Total_instock

* Instock BIT & Non-EU
egen Total_in_bit_non_eu = total(instock) if bit == 1 & region == "Non-EU"

egen max_total_in_bit_non_eu = max(Total_in_bit_non_eu)
drop Total_in_bit_non_eu
rename max_total_in_bit_non_eu Total_in_bit_non_eu

gen Share_in_bit_non_eu = Total_in_bit_non_eu / Total_instock

* Instock table by host
table EU, c(mean Share_in_no_bit_eu mean Share_in_bit_eu mean Share_in_no_bit_non_eu mean Share_in_bit_non_eu) format(%9.4f) center

** Labeling **
label var EU "EU"
label var host "Host Country"
label var region "Region"
label var destination "Destination Country"

label var inflows "Inflows"
label var instock "Instock"
label var outflows "Outflows"
label var outstock "Outstock"

label var bit "Bilateral Investment Treaties"
label var year "Year of entry into force"
label var status "Status of BIT"
label var date_of_signature "Date of Signature of BIT"
label var date_of_entry_into_force "Date of entry into force of BIT"

* Country-specific variables
label var total_out "Total Outstock (USD, Millions)"
label var total_in "Total Instock (USD, Millions)"

label var share_out_no_bit_eu "No BIT, EU (% Outstock)"
label var share_out_bit_eu	"BIT, EU (% Outstock)"
label var share_out_no_bit_non_eu "No BIT, Non-EU (% Outstock)"
label var share_out_bit_non_eu "Bit, Non-EU (% Outstock)"

label var share_in_no_bit_eu "No BIT, EU (% Instock)"
label var share_in_bit_eu	"BIT, EU (% Instock)"
label var share_in_no_bit_non_eu "No BIT, Non-EU (% Instock)"
label var share_in_bit_non_eu "Bit, Non-EU (% Instock)"

label var total_out_no_bit_eu "No BIT, EU (USD, Millions, Outstock)"
label var total_out_bit_eu "BIT, EU (USD, Millions, Outstock)"
label var total_out_no_bit_non_eu "No BIT, Non-EU (USD, Millions, Outstock)"
label var total_out_bit_non_eu "Bit, Non-EU (USD, Millions, Outstock)"

label var total_in_no_bit_eu "No BIT, EU (USD, Millions, Instock)"
label var total_in_bit_eu "BIT, EU (USD, Millions, Instock)"
label var total_in_no_bit_non_eu "No BIT, Non-EU (USD, Millions, Instock)"
label var total_in_bit_non_eu "Bit, Non-EU (USD, Millions, Instock)"

* EU variables
label var Total_outstock "Total Outstock (USD, Millions)"
label var Total_instock "Total Instock (USD, Millions)"

label var Share_out_no_bit_eu "No BIT, EU (% Outstock)"
label var Share_out_bit_eu	"BIT, EU (% Outstock)"
label var Share_out_no_bit_non_eu "No BIT, Non-EU (% Outstock)"
label var Share_out_bit_non_eu "Bit, Non-EU (% Outstock)"

label var Share_in_no_bit_eu "No BIT, EU (% Instock)"
label var Share_in_bit_eu	"BIT, EU (% Instock)"
label var Share_in_no_bit_non_eu "No BIT, Non-EU (% Instock)"
label var Share_in_bit_non_eu "Bit, Non-EU (% Instock)"

label var Total_out_no_bit_eu "No BIT, EU (USD, Millions, Outstock)"
label var Total_out_bit_eu "BIT, EU (USD, Millions, Outstock)"
label var Total_out_no_bit_non_eu "No BIT, Non-EU (USD, Millions, Outstock)"
label var Total_out_bit_non_eu "Bit, Non-EU (USD, Millions, Outstock)"

label var Total_in_no_bit_eu "No BIT, EU (USD, Millions, Instock)"
label var Total_in_bit_eu "BIT, EU (USD, Millions, Instock)"
label var Total_in_no_bit_non_eu "No BIT, Non-EU (USD, Millions, Instock)"
label var Total_in_bit_non_eu "Bit, Non-EU (USD, Millions, Instock)"


* Structuring & saving final dataset
gsort host region -bit destination
order EU host region destination inflows instock outflows outstock bit year

save "${unctd_final}/bit_fdi", replace

log close
