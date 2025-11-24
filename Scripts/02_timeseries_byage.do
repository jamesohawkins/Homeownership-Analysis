////////////////////////////////////////////////////////////////////////////////
// Do File: 02_analysis.do.do
// Primary Author: James Hawkins, JOHCharts.substack.com
// Date: 11/14/2025
// Stata Version: 19
// Description: This code estimates homeownership rates in each year of the CPS
// ASEC for each adult (binned) age group. It then creates a visualization of my 
// preferred homeownership measure (ownp1).
// 
// The script is separated into the following sections:
// 		1. Homeownership rate over time, disaggregated by age group
////////////////////////////////////////////////////////////////////////////////


// =============================================================================
// 1. Homeownership rate over time, disaggregated by age group
// =============================================================================
cd "$directory\derived-data"
use ipumscps_wrangled.dta, clear


// A. Estimate household and person homeownership rates
// -----------------------------------------------------------------------------
** household
preserve
collapse (mean) ownhh [pw = asecwth], by(year agegroup)
tempfile household
save `household'.dta, replace
restore
** person
collapse (mean) ownp1 [pw = asecwt], by(year agegroup)
** merge on household estimates to person estimates
merge 1:1 year agegroup using `household'.dta, nogen


// B. Visualization: U.S. homeownership rates over time, by age
// -----------------------------------------------------------------------------
** graph notes
linewrap, maxlength(140) name("notes") stack longstring("This chart measures homeownership at the individual level for all civilian noninstitutional adults in the 1976-2025 samples of the CPS ASEC. The homeownership status for the household reference person is simply the household homeownership status. All other persons in the household have their homeownership status imputed based on their relationship to that reference person (e.g., the spouse of a reference person is considered an owner if the house is designated as owned in the data).")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
** graph
twoway ///
(line ownp1 year if agegroup == 1, lcolor("67 183 232") lpattern(solid)) ///
(line ownp1 year if agegroup == 2, lcolor("123 120 252") lpattern(solid)) ///
(line ownp1 year if agegroup == 3, lcolor("40 181 77") lpattern(solid)) ///
(line ownp1 year if agegroup == 4, lcolor("230 55 46") lpattern(solid)) ///
(line ownp1 year if agegroup == 5, lcolor("232 189 60") lpattern(solid)) ///
(line ownp1 year if agegroup == 6, lcolor("227 148 30") lpattern(solid)) ///
if year >= 1976 ///
, ///
by(agegroup, rows(1) imargin(small)) ///
by(, title("{fontface Roboto Bold:The Eroding American Dream?}", color(white) size(6.5) pos(11) justification(left))) ///
by(, subtitle("{fontface Roboto Bold:Percentage of individuals who own the home they live in (1976-2025), by age group}", color(gs11) size(3.5) pos(11) justification(left))) ///
subtitle(,  color(white) size(small) lcolor("38 53 84") fcolor("38 53 84")) ///
xtitle("", size(small) color(gs6)) ///
xscale(lstyle(none)) ///
xlabel(1976 2000 2025, angle(45) labcolor(gs14) labsize(2.5) glcolor(gs9%0) tlength(1.25) tlcolor(gs6%30)) xmtick(1980(5)2020, tlength(.75) tlcolor(gs9%30)) ///
ytitle("") ///
yscale(lstyle(none)) ///
ylabel(0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%" .6 "60%" .7 "70%" .8 "80%", angle(0) labcolor(gs14) labsize(3.75) gmax gmin glpattern(solid) glcolor(gs9%40) glwidth(vthin) tlength(0) tlcolor(gs9%15)) ///
legend(off) ///
by(, legend(off)) ///
by(, note("Source: {fontface Lato:Author's analysis of IPUMS-CPS.} Sample: {fontface Lato:U.S. noninstitutional civilians age 18 or older.}" `notes', margin(l+1.5) color(gs7) span size(vsmall) position(7))) ///
by(, caption("@johcharts on Substack", margin(l+1 t-1) color(gs7%50) span size(vsmall) position(7))) ///
by(, graphregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none))) ///
plotregion(fcolor("17 24 39") lcolor("17 24 39")) ///
by(, plotregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none))) ///
by(, graphregion(margin(r+1)))
cd "$directory/output"
graph export own_timeseries_byagegroup.png, replace height(2500) width(4000)


// =============================================================================
// 1. Homeownership rate over time, disaggregated by age group
// =============================================================================

// A. Estimate household and person homeownership rates and person marriage rates (CPS: 1976-2025)
// -----------------------------------------------------------------------------
cd "$directory\derived-data"
use ipumscps_wrangled.dta, clear

// Ownership rates
** household
preserve
collapse (mean) ownhh_cps = ownhh [pw = asecwth], by(year agegroup)
tempfile household
save `household'.dta, replace
restore
** person
preserve
collapse (mean) ownp1_cps = ownp1 [pw = asecwt], by(year agegroup)
** merge on household estimates to person estimates
merge 1:1 year agegroup using `household'.dta, nogen
tempfile ownership
save `ownership'.dta, replace
restore

// Marriage rates
** person
collapse (mean) cmarried_cps = cmarried [pw = asecwt], by(year agegroup)

// Merge on ownership rates to marriage rates
merge 1:1 year agegroup using `ownership'.dta, nogen

// Save cps rates
tempfile cpsrates
save `cpsrates'.dta, replace


// B. Estimate household and person homeownership rates (USA: 1976-2025)
// -----------------------------------------------------------------------------
cd "$directory\derived-data"
use ipumsusa_wrangled.dta, clear

// Ownership rates
** household
preserve
collapse (mean) ownhh_usa = ownhh [pw = hhwt], by(year agegroup)
tempfile household
save `household'.dta, replace
restore
** person
preserve
collapse (mean) ownp1_usa = ownp1 [pw = perwt], by(year agegroup)
** merge on household estimates to person estimates
merge 1:1 year agegroup using `household'.dta, nogen
tempfile ownership
save `ownership'.dta, replace
restore

// Marriage rates
** person
collapse (mean) cmarried_usa = cmarried [pw = perwt], by(year agegroup)

// Merge on ownership rates to marriage rates
merge 1:1 year agegroup using `ownership'.dta, nogen


// C. Merge cps/usa estimates
// -----------------------------------------------------------------------------
** merge on CPS rates
merge 1:1 year agegroup using `cpsrates'.dta, nogen
sort year agegroup


// D. Visualization: U.S. homeownership rates over time, by age
// -----------------------------------------------------------------------------
** graph notes
linewrap, maxlength(140) name("notes") stack longstring("This chart measures homeownership at the individual level for all civilian noninstitutional adults in the 1976-2025 samples of the CPS ASEC. The homeownership status for the household reference person is simply the household homeownership status. All other persons in the household have their homeownership status imputed based on their relationship to that reference person (e.g., the spouse of a reference person is considered an owner if the house is designated as owned in the data).")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
** graph
twoway ///
(connected ownp1_usa year if year != 1950, lcolor("123 120 252%50") lpattern(dash) msymbol(circle) msize(vsmall) mcolor("123 120 252%30")) ///
(connected cmarried_usa year, lcolor("232 189 60%50") lpattern(dash) msymbol(circle) msize(vsmall) mcolor("232 189 60%30")) ///
(line ownp1_cps year, lcolor("67 183 232") lpattern(solid) lwidth(medthick)) ///
(line cmarried_cps year, lcolor("230 55 46") lpattern(solid) lwidth(medthick)) ///
, ///
xline(1960, lcolor(gray%50) lpattern(solid) lwidth(thin)) ///
xline(1980, lcolor(gray%50) lpattern(solid) lwidth(thin)) ///
by(agegroup, rows(1) imargin(small)) ///
by(, title("{fontface Roboto Bold:Marriage Rates Fell (1960-80) While Ownership Rose}", color(white) size(6.5) pos(11) justification(left))) ///
by(, subtitle("{fontface Roboto Bold:Percentage of individuals who own the home they live in (1976-2025), by age group}", color(gs11) size(3.5) pos(11) justification(left))) ///
subtitle(,  color(white) size(small) lcolor("38 53 84") fcolor("38 53 84")) ///
xtitle("", size(small) color(gs6)) ///
xscale(lstyle(none)) ///
xlabel(1940 1960 1980 2000 2025, angle(45) labcolor(gs14) labsize(2.5) glcolor(gs9%0) tlength(1.25) tlcolor(gs9%30)) xmtick(1970 1976(1)1979 1981(1)2024, tlength(.75) tlcolor(gs9%30)) ///
ytitle("") ///
yscale(lstyle(none)) ///
ylabel(0 "0%" .2 "20%" .4 "40%" .6 "60%" .8 "80%", angle(0) labcolor(gs14) labsize(3.75) gmax gmin glpattern(solid) glcolor(gs9%40) glwidth(vthin) tlength(0) tlcolor(gs9%15)) ///
legend(off) ///
by(, legend(off)) ///
by(, note("Source: {fontface Lato:Author's analysis of IPUMS-CPS.} Sample: {fontface Lato:U.S. noninstitutional civilians age 18 or older.}" `notes', margin(l+1.5) color(gs7) span size(vsmall) position(7))) ///
by(, caption("@johcharts on Substack", margin(l+1 t-1) color(gs7%50) span size(vsmall) position(7))) ///
by(, graphregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none))) ///
plotregion(fcolor("17 24 39") lcolor("17 24 39")) ///
by(, plotregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none))) ///
by(, graphregion(margin(r+1)))

// JH: note that data not available for 1950


if year >= 1976 ///














