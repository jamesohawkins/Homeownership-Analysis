////////////////////////////////////////////////////////////////////////////////
// Do File: 02_millennials-vs-genx.do
// Primary Author: James Hawkins, JOHCharts.substack.com
// Date: 11/23/2025
// Stata Version: 19
// Description: This code replicates my analysis from my Substack article "No, 
// Millennial Homeownership has Not Caught up with Gen X", which primarily 
// compares homeownership rates between Gen X and Millennials using an 
// individual measure of homeownership in the CPS (ownp3).
// 
// The script is separated into the following sections:
// 		1. Comparing Intergenerational Homeownership Rates, Replication
//		2. Comparing Intergenerational Homeownership Rates (Updated with 2025 Data)
//		3. Comparing All Millennials vs 1981 Millennial Cohort
//		4. Comparing Each Millennial Cohort Against Each Gen X Cohort
////////////////////////////////////////////////////////////////////////////////


/// ============================================================================
//# 1. Replication of EIG: Comparing Intergenerational Homeownership Rates
/// ============================================================================
/*  In this section, I replicate the intergenerational analysis of homeownership 
    rates from the Economic Innovation Group. 
    See: https://github.com/bnglasner/housing-ownership-generation/tree/main. */
cd "$directory\derived-data"
use ipumscps_raw.dta, clear

// Define generation cohort
gen birth = year - age
gen generation = .
replace generation = 0 if birth <= 1927
replace generation = 1 if inrange(birth, 1928, 1945)
replace generation = 2 if inrange(birth, 1946, 1964)
replace generation = 3 if inrange(birth, 1965, 1980)
replace generation = 4 if inrange(birth, 1981, 1996)
replace generation = 5 if inrange(birth, 1997, 2012)
lab var generation "Generation (Defined by Pew Research Center)"
lab def generation_lbl ///
	1 "Silent" ///
	2 "Boomers" ///
	3 "Gen X" ///
	4 "Millennials" ///
	5 "Gen Z"
lab val generation generation_lbl

// Limit to 2024 or earlier
keep if year >= 1976 & year <= 2024

// Limit to 19 or older and 65 or younger
keep if age >= 19 & age <= 65

// Define homeownership measure
gen ownp_rep = .
replace ownp_rep = 1 if ownershp == 10 & inlist(relate, 101, 201, 202, 203)
replace ownp_rep = 0 if inlist(ownershp, 21, 22) & inlist(relate, 101, 201, 202, 203)
replace ownp_rep = 0 if inlist(relate, 301, 303, 501, 701, 901, 1001, 1113, 1114, 1115, 1116, 1117, 1241, 1242, 1260)
** check for missing values
assert !missing(ownp_rep)

// Estimate person measure homeownership rates, by generation and age
collapse (mean) ownp_rep [pw = asecwth], by(generation age)

