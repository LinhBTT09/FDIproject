*------------------------------------------------------
* Construct the panel data for FDI project
*------------------------------------------------------
*
clear
set more off

/* path for the input */
               if c(username) == "buithithuylinh" {

                               cd "D:\Dropbox (GEMMES - VN)\WorkingEC" 


               }       
			   * output

               if c(username) == "buithithuylinh" {

                               global outputdata "D:\Linh\project FDI\Output"

               } 

*---------------------------------------------------
*--- I-O table
*---------------------------------------------------
import excel "D:\Linh\project FDI\viet-nam-I-O.xlsx", sheet("code") firstrow clear
destring CodeADB, replace
destring CodeVSIC,replace
duplicates drop CodeVSIC, force
save "$outputdata/IO_code.dta",replace


import excel "D:\Linh\project FDI\viet-nam-I-O.xlsx", sheet("matrix") firstrow clear	
reshape long c, i(id) j(input)
rename id output
drop if output < 3| output >17
drop if input < 3| input >17
save "$outputdata/IO_matrix.dta",replace

import excel "D:\Linh\project FDI\viet-nam-I-O.xlsx", sheet("matrix_full") firstrow clear	
reshape long c, i(A) j(input)
rename A output
drop if output < 3
drop if input < 3
save "$outputdata/IO_matrix_full.dta",replace

	   
*---------------------------------------------------
*--- Year 2018
*---------------------------------------------------
use DN2018\Y2018_ent.dta,clear
rename tsld labour
rename ts91 capital
rename kqkd1 output
rename nganh_kd industry_code
rename lhdn firm_type

*--------
destring industry_code, replace
gen code2 = real(substr(string(industry_code, "%9.0f"), 1, 2))
drop if labour ==. | labour ==0 

drop if output ==. | output ==0
gen output_per_employee = output/labour
gen capital_per_employee = capital/labour

*Compute the number of firm in each industry
gen N = 1
**Foreign firm
gen foreign_firm = 0
replace foreign_firm = 1 if firm_type == 11|firm_type == 12|firm_type == 13
gen capital_per_employee_F = capital_per_employee if foreign_firm == 1
gen output_per_employee_F = output_per_employee if foreign_firm == 1

gen tn1_F = tn1 if foreign_firm == 1
gen Labour_F = labour if foreign_firm == 1 
gen LabourP_F = tn1_F/Labour_F 

**Domestic firm
gen domestic_firm = 0
replace domestic_firm = 1 if foreign_firm == 0
gen capital_per_employee_D = capital_per_employee if foreign_firm == 0
gen output_per_employee_D = output_per_employee if foreign_firm == 0
gen output_D = output if foreign_firm == 0

gen tn1_D = tn1 if foreign_firm == 0
gen Labour_D = labour if foreign_firm == 0 
gen LabourP_D = tn1_D/Labour_D

* Define SOE and private_firm
gen SOE = 0
replace SOE = 1 if firm_type == 1|firm_type == 2|firm_type == 3
gen private_firm = 0
replace private_firm = 1 if firm_type == 6|firm_type == 7|firm_type == 8|firm_type == 9|firm_type == 10
gen collective_firm = 0
replace collective_firm = 1 if firm_type == 5
*Compute HHI
egen y_i = sum(output), by(code2)
gen s_i = output/y_i
gen s_i2 = s_i^2
egen HHI = sum(s_i2),by(code2)
*Techonology Gap
egen Average_LP_F = mean(LabourP_F), by(code2) 
gen Tech_gap = (Average_LP_F - LabourP_D)/LabourP_D

*Horizontal spillover effect
gen labourF = labour if foreign_firm == 1
egen FL_i = sum(labourF), by(code2)
egen L_i = sum(labour), by(code2)
gen HS = FL_i/L_i

save "$outputdata/firm_2018.dta",replace

*Compute HS by ADB code
use "$outputdata/firm_2018.dta",clear
keep code2 HS
duplicates drop code2 HS,force
sort code2
rename code2 CodeVSIC
merge 1:1 CodeVSIC using "$outputdata/IO_code.dta"
drop if _m == 2
collapse (mean) HS, by(CodeADB) cw
save "$outputdata/firm_2018_IO.dta",replace

