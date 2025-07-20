*** REPLICATION OF PAPER ON MIGRANT SHIPWRECKS ****
*** This version: April 2025

** Replication of ESS Analysis (From Figure 2 onwards) **
use "C:\Users\CavalliNic\Desktop\Replication\Analysis_data\ESS Round 6\ESS6_Main\ESS6_Main.dta", clear

** DATA PREPARATION **
set scheme stmono2

keep if cntry=="IT"

* Recoding missing values (based on ESS script)
quietly label dir 					
foreach v in `r(names)' {
	capture confirm variable `v'
	if !_rc {
		quietly label list `v'	
		local length = length("`r(max)'")
		local format = (10^`length'-1)/-9
		local 6 = 6*`format'
		local 7 = 7*`format'
		local 8 = 8*`format'
		local 9 = 9*`format'

		local a : label `v' `6'
		if regexm("`a'","Not .p+lic+able")  {
			local r `6'=.a \
			label define `v' .a "`a'" `6' "", modify
		}
		local b : label `v' `7'
		if regexm("`b'","Refus..") {
			local r `r' `7'=.b \
			label define `v' .b "`b'" `7' "", modify
		}
		local c : label `v' `8'
		if regexm("`c'","Don.?t .now") {
			local r `r' `8'=.c \
			label define `v' .c "`c'" `8' "", modify
		}
		local d : label `v' `9'
		if regexm("`d'","[No .nswer|Not .vailable]") {
			local r `r' `9'=.d \
			label define `v' .d "`d'" `9' "", modify
		}
		if !missing("`r'") mvdecode `v', mv(`r')
		local r
	}
}

quietly ds, has(type string)
foreach v of varlist `r(varlist)' {	
	local length = substr("`:type `v''",4,4)
	local format = (10^`length'-1)/9
	local 6 = 6*`format'
	local 7 = 7*`format'
	local 8 = 8*`format'
	local 9 = 9*`format'
	di "`v'"
	replace `v'= "" if inlist(`v',"`9'","`8'","`7'","`6'")
}

* Define independent variables
* Gender
tab gndr, missing
gen male=1 if gndr==1
replace male=0 if gndr==2

* Migrant background
gen immigrant="No" if brncntr==1
replace immigrant="First generation" if brncntr==2
replace immigrant="Second generation" if (brncntr==1 & facntr==2) | (brncntr==1 & mocntr==2)

encode immigrant, gen(immigrant_num)

* Occupation
des pdwrk edctn uempla uempli dsbld rtrd cmsrv hswrk dngoth dngref dngdk dngna

gen activity_pastweek="Paid Work" if pdwrk==1
replace activity_pastweek="In Education or Training" if edctn==1
replace activity_pastweek="Unemployed" if uempla==1 | uempli==1
replace activity_pastweek="Retired or Pension" if rtrd==1 | dsbld==1
replace activity_pastweek="Housework and other" if hswrk==1 | cmsrv==1 | dngoth==1

encode activity_pastweek, gen(mainjob_num)

* Region
encode region, gen(region_num)
/*
ITC1 - Piemonte
ITC2 - Valle d'Aosta
ITC3 - Liguria
ITC4 - Lombardia
ITH1 - Provincia autonoma di Bolzano
ITH2 - Provincia autonoma di Trento
ITH3 - Veneto
ITH4 - Friulia Venezia Giulia
ITH5 - Emilia Romagna
ITI1 - Toscana
ITI2 - Umbria
ITI3 - Marche
ITI4 - Lazio
ITF1 - Abruzzo
ITF2 - Molise
ITF3 - Campania
ITF4 - Puglia
ITF5 - Basilicata
ITF6 - Calabria
ITG1 - Sicilia
ITG2 - Sardegna
*/


*** GENERATE TIME VARIABLES AND TREATMENT ASSIGNMENT INDICATOR ***
gen day=inwdds
gen month=inwmms
gen year=inwyys
gen date = mdy(month, day, year)

sum date if month==10 & day==3 & year==2013
gen support_lampedusa=date-19634 
gen treatment_lampedusa=(support_lampedusa>=0)

** AUGMENT WITH ATTEMPTS **
preserve
use "Analysis_data\ESS Round 6\ESS6_ContactForms\ESS6_ContactForms.dta", clear
keep if cntry=="IT"

rename datev1 date1
forvalues i = 1(1)69 {
gen date_contact`i'=mdy(monv`i', date`i', 2013)
}

forvalues i = 1(1)69 {
gen attempted`i'=(resulb`i'<=8)
}

forvalues i = 1(1)69 {
gen completed`i'=(resulb`i'==1)
}

keep idno date_contact* attempted* completed*
reshape long date_contact attempted completed, i(idno) 
keep if date_contact!=.

collapse (sum) attempted completed, by(idno)

save "Analysis_data\ESS Round 6\ESS6_ContactForms\NumberOfContacts"
 
restore
****

merge 1:1 idno using "C:\Users\CavalliNic\OneDrive - Università Commerciale Luigi Bocconi\Desktop\Replication\Analysis_data\ESS Round 6\ESS6_ContactForms\NumberOfContacts"

keep if _merge==3

drop if month==5 

** FIGURE 1 **
gen ratio=completed/attempted
sum ratio

preserve

collapse (sum) completed attempted , by(date)
tsset date
tsfill, full

gen number_of_contacts=attempted-completed

sum attempted	   
local max=`r(max)'+15
gen c1=`max' if date>=19604 & date<19634
gen c2=`max' if date>19634  & date<=19664
twoway (bar attempted completed date, xline(19634) xaxis(1) xla(19634 "Shipwreck", axis(1) grid glcolor(black)) xtitle("", axis(1))) 
restore


*** MAIN ANALYSIS ***
* Running imputations

summarize imsmetn imdfetn impcntr imbgeco imueclt imwbcnt agea male eisced mainjob_num immigrant_num lrscale attempted region_num 

misstable summarize imsmetn imdfetn impcntr imbgeco imueclt imwbcnt agea male eisced mainjob_num immigrant_num lrscale attempted region_num

foreach var of varlist imsmetn imdfetn impcntr imbgeco imueclt imwbcnt agea male eisced mainjob_num immigrant_num lrscale attempted region_num {
	replace `var'=. if `var'>.
}

mi set wide

mi register imputed  imsmetn imdfetn impcntr imbgeco imueclt imwbcnt agea male eisced mainjob_num immigrant_num lrscale attempted region_num

mi impute mvn imsmetn imdfetn impcntr imbgeco imueclt imwbcnt agea male eisced mainjob_num immigrant_num lrscale attempted region_num, add(100)

foreach var of varlist imsmetn imdfetn impcntr imbgeco imueclt imwbcnt agea male eisced mainjob_num immigrant_num lrscale attempted region_num  {
		egen `var'_mi= rowmean(_1_`var' _2_`var' _3_`var' _4_`var' _5_`var' _6_`var' _7_`var' _8_`var' _9_`var' _10_`var' _11_`var' _12_`var' _13_`var' _14_`var' _15_`var' _16_`var' _17_`var' _18_`var' _19_`var' _20_`var')
	}

foreach var of varlist *_mi {
replace `var'=round(`var')
}


* Generate dependent variables
alpha imsmetn_mi imdfetn_mi impcntr_mi imbgeco_mi imueclt_mi imwbcnt_mi
factortest imsmetn_mi imdfetn_mi impcntr_mi imbgeco_mi imueclt_mi imwbcnt_mi

foreach var of varlist imbgeco_mi imueclt_mi imwbcnt_mi {
replace `var'=`var'*-1+10
}
	
factor imsmetn_mi imdfetn_mi impcntr_mi imbgeco_mi imueclt_mi imwbcnt_mi
rotate 
predict policy attitudes


preserve 
** GENERATE FIGURE 3.a and FIGURE 3.b **
use "Analysis_data\st_diff", clear

gen variance_ratio_pre=var_Co_Pre^2/var_Tr^2
gen variance_ratio_post=var_Co_Post^2/var_Tr^2

scatter variance_ratio_pre sdiff_Pre
scatter variance_ratio_post sdiff_Post

restore
**

** Generate Table 1 **
tab eisced_mi, gen(eisced_dummy)
tab mainjob_num_mi, gen(mainjob_dummy)
tab immigrant_num_mi, gen(immigrant_dummy)
tab region_num, gen(region_dummy)

foreach var of varlist agea_mi male_mi eisced_dummy* mainjob_dummy* immigrant_dummy* lrscale_mi attempted {
ttest `var', by(treatment_lampedusa)
reg `var' treatment_lampedusa [w=_webal]
}

foreach var of varlist region_dummy* {
ttest `var', by(treatment_lampedusa)
reg `var' treatment_lampedusa [w=_webal]
}
**


** FIGURE 5 **
* Discontinuity plots *

tw  (scatter policy support_lampedusa, mcolor(gs14))  (lfitci policy support_lampedusa if support_lampedusa<0 [w=pspwght], fcolor(none))  (lfitci policy support_lampedusa if support_lampedusa>=0 [w=pspwght], fcolor(none)), title(Anti-immigration attitudes, size(medsmall)) ytitle(Factor score 1 - Anti-immigration attitudes, size(small)) xtitle(Days since shipwreck, size(small)) xline(0)  ylabel(,labsize(small))  legend(off)

tw  (scatter attitudes support_lampedusa, mcolor(gs14))  (lfitci attitudes support_lampedusa if support_lampedusa<0 [w=pspwght], fcolor(none))  (lfitci attitudes support_lampedusa if support_lampedusa>=0  [w=pspwght], fcolor(none)), title(Anti-immigrant attitudes, size(medsmall)) ytitle(Factor score 1 - Anti-immigrant attitudes, size(small)) xtitle(Days since shipwreck, size(small)) xline(0)  ylabel(,labsize(small))  legend(off)


** FIGURE 6 **
* Regressions with and without controls *

** ENTROPY BALANCING **
ebalance treatment_lampedusa agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num attempted, keep(st_diff) replace


foreach var of varlist policy imsmetn_mi imdfetn_mi impcntr_mi attitudes imbgeco_mi imueclt_mi imwbcnt_mi {
gen t`var'=(treatment_lampedusa)
reg `var' t`var'  [w=pspwght*_webal]
eststo reg1`var'
}

foreach var of varlist policy imsmetn_mi imdfetn_mi impcntr_mi attitudes imbgeco_mi imueclt_mi imwbcnt_mi {
reg `var' t`var' agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num  [w=pspwght*_webal]
eststo reg2`var'
}

coefplot reg1* || reg2*, keep(tpolicy timsmetn_mi timdfetn_mi timpcntr_mi tattitudes timbgeco_mi timueclt_mi timwbcnt_mi) mcolor(black) lcolor(black) horizontal xline(0) legend(off) symbol(O)

	
** Appendix B **
* Create regression table for Figure 5 *
foreach var of varlist policy imsmetn_mi imdfetn_mi impcntr_mi attitudes imbgeco_mi imueclt_mi imwbcnt_mi {
reg `var' treatment_lampedusa  [w=pspwght*_webal]
outreg2 using Figure5_NoControls.doc, append  dec(3) bdec(3) alpha(0.001, 0.01, 0.05)
}

foreach var of varlist policy imsmetn_mi imdfetn_mi impcntr_mi attitudes imbgeco_mi imueclt_mi imwbcnt_mi {
reg `var' treatment_lampedusa agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num  [w=pspwght*_webal]
outreg2 using Figure5Controls.doc, append  dec(3) bdec(3) alpha(0.001, 0.01, 0.05)
}

** FIGURE 7 ** 
* Adding Polynomial Terms *
ebalance treatment_lampedusa agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num attempted 

foreach var of varlist policy imsmetn_mi imdfetn_mi impcntr_mi attitudes imbgeco_mi imueclt_mi imwbcnt_mi {
*gen t`var'=treatment_lampedusa
reg `var' t`var' i.t`var'##c.support_lampedusa agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num  [w=pspwght*_webal]
eststo reg8`var'
}

foreach var of varlist policy imsmetn_mi imdfetn_mi impcntr_mi attitudes imbgeco_mi imueclt_mi imwbcnt_mi {
*gen t`var'=treatment_lampedusa
reg `var' t`var' i.t`var'##c.support_lampedusa##c.support_lampedusa agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num  [w=pspwght*_webal]
eststo reg10`var'
}

coefplot reg8* || reg10*, keep(tpolicy timsmetn_mi timdfetn_mi timpcntr_mi tattitudes timbgeco_mi timueclt_mi timwbcnt_mi ) mcolor(black) lcolor(black) horizontal  xline(0) legend(off)  symbol(O)


** Appendix B **
* Create regression table for Figure 6 *
foreach var of varlist policy imsmetn_mi imdfetn_mi impcntr_mi attitudes imbgeco_mi imueclt_mi imwbcnt_mi {
reg `var' treatment_lampedusa i.treatment_lampedusa##c.support_lampedusa agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num  [w=pspwght*_webal]
outreg2 using Figure7_1stPoly.doc, append  dec(3) bdec(3) alpha(0.001, 0.01, 0.05)
}

foreach var of varlist policy imsmetn_mi imdfetn_mi impcntr_mi attitudes imbgeco_mi imueclt_mi imwbcnt_mi {
reg `var' treatment_lampedusa i.treatment_lampedusa##c.support_lampedusa##c.support_lampedusa agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num  [w=pspwght*_webal]
outreg2 using Figure7_2ndPoly.doc, append  dec(3) bdec(3) alpha(0.001, 0.01, 0.05)
}


** FIGURE 8 **
* Experimenting with different bandwiths *

forvalues i = 75(-15)14 {
	foreach var of varlist policy imsmetn_mi imdfetn_mi impcntr_mi attitudes imbgeco_mi imueclt_mi imwbcnt_mi {
ebalance treatment_lampedusa agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num attempted  if support_lampedusa>=-`i'   & support_lampedusa<=`i' 
*reg `var' t`var' if support_lampedusa>=-`i'   & support_lampedusa<=`i' [w=pspwght*_webal]
*eststo reg3`i'_`var'
reg `var' t`var'  agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num if support_lampedusa>=-`i'   & support_lampedusa<=`i' [w=pspwght*_webal]
eststo reg4`i'_`var'
	}
}
coefplot  reg460_* || reg445_* || reg430_* || reg415_* , keep(tpolicy timsmetn_mi timdfetn_mi timpcntr_mi tattitudes timbgeco_mi timueclt_mi timwbcnt_mi ) mcolor(black) lcolor(black) horizontal  xline(0) legend(off) symbol(0)


* Checking balance of observables in the 15 days bandwitdh
foreach var of varlist agea_mi male_mi eisced_dummy* mainjob_dummy* immigrant_dummy* lrscale_mi {
ttest `var' if support_lampedusa>=-15 & support_lampedusa<=15, by(treatment_lampedusa)
}

	
** Appendix B **
* Generating full regression tables for bandwidth sensitivty *

foreach var of varlist policy imsmetn_mi imdfetn_mi impcntr_mi attitudes imbgeco_mi imueclt_mi imwbcnt_mi {
ebalance treatment_lampedusa agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num attempted  if support_lampedusa>=-60   & support_lampedusa<=60
reg `var' treatment_lampedusa  agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num if support_lampedusa>=-60  & support_lampedusa<=60 [w=pspwght*_webal]
outreg2 using Figure7_60.doc, append  dec(3) bdec(3) alpha(0.001, 0.01, 0.05)
	}

	
foreach var of varlist policy imsmetn_mi imdfetn_mi impcntr_mi attitudes imbgeco_mi imueclt_mi imwbcnt_mi {
ebalance treatment_lampedusa agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num attempted  if support_lampedusa>=-45   & support_lampedusa<=45
reg `var' treatment_lampedusa  agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num if support_lampedusa>=-45  & support_lampedusa<=45 [w=pspwght*_webal]
outreg2 using Figure7_45.doc, append  dec(3) bdec(3) alpha(0.001, 0.01, 0.05)
	}

		
foreach var of varlist policy imsmetn_mi imdfetn_mi impcntr_mi attitudes imbgeco_mi imueclt_mi imwbcnt_mi {
ebalance treatment_lampedusa agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num attempted  if support_lampedusa>=-30   & support_lampedusa<=30
reg `var' treatment_lampedusa  agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num if support_lampedusa>=-30  & support_lampedusa<=30 [w=pspwght*_webal]
outreg2 using Figure7_30.doc,  append  dec(3) bdec(3) alpha(0.001, 0.01, 0.05)
	}

		
foreach var of varlist policy imsmetn_mi imdfetn_mi impcntr_mi attitudes imbgeco_mi imueclt_mi imwbcnt_mi {
ebalance treatment_lampedusa agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num attempted  if support_lampedusa>=-15   & support_lampedusa<=15
reg `var' treatment_lampedusa  agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num if support_lampedusa>=-15  & support_lampedusa<=15 [w=pspwght*_webal]
outreg2 using Figure7_15.doc,  append  dec(3) bdec(3) alpha(0.001, 0.01, 0.05)
	}

	
	
***
reg policy i.treatment_lampedusa#(c.agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi c.lrscale_mi)  i.region_num [w=pspwght*_webal]

reg attitudes i.treatment_lampedusa#(c.agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi c.lrscale_mi i.region_num)  i.region_num [w=pspwght*_webal]
	
*** 
** Appendix C **
* Additional robustness checks *

* Placebo test * 
sum support_lampedusa if support_lampedusa<0
gen placebo_treatment=(support_lampedusa>=-60)
replace placebo_treatment=. if support_lampedusa>=0
ebalance placebo_treatment agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num attempted  

gen ptpolicy=(placebo_treatment)
gen ptimsmetn_mi=(placebo_treatment)
gen ptimdfetn_mi=(placebo_treatment)
gen ptimpcntr_mi=(placebo_treatment)
gen ptattitudes=(placebo_treatment)
gen ptimbgeco_mi=(placebo_treatment)
gen ptimueclt_mi=(placebo_treatment)
gen ptimwbcnt_mi=(placebo_treatment)
 
foreach var of varlist policy imsmetn_mi imdfetn_mi impcntr_mi attitudes imbgeco_mi imueclt_mi imwbcnt_mi {
ebalance pt`var' agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num attempted  
reg `var' pt`var' [w=pspwght*_webal]
eststo placebo1_`var'
reg `var' pt`var' agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num [w=pspwght*_webal]
eststo placebo2_`var'
}
coefplot placebo1_* || placebo2_*, keep(ptpolicy ptimsmetn_mi ptimdfetn_mi ptimpcntr_mi ptattitudes ptimbgeco_mi ptimueclt_mi ptimwbcnt_mi) mcolor(black) lcolor(black) horizontal  xline(0) legend(off) symbol(0)


* Seemingly unrelated regressions
ebalance treatment_lampedusa agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num attempted  

sureg (policy attitudes = treatment_lampedusa) [w=pspwght*_webal]
outreg2 using TableS11.doc,  append  dec(3) bdec(3) alpha(0.001, 0.01, 0.05)

sureg (policy attitudes = treatment_lampedusa agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num) [w=pspwght*_webal]
outreg2 using TableS11.doc,  append  dec(3) bdec(3) alpha(0.001, 0.01, 0.05)

sureg (imsmetn_mi imdfetn_mi impcntr_mi imbgeco_mi imueclt_mi imwbcnt_mi = treatment_lampedusa) [w=pspwght*_webal]
outreg2 using TableS12.doc,  append  dec(3) bdec(3) alpha(0.001, 0.01, 0.05)

sureg (imsmetn_mi imdfetn_mi impcntr_mi imbgeco_mi imueclt_mi imwbcnt_mi = treatment_lampedusa agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num) [w=pspwght*_webal]
outreg2 using TableS12.doc,  append  dec(3) bdec(3) alpha(0.001, 0.01, 0.05)


* Propsensity score matching
foreach var of varlist policy imsmetn_mi imdfetn_mi impcntr_mi attitudes imbgeco_mi imueclt_mi imwbcnt_mi {
teffects psmatch (`var') (t`var' agea_mi male_mi eisced_mi lrscale_mi mainjob_num_mi immigrant_num_mi attempted region_num) 
eststo regS7`var'
teffects psmatch (`var') (t`var' agea_mi male_mi eisced_mi lrscale_mi mainjob_num_mi immigrant_num_mi attempted region_num)  
eststo regS7`var'
}
coefplot regS7* ,  mcolor(black) lcolor(black) horizontal  xline(0) legend(off) symbol(0)


**

*** MISSING VALUE ANALYSIS **

* Missign value analysis

foreach var of varlist imsmetn imdfetn impcntr imbgeco imueclt imwbcnt   {
	gen miss_`var'=(`var'==.)
}

