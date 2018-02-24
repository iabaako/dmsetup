*! version 2.0.0 Christopher Boyer 01feb2018

/* =============================================================== 
   ===============================================================
   ============== IPA HIGH FREQUENCY CHECK TEMPLATE  ============= 
   ===============================================================
   =============================================================== */

/* overview:
   this file contains the following data quality checks...
     1. Check that all interviews were completed
     2. Check that there are no duplicate observations
     3. Check that all surveys have consent
     4. Check that certain critical variables have no missing values
     5. Check that follow up record ids match original
     6. Check skip patterns and survey logic
     7. Check that no variable has all missing values
     8. Check hard/soft constraints
     9. Check specify other vars for items that can be included
     10. Check that date values fall within survey range
     11. Check that there are no outliers for unconstrained vars */
	 

/* =============================================================== 
   ================== Import globals from Excel  ================= 
   =============================================================== */
 
ipacheckimport using "hfc_inputs.xlsx"

/* =============================================================== 
   ================= Replacements and Corrections ================ 
   =============================================================== */

use "${dataset}", clear

* recode don't know/refusal values
ds, has(type numeric)
local numeric `r(varlist)'
if !mi("${mv1}") recode `numeric' (${mv1} = .d)
if !mi("${mv2}") recode `numeric' (${mv2} = .r)
if !mi("${mv3}") recode `numeric' (${mv3} = .n)

ipacheckreadreplace using "${repfile}", ///
	id(${id}) 							///
	variable(variable) 					///
	value(value) 						///
	newvalue(newvalue) 					///
	action(action) 						///
	logusing("${replog}") 				///
	sheet("hfc_replacements")

/* =============================================================== 
   ==================== Survey Tracking ==========================
   =============================================================== */

 /* <============ Track 1. Summarize completed surveys by date ============> */

      /* the command below creates a summary page for the HFC 
      output showing stats on survey completion by submission 
	  date */


ipatracksummary using "${outfile}", submit(${date}) target(${target}) 

/* <========== Track 2. Track surveys completed against planned ==========> */

      /* the command below creates a table showing the num of 
	  surveys completed, num of surveys planned, and num of 
	  surveys remaining in each given unit (e.g. by region, 
	  district, etc.). It also shows the date of the first
	  survey completed in that unit and the date of the last
	  
	  * Note
		* If variable names for units and id differ in sample dataset, use
			options s_id and s_unit to specify varnames in sample data 
		* command will break if dataset in is not unique on id. Use the following
		options if neccesary:
			* includedups - count duplicates as different observations
			* ignoredups - count duplicates as single observation
	  */

ipatracksurveys using "${outfile}", unit(${geounit}) ///
	id(surveyid) submit(${date}) sample("${master}") ///
	includedups

 /* <======== Track 3. Track form versions used by submission date ========> */

      /* the command below creates a table showing the num of 
	  each form version used on each submission date. For the 
	  most recent submission date, if any entries didn't use the
	  latest form version, the id and enumerator is listed below
	  the table */


ipatrackversions ${formversion}, id(${id}) 	///
	enumerator(${enum}) 					///
	submit(${date}) 						///
    saving("${outfile}") 
 
/* =============================================================== 
   ==================== High Frequency Checks ==================== 
   =============================================================== */

/* <=========== HFC 1. Check that all interviews were completed ===========> */ 
ipacheckcomplete, compvars(${variable1}) 	///
	complete(${complete_value1}) 			///
	condition(${if_condition1}) 			///
	id(${id}) 								///
	enumerator(${enum}) 					///
	submit(${date}) 						///
	keepvars("${keep1}") 					///
	saving("${outfile}") 					///
	sheetreplace ${nolabel}

/* <======== HFC 2. Check that there are no duplicate observations ========> */
ipacheckdups ${variable2}, id(${id}) 		///
	enumerator(${enum}) 					///
	submit(${date}) 						///
	keepvars(${keep2}) 						///
	saving("${outfile}") 					///
	sheetreplace ${nolabel}
  
/* <============== HFC 3. Check that all surveys have consent =============> */
ipacheckconsent ${variable3}, 				///
	consentvalue(${consent_value3}) 		///
	id(${id}) 								///
	enumerator(${enum}) 					///
	submit(${date}) 						///
	keepvars(${keep3}) 						///
	saving("${outfile}") 					///
	sheetreplace ${nolabel}

/* <===== HFC 4. Check that critical variables have no missing values =====> */
ipachecknomiss ${variable4}, id(${id}) 		/// 
	enumerator(${enum})						///
	submit(${date}) 						///
	keepvars(${keep4}) 						///
	saving("${outfile}") 					///
	sheetreplace ${nolabel}	
	
/* <======== HFC 5. Check that follow up record ids match original ========> 
ipacheckfollowup ${variable5} using ${master},	///
	id(${id})				 					///
	enumerator(${enum}) 						///
	submit(${date}) 							///
	saving("${outfile}")	 					///
	sheetreplace
}
*/
/* <============= HFC 6. Check skip patterns and survey logic =============> */
ipacheckskip ${variable6}, assert(${assert6}) 	///
	condition(${if_condition6})					///
	id(${id}) 									///
	enumerator(${enum}) 						///
	submit(${date}) 							///
	keepvars(${keep6}) 							///
	saving("${outfile}") 						///
	sheetreplace ${nolabel}

 /* <======== HFC 7. Check that no variable has all missing values =========> */