use "$outputdata/IO_matrix_full.dta", clear
rename input CodeADB
merge m:1 CodeADB using "$outputdata/firm_2018_IO.dta"
keep if _m == 3
drop _m
rename CodeADB input
sort output input
collapse (sum) HS [pw=c],by(output) cw
rename HS BS 
rename output CodeADB
*bys output: egen BS = total(c * HS)
save "$outputdata/firm_2018_IO.dta", replace

*Merge BS with master data
use "$outputdata/firm_2018.dta",clear
rename code2 CodeVSIC
merge m:1 CodeVSIC using "$outputdata/IO_code.dta"
keep if _m == 3
drop _m Name
merge m:1 CodeADB using "$outputdata/firm_2018_IO.dta"
keep if _m == 3
drop _m 

*Gen region variable
destring tinh, replace
gen region = 0
replace region = 1 if tinh == 1 | tinh == 26| tinh == 27| tinh == 22| tinh == 30| tinh == 31| tinh == 33| tinh == 34| tinh == 35| tinh == 36| tinh == 37
replace region = 2 if tinh == 2| tinh ==4| tinh ==6| tinh ==8| tinh ==10| tinh ==15| tinh ==19| tinh ==20| tinh ==24| tinh ==25| tinh ==11| tinh ==12| tinh ==14| tinh ==17
replace region = 3 if tinh == 38| tinh ==40| tinh ==42| tinh ==44| tinh ==45| tinh ==46| tinh ==48| tinh ==49| tinh ==51| tinh ==52| tinh ==54| tinh ==56| tinh ==58| tinh ==60
replace region = 4 if tinh == 62| tinh ==64| tinh ==66| tinh ==67| tinh ==68
replace region = 5 if tinh == 70| tinh ==72| tinh ==74| tinh ==75| tinh ==77| tinh ==79
replace region = 6 if tinh == 80| tinh ==82| tinh ==83| tinh ==84| tinh ==86| tinh ==87| tinh ==89| tinh ==91| tinh ==92| tinh ==93| tinh ==94| tinh ==95| tinh ==96
lab var region "Region"
lab define region 1"DBSH" 2"Trung du mien nui Bac" 3"Bac Trung bo" 4"Tay Nguyen" 5"Dong Nam Bo" 6"DBSCL"

*Final data
keep if foreign_firm == 0
keep tinh ma_thue CodeVSIC industry_code output_per_employee_D capital_per_employee_D s_i HHI Tech_gap HS BS region SOE private_firm LabourP_D collective_firm
sort CodeVSIC
gen year = 2018
save "$outputdata/firm_2018.dta",replace

