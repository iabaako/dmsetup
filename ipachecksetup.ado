*! Version 1.0.0 Ishmail Azindoo Baako (IPA) 24feb2018

version 	13.0
program define ipachecksetup
	#d;
	syntax	using/, template(string) outfile(string) [osp(real -666) REFusal(real -888) DONTKnow(real -999) replace long wide] 
		;
	#d cr

	qui {
		* tempfiles
		tempfile _choices _survey 

			* import choices data
			import excel using "`using'", sheet("choices") first allstr clear
				drop if missing(value) 
			* save choices
			save `_choices', replace
		
			* import survey
			import excel using "`using'", sheet("survey") firstrow allstr clear
			drop if missing(type) | regexm(disabled, "[Yy][Es][Ss]")
			save `_survey'

		* check if form includes repeat groups and ask user to specify long or wide option
		if "`long'`wide'" == "" {
			cap assert !regexm(type, "begin repeat|end repeat")
			if _rc {
				disp as err "must specify either long or wide option. XLS form contains repeat groups"
				exit 198 
			}
		}

		* check that both long and wide formats are not specified
		if "`long'" ~= "" & "`wide'" ~= "" {
			disp as err "options long and wide are mutually exclusive"
			exit 198
		}


		* Mark beginning and end of groups and repeats
		count if regexm(type, "group|repeat")

		gen grp_var 	= .
		gen rpt_grp_var = .

		gen begin_row 		= .
		gen begin_fieldname = ""
		gen end_row			= .
		gen end_fieldname 	= ""

		if `r(N)' > 0 {
			
			* generate _n to mark groups
			gen _sn = _n
			
			* get the name of all begin groups|repeat and check if the name if their pairs match
			levelsof _sn if (regexm(type, "^(begin)") & regexm(type, "group|repeat")), ///
				loc (_sns) clean
			
			count if (regexm(type, "^(begin)") & regexm(type, "group|repeat"))
			loc b_cnt `r(N)'
			count if (regexm(type, "^(end)") & regexm(type, "group|repeat"))
			loc e_cnt `r(N)'
			
			if `b_cnt' ~= `e_cnt' {
				di as err "Error in XLS form: There are `b_cnt' begin types and `e_cnt' end types"
				exit 198
			}
		
			foreach _sn in `_sns' {	

				if regexm(type[`_sn'], "group") loc gtype "grp"
				else loc gtype "rpt_grp"

				loc b 1
				loc e 0
				loc curr_sn `_sn'
				loc stop 0
				while `stop' == 0 {
					loc ++curr_sn 
					cap assert regexm(type, "^(end)") & regexm(type, "group|repeat") in `curr_sn'
					if !_rc {
						loc ++e
						if `b' == `e' {
							loc end `curr_sn'
							loc stop 1
						}
					}
					else {
						if "`gtype'" == "grp" replace grp_var = 1 in `curr_sn'
						if "`gtype'" == "rpt_grp" replace rpt_grp_var = 1 in `curr_sn'
						cap assert regexm(type, "^(begin)") & regexm(type, "group|repeat") in `curr_sn'
						if !_rc loc ++b
					}
				}

				replace begin_row 		= 	_sn[`_sn']		in `_sn'
				replace begin_fieldname =	name[`_sn']		in `_sn'
				replace end_row 		= 	_sn[`end']		in `_sn'
				replace end_fieldname 	=	name[`end']		in `_sn'
			}

			replace grp_var 	= 0 if missing(grp_var)
			replace rpt_grp_var = 0 if missing(rpt_grp_var)

			replace name = subinstr(name, "*", "", .) if (regexm(type, "^(begin)") & regexm(type, "group|repeat")) in `curr_sn'
		}
		
		* Check form for repeat groups and mark all repeat group variables
			
		* drop all repeat variables if long option is used
		if "`long'" ~= "" {
			drop if rpt_grp_var
			replace _sn = _n
		}
			
		* include a wild card in repeat var names if option excluderepeats is not used
		if  "`wide'" ~= "" replace name = name + "*" if rpt_grp_var

		save `_survey', replace

		noi disp
		noi disp "Prefilling HFC Inputs ..."
		
		copy "`template'" "`outfile'", replace
	
		* 04. no miss
		
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
		export excel name label using "`outfile'", 							///
				sheet("4. no miss") sheetmodify cell(A2)
		noi disp "... 4. no miss complete"
		
		* 06. logic
		use `_survey', clear
		
		* Add group|repeat relevance to individual field within groups

		gen if_condition = ""
		replace relevance = subinstr(relevance, "$", "", .) if !missing(relevance)
		levelsof _sn if !missing(relevance) & regexm(type, "begin group|begin repeat"), ///
			loc (groups) clean
		foreach group in `groups' {
			gen n = _n
			loc start 	= _sn[`group']
			loc end 	= _sn[`group']
			loc relevance = relevance[`start']
			replace if_condition = if_condition + "\(" + "`relevance'" + ")" in `start'/`end'
			drop n
		}
			
		* drop all field without relevance
		drop if missing(relevance) | type == "note" | regexm(type, "group|repeat")

		* to cater for no spaces in programming, add white space to either side of =
		* trim excess whitespace, change = to ==
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
			replace `var' = subinstr(`var', "\", " & ", .)
			replace `var' = subinstr(`var', "not(", "!(", .)
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
		replace assertion = "!missing(" + name + ")" ///
											if missing(assertion) & ///
											!inlist(type, "begin group", "end group", "begin repeat", "end repeat")
												
		* export variables to skip sheet. 
		export excel name label assertion if_condition using "`outfile'", sheet("6. logic") sheetmodify cell(A2)
		noi disp "... 6. logic"
		
		* 8. constraints
		use `_survey', clear
		keep type name label constraint		
			* keep only fields with contraints
			keep if !missing(constraint)

			* export variable names, label and constraints to first column A
			if `=_N' > 0 {
				export excel name label constraint using "`outfile'", ///
					sheet("8. constraints") sheetmodify cell(A2)
				noi disp "... 8. constraint complete"
			}
			
		* 9. specify
		use `_survey', clear
		keep type name relevance		
			keep if regexm(relevance, "`osp'") & !regexm(type, "begin") & type == "text"
			if `=_N' > 0 {
				* rename name child and keep only needed variables
				ren (name) (child)
				keep child relevance
				* generate parent
				replace relevance = trim(itrim(relevance))
				gen parent = substr(relevance, strpos(relevance, "$") + 2, strpos(relevance, "}") - strpos(relevance, "$") - 2)

				* Export child and parent variables
				export excel child parent using "`outfile'", sheet("9. specify") sheetmodify cell(A2)
				noi disp "... 9. specify complete"
			}
			
		* 11. outliers
		use `_survey', clear
		keep type label name 		
			* keep only integer and decimal fields
			keep if type == "decimal" | type == "integer"
			* Export variable names and multiplier
			if `=_N' > 0 {
				export excel name label using "`outfile'", sheet("11. outliers") sheetmodify cell(A2)
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

			* Export dk and refusal vars
			export excel name using "`outfile'", sheet("enumdb") sheetmodify cell(A2)

		* export missing rate
		use `_survey', clear
		gen include_grp = 0
		replace relevance = subinstr(relevance, "$", "", .) if !missing(relevance)
		levelsof _sn if !missing(relevance) & regexm(type, "begin group|begin repeat"), ///
			loc (groups) clean
		foreach group in `groups' {
			loc start 	= _sn[`group']
			loc end 	= _sn[`group']
			replace include_grp = 1 in `start'/`end'
		}

		keep if include_grp | (!missing(relevance) & regexm(type, "note|begin group|end group"))
		* Export missing var rate and refusal vars
			export excel name using "`outfile'", sheet("enumdb") sheetmodify cell(B2)

		* export other specify
		use `_survey', clear
		export excel name using "`outfile'" if regexm(relevance, "`osp'"), sheet("enumdb") sheetmodify cell(D2)
	}

end