foreach var of varlist miss_imsmetn miss_imdfetn miss_impcntr miss_imbgeco miss_imueclt miss_imwbcnt  {
gen t`var'=treatment_lampedusa
reg `var' t`var' agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi  [w=pspwght*_webal]
eststo regsodmiss`var'
}

coefplot regsodmiss*, keep(t*)  mcolor(black) lcolor(black) horizontal symbol(O)  xline(0) legend(off)
graph save "regsocdmiss.gph"


drop _merge

merge 1:1 idno using "C:\Users\CavalliNic\Downloads\Replication\Analysis_data\ESS Round 6\ESS6_Interviewers\ESS6_InterviewersIT.dta"


foreach var of varlist policy imsmetn_mi imdfetn_mi impcntr_mi attitudes imbgeco_mi imueclt_mi imwbcnt_mi {
*gen t`var'=treatment_lampedusa
areg `var' t`var' agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num  [w=pspwght*_webal], a(intnum)
eststo regsocdint`var'
}

coefplot regsocdint*, keep(t*)  mcolor(black) lcolor(black) horizontal symbol(O)  xline(0) legend(off)
graph save "regsocdint.graph"

** Extend analysis  **

mi unset
drop *_mi

summarize imsmetn imdfetn impcntr imbgeco imueclt imwbcnt agea male eisced mainjob_num immigrant_num lrscale fltsd fltlnl flteeff fltdpr fltpcfl fltanx happy stflife vote wkvlorg attempted region_num eduyrs tvpol tvtot polintr

misstable summarize imsmetn imdfetn impcntr imbgeco imueclt imwbcnt agea male eisced mainjob_num immigrant_num lrscale fltsd fltlnl flteeff fltdpr fltpcfl fltanx happy stflife vote wkvlorg attempted region_num eduyrs tvpol tvtot polintr

foreach var of varlist imsmetn imdfetn impcntr imbgeco imueclt imwbcnt agea male eisced mainjob_num immigrant_num lrscale fltsd fltlnl flteeff fltdpr fltpcfl fltanx happy stflife vote wkvlorg attempted region_num eduyrs tvpol tvtot polintr {
	replace `var'=. if `var'>.
}