//## 1a. Visualization: Replication
** graph notes
linewrap, maxlength(115) name("notes") stack longstring("This chart replicates homeownership analysis by the Economic Innovation Group. The individual measure of homeownership assumes that both the household reference person and their spouse are homeowners if they reside in a home that is recorded as owned by its residents. All other persons in an owner-occupied household or non-owner-occupied household are assumed to not be homeowners. Generations are based on the Pew Research Center definition: Greatest Generation (pre-1928), Silent (1928-1945), Baby Boomers (1946-1964), Gen X (1965-1980), Millennials (1981-1996), and Gen Z (1997-2012).")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
** graph
twoway ///
(connected ownp_rep age if generation == 0, lcolor("#B654E3") lpattern(solid) msize(1) msymbol(triangle) mfcolor("#B654E3") mlcolor("17 24 39") mlwidth(thin)) ///
(connected ownp_rep age if generation == 1, lcolor("#43B7E8") lpattern(solid) msize(1) msymbol(triangle) mfcolor("67 183 232") mlcolor("17 24 39") mlwidth(thin)) ///
(connected ownp_rep age if generation == 2, lcolor("#3EC238") lpattern(solid) msize(1) msymbol(square) mfcolor("#3EC238") mlcolor("17 24 39") mlwidth(thin)) ///
(connected ownp_rep age if generation == 3, lcolor("#E6372E") lpattern(solid) msize(1) msymbol(diamond) mfcolor("#E6372E") mlcolor("17 24 39") mlwidth(thin)) ///
(connected ownp_rep age if generation == 4, lcolor("#368CF5") lpattern(solid) msize(1) msymbol(circle) mfcolor("#368CF5") mlcolor("17 24 39") mlwidth(thin)) ///
(connected ownp_rep age if generation == 5, lcolor("#E6D74D") lpattern(solid) msize(1) msymbol(triangle) mfcolor("#E6D74D") mlcolor("17 24 39") mlwidth(thin)) ///
, ///
title("{fontface Roboto Bold:Have Millennials Caught Up?}", color(white) size(6.5) pos(11) justification(left)) ///
subtitle("{fontface Roboto Bold:Percentage of individuals who own the home they live in, by age}", color(gs11) size(3.5) pos(11) justification(left)) ///
xtitle("Age", size(3.5) color(gs14) margin(b-1 t-1)) xscale(lstyle(none)) ///
xlabel(19 "19" 25 "25" 30 "30" 35 "35" 40 "40" 45 "45" 50 "50" 55 "55" 60 "60" 65 "65", labcolor(gs8) labsize(3.5) glcolor(gs9%0) tlength(1.25) tlcolor(gs9%30)) xmtick(20 21(1)24 26(1)29 31(1)34 36(1)39 41(1)44 46(1)49 51(1)54 56(1)59 61(1)64, tlength(.75) tlcolor(gs9%30)) ///
ytitle("") ///
yscale(lstyle(none)) ///
ylabel(0 "0%" .10 "10%" .20 "20%" .30 "30%" .40 "40%" .50 "50%" .60 "60%" .70 "70%" .80 "80%", angle(0) labcolor(gs14) labsize(3.75) gmax gmin glpattern(solid) glcolor(gs9%20) glwidth(vthin) tlength(0) tlcolor(gs9%15)) ///
legend(order(1 "Greatest Generation" 2 "Silent Generation" 3 "Baby Boomers" 4 "Gen X" 5 "Millennials" 6 "Gen Z") ring(0) pos(4) color(gs11) size(4) region(fcolor("17 24 39%0"))) ///
note("Source: {fontface Lato:Author's analysis of IPUMS-CPS (1976-2024).} Sample: {fontface Lato:U.S. adult civilians.}" `notes', margin(l+1.5) color(gs11) span size(vsmall) position(7)) ///
caption("@johcharts on Substack", margin(l+1 t-1) color(white) span size(vsmall) position(7)) ///
graphregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none)) ///
plotregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none)) ///
graphregion(margin(r+5))
cd "$directory/output/millennial-vs-genx"
graph export "ownp_generations_replication.png", replace width(3000) height(2000)


/// ============================================================================
//# 2. Comparing Intergenerational Homeownership Rates (Updated with 2025 Data)
/// ============================================================================
/*  In this section, I update the preceding analysis with data that includes the 
    2025 ASEC, excludes group quarters (includes only households, which is a 
    small fraction of the sample), visualizes home-ownership for 18-year-olds as 
    well as those older than 65, and uses the person weight (asecwt) instead of 
    the household weight (asecwth). I include only Gen X and Millennials in this 
    version. */
cd "$directory\derived-data"
use ipumscps_wrangled.dta, clear

// Restrict sample to 2025 or earlier
keep if year <= 2025

// Estimate person measure homeownership rates, by generation and age
collapse (mean) ownp3 [pw = asecwt], by(generation age)

//## 2a. Visualization: Version 2
** graph notes
linewrap, maxlength(120) name("notes") stack longstring("The individual measure of homeownership assumes that both the household reference person and their spouse are homeowners if they reside in a home that is recorded as owned by its residents. All other persons in an owner-occupied household or non-owner-occupied household are assumed to not be homeowners. Generations are based on the Pew Research Center definition: Gen X (1965-1980) and Millennials (1981-1996).")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
** graph
twoway ///
(connected ownp3 age if generation == 3, lcolor("#E6372E") lpattern(solid) msize(1) msymbol(diamond) mfcolor("#E6372E") mlcolor("17 24 39") mlwidth(thin)) ///
(connected ownp3 age if generation == 4, lcolor("#368CF5") lpattern(solid) msize(1) msymbol(circle) mfcolor("#368CF5") mlcolor("17 24 39") mlwidth(thin)) ///
, ///
title("{fontface Roboto Bold:Have Millennials Caught Up? (With 2025 Data)}", color(white) size(6.5) pos(11) justification(left)) ///
subtitle("{fontface Roboto Bold:Percentage of individuals who own the home they live in, by age}", color(gs11) size(3.5) pos(11) justification(left)) ///
xtitle("Age", size(3.5) color(gs14) margin(b-1 t-1)) xscale(lstyle(none)) ///
xlabel(18 "18" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80+", labcolor(gs8) labsize(3.5) glcolor(gs9%0) tlength(1.25) tlcolor(gs9%30)) xmtick(19 20 21(1)29 31(1)39 41(1)49 51(1)59 61(1)69 71(1)79, tlength(.75) tlcolor(gs9%30)) ///
ytitle("") ///
yscale(lstyle(none)) ///
ylabel(0 "0%" .10 "10%" .20 "20%" .30 "30%" .40 "40%" .50 "50%" .60 "60%" .70 "70%" .80 "80%", angle(0) labcolor(gs14) labsize(3.75) gmax gmin glpattern(solid) glcolor(gs9%20) glwidth(vthin) tlength(0) tlcolor(gs9%15)) ///
legend(order(1 "Gen X" 2 "Millennials") ring(0) rows(1) pos(11) color(gs11) size(4) region(fcolor("17 24 39%0"))) ///
note("Source: {fontface Lato:Author's analysis of IPUMS-CPS.} Sample: {fontface Lato:U.S. adult civilians (excludes group quarters).}" `notes', margin(l+1.5) color(gs11) span size(vsmall) position(7)) ///
caption("@johcharts on Substack", margin(l+1 t-1) color(white) span size(vsmall) position(7)) ///
graphregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none)) ///
plotregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none)) ///
graphregion(margin(r+10))
cd "$directory/output/millennial-vs-genx"
graph export "ownp_generations_version2.png", replace width(3000) height(2000)


