
log using "${outputdir}/logs/analyzing_bit_fdi.log", replace

use "${unctd_final}/bit_fdi", clear

** Country Matrix **
preserve

replace destination = "Rest of the World" if region == "Non-EU"

table host destination, c(mean outstock)

table host destination, c(mean instock)

restore

** Figures **

* Barplots
graph bar (mean) share_out_no_bit_eu (mean) share_out_bit_eu ///
	(mean) share_out_no_bit_non_eu (mean) share_out_bit_non_eu if host != "Cyprus", ///
	over(host, sort(1) descending label(angle(vertical))) /// 
	legend(on order(1 "No BIT & EU" 2 "BIT & EU" 3 "No BIT & Non-EU" 4 "BIT & Non-EU")	///
	size(medium)) nofill stack title("Share of Outstock")
	graph export "${outputdir}/figures/bar_share_out.pdf", replace

graph bar (mean) share_in_no_bit_eu (mean) share_in_bit_eu ///
	(mean) share_in_no_bit_non_eu (mean) share_in_bit_non_eu if host != "Cyprus", ///
	over(host, sort(1) descending label(angle(vertical))) /// 
	legend(on order(1 "No BIT & EU" 2 "BIT & EU" 3 "No BIT & Non-EU" 4 "BIT & Non-EU") ///
	size(medium)) nofill stack title("Share of Instock")
	graph export "${outputdir}/figures/bar_share_in.pdf", replace

* Binscatter
binscatter total_out_no_bit_eu total_out_bit_eu total_out_no_bit_non_eu ///
	total_out_bit_non_eu total_out, line(none) ///
	legend(on order(1 "No BIT & EU" 2 "BIT & EU" 3 "No BIT & Non-EU" 4 "BIT & Non-EU")) ///
	title("Outstock") xtitle("Total outstock (Millions {c $|}USD)") ytitle("Outstock (Millions {c $|}USD)")
	graph export "${outputdir}/figures/bin_out_total.pdf", replace
	
binscatter total_in_no_bit_eu total_in_bit_eu total_in_no_bit_non_eu total_in_bit_non_eu total_in, line(none) ///
	legend(on order(1 "No BIT & EU" 2 "BIT & EU" 3 "No BIT & Non-EU" 4 "BIT & Non-EU")) ///
	title("Instock") xtitle("Total Instock (Millions {c $|}USD)") ytitle("Instock (Millions {c $|}USD)")
	graph export "${outputdir}/figures/bin_in_total.pdf", replace

* Binscatter: Entry into force and size of stock
binscatter total_in_bit_eu total_in_bit_non_eu total_out_bit_eu ///
	total_out_bit_non_eu year, line(connect) ///
	legend(on order(1 "Instock, EU" 2 "Instock, Non-EU" 3 "Outstock, EU" 4 "Outstock, Non-EU")) ///
	msymbol(Oh O Th T)  mcolor(dknavy dknavy emerald emerald) lcolor(dknavy dknavy emerald emerald) ///
	title("BIT Year of Entry Into Force and Stock") xtitle("Year") ///
	ytitle("Outstock and Instock" "(Millions {c $|}USD)")
	graph export "${outputdir}/figures/bin_year_total_in_out.pdf",replace
	
log close
