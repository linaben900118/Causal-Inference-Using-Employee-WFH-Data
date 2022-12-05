cd "C:\Users\tejir\OneDrive\Desktop\econ 318 empirical project"

clear all 
frames reset

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
frame create employeeCharacteristics
frame employeeCharacteristics: use EmployeeCharacteristics, clear
frame change employeeCharacteristics
browse
replace prior_experience = . if (prior_experience/12 > age) | (prior_experience < 0)

replace age = . if (age <= 0)
replace tenure = . if (tenure < 0)
replace basewage = . if (basewage < 0)
replace bonus = . if (bonus < 0)
replace grosswage = . if (grosswage < 0)

merge 1:1 personid using EmployeeStatus
balancetable treatment age tenure basewage bonus grosswage costofcommute rental male married high_school  using "Employee Characteristics BalanceTable.xls",replace
drop _merge

merge 1:m personid using Performance
drop _merge
drop if post != 0
eststo clear
eststo: regress performance_score age tenure costofcommute rental male married high_school 
esttab using "performance_score and Xtics.rtf", replace
browse

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
frame create attitudes
frame attitudes: use Attitudes, clear
frame change attitudes
browse

replace surveyno = . if surveyno < 1 & surveyno > 5
replace surveyno = . if surveyno < 1 & surveyno > 5
replace satisfaction = . if (satisfaction < 1) | (satisfaction > 7)
replace general = . if (general < 0) | (general > 100)
replace life = . if (life < 0) | (life > 40)

merge m:1 personid using EmployeeStatus
bysort personid post: egen avg_satisfaction = mean(satisfaction)

drop satisfaction life general surveyno 
bysort personid post: gen dup = cond(_N==1,0,_n) //getting duplicates: https://www.stata.com/support/faqs/data-management/duplicate-observations/
drop if dup>1

gen treatmentXpost = treatment * post

eststo clear
eststo: reg avg_satisfaction post treatment treatmentXpost, cluster(personid)
esttab using "satisfaction and treatment panel.rtf", replace
browse

//////////////////////////////////////////////////////////////////////////////////////////////////////
frames reset
frame create performance
frame performance: use Performance, clear
frame change performance

//cleaning the data in Performance.dta by removing values that are less than or equal to zero
replace performance_score = . if (performance_score > 100) | (performance_score <0 )
replace total_monthly_calls = . if (total_monthly_calls <= 0) & (calls_per_hour > 0)
replace calls_per_hour = . if calls_per_hour <= 0 & total_monthly_calls > 0

twoway histogram performance_score, discrete by(post)
twoway histogram total_monthly_calls, discrete by(post)
twoway histogram calls_per_hour, discrete by(post)


merge m:1 personid using EmployeeStatus

gen treatmentXpost = treatment * post

eststo clear
eststo: regress performance_score treatment post treatmentXpost, cluster(personid)
eststo: regress total_monthly_calls treatment post treatmentXpost, cluster(personid)
eststo: regress calls_per_hour treatment post treatmentXpost, cluster(personid)
esttab using "performance and treatment.rtf", replace
////////////////////////////////////////////////////////////////////////////
frame create quitAndEmployeeCharacteristics
frame quitAndEmployeeCharacteristics: use Quits, clear
frame change quitAndEmployeeCharacteristics
merge 1:1 personid using EmployeeCharacteristics

eststo clear
eststo: regress quitjob age tenure rental male married high_school 
esttab using "quit and characteristics.rtf", replace


/////////////////////////////////////////////////////////////////////////
frames reset
frame create quit
frame quit: use Quits, clear
frame change quit
replace quit = . if (quit != 0) & (quit != 1)

merge 1:1 personid using EmployeeStatus
gen post = 1
drop _merge
merge 1:m personid post using Attitudes
replace surveyno = . if surveyno < 1 & surveyno > 5
replace surveyno = . if surveyno < 1 & surveyno > 5
replace satisfaction = . if (satisfaction < 1) | (satisfaction > 7)
bysort personid post: egen avg_satisfaction = mean(satisfaction)
drop satisfaction life general surveyno 
drop if post != 1
bysort personid post: gen dup = cond(_N==1,0,_n) //getting duplicates: https://www.stata.com/support/faqs/data-management/duplicate-observations/
drop if dup>1
browse

gen satisfactionXtreatment = treatment * avg_satisfaction


reg quit avg_satisfaction
logit quit treatment
reg quit treatment
logit quit avg_satisfaction

eststo clear
eststo: logit quit avg_satisfaction
esttab using "quit and satisfaction - logit.rtf", replace

eststo clear
eststo: logit quit satisfactionXtreatment
esttab using "quit and satisfactionXtreatment - logit.rtf", replace

eststo clear
eststo: reg quit treatment
esttab using "quit and treatment - lpm.rtf", replace

eststo clear
eststo: logit quit treatment
esttab using "quit and treatment - logit.rtf", replace

browse


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
frames reset
frame create quitDate
frame quitDate: use QuitDate, clear
frame change quitDate
replace stillworking = . if (stillworking != 0) & (stillworking != 1)
replace quit = . if (quit != 0) & (quit != 1)
replace month = . if (month < 12) & (year == 2010)
replace month = . if (month > 8) & (year == 2011)
replace year = . if (year != 2010) & (year != 2011)
replace month = . if (year != 2010) & (year != 2011)
merge m:1 personid using EmployeeStatus
gen monthOfTreatment = month + 1
replace monthOfTreatment = 1 if monthOfTreatment == 13
summarize if (treatment == 1) & (quit == 1)
summarize if (treatment == 0) & (quit == 1)

histogram monthOfTreatment if (treatment == 1) & (quit == 1), freq title("Frequency Distribution of Quit Month") subtitle("For employees in the treatment group after the treatment went into effect") xtitle("Month of Experiment (After Treatment is Implemented)")
histogram monthOfTreatment if (treatment == 0) & (quit == 1), freq title("Frequency Distribution of Quit Month") subtitle("For employees in the control group after the treatment went into effect") xtitle("Month of Experiment (After Treatment is Implemented)")


