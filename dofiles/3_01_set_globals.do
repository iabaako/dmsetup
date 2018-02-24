/*
--------------------------------------------------------------------------------
Title		: SET GLOBALS
Purporse	: This dofile sets the neccesary globals for
			  data quality check.
Ado(s)		: 
--------------------------------------------------------------------------------
*/

/* -----------------------------------------------------------------------------
1.0 Project Back Up Directory
	* This folder should be in the IPA Ghana Central Backup folder
-------------------------------------------------------------------------------	*/

gl dir_backup ""

/* -----------------------------------------------------------------------------
2.0 Global Files
	* Set the names of directories and files
	* Include file extensions
-------------------------------------------------------------------------------	*/

* Excel Files
gl xlsx_survey_xls			"XLSX SURVEY XLS"						// SurveyCTO programmed XLS form
gl xlsx_mon_xls				"XLSX MON XLS"							// SurveyCTO programmed XLS form
gl xlsx_bc_xls				"XLSX BC XLS"							// SurveyCTO programmed XLS form
gl xlsx_hfc_inputs 			"hfc_inputs.xlsx"						// HFC inputs sheet
gl xlsx_hfc_output 			"hfc_output.xlsx"						// HFC output sheet
gl xlsx_hfc_enum_db			"hfc_enumerators.xlsx"					// HFC Enumerator Dashboard
gl xlsx_research_db			"research_dashboard.xlsx"				// HFC research dashboard
gl xlsx_text_audit_db		"text_audit_dashboard.xlsx"				// HFC research dashboard
gl xlsx_hfc_repl 			"hfc_replacements.xlsx"					// HFC Replacement File
gl xlsx_hfc_repl_log		"hfc_replacements_log.xlsx"				// HFC Replacement File
gl xlsx_bc_repl_log			"bc_replacements_log.xlsx"				// BC Replacement File
gl xlsx_bc_list				"bc_list.xlsx"							// BC randomization list
gl xlsx_bc_diffs			"bc_diffs.xlsx"							// BC Diffrences
gl xlsx_mon_inputs			"ipagh_field_monitoring_inputs.xlsx"	// Inputs file for field monitoring
gl xlsx_mon_output 			"ipagh_field_monitoring_output.xlsx"	// Report on Monitoring Data

* Do Files
gl do_api_download			""										// Import dofile for main survey
gl do_import_survey			""										// Import dofile for main survey
gl do_import_bc				""										// Import dofile for back check
gl do_import_mon			""										// Import dofile for field monitoring
gl do_prep_survey			"5_01_prepare_survey.do"				// Preparation dofile for Survey Data
gl do_prep_bc				"5_02_prepare_bc.do"					// Preparation dofile for BC Data
gl do_prep_mon				"5_03_prepare_mon.do"					// Preparation dofile for Field Monitoring Data
gl do_master_check			"6_01_master_check.do"					// HFC Master Check dofile
gl do_ps_profile			"6_e1_psemail_profile.do"				// psemail profile setter
gl do_randomize_bc			"7_01_randomize_bc.do"					// BC randomization do file
gl do_compare_bc   		    "8_01_compare_bc.do"     				// BC comparison dofile

* Dta files (Exclude .dta)
gl dta_survey_raw			"DTA SURVEY RAW"						// Raw Survey Data 
gl dta_survey				""										// Prefix for edited survey datasets
gl dta_bc_raw				"DTA BC RAW"							// Raw BC Data 
gl dta_bc					""										// Prefix for edited bc datasets
gl dta_mon_raw				"DTA MON RAW"							// Raw field monitoring data
gl dta_mon					""										// Prefix for edited monitoring data

* Tracking Data (include extension ie. .xlsx, .dta)
gl tracking_data			""										// Master Tracking Data
	
/* -----------------------------------------------------------------------------
3.0 Global Variables, Values and Text
	* Set globals for variable and values
-------------------------------------------------------------------------------	*/

* Variables
gl var_survey_id			"VAR SURYEY ID"				// Specify Survey ID
gl var_enum_id				"VAR ENUM ID"				// Enumerator ID
gl var_team_id				""							// Team ID
gl var_bcer_id				"VAR BC ID"					// Back Checker ID
gl var_geo_cluster			"VAR GEO CLUSTER"			// Geographical Cluster 
gl var_text_audit			"text_audit"				// Text Audit
gl varl_keeplist_hfc		"VARL KEEPLIST HFC"			// Additional Variables to show in HFC
gl varl_keeplist_bc			"VARL KEEPLIST BC"			// Additional Variables to show in BC

