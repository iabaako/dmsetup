/*
--------------------------------------------------------------------------------
Title		: MASTER RUN
Purporse	: This is the master do file which runs all other do files used for
			  data quality check.
Ado(s)		: ssc: 	touch, cfout, bcstats, ipacheck ados, remedia
					psemail_v2
--------------------------------------------------------------------------------
INSTRUCTIONS:
--------------------------------------------------------------------------------
1. Download Dataset (For None API Users)
2. Add all corrections to replacement sheet
2. Run this dofile

NB: CURRENT FOLDER MUST BE 02_dofiles
--------------------------------------------------------------------------------
*/	

/* -----------------------------------------------------------------------------
0.1 Begin Log:
-------------------------------------------------------------------------------	*/

loc logfile = "dm_log_" + 	subinstr("`c(current_date)'", " ", "", .) + "_" + ///
							subinstr("`c(current_time)'", ":", "", .)

cap log close
log using "../03_tools_logs/03_logs/`logfile'", text replace

/* -----------------------------------------------------------------------------
0.2 Setup:
------------------------------------------------------------------------------- */

set seed 		12345
set sortseed	12345		
ipadoheader, 	version(15.0)
 
/* -----------------------------------------------------------------------------
2.0 Back Check
	0: No 1: Yes
-------------------------------------------------------------------------------	*/
loc randomize_bc 		1
loc compare_bc			1

glo lastdate_bc 		""		// Date format: 14feb2018
/* -----------------------------------------------------------------------------
3.0 Set Globals
-------------------------------------------------------------------------------	*/

do ../02_dofiles/01_background/3_01_set_globals.do

/* -----------------------------------------------------------------------------
4.0 IMPORT DATASETS
-------------------------------------------------------------------------------	*/
* import survey data
do "${dir_do_background}/${do_import_survey}.do"

* import bc data
do "${dir_do_background}/${do_import_bc}.do"

* import field monitoring data
do "${dir_do_background}/${do_import_mon}"

/* -----------------------------------------------------------------------------
5.0 PREPARE THE DATA SET FOR HFCs
-------------------------------------------------------------------------------	*/
*/
* Prepare survey data
do "${dir_do_background}/${do_prep_survey}"

* Prepare bc data
if `compare_bc' == 1 do "${dir_do_background}/${do_prep_bc}"

* Prepare field monitoring data
do "${dir_do_background}/${do_prep_mon}"

/*------------------------------------------------------------------------------
6.0 RUN HFCs
	run hfc dofiles
-------------------------------------------------------------------------------	*/
* Create HFC Folder
cap mkdir "${dir_hfc}/`c(current_date)'"

* Remove existing output files
	cap rm "${dir_hfc}/`c(current_date)'/${xlsx_hfc_enum_db}"
	cap rm "${dir_hfc}/`c(current_date)'/${xlsx_hfc_output}"
	
* Copy hfc enumerator template into folder
	copy "${dir_tools}/hfc_enumerators.xlsx" ///
		 "${dir_hfc}/`c(current_date)'/${xlsx_hfc_enum_db}", replace
	
	* run master check 
	do "${dir_do_background}/${do_master_check}"

/*------------------------------------------------------------------------------
7.0 RANDOMIZE FOR BACK CHECKS
-------------------------------------------------------------------------------	*/

if `randomize_bc' == 1 do "${dir_do_background}/${do_randomize_bc}"
	
/*------------------------------------------------------------------------------
8.0 RUN BC COMPARISON
	run hfc dofiles
-------------------------------------------------------------------------------	*/

if `compare_bc' == 1 do "${dir_do_background}/${do_compare_bc}"

/*------------------------------------------------------------------------------
9.0 FIELD MONITORING
-------------------------------------------------------------------------------	*/

* Create HFC Folder
if `c(version)' >= 14 {
	cap mkdir "${dir_mon_out}/`c(current_date)'"
	cap rm "${dir_mon_out}/`c(current_date)'/${xlsx_mon_output}"

	ipacheckmonitor using "${dir_mon}/${dta_mon}_prepped", 					///
		infile("${dir_tools}/${xlsx_mon_inputs}")							///
		outfile("${dir_mon_out}/`c(current_date)'/${xlsx_mon_output}")		///
		commentdata("${dir_mon}/${dta_mon_raw}-ac_rpt")						///
		xlsform("${dir_scto_xls}/${xlsx_mon_xls}")
}

log close
*----------------------      END OF DO FILE       -----------------------------*
