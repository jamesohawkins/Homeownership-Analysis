////////////////////////////////////////////////////////////////////////////////
// Do File: 01_wrangling.do.do
// Primary Author: James Hawkins, JOHCharts.substack.com
// Date: 11/14/2025
// Stata Version: 19
// Description: This code uses the ipumspy package to download homeownership 
// data directly from IPUMS-CPS for all available cross-sections of the CPS 
// ASEC. The code then constructs several variations of homeownership indicators
// using available relationship data in the CPS. This includes my preferred
// individual homeownerhsip indicator, which is defined in 'ownp1'. This 
// incorporates partners as potential owners (depending on the ownership status
// of the household).
// 
// The script is separated into the following sections:
// 		1. Wrangle Current Population Survey (CPS) data set
////////////////////////////////////////////////////////////////////////////////


// =============================================================================
// 1. Wrangle Current Population Survey (CPS) data set
// =============================================================================

// A. Obtain CPS data via IPUMS api
// -----------------------------------------------------------------------------
/* In this sub-section, I obtain CPS data from the IPUMS API. Instructions for 
   implementing using the IPUMS API in Stata are available here: 
   https://blog.popdata.org/making-ipums-extracts-from-stata/. General 
   instructions for creating extracts via the API are available here:
   https://v1.developer.ipums.org/docs/workflows/create_extracts/cps/. Users
   seeking to replicate my analysis will need to obtain an API key from IPUMS
   and insert it below or define their API key in their profile.do script that 
   executes every time Stata starts. Instructions to implement the latter are 
   available here: 
   https://www.stata.com/support/faqs/programming/profile-do-file/. */
   
cd "$directory\raw-data"
clear
python
import gzip
import shutil

from ipumspy import IpumsApiClient, MicrodataExtract
from sfi import Macro

my_api_key = Macro.getGlobal("MY_API_KEY")

ipums = IpumsApiClient(my_api_key)

# define extract
ipums_collection = "cps"
samples = ["cps1976_03s", "cps1977_03s", "cps1978_03s", "cps1979_03s",
"cps1980_03s", "cps1981_03s", "cps1982_03s", "cps1983_03s", "cps1984_03s", 
"cps1985_03s", "cps1986_03s", "cps1987_03s", "cps1988_03s", "cps1989_03s", 
"cps1990_03s", "cps1991_03s", "cps1992_03s", "cps1993_03s", "cps1994_03s", 
"cps1995_03s", "cps1996_03s", "cps1997_03s", "cps1998_03s", "cps1999_03s", 
"cps2000_03s", "cps2001_03s", "cps2002_03s", "cps2003_03s", "cps2004_03s", 
"cps2005_03s", "cps2006_03s", "cps2007_03s", "cps2008_03s", "cps2009_03s", 
"cps2010_03s", "cps2011_03s", "cps2012_03s", "cps2013_03s", "cps2014_03s", 
"cps2015_03s", "cps2016_03s", "cps2017_03s", "cps2018_03s", "cps2019_03s", 
"cps2020_03s", "cps2021_03s", "cps2022_03s", "cps2023_03s", "cps2024_03s",
"cps2025_03s"]
variables = ["YEAR", "SERIAL", "MONTH", "CPSID", "CPSIDP", "ASECFLAG", "ASECWT", 
"ASECWTH", "REPWTP", "PERNUM", "AGE", "SEX", "RACE", "OWNERSHP", "RELATE", "GQ", "MIGSTA1", "EDUC", "MARST",
"STATEFIP"]
extract_description = "Homeownership (2024)"

extract = MicrodataExtract(ipums_collection, samples, variables, description=extract_description)
	 
# submit your extract to the IPUMS extract system
ipums.submit_extract(extract)

# wait for the extract to finish
ipums.wait_for_extract(extract, collection=ipums_collection)

# download it to your current working directory
ipums.download_extract(extract, stata_command_file=True)

Macro.setLocal("id", str(extract.extract_id).zfill(5))
Macro.setLocal("collection", ipums_collection)

extract_name = f"{ipums_collection}_{str(extract.extract_id).zfill(5)}"
# unzip the extract data file
with gzip.open(f"{extract_name}.dat.gz", 'rb') as f_in:
	with open(f"{extract_name}.dat", 'wb') as f_out:
		shutil.copyfileobj(f_in, f_out)