/// ============================================================================
//# 3. Comparing All Millennials vs 1981 Millennial Cohort
/// ============================================================================
/*  In this section, I compare homeownership estimates for the 1981 Millennial 
    cohort to homeownership estimates for all Millennial cohorts. */
cd "$directory\derived-data"
use ipumscps_wrangled.dta, clear

// Limit sample to Millennials
keep if generation == 4

// Calculate homeownership among each Millennial birth cohort
preserve
	collapse (mean) ownp3 [pw = asecwt], by(birth age)
	rename ownp3 ownp3_
	reshape wide ownp3_, i(age) j(birth)
	tempfile allcohorts
	save `allcohorts'.dta, replace
restore

// Estimate person measure homeownership rates among all Millennials
collapse (mean) ownp3 [pw = asecwt], by(age)

// Merge estimates
merge 1:1 age using `allcohorts'.dta, nogen

gen ylo = 0
gen yhi = .8

//## 3a. Visualization: 1981 Millennials vs all Millennials
** graph notes
linewrap, maxlength(120) name("notes") stack longstring("The individual measure of homeownership assumes that both the household reference person and their spouse are homeowners if they reside in a home that is recorded as owned by its residents. All other persons in an owner-occupied household or non-owner-occupied household are assumed to not be homeowners. Generations are based on the Pew Research Center definition: Millennials (1981-1996).")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
** graph
twoway (line ownp3 ownp3_1981 age, lcolor("#368CF5" white) lpattern(solid shortdash)) ///
(scatter ownp3_1981 age if age == 44, msize(2) msymbol(circle) mfcolor(white) mlcolor("17 24 39") mlwidth(thin)) ///
(rarea ylo yhi age if inrange(age, 18, 29), fcolor(gs3%35) lcolor("17 24 39%0")) ///
, ///
xline(44, lcolor(gray%35) lpattern(solid)) ///
xline(43, lcolor(gray%35) lpattern(solid)) ///
title("{fontface Roboto Bold:1981 Millennials vs All Millennials}", color(white) size(6.5) pos(11) justification(left)) ///
subtitle("{fontface Roboto Bold:Percentage of individuals who own the home they live in, by age}", color(gs11) size(3.5) pos(11) justification(left)) ///
xtitle("Age", size(3.5) color(gs14) margin(b-1 t-1)) xscale(lstyle(none)) ///
xlabel(18 "18" 20 "20" 25 "25" 30 "30" 35 "35" 40 "40", labcolor(gs8) labsize(3.5) glcolor(gs9%0) tlength(1.25) tlcolor(gs9%30)) xmtick(19 21(1)24 26(1)29 31(1)34 36(1)39 41(1)44, tlength(.75) tlcolor(gs9%30)) ///
ytitle("") ///
yscale(lstyle(none)) ///
ylabel(0 "0%" .10 "10%" .20 "20%" .30 "30%" .40 "40%" .50 "50%" .60 "60%" .70 "70%" .80 "80%", angle(0) labcolor(gs14) labsize(3.75) gmax gmin glpattern(solid) glcolor(gs9%20) glwidth(vthin) tlength(0) tlcolor(gs9%15)) ///
legend(order(1 "Millennials" 2 "1981 Millennials") ring(0) rows(2) pos(5) color(gs11) size(4) region(fcolor("17 24 39%0"))) ///
note("Source: {fontface Lato:Author's analysis of IPUMS-CPS.} Sample: {fontface Lato:U.S. adult civilians (excludes group quarters).}" `notes', margin(l+1.5) color(gs11) span size(vsmall) position(7)) ///
caption("@johcharts on Substack", margin(l+1 t-1) color(white) span size(vsmall) position(7)) ///
text(.4 44 "44 years old", orientation(vertical) color(gray) size(small) placement(w)) ///
text(.4 43 "43 years old", orientation(vertical) color(gray) size(small) placement(w)) ///
text(.547 28.9 "All Millennials have" "turned at least 29" "years old by 2025", justification(right) orientation(horizontal) color(gray) size(small) placement(w)) ///
text(.75 43.9 "Only one cohort (1981) of" "Millennials have reached 44 years old", justification(right) orientation(horizontal) color(gray) box fcolor("17 24 39") lcolor("17 24 39%0") lwidth(thick) margin(vsmall) size(small) placement(w)) ///
text(.65 42.9 "Two cohorts (1981 and 1982) of" "Millennials have reached 43 years old", justification(right) orientation(horizontal) color(gray) size(small) placement(w)) ///
graphregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none)) ///
plotregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none)) ///
graphregion(margin(r+5))
cd "$directory/output/millennial-vs-genx"
graph export "ownp_millennial_cohorts-1981.png", replace width(3000) height(2000)


/// ============================================================================
//# 4. Comparing Each Millennial Cohort Against Each Gen X Cohort
/// ============================================================================
/*  In this section I chart the differences between individual Millennial and 
    Gen X cohorts, by age. This pairs the oldest Millennial cohort with the 
	oldest Gen X cohort, the second oldest Millennials with the second oldest 
	Gen Xers, etc. (such that there is a 16 year difference between each pair). 
	*/
cd "$directory\derived-data"
use ipumscps_wrangled.dta, clear

// Restrict sample to Gen X and Millennials
keep if inlist(generation, 3, 4)

// Estimate person measure homeownerships rate, by birth cohort and age
collapse (mean) ownp3 [pw = asecwt], by(age birth generation)
** create cohort comparison groups (Gen X vs Millennials)
gen cohort_comparison = .
local y = 1965
local z = 1981
forvalues x = 1/16 {
	replace cohort_comparison = `x' if inlist(birth, `y', `z')
	local y = `y' + 1
	local z = `z' + 1
}
** label cohorts in comparison groups
lab var cohort_comparison "Comparison group for Millennials vs Gen X"
lab def cohort_comparison_lbl ///
	1 "1965 vs 1981" ///
	2 "1966 vs 1982" ///
	3 "1967 vs 1983" ///
	4 "1968 vs 1984" ///
	5 "1969 vs 1985" ///
	6 "1970 vs 1986" ///
	7 "1971 vs 1987" ///
	8 "1972 vs 1988" ///
	9 "1973 vs 1989" ///
	10 "1974 vs 1990" ///
	11 "1975 vs 1991" ///
	12 "1976 vs 1992" ///
	13 "1977 vs 1993" ///
	14 "1978 vs 1994" ///
	15 "1979 vs 1995" ///
	16 "1980 vs 1996"
lab val cohort_comparison cohort_comparison_lbl

// Reshape data
drop birth
rename ownp3 ownp3_
** reshape data
reshape wide ownp3_, i(age cohort_comparison) j(generation)

** Estimate Millennial-Gen X difference
gen ownp3_diff = ownp3_4 - ownp3_3

//## 4a. Visualization: Comparing Each Millennial/Gen X Cohort (Sixteen Year Gaps)
** graph notes
linewrap, maxlength(120) name("notes") stack longstring("The individual measure of homeownership assumes that both the household reference person and their spouse are homeowners if they reside in a home that is recorded as owned by its residents. All other persons in an owner-occupied household or non-owner-occupied household are assumed to not be homeowners. Generations are based on the Pew Research Center definition: Gen X (1965-1980) and Millennials (1981-1996).")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
** graph
twoway (line ownp3_3 ownp3_4 age, lcolor("#368CF5" "#E6372E") lwidth(thick thick) lpattern(solid solid)) ///
, ///
by(cohort_comparison, rows(2)) ///
by(, title("{fontface Roboto Bold:Gen X Homeownership Higher}", color(white) size(6.5) pos(11) justification(left))) ///
by(, subtitle("{fontface Roboto Bold:Percentage of individuals who own the home they live, by age (Gen X vs Millennial Cohorts)}", color(gs11) size(3.5) pos(11) justification(left))) ///
subtitle(,  color(white) size(small) lcolor("38 53 84") fcolor("38 53 84")) ///
xtitle("Age", size(small) color(white) margin(t-2)) ///
xscale(lstyle(none)) ///
xlabel(, angle(45) labcolor(gs14) labsize(2.5) glcolor(gs9%0) tlength(1.25) tlcolor(gs9%30)) ///
ytitle("") ///
yscale(lstyle(none)) ///
ylabel(0 "0%" .2 "20%" .4 "40%" .6 "60%" .8 "80%", angle(0) labcolor(gs14) labsize(3.75) gmax gmin glpattern(solid) glcolor(gs9%40) glwidth(vthin) tlength(0) tlcolor(gs9%15)) ///
legend(order(1 "Gen X Cohorts" 2 "Millennial Cohorts") pos(12) rows(1) color(white) region(fcolor("17 24 39") lcolor("17 24 39"))) ///
by(, legend(order(1 "Gen X Cohorts" 2 "Millennial Cohorts") pos(12) rows(1))) ///
by(, note("Source: {fontface Lato:Author's analysis of IPUMS-CPS.} Sample: {fontface Lato:U.S. adult civilians (excludes group quarters).}" `notes', margin(l+1.5) color(gs7) span size(vsmall) position(7))) ///
by(, caption("@johcharts on Substack", margin(l+1 t-1) color(white) span size(vsmall) position(7))) ///
by(, graphregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none))) ///
plotregion(fcolor("17 24 39") lcolor("17 24 39")) ///
by(, plotregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none))) ///
by(, graphregion(margin(r+1)))
cd "$directory/output/millennial-vs-genx"
graph export "ownp3_genx-millennial-cohorts.png", replace width(3000) height(2000)