*---------------------------------------------------
*--- Loop for 2016-2017
*---------------------------------------------------
forvalues year = 2016(1)2017 {
use DN`year'\Y`year'_ent.dta,clear
rename tsld labour
rename ts12 capital
rename kqkd1 output
rename nganh_kd industry_code
rename lhdn firm_type

*--------
destring industry_code, replace
gen code2 = real(substr(string(industry_code, "%9.0f"), 1, 2))
drop if labour ==. | labour ==0 

drop if output ==. | output ==0
gen output_per_employee = output/labour
gen capital_per_employee = capital/labour

*Compute the number of firm in each industry
gen N = 1
**Foreign firm
gen foreign_firm = 0
replace foreign_firm = 1 if firm_type == 11|firm_type == 12|firm_type == 13
gen capital_per_employee_F = capital_per_employee if foreign_firm == 1
gen output_per_employee_F = output_per_employee if foreign_firm == 1

gen tn1_F = tn1 if foreign_firm == 1
gen Labour_F = labour if foreign_firm == 1 
gen LabourP_F = tn1_F/Labour_F 

**Domestic firm
gen domestic_firm = 0
replace domestic_firm = 1 if foreign_firm == 0
gen capital_per_employee_D = capital_per_employee if foreign_firm == 0
gen output_per_employee_D = output_per_employee if foreign_firm == 0
gen output_D = output if foreign_firm == 0

gen tn1_D = tn1 if foreign_firm == 0
gen Labour_D = labour if foreign_firm == 0 
gen LabourP_D = tn1_D/Labour_D

* Define SOE and private_firm
gen SOE = 0
replace SOE = 1 if firm_type == 1|firm_type == 2|firm_type == 3
gen private_firm = 0
replace private_firm = 1 if firm_type == 6|firm_type == 7|firm_type == 8|firm_type == 9|firm_type == 10
gen collective_firm = 0
replace collective_firm = 1 if firm_type == 5
*Compute HHI
egen y_i = sum(output), by(code2)
gen s_i = output/y_i
gen s_i2 = s_i^2
egen HHI = sum(s_i2),by(code2)
*Techonology Gap
egen Average_LP_F = mean(LabourP_F), by(code2) 
gen Tech_gap = (Average_LP_F - LabourP_D)/LabourP_D

*Horizontal spillover effect
gen labourF = labour if foreign_firm == 1
egen FL_i = sum(labourF), by(code2)
egen L_i = sum(labour), by(code2)
gen HS = FL_i/L_i

save "$outputdata/firm_`year'.dta",replace

*Compute HS by ADB code
use "$outputdata/firm_`year'.dta",clear
keep code2 HS
duplicates drop code2 HS,force
sort code2
rename code2 CodeVSIC
merge 1:1 CodeVSIC using "$outputdata/IO_code.dta"
drop if _m == 2
collapse (mean) HS, by(CodeADB) cw
save "$outputdata/firm_`year'_IO.dta",replace

use "$outputdata/IO_matrix_full.dta", clear
rename input CodeADB
merge m:1 CodeADB using "$outputdata/firm_`year'_IO.dta"
keep if _m == 3
drop _m
rename CodeADB input
sort output input
collapse (sum) HS [pw=c],by(output) cw
rename HS BS 
rename output CodeADB
*bys output: egen BS = total(c * HS)
save "$outputdata/firm_`year'_IO.dta", replace

*Merge BS with master data
use "$outputdata/firm_`year'.dta",clear
rename code2 CodeVSIC
merge m:1 CodeVSIC using "$outputdata/IO_code.dta"
keep if _m == 3
drop _m Name
merge m:1 CodeADB using "$outputdata/firm_`year'_IO.dta"
keep if _m == 3
drop _m 

*Gen region variable
destring tinh, replace
gen region = 0
replace region = 1 if tinh == 1 | tinh == 26| tinh == 27| tinh == 22| tinh == 30| tinh == 31| tinh == 33| tinh == 34| tinh == 35| tinh == 36| tinh == 37
replace region = 2 if tinh == 2| tinh ==4| tinh ==6| tinh ==8| tinh ==10| tinh ==15| tinh ==19| tinh ==20| tinh ==24| tinh ==25| tinh ==11| tinh ==12| tinh ==14| tinh ==17
replace region = 3 if tinh == 38| tinh ==40| tinh ==42| tinh ==44| tinh ==45| tinh ==46| tinh ==48| tinh ==49| tinh ==51| tinh ==52| tinh ==54| tinh ==56| tinh ==58| tinh ==60
replace region = 4 if tinh == 62| tinh ==64| tinh ==66| tinh ==67| tinh ==68
replace region = 5 if tinh == 70| tinh ==72| tinh ==74| tinh ==75| tinh ==77| tinh ==79
replace region = 6 if tinh == 80| tinh ==82| tinh ==83| tinh ==84| tinh ==86| tinh ==87| tinh ==89| tinh ==91| tinh ==92| tinh ==93| tinh ==94| tinh ==95| tinh ==96
lab var region "Region"
lab define region 1"DBSH" 2"Trung du mien nui Bac" 3"Bac Trung bo" 4"Tay Nguyen" 5"Dong Nam Bo" 6"DBSCL"

*Final data
keep if foreign_firm == 0
keep tinh ma_thue CodeVSIC industry_code output_per_employee_D capital_per_employee_D s_i HHI Tech_gap HS BS region SOE private_firm LabourP_D collective_firm
sort CodeVSIC
gen year = `year'
save "$outputdata/firm_`year'.dta",replace
}