# exit python
end
qui do `collection'_`id'.do

cd "$directory\derived-data"
save ipumscps_raw.dta, replace


// B. Wrangle CPS data
// -----------------------------------------------------------------------------
cd "$directory\derived-data"
use ipumscps_raw.dta, clear
   
// Original age var
gen age_orig = age
   
// Restrict sample to adult records
/* NOTE: In some marginal cases, this will lead to households having no 
   household head (aka absent from the household measure) but include other 
   persons in the household who are adults (person measure). */ // JH: is this also true of the acs?
keep if age >= 18

// Restrict sample to household records
keep if gq == 1

// Top-code age
replace age = 80 if age > 80

// Define individual-level age group measure (primary groupings used in analysis across time)
gen agegroup = .
replace agegroup = 1 if age >= 18 & age <= 24
replace agegroup = 2 if age >= 25 & age <= 34
replace agegroup = 3 if age >= 35 & age <= 44
replace agegroup = 4 if age >= 45 & age <= 54
replace agegroup = 5 if age >= 55 & age <= 64
replace agegroup = 6 if age >= 65
** label(s)
lab var agegroup "Primary age groups for household heads (harmonized across time)"
lab def agegroup_lbl ///
	1 "18-24" ///
	2 "25-34" ///
	3 "35-44" ///
	4 "45-54" ///
	5 "55-64" ///
	6 "65+"
lab val agegroup agegroup_lbl

// Define generation cohort
gen birth = year - age
gen generation = .
replace generation = 1 if inrange(birth, 1928, 1945)
replace generation = 2 if inrange(birth, 1946, 1964)
replace generation = 3 if inrange(birth, 1965, 1980)
replace generation = 4 if inrange(birth, 1981, 1996)
replace generation = 5 if inrange(birth, 1997, 2012)
lab var generation "Generation (Defined by Pew Research Center)"
lab def generation_lbl ///
	0 "Greatest" ///
	1 "Silent" ///
	2 "Boomers" ///
	3 "Gen X" ///
	4 "Millennials" ///
	5 "Gen Z"
lab val generation generation_lbl

// Define homeownership measure (household)
gen ownhh = 1 if ownershp == 10 & relate == 101
replace ownhh = 0 if inlist(ownershp, 21, 22) & relate == 101
lab var ownhh "Homeownership (household)"

// Define homeownership measures (person)
** partners included (preferred measure)
gen ownp1 = .
replace ownp1 = 1 if ownershp == 10 & inlist(relate, 101, 201, 202, 203, 1114, 1116, 1117)
replace ownp1 = 0 if inlist(ownershp, 21, 22) & inlist(relate, 101, 201, 202, 203, 1114, 1116, 1117)
replace ownp1 = 0 if inlist(relate, 301, 303, 501, 701, 901, 1001, 1113, 1115, 1241, 1242, 1260)
lab var ownp1 "Homeownership (person, including spouses and partners)"
** partner/roommates (1989 and 1992) included
gen ownp2 = .
replace ownp2 = 1 if ownershp == 10 & inlist(relate, 101, 201, 202, 203, 1113, 1114, 1116, 1117)
replace ownp2 = 0 if inlist(ownershp, 21, 22) & inlist(relate, 101, 201, 202, 203, 1113, 1114, 1116, 1117)
replace ownp2 = 0 if inlist(relate, 301, 303, 501, 701, 901, 1001, 1115, 1241, 1242, 1260)
lab var ownp2 "Homeownership (person, including spouses, partners, and partner/roommates)"
** spouses
gen ownp3 = .
replace ownp3 = 1 if ownershp == 10 & inlist(relate, 101, 201, 202, 203)
replace ownp3 = 0 if inlist(ownershp, 21, 22) & inlist(relate, 101, 201, 202, 203)
replace ownp3 = 0 if inlist(relate, 301, 303, 501, 701, 901, 1001, 1113, 1114, 1115, 1116, 1117, 1241, 1242, 1260)
lab var ownp3 "Homeownership (person, including spouses)"

