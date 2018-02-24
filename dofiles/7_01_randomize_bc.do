/*
--------------------------------------------------------------------------------
Title		: RANDOMIZE FOR BACK CHECKS
Purporse	: This creates a random list of respondents for back checks
Ado(s)		: 
--------------------------------------------------------------------------------
*/

/* -----------------------------------------------------------------------------
1.0 Import BC Data
-------------------------------------------------------------------------------	*/

use "${dir_survey}/${dta_survey}_post_hfc", clear

* STOP IF DATA CONTAINS DUPLICATES
cap isid ${var_survey_id}
if _rc == 459 {
	noi di as err "{p}Variable ${surveyid} does not uniquely identify observations in Survey Data"
	noi di as err _column(10) "More details can be found in the hfc_outputs folder. Resolve this and re-run the master_run do file{p_end}"
	ex 459
}

/* -----------------------------------------------------------------------------
2.0 randomize
-------------------------------------------------------------------------------	*/
gen subdate = dofc(submissiondate)
drop if subdate <= date("${lastdate_bc}", "DMY")

sample 10, count by(${var_team_id} ${var_enum_id})

/* -----------------------------------------------------------------------------
3.0 Export Results
-------------------------------------------------------------------------------	*/

* make date folder
cap mkdir "${dir_bc_list}/`c(current_date)'"

#d;
export excel 
			${id}
			${var_survey_id}
			${var_enum_id}
			${var_team_id}
			${var_geo_cluster} 
			${varl_keeplist_bc}
			using 
			"${dir_bc_list}/`c(current_date)'/${xlsx_bc_list}", 
			first(var) replace
		;
#d cr
