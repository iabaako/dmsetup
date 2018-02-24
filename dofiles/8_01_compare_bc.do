/*
--------------------------------------------------------------------------------
Title		: RANDOMIZE FOR BACK CHECKS
Purporse	: This creates a random list of respondents for back checks
Ado(s)		: 
--------------------------------------------------------------------------------
*/

/* -----------------------------------------------------------------------------
1.0 List Type I Variables

Type 1 Vars: These should not change. They gauge whether the enumerator 
	performed the interview and whether it was with the right respondent. 
	If these are high, you must discuss them with your field team and consider
	disciplinary action against the surveyor and redoing her/his interviews.
-------------------------------------------------------------------------------	*/

#d;
local 	t1vars 
		""
		;
#d cr

/* -----------------------------------------------------------------------------
2.0 List Type II Variables
Type 2 Vars: These are difficult questions to administer, such as skip 
	patterns or those with a number of examples. The responses should be the  
	same, though respondents may change their answers. Discrepanices should be 
	discussed with the team and may indicate the need for additional training.
-------------------------------------------------------------------------------	*/

#d;
local 	t2vars 	
		""
		;
#d cr

/* -----------------------------------------------------------------------------
3.0 List Type III Variables
Type 3 Vars: These are key outcomes that you want to understand how 
	they're working in the field. These discrepancies are not used
	to hold surveyors accountable, but rather to gauge the stability 
	of the measure and how well your survey is performing. 
-------------------------------------------------------------------------------	*/

#d;
local 	t3vars 
		""
		;
#d cr

/* -----------------------------------------------------------------------------
4.0 ttest variables
	Compaire two-sample means for varlist in the back check and survey data using ttest
-------------------------------------------------------------------------------	*/
* ttest variables
#d;
loc 	ttest_vars
		""
		;
#d cr

/* -----------------------------------------------------------------------------
5.0 Run bcstats
-------------------------------------------------------------------------------	*/

* make directory
cap mkdir "${dir_bc_diffs}/`c(current_date)'"

#d;
bcstats, surveydata("${dir_survey}/${dta_survey}_post_hfc") 
bcdata("${dir_bc}/${dta_bc}_prepped") id("${var_survey_id}")
	enumerator("${var_enum_id}") 
	backchecker("${var_bcer_id}")
	enumteam("${var_team_id}")
	t1vars("`t1vars'") 	
	t2vars("`t2vars'")
	t3vars("`t3vars'")
	exclude(. "")
	keepbc("${varl_keeplist_bc}")
	ttest("`ttest_vars'")
	reliab("`t2vars' `t3vars'")
	nodiff(-999 "-999", -888 "-888") 
	filename("${dir_bc_diffs}/`c(current_date)'/${xlsx_bc_diffs}")
	showall
	upper 
	trim
	replace
	;
#d cr