mi set wide

mi register imputed  imsmetn imdfetn impcntr imbgeco imueclt imwbcnt agea male eisced mainjob_num immigrant_num lrscale fltsd fltlnl flteeff fltdpr fltpcfl fltanx happy stflife vote wkvlorg attempted region_num eduyrs tvpol tvtot polintr

mi impute mvn imsmetn imdfetn impcntr imbgeco imueclt imwbcnt agea male eisced mainjob_num immigrant_num lrscale fltsd fltlnl flteeff fltdpr fltpcfl fltanx happy stflife vote wkvlorg attempted region_num eduyrs tvpol tvtot polintr, add(100)


foreach var of varlist imsmetn imdfetn impcntr imbgeco imueclt imwbcnt agea male eisced mainjob_num immigrant_num lrscale fltsd fltlnl flteeff fltdpr fltpcfl fltanx happy stflife vote wkvlorg attempted region_num eduyrs tvpol tvtot polintr  {
		egen `var'_mi= rowmean(_1_`var' _2_`var' _3_`var' _4_`var' _5_`var' _6_`var' _7_`var' _8_`var' _9_`var' _10_`var' _11_`var' _12_`var' _13_`var' _14_`var' _15_`var' _16_`var' _17_`var' _18_`var' _19_`var' _20_`var')
	}