ipacheckallmiss ${variable7}, id(${id}) 		///
	enumerator(${enum}) 						///
	saving("${outfile}")						///
	sheetreplace ${nolabel}

/* <=============== HFC 8. Check for hard/soft constraints ================> */
ipacheckconstraints ${variable8}, 
	smin(${soft_min8}) 							///
	smax(${soft_max8}) 							///
	id(${id}) 									///
	enumerator(${enum}) 						///
	submit(${date}) 							///
	keepvars(${keep8}) 							///
	saving("${outfile}") 						///
	sheetreplace ${nolabel}

/* <================== HFC 9. Check specify other values ==================> */
ipacheckspecify ${child9}, 						///
	parentvars(${parent9}) 						///
	id(${id}) 									///
	enumerator(${enum}) 						///
	submit(${date}) 							///
	keepvars(${keep9}) 							///
	saving("${outfile}") 						///
	sheetreplace ${nolabel}

/* <========== HFC 10. Check that dates fall within survey range ==========> */
ipacheckdates ${startdate10} ${enddate10},		/// 
	surveystart(${surveystart10}) 				///
	id(${id}) 									///
	enumerator(${enum})							///
	submit(${date})								///
	keepvars(${keep10})							///
	saving("${outfile}")						///
	sheetreplace ${nolabel}		 

/* <============= HFC 11. Check for outliers in unconstrained =============> */
ipacheckoutliers ${variable11}, id(${id}) 		///
	enumerator(${enum}) 						///
	submit(${date}) 							///
	multiplier(${multiplier11}) 				///
	keepvars(${keep11}) 						///
	ignore(${ignore11}) 						///
	saving("${outfile}") 						///
	sheetreplace ${nolabel} ${sd}

/* <============= HFC 12. Check for and output field comments =============> */
ipacheckcomment ${fieldcomments}, id(${id}) 	///
	media(${sctomedia}) 						///
	enumerator(${enum}) 						///
	submit(${date}) 							///
	keepvars(${keep12}) 						///
	saving("${outfile}") 						///
	sheetreplace ${nolabel}
 
/* ===============================================================
   ================= Create Enumerator Dashboard =================
   =============================================================== */

ipacheckenum ${enum} using "${enumdb}", 		///
	dkrfvars(${dkrf_variable12}) 				///
	missvars(${missing_variable12}) 			///
	durvars(${duration_variable12}) 			///
	exclude(${exclude_variable12}) 				///
	subdate(${submission_date12})
 
/* ===============================================================
   ================== Create Research Dashboard ==================
   =============================================================== */

* tabulate one-way summaries of important research variables
ipacheckresearch using "${researchdb}", 		///
	variables(${variablestr13})

* tabulate two-way summaries of important research variables
ipacheckresearch using "${researchdb}", 		///
	variables(${variablestr14}) by(${by14}) 

/* ===============================================================
   ========================= Text Audits =========================
   =============================================================== */

* output summaries for text audits  
ipachecktextaudit ${textaudit} using "${textauditdb}", 	///
	media("${sctomedia}") 								///
	enumerator(${enum}) 								///
	keepvars(${keep15})
   
/* ===============================================================
   ====================== Rename Media Files =====================
   =============================================================== */
/*
remedia audio_audio ///
  if audio_consent == 1, ///
  by(hhiddistrict date) ///
  id(${var_survey_id}) ///
  enum(${var_enum_id}) ///
  from("${dir_survey}/media") ///
  to(${${dir_audio}) ///
  reso(${id})
*/
/* ===============================================================
   ========================= Backup Data =========================
   =============================================================== */

#d;
loc datasets 
	""${dir_survey}/${dta_survey_raw}"
	"${dir_survey}/${dta_survey}_prepped"
	"${dir_survey}/${dta_survey}_post_hfc""
    ;
#d cr

cap mkdir "${dir_backup}/`c(current_date)'"

noi di "Backing Up datasets"
foreach data in `datasets' {
	loc saveas = subinstr("`data'", "${dir_survey}/", "", 1)
	copy "`data'.dta" "${dir_backup}/`c(current_date)'/`saveas'.dta", replace
	noi di "... `data' backup completed"
}

/* ===============================================================
   ========================= Email Dashboards ====================
   =============================================================== */

* setup psemail
do "${dir_do_background}/${do_ps_profile}"

#d;
loc mail_list 
	"iabaako@poverty-action.org"
	;
#d cr

foreach email in `mail_list' {
	psemail_v2 `email', s("HFC Enumerator Dashboard - `c(current_date)'") ///
		b("HFC for ${form_id} succesfully run on `c(current_date)' by `c(username)'.`r`n Please find attached HFC enumerator dashboard") ///
		a("${dir_hfc}/`c(current_date)'/${xlsx_hfc_enum_db}")
		
	sleep 10000
}
