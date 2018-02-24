/*
--------------------------------------------------------------------------------
Title		: Prepare Back Check Dataset
Purporse	: Prepares the raw dataset for HFCs
Ado(s)		: 
--------------------------------------------------------------------------------
*/

/* -----------------------------------------------------------------------------
1.0 IMPORT DATA
------------------------------------------------------------------------------	*/

* Import raw dataset
use "${dir_bc}/${dta_bc_raw}", replace

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
		
	* Genarate start and end date variables
	gen startdate = dofc(starttime)
	gen enddate = dofc(endtime)
	format startdate enddate %td
	
* Save dataset
save "${dir_bc}/${dta_bc}_prepped", replace
	
/* -----------------------------------------------------------------------------
4.0 Check for Duplicates in BC Dataset
------------------------------------------------------------------------------	*/
* Create HFC Folder
cap mkdir "${dir_bc_diffs}/`c(current_date)'"

* Make corrections to data
ipacheckreadreplace using "${dir_hfc_repl}/${xlsx_hfc_repl}", ///
	id(skey) ///
	variable(variable) ///
	value(value) ///
	newvalue(newvalue) ///
	action(action) ///
	logusing("${dir_bc_diffs}/`c(current_date)'/${xlsx_bc_repl_log}") ///
	sheet("bc_replacements")

cap isid ${var_survey_id} 
if _rc == 459 {

	duplicates tag ${var_survey_id}, gen (_dups)
	sort ${var_survey_id}
	
	#d;
	export 	excel
			skey submissiondate ${var_survey_id} ${var_bcer_id} ${varl_keeplist_bc}
			using "${dir_bc_diffs}/`c(current_date)'/bc_duplicates_output.xlsx"
			if _dups,
			first(var) replace
			;
	
	noi di as err "{p}${var_survey_id} does not uniquely identify the observations in back check data. Please refer to the file {break}
					${dir_bc_diffs}/bc_duplicates_output.xlsx for further details. You must correct this to proceed"
				;
	#d cr
	ex 459
}

/* -----------------------------------------------------------------------------
5.0 Save Prepped Dataset
------------------------------------------------------------------------------	*/
save "${dir_bc}/${dta_bc}_prepped", replace