*---------------------------------------------------
*--- Loop for 2012-2015
*---------------------------------------------------
forvalues year = 2012(1)2013 {
use DN`year'\Y`year'_ent.dta,clear
rename tsld labour
rename ts12 capital
rename kqkd1 output
rename nganh_kd industry_code
rename lhdn firm_type
*--------
destring industry_code, replace
gen code2 = real(substr(string(industry_code, "%9.0f"), 1, 2))
drop if labour ==. | labour ==0 

drop if output ==. | output ==0
gen output_per_employee = output/labour
gen capital_per_employee = capital/labour

*Compute the number of firm in each industry
gen N = 1
**Foreign firm
gen foreign_firm = 0
replace foreign_firm = 1 if firm_type == 11|firm_type == 12|firm_type == 13
gen capital_per_employee_F = capital_per_employee if foreign_firm == 1
gen output_per_employee_F = output_per_employee if foreign_firm == 1

gen tn1_F = tn1 if foreign_firm == 1
gen Labour_F = labour if foreign_firm == 1 
gen LabourP_F = tn1_F/Labour_F 

**Domestic firm
gen domestic_firm = 0
replace domestic_firm = 1 if foreign_firm == 0
gen capital_per_employee_D = capital_per_employee if foreign_firm == 0
gen output_per_employee_D = output_per_employee if foreign_firm == 0
gen output_D = output if foreign_firm == 0

gen tn1_D = tn1 if foreign_firm == 0
gen Labour_D = labour if foreign_firm == 0 
gen LabourP_D = tn1_D/Labour_D

* Define SOE and private_firm
gen SOE = 0
replace SOE = 1 if firm_type == 1|firm_type == 2|firm_type == 3
gen private_firm = 0
replace private_firm = 1 if firm_type == 6|firm_type == 7|firm_type == 8|firm_type == 9|firm_type == 10
gen collective_firm = 0
replace collective_firm = 1 if firm_type == 5
*Compute HHI
egen y_i = sum(output), by(code2)
gen s_i = output/y_i
gen s_i2 = s_i^2
egen HHI = sum(s_i2),by(code2)
*Techonology Gap
egen Average_LP_F = mean(LabourP_F), by(code2) 
gen Tech_gap = (Average_LP_F - LabourP_D)/LabourP_D

*Horizontal spillover effect
gen labourF = labour if foreign_firm == 1
egen FL_i = sum(labourF), by(code2)
egen L_i = sum(labour), by(code2)
gen HS = FL_i/L_i

save "$outputdata/firm_`year'.dta",replace

*Compute HS by ADB code
use "$outputdata/firm_`year'.dta",clear
keep code2 HS
duplicates drop code2 HS,force
sort code2
rename code2 CodeVSIC
merge 1:1 CodeVSIC using "$outputdata/IO_code.dta"
drop if _m == 2
collapse (mean) HS, by(CodeADB) cw
save "$outputdata/firm_`year'_IO.dta",replace

use "$outputdata/IO_matrix_full.dta", clear
rename input CodeADB
merge m:1 CodeADB using "$outputdata/firm_`year'_IO.dta"
keep if _m == 3
drop _m
rename CodeADB input
sort output input
collapse (sum) HS [pw=c],by(output) cw
rename HS BS 
rename output CodeADB
*bys output: egen BS = total(c * HS)
save "$outputdata/firm_`year'_IO.dta", replace

*Merge BS with master data
use "$outputdata/firm_`year'.dta",clear
rename code2 CodeVSIC
merge m:1 CodeVSIC using "$outputdata/IO_code.dta"
keep if _m == 3
drop _m Name
merge m:1 CodeADB using "$outputdata/firm_`year'_IO.dta"
keep if _m == 3
drop _m 

*Gen region variable
destring tinh, replace
gen region = 0
replace region = 1 if tinh == 1 | tinh == 26| tinh == 27| tinh == 22| tinh == 30| tinh == 31| tinh == 33| tinh == 34| tinh == 35| tinh == 36| tinh == 37
replace region = 2 if tinh == 2| tinh ==4| tinh ==6| tinh ==8| tinh ==10| tinh ==15| tinh ==19| tinh ==20| tinh ==24| tinh ==25| tinh ==11| tinh ==12| tinh ==14| tinh ==17
replace region = 3 if tinh == 38| tinh ==40| tinh ==42| tinh ==44| tinh ==45| tinh ==46| tinh ==48| tinh ==49| tinh ==51| tinh ==52| tinh ==54| tinh ==56| tinh ==58| tinh ==60
replace region = 4 if tinh == 62| tinh ==64| tinh ==66| tinh ==67| tinh ==68
replace region = 5 if tinh == 70| tinh ==72| tinh ==74| tinh ==75| tinh ==77| tinh ==79
replace region = 6 if tinh == 80| tinh ==82| tinh ==83| tinh ==84| tinh ==86| tinh ==87| tinh ==89| tinh ==91| tinh ==92| tinh ==93| tinh ==94| tinh ==95| tinh ==96
lab var region "Region"
lab define region 1"DBSH" 2"Trung du mien nui Bac" 3"Bac Trung bo" 4"Tay Nguyen" 5"Dong Nam Bo" 6"DBSCL"

*Final data
keep if foreign_firm == 0
keep tinh ma_thue CodeVSIC industry_code output_per_employee_D capital_per_employee_D s_i HHI Tech_gap HS BS region SOE private_firm LabourP_D collective_firm
sort CodeVSIC
gen year = `year'
save "$outputdata/firm_`year'.dta",replace
}

