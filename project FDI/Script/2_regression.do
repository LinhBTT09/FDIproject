*------------------------------------------------------
* Run the regression
*------------------------------------------------------
* We want to explore the spillover effects FDI on the productivity of domestic firms
*
clear
set more off

/* path for the input */
               if c(username) == "buithithuylinh" {

                               cd "D:\Linh\project FDI\Output"


               }       
			   * output

               if c(username) == "buithithuylinh" {

                               global outputdata "D:\Linh\project FDI\Output\regression"

               } 
			   
*0. Descriptive statistic
use firm_2012_2018.dta, clear
* Take only manufacture industry
drop if CodeVSIC < 10 | CodeVSIC > 39

drop if LabourP_D < 0
drop if capital_per_employee_D < 0
drop if output_per_employee_D < 0

gen log_output_D = log(output_per_employee_D)
gen log_capital_D = log(capital_per_employee_D)
gen LabourP_D_HS = LabourP_D*HS 
gen LabourP_D_BS = LabourP_D*BS
gen HS_province = HS*tinh
gen Tech_gap_HS = Tech_gap*HS
gen Tech_gap_BS = Tech_gap*BS

save "$outputdata/regression_data2.dta", replace

asdoc sum log_output_D log_capital_D LabourP_D SOE private_firm collective_firm scale HHI Tech_gap HS BS , save(Summary stats1.doc)

asdoc sum HS, stat(mean sd) by(year) save(Summary stats2.doc)
asdoc sum BS, stat(mean sd) by(year) save(Summary stats2.doc)

tab CodeVSIC, by(year)

tab year, summarize(CodeVSIC) obs  
			   
*1. The labor productivity of domestic sector 

*Table 1: 
use "$outputdata/regression_data.dta", clear

xtreg log_output_D log_capital_D HS BS LabourP_D scale HHI Tech_gap i.year i.region i.CodeVSIC, fe 

reghdfe log_output_D log_capital_D HS BS LabourP_D scale HHI Tech_gap , absorb(year CodeVSIC region) 
outreg2 using "reg_table.doc", replace  ///
 addtext(Industry FE, YES, Year FE, YES, Region FE, Yes) 
 
reghdfe log_output_D log_capital_D HS_lagged BS_lagged LabourP_D scale HHI Tech_gap , absorb(year CodeVSIC region) 
outreg2 using "reg_table.doc", append  ///
 addtext(Industry FE, YES, Year FE, YES, Region FE, Yes) 
 
reghdfe log_output_D log_capital_D HS BS LabourP_D scale HHI Tech_gap LabourP_D_HS LabourP_D_BS, absorb(year CodeVSIC region) 
outreg2 using "reg_table.doc", append  ///
 addtext(Industry FE, YES, Year FE, YES, Region FE, Yes) 

reghdfe log_output_D log_capital_D HS BS LabourP_D scale HHI Tech_gap Tech_gap_HS Tech_gap_BS, absorb(year CodeVSIC region) 
outreg2 using "reg_table.doc", append  ///
 addtext(Industry FE, YES, Year FE, YES, Region FE, Yes) 

*Table 2
use "$outputdata\regression_data.dta", clear
*SOE
keep if SOE == 1
reghdfe log_output_D log_capital_D HS BS LabourP_D scale HHI Tech_gap, absorb(year CodeVSIC region) 
outreg2 using "reg_table2.doc", replace  ///
 addtext(Industry FE, YES, Year FE, YES, Region FE, Yes) 
 

*Private firm
use "$outputdata/regression_data.dta", clear
keep if private_firm == 1
reghdfe log_output_D log_capital_D HS BS LabourP_D scale HHI Tech_gap, absorb(year CodeVSIC region) 
outreg2 using "reg_table2.doc", append  ///
 addtext(Industry FE, YES, Year FE, YES, Region FE, Yes) 
 

 
*Collective firm
use "$outputdata/regression_data.dta", clear
keep if collective_firm == 1
reghdfe log_output_D log_capital_D HS BS LabourP_D scale HHI Tech_gap, absorb(year CodeVSIC region) 
outreg2 using "reg_table2.doc", append  ///
 addtext(Industry FE, YES, Year FE, YES, Region FE, Yes) 
 