//## 4b. Visualization: Difference Between Individual Gen X and Millennial Cohorts
** graph notes
linewrap, maxlength(120) name("notes") stack longstring("The individual measure of homeownership assumes that both the household reference person and their spouse are homeowners if they reside in a home that is recorded as owned by its residents. All other persons in an owner-occupied household or non-owner-occupied household are assumed to not be homeowners. Generations are based on the Pew Research Center definition: Gen X (1965-1980) and Millennials (1981-1996).")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
** graph
twoway (bar ownp3_diff age if age <= 44, barwidth(.80) fcolor("123 120 252") lwidth(none)) ///
, ///
by(cohort_comparison, rows(2)) ///
by(, title("{fontface Roboto Bold:Difference between Millennial and Gen X Cohorts}", color(white) size(6.5) pos(11) justification(left))) ///
by(, subtitle("{fontface Roboto Bold:Percentage point (ppt) difference in homeownership rates (Millennials minus Gen X), by age}", color(gs11) size(3.5) pos(11) justification(left))) ///
subtitle(,  color(white) size(small) lcolor("38 53 84") fcolor("38 53 84")) ///
xtitle("Age", size(small) color(white) margin(b-1 t-3)) ///
xscale(lstyle(none)) ///
xlabel(20 30 40, angle(45) labcolor(gs14) labsize(2.5) glcolor(gs9%0) tlength(1.25) tlcolor(gs9%30)) xmtick(18(1)19 21(1)29 31(1)39 40(1)44, tlength(.75) tlcolor(gs9%30)) ///
ytitle("") ///
yscale(lstyle(none)) ///
ylabel(.05 "+5" 0 "0" -.05 "-5" -.10 "-10" -.15 "-15", angle(0) labcolor(gs14) labsize(3.75) gmax gmin glpattern(solid) glcolor(gs9%40) glwidth(vthin) tlength(0) tlcolor(gs9%15)) ///
legend(order(1 "Gen X Cohorts" 2 "Millennial Cohorts") pos(12) rows(1) color(white) region(fcolor("17 24 39") lcolor("17 24 39"))) ///
by(, legend(order(1 "Gen X Cohorts" 2 "Millennial Cohorts") pos(12) rows(1))) ///
by(, note("Source: {fontface Lato:Author's analysis of IPUMS-CPS.} Sample: {fontface Lato:U.S. adult civilians (excludes group quarters).}" `notes', margin(l+1.5) color(gs7) span size(vsmall) position(7))) ///
by(, caption("@johcharts on Substack", margin(l+1 t-1) color(white) span size(vsmall) position(7))) ///
by(, graphregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none))) ///
plotregion(fcolor("17 24 39") lcolor("17 24 39")) ///
by(, plotregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none))) ///
by(, graphregion(margin(r+1)))
cd "$directory/output/millennial-vs-genx"
graph export "ownp3_genx-millennial-cohorts-diff.png", replace width(3000) height(2000)


/// ============================================================================
//# 5. Alternative methodology
/// ============================================================================
/*  In this section I construct an updated methodology for measuring 
    homeownesrhip trends across generations. */
	
// A. Homeownership across time
// -----------------------------------------------------------------------------
cd "$directory\derived-data"
use ipumscps_wrangled.dta, clear

// Limit analysis to Baby Boomers, Gen X, Millennials, and Gen Z
keep if inlist(generation, 2, 3, 4, 5)

// Estimate person measure homeownership rates, by generation and age
collapse (mean) ownp3 [pw = asecwt], by(generation year)

//## 5a. Visualization: Homeownership rates over time
** graph notes
linewrap, maxlength(120) name("notes") stack longstring("The individual measure of homeownership assumes that both the household reference person and their spouse are homeowners if they reside in a home that is recorded as owned by its residents. All other persons in an owner-occupied household or non-owner-occupied household are assumed to not be homeowners. Generations based on the Pew Research Center definition: Silent (1928-1945), Baby Boomers (1946-1964), Gen X (1965-1980), Millennials (1981-1996), and Gen Z (1997-2012).")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
** graph
twoway ///
(connected ownp3 year if generation == 2, lcolor("#3EC238") lpattern(solid) msize(1) msymbol(square) mfcolor("#3EC238") mlcolor("17 24 39") mlwidth(thin)) ///
(connected ownp3 year if generation == 3, lcolor("#E6372E") lpattern(solid) msize(1) msymbol(diamond) mfcolor("#E6372E") mlcolor("17 24 39") mlwidth(thin)) ///
(connected ownp3 year if generation == 4, lcolor("#368CF5") lpattern(solid) msize(1) msymbol(circle) mfcolor("#368CF5") mlcolor("17 24 39") mlwidth(thin)) ///
(connected ownp3 year if generation == 5, lcolor("#E6D74D") lpattern(solid) msize(1) msymbol(triangle) mfcolor("#E6D74D") mlcolor("17 24 39") mlwidth(thin)) ///
, ///
title("{fontface Roboto Bold:Have Millennials Caught Up?}", color(white) size(6.5) pos(11) justification(left)) ///
subtitle("{fontface Roboto Bold:Percentage of individuals who own the home they live in, by age}", color(gs11) size(3.5) pos(11) justification(left)) ///
xtitle("Year", size(3.5) color(gs14) margin(b-1)) xscale(lstyle(none)) ///
xlabel(1980 1990 2000 2010 2020, labcolor(gs8) labsize(3.5) glcolor(gs9%0) tlength(1.25) tlcolor(gs9%30)) xmtick(1976(1)1979 1981(1)1989 1991(1)1999 2001(1)2009 2011(1)2019 2021(1)2025, tlength(.75) tlcolor(gs9%30)) ///
ytitle("") ///
yscale(lstyle(none)) ///
ylabel(0 "0%" .10 "10%" .20 "20%" .30 "30%" .40 "40%" .50 "50%" .60 "60%" .70 "70%" .80 "80%", angle(0) labcolor(gs14) labsize(3.75) gmax gmin glpattern(solid) glcolor(gs9%20) glwidth(vthin) tlength(0) tlcolor(gs9%15)) ///
legend(order(1 "Baby Boomers" 2 "Gen X" 3 "Millennials" 4 "Gen Z") ring(1) rows(1) pos(12) size(small) color(gs11) region(fcolor("17 24 39") lcolor("17 24 39") margin(t-1))) ///
note("Source: {fontface Lato:Author's analysis of IPUMS-CPS (1976-2025).} Sample: {fontface Lato:U.S. adult civilians (excludes group quarters).}" `notes', margin(l+1.5) color(gs11) span size(vsmall) position(7)) ///
caption("@johcharts on Substack", margin(l+1 t-1) color(white) span size(vsmall) position(7)) ///
graphregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none)) ///
plotregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none)) ///
graphregion(margin(r+5))
cd "$directory/output/millennial-vs-genx"
graph export "ownp3_generations-over-time.png", replace width(3000) height(2000)