// Define headship measures
** partners included (preferred measure)
gen headship1 = .
replace headship1 = 1 if inlist(relate, 101, 201, 202, 203, 1114, 1116, 1117)
replace headship1 = 0 if inlist(relate, 301, 303, 501, 701, 901, 1001, 1113, 1115, 1241, 1242, 1260)
lab var headship1 "Headship (including spouses and partners)"
** partner/roommates (1989 and 1992) included
gen headship2 = .
replace headship2 = 1 if inlist(relate, 101, 201, 202, 203, 1113, 1114, 1116, 1117)
replace headship2 = 0 if inlist(relate, 301, 303, 501, 701, 901, 1001, 1115, 1241, 1242, 1260)
lab var headship2 "Homeownership (person, including spouses, partners, and partner/roommates)"
** spouses
gen headship3 = .
replace headship3 = 1 if inlist(relate, 101, 201, 202, 203)
replace headship3 = 0 if inlist(relate, 301, 303, 501, 701, 901, 1001, 1113, 1114, 1115, 1116, 1117, 1241, 1242, 1260)
lab var headship3 "Homeownership (person, including spouses)"

// Define marriage status
gen cmarried = 1 if inlist(marst, 1, 2)
replace cmarried = 0 if inlist(marst, 3, 4, 5, 6) // JH
lab var cmarried "Currently married"
lab def cmarried_lbl ///
	1 "Married" ///
	0 "Not married"
lab val cmarried cmarried_lbl

