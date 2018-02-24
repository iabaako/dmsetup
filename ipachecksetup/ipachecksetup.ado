*! Version 1.0.0 Ishmail Azindoo Baako (IPA) Dec 13, 2017

cap version 	15.1
program define ipachecksetup
	#d;
	syntax 	using/, 
			OUTput(string) 
			[dontknow(real -999)
			refusal(real -888)
			specify(real -666)
			TEMPLate(string) 
			excluderepeats]
		;
	#d cr

	qui {
	
		* tempfiles
		tempfile _choices _survey 
		
		* check that file exist
		cap confirm file "`using'"
		if _rc == 601 {
			noi disp "File `using' not found"
			exit 601
		}

		* Download Input File
		* Use template if option template is specified
		if !missing("`template'") {
			copy 	"`template'" "`output'", replace
		}
		
		* If template is not specified, download template from IPA github repo
		else {
			* Download template if the user has internet connection
			cap copy 																								///		
				"https://raw.githubusercontent.com/PovertyAction/high-frequency-checks/master/xlsx/hfc_inputs.xlsx" ///
				"`output'", replace
			* Error if there is no internet connection
			if _rc == 631 {
				noi disp as error "Host not found: Check your internet connection or specify option template"
				exit 631
			}
		} 

		noi disp
		noi disp "Prefilling HFC Inputs ..."
		
		* 0. setup
			putexcel 	set "`output'", sheet("0. setup") modify
			putexcel 	B5 	= ("`output'") 					///
						B13	= ("submisssiondate")			///
						B16 = ("formdef_version")		
			
			putexcel	B6 	= ("PATH/hfc_output.xlsx") 		///
						B7 	= ("PATH/hfc_enumerators.xlsx")	///
						, font(calibri, 11, red)			

			noi disp "... 0. setup complete"
			
			putexcel clear
			
		* 2. duplicates
			* export key and a global for survey key into duplicates sheet
			putexcel 	set "`output'", sheet("2. duplicates") modify
			putexcel 	A2 = (char(36) + "{id}") A3 = ("key")
				
			noi disp "... 2. duplicates complete"
		
		* 04. no miss
		* Import inputs sheet
		import excel using "`using'", sheet("choices") first allstr clear
			drop if missing(value) 
		* save choices
		save `_choices', replace

		* Import inputs sheet
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
			keep if regexm(relevance, "`specify'") & !regexm(type, "begin") & type == "text"
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
			
	}

end