// B. Alternative method
// -----------------------------------------------------------------------------
/* NOTE: I exclude the Silent Generation from this analysis for consistency of 
   the homeownership trends I am visualizing. Specifically, since I exclude the
   three oldest Baby Boomer cohorts in order to adjust the size of that 
   generation to be consistent with Gen X, Millennials, and Gen Z, this leaves
   a gap between the Silent Generation and Baby Boomers. Of course, the home-
   ownership trends for the Silent Generation could be visualized with this 
   framework, but the visualization would no longer be showing generations in 
   consistent sixteen year increments, as I have done below. */
cd "$directory\derived-data"
use ipumscps_wrangled.dta, clear

// Limit analysis to Baby Boomers, Gen X, Millennials, and Gen Z
keep if inlist(generation, 2, 3, 4, 5)

// Recode Baby Boomer generation definition
replace generation = . if generation == 2
replace generation = 2 if inrange(birth, 1949, 1964)

// Calculate midpoint age in each year for each generation
/* NOTE: In this section I change the bottom of the generational range for Baby
   Boomers from 1946 to 1949 so that they have the same number of birth cohorts
   (sixteen in total) as the other generations. */
** define empty vars corresponding to beginning year and end year of generational ranges
gen range1 = .
gen range2 = .
** define range for baby boomers
replace range1 = 1949 if generation == 2 // adjusted from 1946 to 1949 (see NOTE)
replace range2 = 1964 if generation == 2
** define range for gen x
replace range1 = 1965 if generation == 3
replace range2 = 1980 if generation == 3
** define range for millennials
replace range1 = 1981 if generation == 4
replace range2 = 1996 if generation == 4
** define range for gen z
replace range1 = 1997 if generation == 5
replace range2 = 2012 if generation == 5
** calculate midpoint age
gen midpoint = year - (range1 + ((range2 - range1) / 2))

