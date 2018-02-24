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
use "${dir_mon}/${dta_mon_raw}", clear

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
		 username
		 caseid
		 ;
	#d cr

	* Destring Variables. Check if string variables can be changed to numeric. 
	* By default SCTO will import them as strings unless they have var lables
	ds, has (type string)
	foreach var of varlist `r(varlist)' {
		destring `var', replace
	}
			
	* Genarate start and end date variables
	gen startdate = dofc(starttime)
	gen enddate = dofc(endtime)
	format startdate enddate %td
	
	* carryforward the last name for each enumerator and monitor
	* This is take care if situations were names were different over periods
	sort enumerator_id submissiondate
	by enumerator_id: gen index = _n
	levelsof enumerator_id, loc (ids) clean
	foreach id in `ids' {
		su index if enumerator_id == `id'
		levelsof enumerator_name if enumerator_id == `id' & index == `r(max)', ///
			loc (enum_name) clean
		replace enumerator_name = "`enum_name'" if enumerator_id == `id'
	}
			
	sort mon_id submissiondate
		drop index
		by mon_id: gen index = _n
		levelsof mon_id, loc (ids) clean
		foreach id in `ids' {
			su index if mon_id == `id'
			levelsof mon_name if mon_id == `id' & index == `r(max)', 	 ///
				loc (mon_name) clean
			replace mon_name = "`mon_name'" if mon_id == `id'
	}
	
	* change enum and mon names to proper format
	replace enumerator_name = proper(enumerator_name)
	replace mon_name = proper(mon_name)
	drop index
	
	* drop duplicates. Drop newer observations that for duplicates
	* An observation is considered a duplicate if it was submitted by a monitor
	* for the same enumerator and has the same starttime
	duplicates drop mon_id enumerator_id starttime, force
	
/* -----------------------------------------------------------------------------
3.0 ADDITIONAL PREPARATIONS
	* Include additional preparation code here
------------------------------------------------------------------------------	*/


/* -----------------------------------------------------------------------------
4.0 Save Prepped Dataset
------------------------------------------------------------------------------	*/
save "${dir_mon}/${dta_mon}_prepped", replace