* Values
gl val_sample_size			VAL_SS				// Sample Size
gl val_dk					VAL_DK				// Dont Know
gl val_rf					VAL_RF				// Refuse to Answer
gl val_osp					VAL_OSP				// Other Specify
gl val_bc_perc				VAL_BC_PERC			// Percentage to Randomize for BC

* Text
gl txt_scto_Server			"TXT SCTO SERVER"	// SCTO Server Name

/* -----------------------------------------------------------------------------
4.0 Global Directories: DO NOT EDIT
-------------------------------------------------------------------------------	*/

gl main 				..
gl dir_scto_xls			../01_instruments/03_scto_xls
gl dir_do_background	../02_dofiles/01_background
gl dir_tools			../03_tools_logs/01_tools	
gl dir_hfc				../03_tools_logs/02_outputs_encrypted/01_hfcs
gl dir_bc_list			../03_tools_logs/02_outputs_encrypted/02_bc_list
gl dir_bc_diffs			../03_tools_logs/02_outputs_encrypted/03_bc_diffs
gl dir_mon_out			../03_tools_logs/02_outputs_encrypted/04_monitoring
gl dir_logs				../03_tools_logs/03_logs
gl dir_preloads			../04_data_encrypted/01_preloads
gl dir_survey			../04_data_encrypted/02_survey
gl dir_bc				../04_data_encrypted/03_bc
gl dir_mon				../04_data_encrypted/04_field_monitoring
gl dir_hfc_repl			../04_data_encrypted/05_hfc_replacements
gl dir_clean			../04_data_encrypted/06_clean
gl dir_data_no_pii		../05_data_no_pii
gl dir_audio			../06_media_encrypted/01_audio
gl dir_pictures			../06_media_encrypted/02_pictures
gl dir_videos			../06_media_encrypted/03_videos


/* -----------------------------------------------------------------------------
5.0 Verify BackuUp Folder: DO NOT EDIT THIS
-------------------------------------------------------------------------------	*/

* Verify Folder and reset Back Up Global
cap conf file 					"X:/Box/IPA_GHA_Projects/0_GENERAL_PROJECTS/DATA BACK UPs_encrypted/${dir_backup}/nul"
if !_rc {
	gl dir_backup 				"X:/Box/IPA_GHA_Projects/0_GENERAL_PROJECTS/DATA BACK UPs_encrypted/${dir_backup}"
}
else {
	cap conf file 				"X:/Box/0_GENERAL_PROJECTS/DATA BACK UPs_encrypted/${dir_backup}/nul"
	if !_rc {
		gl dir_backup 			"X:/Box/0_GENERAL_PROJECTS/DATA BACK UPs_encrypted/${dir_backup}"
	}
	else {
		cap conf file 			"X:/Box/DATA BACK UPs_encrypted/${dir_backup}/nul"
		if !_rc {
			gl dir_backup 		"X:/Box/DATA BACK UPs_encrypted/${dir_backup}"
		}
		else {
			cap conf file 		"X:/Box/${dir_backup}/nul"
			if !_rc {
				gl dir_backup	"X:/Box/${dir_backup}"
			}
			else {
				cap conf file 	"${dir_backup}/nul"
				if !_rc {
					* verify that file is in IPA HFC Back up Dir
					if regexm("${dir_backup}", "X:") & regexm("${dir_backup}", "0_GENERAL_PROJECTS/DATA BACK UPs_encrypted") {
						gl dir_backup 	"${dir_backup}"
					}
				} 
				else if !regexm("${dir_backup}", "X:") & regexm("${dir_backup}", "0_GENERAL_PROJECTS/DATA BACK UPs_encrypted") {
					di as err "${dir_backup} is not Boxcryptor Directory"
					ex 601
				}
				else {
					#d;
					di as err 	"{p}folder ${dir_backup} not found.	This could be as a result of one of the following: {break}{p_end}"
						_column(5) "1. You have not synced the backup folder to your computer{break}"
						_column(5) "2. You do not have boxcryptor installed or you have an outdated boxcryptor{break}"
						_column(5) "3. You do not have the required boxcryptor access to the data back up folder"
					;
					#d cr
					ex 601			
				}
			}
		}
	}
}

/* -----------------------------------------------------------------------------
6.0 INCLUDE SURVEY ID IN KEEP VARS : DO NOT EDIT THIS
-------------------------------------------------------------------------------	*/

gl	varl_keep_vars		"${varl_keeplist_hfc} ${var_survey_id}" 
