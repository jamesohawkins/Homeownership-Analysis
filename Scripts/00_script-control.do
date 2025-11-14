////////////////////////////////////////////////////////////////////////////////
// Do File: 00_script-control.do
// Primary Author: James Hawkins, JOHCharts.substack.com
// Date: 11/14/2025
// Stata Version: 19
// Description: This script runs the core Stata do files necessary to replicate
// my analysis of homeownership rates in the U.S. population. Please note that
// you will need 1) to set the directory via the global below (see 'enter your 
// own directory here'), 2) a version of Python installed that Stata can access,
// 3) to set the directory for the python.exe ('enter your own python directory
// here'), and 4) a corresponding API key for IPUMS CPS inserted into a 
// profile.do file within the scripts subdirectory. The profile.do script will
// contain one line that reads 'global MY_API_KEY = "[INSERT API KEY HERE]'. 
// Alternatively, for convenience, you can uncomment the MY_API_KEY on line 57
// below and enter your key there.
// 
// The script is separated into the following sections:
// 		1. Miscellaneous Set Up
//		2. Execute Scripts
////////////////////////////////////////////////////////////////////////////////
timer on 1


/// ============================================================================
**# 1. Miscellaneous Set Up
/// ============================================================================
/*  In this section, I define the random number seeds, the local directory of 
    the repository, set up the python environment for use with IPUMS API, and 
	provide code to set a user's IPUMS API key (in my own analysis, I use a 
	profile.do script to establish the IPUMS API key each time Stata starts). */
	
// Random number seeds
// -----------------------------------------------------------------------------
set seed 690942
set sortseed 343446

// Set directory for repository
// -----------------------------------------------------------------------------
global directory "" // enter your own directory here

// Set up python (only applicable if using IPUMS API)
// -----------------------------------------------------------------------------
python query
set python_exec "" //  enter your own python directory here

// Set IPUMS API key
// -----------------------------------------------------------------------------
/* NOTE: To set up an API key to access IPUMS API, follow these instructions:
   https://developer.ipums.org/docs/v2/get-started/. To define your API key,
   uncomment the following line and replace "INSERT HERE" with your API key.
   Alternatively, create a profile.do script that defines the API key by 
   following these instructions: 
   https://www.stata.com/manuals/gswb.pdf#B.3ExecutingcommandseverytimeStataisstarted 
   */
** global MY_API_KEY "INSERT HERE" // if not using a profile.do script, uncomment this line and enter your own API key here

// Visualization settings
// -----------------------------------------------------------------------------
set scheme plotplain
graph set window fontface "Lato Bold"

// Script settings
// -----------------------------------------------------------------------------
set varabbrev off

// Packages
// -----------------------------------------------------------------------------
net from http://fmwww.bc.edu/repec/bocode
ssc install palettes, replace
ssc install colrspace, replace
ssc install blindschemes, replace
net install linewrap, from("http://digital.cgdev.org/doc/stata/MO/Misc")

/// ============================================================================
**# 2. Execute Scripts
/// ============================================================================
/*  In this sub-section, I execute the scripts necessary to reproduce my 
    analysis of SCF and CPS homeownership rates. */

// Execute data wrangling script
cd "$directory\scripts"
do 01_wrangling.do

// Execute data analysis script
cd "$directory\scripts"
do 02_analysis.do

timer off 1
timer list 1
noi display as text "Runtime was " as result %3.2f `=r(t1)/60' " minutes"