// Estimate person measure homeownership rates, by generation and age
collapse (mean) ownp3 ownp1 (max) agemax = age (min) agemin = age [pw = asecwt], by(generation midpoint)

// Round midpoint up (age label based on age of ninth cohort)
replace midpoint = midpoint + .5

//## 5b. Visualization: Homeownership estimates with alternative methodology
** graph notes
linewrap, maxlength(120) name("notes") stack longstring("The individual measure of homeownership assumes that both the household reference person and their spouse are homeowners if they reside in a home that is recorded as owned by its residents. All other persons in an owner-occupied household or non-owner-occupied household are assumed to not be homeowners. The definition of Baby Boomers is adjusted from the Pew Research definition, which is 1946-1964, to 1949-1964 so the range of birth years contains exactly sixteen birth cohorts to match the other younger generations. All other generations follow the Pew Research Center definition, including: Gen X (1965-1980), Millennials (1981-1996), and Gen Z (1997-2012).")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
** graph
twoway (connected ownp3 midpoint if generation == 5, lcolor("#E6D74D") lpattern(solid) msize(1) msymbol(triangle) mfcolor("#E6D74D") mlcolor("17 24 39") mlwidth(thin)) ///
(connected ownp3 midpoint if generation == 4, lcolor("#368CF5") lpattern(solid) msize(1) msymbol(circle) mfcolor("#368CF5") mlcolor("17 24 39") mlwidth(thin)) ///
(connected ownp3 midpoint if generation == 3, lcolor("#E6372E") lpattern(solid) msize(1) msymbol(diamond) mfcolor("#E6372E") mlcolor("17 24 39") mlwidth(thin)) ///
(connected ownp3 midpoint if generation == 2, lcolor("#3EC238") lpattern(solid) msize(1) msymbol(square) mfcolor("#3EC238") mlcolor("17 24 39") mlwidth(thin)) ///
if midpoint >= 18 ///
, ///
title("{fontface Roboto Bold:Millennial Homeownership Lags Other Gens}", color(white) size(6.5) pos(11) justification(left)) ///
subtitle("{fontface Roboto Bold:Percentage of individuals who own the home they live in, by age}", color(gs11) size(3.5) pos(11) justification(left)) ///
xtitle("Age Midpoint* (Each Generation in Each Year)", size(3.5) color(gs14)) ///
xscale(lstyle(none)) ///
xlabel(20 30 40 50 60 70, labcolor(gs14) labsize(3.5) glcolor(gs9%0) tlength(1.25) tlcolor(gs9%30)) xmtick(18 19 21(1)29 31(1)39 41(1)49 51(1)59 61(1)69, tlength(.75) tlcolor(gs9%30)) ///
ytitle("") ///
yscale(lstyle(none)) ///
ylabel(0 "0%" .10 "10%" .20 "20%" .30 "30%" .40 "40%" .50 "50%" .60 "60%" .70 "70%" .80 "80%", angle(0) labcolor(gs14) labsize(3.75) gmax gmin glpattern(solid) glcolor(gs9%20) glwidth(vthin) tlength(0) tlcolor(gs9%15)) ///
legend(order(4 "Baby Boomers" 3 "Gen X" 2 "Millennials" 1 "Gen Z") ring(0) rows(1) pos(6) size(small) color(gs11) region(fcolor("17 24 39") lcolor("17 24 39") margin(t-2))) ///
note("Source: {fontface Lato:Author's analysis of IPUMS-CPS (1976-2025).} Sample: {fontface Lato:U.S. adult civilians (excludes group quarters).}" `notes' "{fontface Lato:*Since the age midpoint for each gen in each year is a fractional number, I use the age of the 9th cohort (of 16) of each gen.}", margin(l+1.5) color(gs11) span size(vsmall) position(7)) ///
caption("@johcharts on Substack", margin(l+1 t-1) color(white) span size(vsmall) position(7)) ///
graphregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none)) ///
plotregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none)) ///
graphregion(margin(r+5))
** output
cd "$directory/output/millennial-vs-genx"
graph export "ownp3_alt-method.png", replace width(3000) height(2000)


// C. QC: Mean age within each generation
// -----------------------------------------------------------------------------
cd "$directory\derived-data"
use ipumscps_wrangled.dta, clear

// Updated range for Baby Boomers
replace generation = . if generation == 2
replace generation = 2 if inrange(birth, 1949, 1964)

// Limit analysis to Baby Boomers, Gen X, Millennials, and Gen Z
keep if inlist(generation, 2, 3, 4, 5)

// Estimate mean age, by generation and year
collapse (mean) age [pw = asecwt], by(generation year)

// Reshape so each generation's estimates has its own column
reshape wide age, i(year) j(generation)

// Shift estimates such that they align with Gen X (for the same age range within each row)
gen age2_shift = age2[_n-16]
gen age4_shift = age4[_n+16]
gen age5_shift = age5[_n+32]

// Running variable
gen order = _n + 10

// Visualize results
order age2_shift age3 age4_shift age5_shift
* twoway (line age2_shift age3 age4_shift age5_shift order)


/// ============================================================================
//# 6. Homeownership rate over time, disaggregated by age group
/// ============================================================================
cd "$directory\derived-data"
use ipumscps_wrangled.dta, clear

// Estimate person measure homeownership rates, by generation and age
** household
preserve
collapse (mean) ownhh [pw = asecwth], by(year agegroup)
tempfile household
save `household'.dta, replace
restore
** person
collapse (mean) ownp3 [pw = asecwt], by(year agegroup)
** merge on household estimates to person estimates
merge 1:1 year agegroup using `household'.dta, nogen

//## 6a. Visualization: U.S. homeownership rates over time, by age
** graph notes
linewrap, maxlength(115) name("notes") stack longstring("The individual measure of homeownership assumes that both the household reference person and their spouse are homeowners if they reside in a home that is recorded as owned by its residents. All other persons in an owner-occupied household or non-owner-occupied household are assumed to not be homeowners.")
local notes = `" "Notes: {fontface Lato:`r(notes1)'}""'
local y = r(nlines_notes)
forvalues i = 2/`y' {
	local notes = `"`notes' "{fontface Lato:`r(notes`i')'}""'
}
** graph
twoway ///
(line ownp3 year if agegroup == 1, lcolor("67 183 232") lpattern(solid)) ///
(line ownp3 year if agegroup == 2, lcolor("123 120 252") lpattern(solid)) ///
(line ownp3 year if agegroup == 3, lcolor("40 181 77") lpattern(solid)) ///
(line ownp3 year if agegroup == 4, lcolor("230 55 46") lpattern(solid)) ///
(line ownp3 year if agegroup == 5, lcolor("232 189 60") lpattern(solid)) ///
(line ownp3 year if agegroup == 6, lcolor("227 148 30") lpattern(solid)) ///
, ///
by(agegroup, rows(1) imargin(small)) ///
by(, title("{fontface Roboto Bold:Homeownership Rates Across Age Groups}", color(white) size(6.5) pos(11) justification(left))) ///
by(, subtitle("{fontface Roboto Bold:Percentage of individuals who own the home they live in over time (1976-2025), by age group}", color(gs11) size(3.5) pos(11) justification(left))) ///
subtitle(,  color(white) size(small) lcolor("38 53 84") fcolor("38 53 84")) ///
xtitle("Year", size(3.5) color(gs14) margin(b-1 t-2)) xscale(lstyle(none)) ///
xscale(lstyle(none)) ///
xlabel(1976 2000 2025, angle(45) labcolor(gs14) labsize(2.5) glcolor(gs9%0) tlength(1.25) tlcolor(gs6%30)) xmtick(1980(5)1995 2005(5)2020, tlength(.75) tlcolor(gs9%30)) ///
ytitle("") ///
yscale(lstyle(none)) ///
ylabel(0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%" .6 "60%" .7 "70%" .8 "80%", angle(0) labcolor(gs14) labsize(3.75) gmax gmin glpattern(solid) glcolor(gs9%40) glwidth(vthin) tlength(0) tlcolor(gs9%15)) ///
legend(off) ///
by(, legend(off)) ///
by(, note(" " "Source: {fontface Lato:Author's analysis of IPUMS-CPS (1976-2025).} Sample: {fontface Lato:U.S. adult civilians (excludes group quarters).}" `notes', margin(l+1.5) color(gs7) span size(vsmall) position(7))) ///
by(, caption("@johcharts on Substack", margin(l+1 t-1) color(white) span size(vsmall) position(7))) ///
by(, graphregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none))) ///
plotregion(fcolor("17 24 39") lcolor("17 24 39")) ///
by(, plotregion(margin(0 0 0 0) fcolor("17 24 39") lcolor("17 24 39") lwidth(none) ifcolor("17 24 39") ilcolor("17 24 39") ilwidth(none))) ///
by(, graphregion(margin(r+1)))
cd "$directory/output/millennial-vs-genx"
graph export ownp3_timeseries-byagegroup.png, replace height(2500) width(4000)