*2014
use DN2014\Y2014_ent.dta,clear
rename macs ma_thue
save DN2014\Y2014_ent.dta,replace

use DN2014\Y2014_ent.dta,clear
rename tsld labour
rename ts12 capital
rename kqkd1 output
rename nganh_kd industry_code
rename lhdn firm_type
*--------
destring industry_code, replace
gen code2 = real(substr(string(industry_code, "%9.0f"), 1, 2))
drop if labour ==. | labour ==0 

drop if output ==. | output ==0
gen output_per_employee = output/labour
gen capital_per_employee = capital/labour

*Compute the number of firm in each industry
gen N = 1
**Foreign firm
gen foreign_firm = 0
replace foreign_firm = 1 if firm_type == 11|firm_type == 12|firm_type == 13
gen capital_per_employee_F = capital_per_employee if foreign_firm == 1
gen output_per_employee_F = output_per_employee if foreign_firm == 1

gen tn1_F = tn1 if foreign_firm == 1
gen Labour_F = labour if foreign_firm == 1 
gen LabourP_F = tn1_F/Labour_F 

**Domestic firm
gen domestic_firm = 0
replace domestic_firm = 1 if foreign_firm == 0
gen capital_per_employee_D = capital_per_employee if foreign_firm == 0
gen output_per_employee_D = output_per_employee if foreign_firm == 0
gen output_D = output if foreign_firm == 0

gen tn1_D = tn1 if foreign_firm == 0
gen Labour_D = labour if foreign_firm == 0 
gen LabourP_D = tn1_D/Labour_D

* Define SOE and private_firm
gen SOE = 0
replace SOE = 1 if firm_type == 1|firm_type == 2|firm_type == 3
gen private_firm = 0
replace private_firm = 1 if firm_type == 6|firm_type == 7|firm_type == 8|firm_type == 9|firm_type == 10
gen collective_firm = 0
replace collective_firm = 1 if firm_type == 5
*Compute HHI
egen y_i = sum(output), by(code2)
gen s_i = output/y_i
gen s_i2 = s_i^2
egen HHI = sum(s_i2),by(code2)
*Techonology Gap
egen Average_LP_F = mean(LabourP_F), by(code2) 
gen Tech_gap = (Average_LP_F - LabourP_D)/LabourP_D

*Horizontal spillover effect
gen labourF = labour if foreign_firm == 1
egen FL_i = sum(labourF), by(code2)
egen L_i = sum(labour), by(code2)
gen HS = FL_i/L_i

save "$outputdata/firm_2014.dta",replace

*Compute HS by ADB code
use "$outputdata/firm_2014.dta",clear
keep code2 HS
duplicates drop code2 HS,force
sort code2
rename code2 CodeVSIC
merge 1:1 CodeVSIC using "$outputdata/IO_code.dta"
drop if _m == 2
collapse (mean) HS, by(CodeADB) cw
save "$outputdata/firm_2014_IO.dta",replace

use "$outputdata/IO_matrix_full.dta", clear
rename input CodeADB
merge m:1 CodeADB using "$outputdata/firm_2014_IO.dta"
keep if _m == 3
drop _m
rename CodeADB input
sort output input
collapse (sum) HS [pw=c],by(output) cw
rename HS BS 
rename output CodeADB
*bys output: egen BS = total(c * HS)
save "$outputdata/firm_2014_IO.dta", replace