// Check for missing values
foreach var of varlist ownp1 ownp2 ownp3 headship1 headship2 headship3 cmarried agegroup birth {
	assert !missing(`var')
}
assert !missing(ownhh) if relate == 101

// Save data
cd "$directory\derived-data"
compress
save ipumscps_wrangled.dta, replace


// =============================================================================
// 1. Wrangle IPUMS USA data set JH
// =============================================================================
/* JH. */

// A. Obtain ACS/Decennial Census data via IPUMS api
// -----------------------------------------------------------------------------
/* In this sub-section, I obtain CPS data from the IPUMS API. Instructions for 
   implementing using the IPUMS API in Stata are available here: 
   https://blog.popdata.org/making-ipums-extracts-from-stata/. General 
   instructions for creating extracts via the API are available here:
   https://v1.developer.ipums.org/docs/workflows/create_extracts/cps/. Users
   seeking to replicate my analysis will need to obtain an API key from IPUMS
   and insert it below or define their API key in their profile.do script that 
   executes every time Stata starts. Instructions to implement the latter are 
   available here: 
   https://www.stata.com/support/faqs/programming/profile-do-file/. */
   
cd "$directory\raw-data"
clear
python
import gzip
import shutil

from ipumspy import IpumsApiClient, MicrodataExtract
from sfi import Macro

my_api_key = Macro.getGlobal("MY_API_KEY")

ipums = IpumsApiClient(my_api_key)

# define extract
ipums_collection = "usa"
samples = ["us1940a", "us1950a", "us1960b", "us1970a", "us1980a", "us1990a", 
		"us2000a", "us2001a", "us2002a", "us2003a", "us2004a", "us2005a",
		"us2006a", "us2007a", "us2008a", "us2009a", "us2010a", "us2011a",
		"us2012a", "us2013a", "us2014a", "us2015a", "us2016a", "us2017a",
		"us2018a", "us2019a", "us2020a", "us2021a", "us2022a", "us2023a"]
variables = ["YEAR", "SERIAL", "PERNUM", "HHWT", "PERWT", "STATEFIP", "COUNTYFIP",
"GQ", "RELATE", "RELATED", "AGE", "OWNERSHP", "VACANCY", "METRO", "MARST"]
extract_description = "Homeownership (Through 2023)"

extract = MicrodataExtract(ipums_collection, samples, variables, description=extract_description)
	 
# submit your extract to the IPUMS extract system
ipums.submit_extract(extract)

# wait for the extract to finish
ipums.wait_for_extract(extract, collection=ipums_collection)

# download it to your current working directory
ipums.download_extract(extract, stata_command_file=True)

Macro.setLocal("id", str(extract.extract_id).zfill(5))
Macro.setLocal("collection", ipums_collection)

extract_name = f"{ipums_collection}_{str(extract.extract_id).zfill(5)}"
# unzip the extract data file
with gzip.open(f"{extract_name}.dat.gz", 'rb') as f_in:
	with open(f"{extract_name}.dat", 'wb') as f_out:
		shutil.copyfileobj(f_in, f_out)

# exit python
end
qui do `collection'_`id'.do

cd "$directory\derived-data"
save ipumsusa_raw.dta, replace


// B. Wrangle data from IPUMS API
// -----------------------------------------------------------------------------
cd "$directory\derived-data"
use ipumsusa_raw.dta, clear

// Original age var
gen age_orig = age

// Restrict sample to adult records
keep if age >= 18

// Group quarter definition
keep if inlist(gq, 1, 2, 5)
	/* IPUMS states that "In most cases, a working definition of "household" as 
	GQ = 1 or 2 is appropriate. Categories are not completely comparable across 
	all years." See: 
	https://usa.ipums.org/usa-action/variables/GQ#comparability_section
	I also include GQ = 5, which is a small segment of the sample since 2000, 
	since these respondents have non-missing responses for home-ownership.
	*/

// Top-code age
replace age = 90 if age > 90

// Define individual-level age group measure (primary groupings used in analysis across time)
gen agegroup = .
replace agegroup = 1 if age >= 18 & age <= 24
replace agegroup = 2 if age >= 25 & age <= 34
replace agegroup = 3 if age >= 35 & age <= 44
replace agegroup = 4 if age >= 45 & age <= 54
replace agegroup = 5 if age >= 55 & age <= 64
replace agegroup = 6 if age >= 65
** label(s)
lab var agegroup "Primary age groups for household heads (harmonized across time)"
lab def agegroup_lbl ///
	1 "18-24" ///
	2 "25-34" ///
	3 "35-44" ///
	4 "45-54" ///
	5 "55-64" ///
	6 "65+"
lab val agegroup agegroup_lbl

// Define generation cohort
gen birth = year - age
gen generation = .
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

// Define homeownership measure (household)
gen ownhh = 1 if ownershp == 1 & relate == 1
replace ownhh = 0 if inlist(ownershp, 2) & relate == 1
lab var ownhh "Homeownership (household)"

// Define homeownership measures (person)
** partners included (preferred measure)
/* NOTE: ACS does not include separate codes for unmarried partners (1114) in
   1980. */
gen ownp1 = 0
replace ownp1 = 1 if ownershp == 1 & inlist(related, 101, 201, 1114)
lab var ownp1 "Homeownership (person, including spouses and partners)"
** partner/roommates included (code 1115)
gen ownp2 = 0
replace ownp2 = 1 if ownershp == 1 & inlist(related, 101, 201, 1113, 1114)
lab var ownp2 "Homeownership (person, including spouses, partners, and partner/roommates)"
** spouses
gen ownp3 = 0
replace ownp3 = 1 if ownershp == 1 & inlist(related, 101, 201)
lab var ownp3 "Homeownership (person, including spouses)"

// Define headship measures
** partners included starting in 1990 (preferred measure)
gen headship1 = 0
replace headship1 = 1 if inlist(relate, 1, 2)
replace headship1 = 1 if related == 1114 // unmarried partner
lab var headship1 "Headship (including spouse and unmarried partner)"
** partner/roommates (1989 and 1992) included
gen headship2 = 0
replace headship2 = 1 if inlist(relate, 1, 2)
replace headship2 = 1 if inlist(related, 1110, 1113, 1114)
lab var headship2 "Homeownership (person, including spouse, partner/friend, partner/roommate, unmarried partner)"
** spouses
gen headship3 = 0
replace headship3 = 1 if inlist(relate, 1, 2)
lab var headship3 "Homeownership (person, including spouse)"

// Define marriage status
gen cmarried = 1 if inlist(marst, 1, 2)
replace cmarried = 0 if inlist(marst, 3, 4, 5, 6) // JH
lab var cmarried "Currently married"
lab def cmarried_lbl ///
	1 "Married" ///
	2 "Not married"
lab val cmarried cmarried_lbl

// Save data
cd "$directory\derived-data"
compress
save ipumsusa_wrangled.dta, replace