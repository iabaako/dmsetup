/*
--------------------------------------------------------------------------------
Title		: Prepare Survey Data
Purporse	: Prepares the raw dataset for HFCs
Ado(s)		: 
--------------------------------------------------------------------------------
*/

/* -----------------------------------------------------------------------------
1.0 IMPORT DATA
------------------------------------------------------------------------------	*/

use "${dir_survey}/${dta_survey_raw}", replace

/* -----------------------------------------------------------------------------
2.0 MANIPULATE VARS
	* remove unneeded variables
	* destring variables
	* generate additional variables
------------------------------------------------------------------------------	*/

	* Drop unneeded surveycto generated variables
	#d;
	drop deviceid
		 subscriberid
		 devicephonenum
		 simid
		 ;
	#d cr

	* Destring Variables. Check if string variables can be changed to numeric. 
	* By default SCTO will import them as strings unless they have var lables
	ds, has (type string)
	foreach var of varlist `r(varlist)' {
		destring `var', replace
	}
	
	* Generate short skey var skey
	gen skey = substr(key, -12, .)
	note skey: Generated from key. Will be used for reporting errors and making replacements
	
	* Variables key and skey should never duplicates and should never be missing, if they do stop dofile
	foreach var of varlist key skey {
		cap assert !missing(`var')
		if !_rc {
			cap isid `var'
			if _rc {
				noi disp as error "Fatal Error: Duplicates in `var'"
				exit 459	
			}
		}
		else {
			noi disp as error "Fatal Error: `var' contains missing values"
			exit 9
		}
	}
		
	* Generate start and end date variables
	gen 	startdate = dofc(starttime)
	gen 	enddate = dofc(endtime)
	format 	startdate enddate %td
	
* Save dataset
save "${dir_survey}/${dta_survey}_prepped", replace

/* -----------------------------------------------------------------------------
4.0 CLEAN OTHER SPECIFY VARIABLES
	* Replace child variables with missing values if -666 is not selected in 
	parent variables
------------------------------------------------------------------------------	*/

if "${xlsx_hfc_inputs}" ~= "" {
	* Import inputs sheet
	import excel using "${dir_tools}/${xlsx_hfc_inputs}", sh("9. specify") first allstr clear
	* keep if parent is not missing
	keep if !missing(parent)
	* Loop through and save child and parent pairings in locals
	loc osp_cnt `=_N'
	forval i = 1/`osp_cnt' {
		loc child_`i' 	= child[`i']
		loc parent_`i' 	= parent[`i']
	}
		
	* Import prepped data
	use ${dir_survey}/${dta_survey}_prepped, replace
	* Loop through and for each pair of child replace values to missing if 
	* osp was not selected in parent
	forval i = 1/`osp_cnt' {
		* tostring child
		tostring `child_`i'', replace
		* check var type and apply appropraite replacement syntax
		cap confirm string var `parent_`i'' 
		if !_rc {
			replace `child_`i'' = "" if !regexm(`parent_`i'', "${val_osp}")
		}
		else {
			replace `child_`i'' = "" if `parent_`i'' != ${val_osp}
		}
	}
}

/* -----------------------------------------------------------------------------
4.0 ADDITIONAL PREPARATIONS
	* Include additional preparation code here
------------------------------------------------------------------------------	*/

/* -----------------------------------------------------------------------------
5.0 Save Prepped Dataset
------------------------------------------------------------------------------	*/
save "${dir_survey}/${dta_survey}_prepped", replace