*Merge BS with master data
use "$outputdata/firm_2014.dta",clear
rename code2 CodeVSIC
merge m:1 CodeVSIC using "$outputdata/IO_code.dta"
keep if _m == 3
drop _m Name
merge m:1 CodeADB using "$outputdata/firm_2014_IO.dta"
keep if _m == 3
drop _m 

*Gen region variable
destring tinh, replace
gen region = 0
replace region = 1 if tinh == 1 | tinh == 26| tinh == 27| tinh == 22| tinh == 30| tinh == 31| tinh == 33| tinh == 34| tinh == 35| tinh == 36| tinh == 37
replace region = 2 if tinh == 2| tinh ==4| tinh ==6| tinh ==8| tinh ==10| tinh ==15| tinh ==19| tinh ==20| tinh ==24| tinh ==25| tinh ==11| tinh ==12| tinh ==14| tinh ==17
replace region = 3 if tinh == 38| tinh ==40| tinh ==42| tinh ==44| tinh ==45| tinh ==46| tinh ==48| tinh ==49| tinh ==51| tinh ==52| tinh ==54| tinh ==56| tinh ==58| tinh ==60
replace region = 4 if tinh == 62| tinh ==64| tinh ==66| tinh ==67| tinh ==68
replace region = 5 if tinh == 70| tinh ==72| tinh ==74| tinh ==75| tinh ==77| tinh ==79
replace region = 6 if tinh == 80| tinh ==82| tinh ==83| tinh ==84| tinh ==86| tinh ==87| tinh ==89| tinh ==91| tinh ==92| tinh ==93| tinh ==94| tinh ==95| tinh ==96
lab var region "Region"
lab define region 1"DBSH" 2"Trung du mien nui Bac" 3"Bac Trung bo" 4"Tay Nguyen" 5"Dong Nam Bo" 6"DBSCL"

*Final data
keep if foreign_firm == 0
keep tinh ma_thue CodeVSIC industry_code output_per_employee_D capital_per_employee_D s_i HHI Tech_gap HS BS region SOE private_firm LabourP_D collective_firm
sort CodeVSIC
gen year = 2014
save "$outputdata/firm_2014.dta",replace

*2015
use DN2015\Y2015_ent.dta,clear
rename tsld labour
rename ts12 capital
rename kqkd1 output
rename nganh_kd industry_code
rename lhdn firm_type
*--------
destring industry_code, replace
gen code2 = real(substr(string(industry_code, "%9.0f"), 1, 2))
drop if labour ==. | labour ==0 

drop if output ==. | output ==0
gen output_per_employee = output/labour
gen capital_per_employee = capital/labour

*Compute the number of firm in each industry
gen N = 1
**Foreign firm
gen foreign_firm = 0
replace foreign_firm = 1 if firm_type == 11|firm_type == 12|firm_type == 13
gen capital_per_employee_F = capital_per_employee if foreign_firm == 1
gen output_per_employee_F = output_per_employee if foreign_firm == 1

gen tn1_F = tn1 if foreign_firm == 1
gen Labour_F = labour if foreign_firm == 1 
gen LabourP_F = tn1_F/Labour_F 

**Domestic firm
gen domestic_firm = 0
replace domestic_firm = 1 if foreign_firm == 0
gen capital_per_employee_D = capital_per_employee if foreign_firm == 0
gen output_per_employee_D = output_per_employee if foreign_firm == 0
gen output_D = output if foreign_firm == 0

gen tn1_D = tn1 if foreign_firm == 0
gen Labour_D = labour if foreign_firm == 0 
gen LabourP_D = tn1_D/Labour_D

* Define SOE and private_firm
gen SOE = 0
replace SOE = 1 if firm_type == 1|firm_type == 2|firm_type == 3
gen private_firm = 0
replace private_firm = 1 if firm_type == 6|firm_type == 7|firm_type == 8|firm_type == 9|firm_type == 10
gen collective_firm = 0
replace collective_firm = 1 if firm_type == 5
*Compute HHI
egen y_i = sum(output), by(code2)
gen s_i = output/y_i
gen s_i2 = s_i^2
egen HHI = sum(s_i2),by(code2)
*Techonology Gap
egen Average_LP_F = mean(LabourP_F), by(code2) 
gen Tech_gap = (Average_LP_F - LabourP_D)/LabourP_D

