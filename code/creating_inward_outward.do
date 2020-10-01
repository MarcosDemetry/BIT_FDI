clear all

cd "${datadir}/outward_inward/"

** Outward Panel

import excel using "Outward and Inward FDI stock current USD with panel", sheet("outward_panel") clear

* Renaming variables
foreach j in `c(ALPHA)' {

ds
local a = r(varlist)

	foreach j of local a {
	
		local heading = strtoname(`j'[1])
		
		rename `j' `heading'
	
	}
}

rename _all, lower

drop if _n == 1

destring outward_stock, replace

save outward_panel, replace


** Inward Panel

import excel using "Outward and Inward FDI stock current USD with panel", sheet("inward_panel") clear

* Renaming variables
foreach j in `c(ALPHA)' {

ds
local a = r(varlist)

	foreach j of local a {
	
		local heading = strtoname(`j'[1])
		
		rename `j' `heading'
	
	}
}

rename _all, lower

drop if _n == 1

destring inward_stock, replace

save inward_panel, replace


** Merging panels

merge 1:1 country year using outward_panel, nogen

save outward_inward_panel, replace
