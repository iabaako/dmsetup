*! Version 1.0.0 Ishmail Azindoo Baako (IPA) 24feb2018

version 	13.0
program define ipachecksetup
	#d;
	syntax 	,inpath(string) surveyxls(string) surveyid(name) enumid(name) geocluster(name)
			[outpath(string) backuppath(string) outfile(string)]
			[bcxls(string) monxls(string)]
			[bcerid(string)]
			[keephfc(string) keepbc(string)]
			[server(string)]
			[ss(integer 0) bcperc(integer 10) dk(real -999) ref(real -888) osp(real -666)	na(real -111)]
			[excluderepeats] replace
		;
	#d cr

	qui {
		* Check syntax: Check that outfile or outfile is specified
		if "`outpath' `outfile'" == "" {
			noi disp as err "must specify either outpath or outfile option"
			err 198
		}
		else if "`outpath'" ~= "" & "`outfile'" ~= "" {
			noi disp as err "options outpath and outfile are mutually exclusive"
		}

		* tempfiles
		tempfile _choices _survey 
		
		* check that file exist
		cap confirm file "`using'"
		if _rc == 601 {
			noi disp "File `using' not found"
			err 601
		}
		
		* Setup folder structure. And set up outfile
		if "`outpath'" ~= "" {
			* Create folder structure 
			* Create. Main folders must come befor subfolders
			#d;
			loc folders 
				""00_archive"
				"01_instruments"
					"01_instruments/01_paper"
					"01_instruments/02_scto_print"
					"01_instruments/03_scto_xls"
				"02_dofiles"
					"02_dofiles/01_background"
				"03_tools_logs"
					"03_tools_logs/01_tools"
					"03_tools_logs/02_outputs_encrypted"
						"03_tools_logs/02_outputs_encrypted/01_hfcs"
						"03_tools_logs/02_outputs_encrypted/02_bc_list"
						"03_tools_logs/02_outputs_encrypted/03_bc_diffs"
						"03_tools_logs/02_outputs_encrypted/04_monitoring"
					"03_tools_logs/03_logs"
				"04_data_encrypted"
					"04_data_encrypted/01_preloads"
					"04_data_encrypted/02_survey"
					"04_data_encrypted/03_bc"
					"04_data_encrypted/04_field_monitoring"
					"04_data_encrypted/05_replacements"
					"04_data_encrypted/06_clean"
				"05_data_no_pii"
				"06_media_encrypted"
					"06_media_encrypted/01_audio"
					"06_media_encrypted/02_pictures"
					"06_media_encrypted/03_videos"
				"07_documentation""
				;
			#d cr
		
			* Display message 
			noi disp
			noi disp "Settinp Up Folders ..."
			noi disp

			* Loop through each folder name, check if folder exist, create/skip and return message
			foreach folder in `folders' {
				* Check that folder already exist
				cap confirm file "`outpath'/`folder'/nul"
				* If folder exist, return message that folder already exist, else create folder
				if !_rc {
					noi disp "{red:Skipped}: Folder `folder' already exist"
				}
				* else create folder
				else {
					mkdir "`outpath'/`folder'"
					noi disp "Successful: Folder `folder' created"
				}
			}
			
			* download sample dofiles into various folders
			* 3_01_set_globals
			* import survey, bc and mon titles
			import excel using "`inpath'/`surveyxls'", sheet("settings") firstrow clear
			loc dtasurvey = form_title[1]
			if "`bcxls'" ~= "" {
				import excel using "`inpath'/`bcxls'", sheet("settings") firstrow clear
				loc dtabc = form_title[1]
			}
			if "`monxls'" ~= "" {
				import excel using "`inpath'/`monxls'", sheet("settings") firstrow clear
				loc dtamon = form_title[1]
			}
			
			* define replacements
			#d;
			loc pairs
				""ins_dir_backup 			`backuppath'"
				 "ins_xlsx_survey_xls		`surveyxls'"
				 "ins_xlsx_mon_xls			`monxls'"
				 "ins_xlsx_bc_xls			`bcxls'"
				 "ins_dta_survey_raw		`dtasurvey'"
				 "ins_dta_bc_raw			`dtabc'"
				 "ins_dta_mon_raw			`dtamon'"
				 "ins_var_survey_id			`surveyid'"
				 "ins_var_enum_id			`enumid'"
				 "ins_var_bcer_id			`bcerid'"
				 "ins_var_geo_cluster		`geocluster'"
				 "ins_varl_keeplist_hfc		`keephfc'"
				 "ins_varl_keeplist_bc		`keepbc'"
				 "ins_val_ss				`ss'"
				 "ins_val_dk				`dk'"
				 "ins_val_rf				`rf'"
				 "ins_val_osp				`osp'"
				 "ins_val_na				`na'"
				 "ins_val_bc_perc			`bcperc'"
				 "ins_txt_scto_server		`server'""
				;
			#d cr
			
			noi disp 
			noi disp "{title:Copying sample files into folders ...}"
			noi disp "{ul:from}" _column(30) "{ul:to}"

			copy 																						///		
				"https://raw.githubusercontent.com/iabaako/dmsetup/master/dofiles/3_01_set_globals.do"  ///
				"`outpath'/02_dofiles/01_background/3_01_set_globals_tmp.do", replace

			* Make replacements
			foreach pair in `pairs' {
				token `pair'
				loc fromtxt 	"`1'"
				macro shift
				loc totxt 		"`*'"
				
				filefilter  "`outpath'/02_dofiles/01_background/3_01_set_globals_tmp.do"  	///
							"`outpath'/02_dofiles/01_background/3_01_set_globals.do", 		///
							from("`fromtxt'") to("`totxt'") replace
							
				copy "`outpath'/02_dofiles/01_background/3_01_set_globals.do" 				///
					 "`outpath'/02_dofiles/01_background/3_01_set_globals_tmp.do", replace
			}
			
			rm "`outpath'/02_dofiles/01_background/3_01_set_globals_tmp.do"
			noi disp "3_01_set_globals.do" _column(30) "02_dofiles/01_background/3_01_set_globals.do"

			#d;
			loc dofiles 
				"5_01_prepare_survey
				 5_02_prepare_bc
				 5_03_prepare_mon
				 6_01_master_check
				 6_e1_psemail_profile
				 7_01_randomize_bc
				 8_01_compare_bc"
				;
			#d cr
			
			foreach do in `dofiles' {
				copy 																			///		
					"https://raw.githubusercontent.com/iabaako/dmsetup/master/dofiles/`do'.do"  ///
					"`outpath'/02_dofiles/01_background/`do'.do", replace
					noi disp "`do'.do" _column(30) "02_dofiles/01_background/`do'.do"
			}
			
			copy 																				  ///		
				"https://raw.githubusercontent.com/iabaako/dmsetup/master/dofiles/master_run.do"  ///
				"`outpath'/02_dofiles/master_run.do", replace
				noi disp "master_run.do" _column(30) "02_dofiles/master_run.do"

			copy 																					 ///		
				"https://raw.githubusercontent.com/iabaako/dmsetup/master/xlsx/hfc_enumerators.xlsx" ///
				"`outpath'/03_tools_logs/01_tools/hfc_enumerators.xlsx", replace
				noi disp "hfc_enumerators.xlsx" _column(30) "03_tools_logs/01_tools/hfc_enumerators.xlsx"
			
			copy 																					///		
				"https://raw.githubusercontent.com/iabaako/dmsetup/master/xlsx/hfc_text_audit.xlsx" ///
				"`outpath'/03_tools_logs/01_tools/hfc_text_audit.xlsx", replace
				noi disp "hfc_text_audit.xlsx" _column(30) "03_tools_logs/01_tools/hfc_text_audit.xlsx"

			copy 																					  ///		
				"https://raw.githubusercontent.com/iabaako/dmsetup/master/xlsx/hfc_replacements.xlsx" ///
				"`outpath'/04_data_encrypted/05_replacements/hfc_replacements.xlsx", replace
				noi disp "hfc_replacements.xlsx" _column(30) "04_data_encrypted/05_replacements/hfc_replacements.xlsx"
		} 		

		noi disp
		noi disp "Prefilling HFC Inputs ..."
		
		copy 																				///		
			"https://raw.githubusercontent.com/iabaako/dmsetup/master/xlsx/hfc_inputs.xlsx" ///
			"`outpath'/03_tools_logs/01_tools/hfc_inputs.xlsx", replace
		
		loc output "`outpath'/03_tools_logs/01_tools/hfc_inputs.xlsx"
		loc using  "`inpath'/`surveyxls'"
					
		* 2. duplicates
			* export key and a global for survey key into duplicates sheet
			putexcel 	set "`output'", sheet("2. duplicates") modify
			putexcel 	A2 = (char(36) + "{id}")
				
			noi disp "... 2. duplicates complete"

		* 04. no miss
		* Import choices sheet from xls form
		import excel using "`using'", sheet("choices") first allstr clear
			drop if missing(value) 
		* save choices
		save `_choices', replace

		* Import survey sheet of xls form
		import excel using "`using'", sheet("survey") first allstr clear
			gen row = _n
			drop if missing(type) | regexm(disabled, "[Yy][Es][Ss]")
		* save dta copy
		save `_survey', replace
		
		* Find variables to be added to no miss
		drop if inlist(type, "deviceid", "subscriberid", "simserial", "phonenumber", "username", "caseid")
		* drop all variables in groups and repeats that have relevance expressions
		loc repeat 9
		while `repeat' == 9 { 
			gen n = _n
			levelsof name if !missing(relevance) & regexm(type, "begin"), ///
				loc (variables) clean 
			loc variable: word 1 of `variables'
			levelsof n if name == "`variable'", loc (indexes)
			loc start: 	word 1 of `indexes'
			loc end:	word 2 of `indexes'
			drop in `start'/`end'
				
			cap assert missing(relevance) if regexm(type, "begin")
			loc repeat `=_rc'
			drop n
		}

		* keep only required or scto always generated vars
		replace required = lower(required)
		keep if regexm(required, "[Yy][Ee][Ss]") | inlist(name, "starttime", "endtime", "duration")
		* drop all notes and fields with no relevance
		drop if type == "note" | !missing(relevance)
		* export variables to nomiss sheet. The first 2 cells will already contain key and skey
		export excel name using "`output'", 							///
				sheet("4. no miss") sheetmodify cell(A2)
		noi disp "... 4. no miss complete"
		
		* 06. skip
		use `_survey', clear
		
		* Check form for repeat groups and mark all repeat group variables
		cap assert type != "begin repeat"
		if _rc {
			gen repeat 		= ""
			gen nrpt_count 	= 0
			
			* save repeat names in local repeats
			levelsof name if type == "begin repeat", loc (rpts) clean
			
			* mark repeat variables
			foreach rpt in `rpts' {
				levelsof row if type == "begin repeat" 	& name == "`rpt'", loc (start) 	clean
				levelsof row if type == "end repeat" 	& name == "`rpt'", loc (end) 	clean

				replace repeat 		= "`rpt'" 	if inrange(row, `start', `end')
				loc ++start
				loc --end 

				count 							if inrange(row, `start', `end') & inlist(type, "begin repeat") 

				if `r(N)' > 0 replace nrpt_count = `r(N)'		if inrange(row, `start', `end') ///
																& !inlist(type, "begin group", "end group", "begin repeat", "end repeat")
			}
			
			* drop all repeat variables if option exclude repeats is used
			if !missing("`excludetrepeats'") drop if !missing(repeat)
			
			* include a wild card in repeat var names if option excluderepeats is not used
			if  missing("`excludetrepeats'") replace name = name + "*" if !mi(repeat)
		}
		
		* save survey without repeat
		save `_survey', replace

			* To create if conditions, get the names of all groups with relevance and 
			* append group relevance together
			gen if_condition = ""
			replace relevance = subinstr(relevance, "$", "", .) if !missing(relevance)
			levelsof name if !missing(relevance) & regexm(type, "begin group"), ///
				loc (groups) clean
			foreach group in `groups' {
				gen n = _n
				levelsof n if name == "`group'", loc (indexes)
				loc start: word 1 of `indexes'
				loc end:word 2 of `indexes'
				loc relevance = relevance[`start']
				replace if_condition = if_condition + "\(" + "`relevance'" + ")" in `start'/`end'
				drop n
			}

			* drop all field without relevance
			drop if missing(relevance) | type == "note" | regexm(type, "group|repeat")
			* to cater for no spaces in programming, add white space to either side of 
			* = and trim excess whitespace and change to ==
			foreach var of varlist relevance if_condition {
				replace `var' = trim(itrim(subinstr(`var', "=", " # ", .)))
				replace `var' = subinstr(`var', "'", char(34), .)
				replace `var' = subinstr(`var', "> # ", ">= ", .)
				replace `var' = subinstr(`var', "< # ", "<= ", .)
				replace `var' = subinstr(`var', "! # ", "!= ", .)
				replace `var' = subinstr(`var', "{", "", .)
				replace `var' = subinstr(`var', "}", "", .)
				replace `var' = subinstr(`var', " and ", " & ", .)
				replace `var' = subinstr(`var', " or ", " | ", .)
				replace `var' = subinstr(`var', "\(", "", 1)
				replace `var' = subinstr(`var', "\", " & ", .)
				replace `var' = subinstr(`var', " div ", "/", .)
				replace `var' = subinstr(`var', ")", "", 1) if strpos(`var', "(") == 0 ///
					| (strpos(`var', "(") > strpos(`var', ")"))
				
				loc repeat = 9
				while `repeat' == 9 {
					gen sub = substr(`var', (strpos(`var', "#") + 2), 1)
					replace `var' = subinstr(`var', "#", "==", 1) if ///
						regexm(sub, "[0-9]|[-]") | regexm(sub, char(34))
					replace `var' = subinstr(`var', "#", "=", 1) if ///
						regexm(sub, "[a-zA-Z]") | regexm(sub, char(34))
					cap assert !regexm(`var', "#")
					loc repeat `=_rc'
					drop sub
				}
				* change selected and selected-at with regexm
				replace `var' = subinstr(`var', "count-selected", "wordcount", .)
				replace `var' = subinstr(`var', "selected-at", "regexm", .)
				replace `var' = subinstr(`var', "selected", "regexm", .)
				
			}
			* add relevance to if condition
			replace if_condition = if_condition + " & (" + relevance + ")" if !missing(if_condition)
			replace if_condition = relevance if missing(if_condition)
			
			* generate assertion. Assert for non-missing in all. Manual edits will be needed for addional
			* assertions required
				gen assertion = name + " == ."  if regexm(type, "integer|select_one")
			replace assertion = name + " == " + char(34) + char(34) ///
												if regexm(type, "text|select_multiple")
			replace assertion = "!missing(" + name + ")" ///
												if missing(assertion) & ///
												!inlist(type, "begin group", "end group", "begin repeat", "end repeat")
												
			* export variables to skip sheet. 
			export excel name assertion if_condition using "`output'", sheet("6. skip") sheetmodify cell(A2)
			noi disp "... 6. skip complete"

		* 8. constraints
		use `_survey', clear
		keep type name label constraint		
			* keep only fields with contraints
			keep if !missing(constraint)

			* export variable names, label and constraints to first column A
			if `=_N' > 0 {
				export excel name label constraint using "`output'", ///
					sheet("8. constraints") sheetmodify cell(A2)
				noi disp "... 8. constraint complete"
			}
			
		* 9. specify
		use `_survey', clear
		keep type name relevance		
			* keep only fields with conatraints. Exclude groups and repeats
			keep if regexm(relevance, "`osp'") & !regexm(type, "begin") & type == "text"
			if `=_N' > 0 {
				* rename name child and keep only needed variables
				ren (name) (child)
				keep child relevance
				* generate parent
				replace relevance = trim(itrim(relevance))
				gen parent = substr(relevance, strpos(relevance, "$") + 2, strpos(relevance, "}") - strpos(relevance, "$") - 2)

				* Export child and parent variables
				export excel child parent using "`output'", sheet("9. specify") sheetmodify cell(A2)
				noi disp "... 9. specify complete"
			}

		* 11. outliers
		use `_survey', clear
		keep type label name 		
			* keep only integer and decimal fields
			keep if type == "decimal" | type == "integer"
			* Export variable names and multiplier
			if `=_N' > 0 {
				export excel name label using "`output'", sheet("11. outliers") sheetmodify cell(A2)
				noi disp "... 11. outliers complete"
			}
			
		* enumdb
		* Import choices
		use `_choices', clear
			* keep only list_name and value fields
			keep list_name value
			* get names of list_names with rf | dk
			levelsof list_name if value == "`refusal'" | value == "`dontknow'", loc (dkrf_opts)
		* Import survey
		use `_survey', clear
		keep type name 
			* Drop group names
			drop if regexm(type, "group")
			* Loop through and mark variables with dk ref opts
			gen dkref_var = 0
			foreach opt in `dkrf_opts' {
				replace dkref_var = 1 if regexm(type, "`opt'")
			}
			
			* keep only dkref vars and text fields
			keep if dkref_var == 1 | type == "text"

			* Export don't and refusal vars
			export excel name using "`output'", sheet("enumdb") sheetmodify cell(A2)

		* Import survey
		use `_survey', clear
		keep type name required
			* Drop group names
			drop if regexm(type, "group") | type == "note"
			* keep only required fields
			keep if !missing(required)
			* Export variables to check for missing rates
			export excel name using "`output'", sheet("enumdb") sheetmodify cell(B2)
			noi disp "... enumdb complete"
			
		* text audit
		use `_survey', clear
		keep if inlist(type, "begin group", "begin repeat")
		export excel name using "`output'", sheet("text audit") sheetmodify cell(A2)
			noi disp "... text audit complete"
	}

end