*Horizontal spillover effect
gen labourF = labour if foreign_firm == 1
egen FL_i = sum(labourF), by(code2)
egen L_i = sum(labour), by(code2)
gen HS = FL_i/L_i

save "$outputdata/firm_2015.dta",replace

*Compute HS by ADB code
use "$outputdata/firm_2015.dta",clear
keep code2 HS
duplicates drop code2 HS,force
sort code2
rename code2 CodeVSIC
merge 1:1 CodeVSIC using "$outputdata/IO_code.dta"
drop if _m == 2
collapse (mean) HS, by(CodeADB) cw
save "$outputdata/firm_2015_IO.dta",replace

use "$outputdata/IO_matrix_full.dta", clear
rename input CodeADB
merge m:1 CodeADB using "$outputdata/firm_2015_IO.dta"
keep if _m == 3
drop _m
rename CodeADB input
sort output input
collapse (sum) HS [pw=c],by(output) cw
rename HS BS 
rename output CodeADB
*bys output: egen BS = total(c * HS)
save "$outputdata/firm_2015_IO.dta", replace

*Merge BS with master data
use "$outputdata/firm_2015.dta",clear
rename code2 CodeVSIC
merge m:1 CodeVSIC using "$outputdata/IO_code.dta"
keep if _m == 3
drop _m Name
merge m:1 CodeADB using "$outputdata/firm_2015_IO.dta"
keep if _m == 3
drop _m 

*Gen region variable
destring tinh, replace
gen region = 0
replace region = 1 if tinh == 1 | tinh == 26| tinh == 27| tinh == 22| tinh == 30| tinh == 31| tinh == 33| tinh == 34| tinh == 35| tinh == 36| tinh == 37
replace region = 2 if tinh == 2| tinh ==4| tinh ==6| tinh ==8| tinh ==10| tinh ==15| tinh ==19| tinh ==20| tinh ==24| tinh ==25| tinh ==11| tinh ==12| tinh ==14| tinh ==17
replace region = 3 if tinh == 38| tinh ==40| tinh ==42| tinh ==44| tinh ==45| tinh ==46| tinh ==48| tinh ==49| tinh ==51| tinh ==52| tinh ==54| tinh ==56| tinh ==58| tinh ==60
replace region = 4 if tinh == 62| tinh ==64| tinh ==66| tinh ==67| tinh ==68
replace region = 5 if tinh == 70| tinh ==72| tinh ==74| tinh ==75| tinh ==77| tinh ==79
replace region = 6 if tinh == 80| tinh ==82| tinh ==83| tinh ==84| tinh ==86| tinh ==87| tinh ==89| tinh ==91| tinh ==92| tinh ==93| tinh ==94| tinh ==95| tinh ==96
lab var region "Region"
lab define region 1"DBSH" 2"Trung du mien nui Bac" 3"Bac Trung bo" 4"Tay Nguyen" 5"Dong Nam Bo" 6"DBSCL"

*Final data
keep if foreign_firm == 0
keep tinh ma_thue CodeVSIC industry_code output_per_employee_D capital_per_employee_D s_i HHI Tech_gap HS BS region SOE private_firm LabourP_D collective_firm
sort CodeVSIC
gen year = 2015
save "$outputdata/firm_2015.dta",replace

*---------------------------------------------------------
*Merge all years
*---------------------------------------------------------
forvalues n = 2012 (1) 2018 {
	use "$outputdata\firm_`n'.dta", clear
	destring ma_thue,replace
	save "$outputdata\firm_`n'.dta", replace
}

use "$outputdata\firm_2018.dta", clear
forvalues n = 2012 (1) 2017 {
	append using "$outputdata\firm_`n'.dta",force
}
sort year CodeVSIC
rename s_i scale
save "$outputdata\firm_2012_2018.dta",replace

*Compute lag variable
use "$outputdata\firm_2012_2018.dta", clear
duplicates drop year CodeVSIC,force
keep CodeVSIC year HS BS
xtset CodeVSIC year
sort CodeVSIC year
gen HS_lagged = L1.HS
gen BS_lagged = L1.BS
drop HS BS
save "$outputdata\firm_2012_2018_lag.dta", replace

use "$outputdata\firm_2012_2018.dta", clear
merge m:1 year CodeVSIC using "$outputdata\firm_2012_2018_lag.dta"
drop _m
save "$outputdata\firm_2012_2018.dta", replace