foreach var of varlist *_mi {
replace `var'=round(`var')
}

ebalance treatment_lampedusa agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi i.region_num attempted

** FIGURE 9
** Social desirability
foreach var of varlist vote_mi wkvlorg_mi   {
gen t`var'=treatment_lampedusa
reg `var' t`var' agea_mi i.male_mi i.eisced_mi i.mainjob_num_mi i.immigrant_num_mi lrscale_mi  [w=pspwght*_webal]
eststo regnewsocdes_`var'
}

coefplot regnewsocdes_*, keep(tvote_mi twkvlorg_mi ) mcolor(black) lcolor(black) horizontal  xline(0) legend(off)


coefplot regnewsocdes_* || regsocdmiss* || regsocdint*  , keep(t*) mcolor(black) lcolor(black) horizontal  xline(0) legend(off)

graph save "socdes3.gph", replace

graph use "socdes3.gph"
graph save socdes3.gph, replace

graph use "regsocdmiss.graph"
graph save regsocdmiss.gph, replace

graph use "regsocdint.graph"
graph save regsocdint.gph, replace

graph combine socdes3.gph regsocdmiss.gph regsocdint.gph, rows(1) 
 
** FIGURE 4 **
foreach var of varlist fltsd_mi fltlnl_mi flteeff_mi fltdpr_mi fltpcfl_mi fltanx_mi happy_mi stflife_mi {
 	cibar `var' [w=pspwght*_webal], over(treatment_lampedusa)
	graph save "cibar_`var'", replace
	}
	
	foreach var of varlist fltsd_mi fltlnl_mi flteeff_mi fltdpr_mi fltpcfl_mi fltanx_mi happy_mi stflife_mi {
 	graph use cibar_`var'
	}
	
	graph combine cibar_fltsd_mi cibar_fltlnl_mi cibar_flteeff_mi cibar_fltdpr_mi cibar_fltpcfl_mi cibar_fltanx_mi cibar_happy_mi cibar_stflife_mi, title("Emotions after the Lampedusa Shipwreck") rows(2)
	
	* Save the graphs for each variable
foreach var of varlist fltsd_mi fltlnl_mi flteeff_mi fltdpr_mi fltpcfl_mi fltanx_mi happy_mi stflife_mi {
    cibar `var' [w=pspwght*_webal], over(treatment_lampedusa)
    graph save "cibar_`var'.gph", replace
}

* Load the saved graphs into memory before combining
graph use "cibar_fltsd_mi.gph"
graph use "cibar_fltlnl_mi.gph"
graph use "cibar_flteeff_mi.gph"
graph use "cibar_fltdpr_mi.gph"
graph use "cibar_fltpcfl_mi.gph"
graph use "cibar_fltanx_mi.gph"
graph use "cibar_happy_mi.gph"
graph use "cibar_stflife_mi.gph"

* Now combine the graphs
graph combine cibar_fltsd_mi.gph cibar_fltlnl_mi.gph cibar_flteeff_mi.gph cibar_fltdpr_mi.gph ///
             cibar_fltpcfl_mi.gph cibar_fltanx_mi.gph cibar_happy_mi.gph cibar_stflife_mi.gph, ///
             title("Emotions after the Lampedusa Shipwreck") rows(2)