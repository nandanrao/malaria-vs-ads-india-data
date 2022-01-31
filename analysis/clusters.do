* GET TREATMENT ASSIGNMENT MASTERFILE
cd "/Users/dantedonati/GitHub/malaria-vs-ads-india-data/analysis"

import delim using "data/final/regression-data/xsection.csv", clear
keep stratumid treatment cluster_kutcha cluster_pucca cluster_university cluster_unemployed cluster_malaria5year cluster_malaria2weeks cluster_sleepundernet cluster_population 
bys stratumid: keep if _n==1
drop if treatment==.
rename stratumid disthash

* drop district with duplicated name: Balrampur
*drop if disthash == "ff099f99"

preserve
import delim using "data/final/geography/base-cities.csv", clear
keep distname disthash state
bys state disthash: keep if _n==1

* drop district with duplicated name: Balrampur
*drop if disthash == "ff099f99"
tempfile temp
save `temp'
restore

merge 1:m disthash using `temp', keep(master matched) nogen
sort state distname
  gen district = distname

replace cluster_population = 2192933 if district == "Sambhal"
replace cluster_population = 1274815 if district == "Samli"

     replace district=subinstr(district," ","",.)
     replace district=subinstr(district,"-","",.)
     replace state=subinstr(state," ","",.)

     replace district = "Korea" if district == "Koriya"
     replace district = "Koderma" if district == "Kodarma"
     replace district = "EastSinghbum" if district == "PurbiSinghbhum"
     replace district = "Prayagraj" if district == "Allahabad"
     replace district = "Barabanki" if district == "BaraBanki"
     replace district = "Ayodhya" if district == "Faizabad"     
     replace district = "Amroha" if district == "JyotibaPhuleNagar"
     replace district = "Kasganj" if district == "KanshiramNagar"
     replace district = "KushiNagar" if district == "Kushinagar"
     replace district = "Hathras" if district == "MahamayaNagar"
     replace district = "Shamli" if district == "Samli"
     replace district = "Bhadohi" if district == "SantRavidasNagar(Bhadohi)"
     replace district = "Maharajganj" if district == "Mahrajganj"

     replace state = "Chhattisgarh" if state == "Chhatisgarh"

save "/Users/dantedonati/GitHub/malaria-vs-ads-india-data/analysis/data/malaria/treatment_assignment.dta", replace



*keep if disthash=="ff099f99" //DUPLICATED DISTRICT NAME




* IMPORT, CLEAN and RESHAPE RAW MALARIA DATA
global dir "/Users/dantedonati/GitHub/malaria-vs-ads-india-data/analysis/data/malaria"

local states "Chhattisgarh Jharkhand UttarPradesh"
local dates "Apr2019 May2019 Jun2019 Jul2019 Aug2019 Sep2019 Oct2019 Nov2019 Dec2019 Jan2020 Feb2020 Mar2020 Apr2020 May2020 Jun2020 Jul2020 Aug2020 Sep2020 Oct2020 Nov2020 Dec2020 Jan2021 Feb2021 Mar2021 Apr2021 May2021"
*local dates "Apr2020 May2020"

foreach state of local states {
     foreach date of local dates {

import excel "$dir/raw/`state'2020_2021/`state'_`date'.xlsx", clear

*import excel "$dir/raw/Chhattisgarh2020_2021/Chhattisgarh_Apr2020.xlsx", clear

replace A = "type" if _n==7
replace A = "type" if _n==8

carryforward A, replace

keep if 	A == "type" | ///
		A == "M10 [Number of cases of Childhood Diseases (0-5 years)]" | ///
		A == "M11 [NVBDCP]" | ///
		A == "M16 [Details of deaths reported with probable causes:]"


compress
replace C="type" if C==""
drop A B D

     local j=0
     foreach var of varlist _all {
          local j=`j'+1     
               rename `var' v`j'
      }

local var_num = 0
foreach var of varlist _all {
     replace `var'= "total" in 2 if `var'=="Total [(A+B) or (C+D)]" 
     replace `var'= "public" in 2 if `var'=="Public [A]" 
     replace `var'= "private" in 2 if `var'=="Private [B]" 
     replace `var'= "urban" in 2 if `var'=="Urban [C]" 
     replace `var'= "rural" in 2 if `var'=="Rural [D]" 
     local var_num = `var_num'+1
 }

     forvalues i = 3/`var_num' {
          local j= `i'-1
          replace v`i'= v`j' in 1 if v`i'=="" 
     }

     forvalues i = 2/`var_num' {
          replace v`i'= v`i'[2]+v`i' in 1
          replace v`i'=subinstr(v`i'," ","",.)
          replace v`i'=subinstr(v`i',"-","",.)

     }

drop v2-v6
foreach var of varlist _all {
     cap rename `var' `=`var'[1]'
 }

drop if _n<=2

     reshape long total public private urban rural, i(type) j(district) string
 

     *CT
     replace district = "Korea" if district == "Koriya"
     replace district = "Bemetara" if district == "Bemetra"
     replace district = "Kabirdham" if district == "Kawardha"
     *replace district = "Bilaspur" if district == "GaurellaPendraMarwahi"
     * GaurellaPendraMarwahi is new: before it was within Bilaspur

     *JK
     replace district = "EastSinghbum" if district == "PurbiSinghbhum"
     replace district = "Koderma" if district == "Kodarma"
     replace district = "Sahibganj" if district == "Sahebganj"
     replace district = "WestSinghbhum" if district == "PashchimiSinghbhum"
     replace district = "SaraikelaKharsawan" if district == "Saraikela"

     *UP
     replace district = "Baghpat" if district == "Bagpat"
     replace district = "Prayagraj" if district == "Allahabad"
     replace district = "Ayodhya" if district == "Faizabad"     
     replace district = "Amroha" if district == "JyotibaPhuleNagar"
     replace district = "Kasganj" if district == "KashiRamNagar"
     replace district = "KushiNagar" if district == "Kushinagar"
     replace district = "Bhadohi" if district == "SantRavidasNagar"
     replace district = "Unnao" if district == "Unnav"
     replace district = "Shravasti" if district == "Shrawasti"
     replace district = "SantKabirNagar" if district == "SantKabeerNagar"
     replace district = "Bulandshahr" if district == "Bulandshahar"
     replace district = "Kheri" if district == "LakhimpurKheri"
     replace district = "Mau" if district == "Maunathbhanjan"
     replace district = "Amethi" if district == "CSMNagar"

destring total public private urban rural, replace
*collapse (sum) total public private urban rural , by(district type)

gen state = "`state'"
gen date = "`date'"

save "$dir/raw/`state'2020_2021/`state'_`date'.dta", replace
     }
}


local states "Chhattisgarh Jharkhand UttarPradesh" 
     foreach state of local states {
u "$dir/raw/`state'2020_2021/`state'_Apr2019.dta", clear

     local dates "May2019 Jun2019 Jul2019 Aug2019 Sep2019 Oct2019 Nov2019 Dec2019 Jan2020 Feb2020 Mar2020 Apr2020 May2020 Jun2020 Jul2020 Aug2020 Sep2020 Oct2020 Nov2020 Dec2020 Jan2021 Feb2021 Mar2021 Apr2021 May2021"
          foreach date of local dates {
               append using "$dir/raw/`state'2020_2021/`state'_`date'.dta" 
          }

     gen date_numeric = date(date, "MY")
     gen year = year(date_numeric)
     gen month = month(date_numeric)

     order state district type date date_numeric year month
     sort district type date_numeric

     save "$dir/raw/`state'2020_2021/`state'_all.dta", replace

}



 * ANALYSIS
global dir "/Users/dantedonati/GitHub/malaria-vs-ads-india-data/analysis/data/malaria"
     u "$dir/raw/Chhattisgarh2020_2021/Chhattisgarh_all.dta", clear
     append using "$dir/raw/Jharkhand2020_2021/Jharkhand_all.dta"
     append using "$dir/raw/UttarPradesh2020_2021/UttarPradesh_all.dta"

     encode type, gen(type_numeric)
     order state district type


     merge m:1 state district using "$dir/treatment_assignment.dta", keep(master matched)

     gen outcome = "malaria_positive" if ///
     type == "Malaria (Microscopy Tests ) - Plasmodium Falciparum test positive" | ///
     type == "Malaria (Microscopy Tests ) - Plasmodium Vivax test positive" | ///
     type == "Malaria (RDT) - Plamodium Falciparum test positive" | ///
     type == "Malaria (RDT) - Plasmodium Vivax test positive"

     replace outcome = "malaria_tests" if ///
     type == "Total Blood Smears Examined for Malaria" | ///
     type == "RDT conducted for Malaria"   

     replace outcome = "childhood_all" if type_numeric>=1 & type_numeric<=13
     replace outcome = "childhood_malaria" if type_numeric==6

     replace outcome = "deaths_adults_all" if type_numeric>=29 & type_numeric<=42
     replace outcome = "deaths_adults_all" if type_numeric>=48 & type_numeric<=53
     replace outcome = "deaths_adults_all" if type_numeric>=59 & type_numeric<=65

     replace outcome = "deaths_adults_malaria" if type_numeric==52| type_numeric==53
     
     replace outcome = "kalaazar_positive" if type_numeric==24
     replace outcome = "kalaazar_tests" if type_numeric==23
    
     replace outcome = "encephalitis_positive" if type_numeric==69
     replace outcome = "encephalitis_tests" if type_numeric==68

     keep if outcome != ""


     * GET TOTAL NUMBERS IN THE THREE STATES
    * collapse (sum) total public private urban rural, by(outcome)
  

     * CONTINUE ANALYSIS IN OUR DISTRICTS
     keep if _m==3
     drop _m
     drop if district == "Balrampur"
     collapse (sum) total public private urban rural (first) treatment cluster_* date year month, by(state district date_numeric outcome)

    
    
     bys state district date_numeric (outcome): gen malaria_rate = total/total[_n+1] if outcome=="malaria_positive"
     bys state district date_numeric (outcome): gen malaria_rate_u = urban/urban[_n+1] if outcome=="malaria_positive"
     bys state district date_numeric (outcome): gen malaria_rate_r = rural/rural[_n+1] if outcome=="malaria_positive"

     bys state district date_numeric (outcome): gen malaria_rate_pub = public/public[_n+1] if outcome=="malaria_positive"
     bys state district date_numeric (outcome): gen malaria_rate_pri = private/private[_n+1] if outcome=="malaria_positive"

     bys state district date_numeric (outcome): gen malaria_tests = total if outcome=="malaria_tests"
     bys state district date_numeric (outcome): gen malaria_tests_u = urban if outcome=="malaria_tests"
     bys state district date_numeric (outcome): gen malaria_tests_r = rural if outcome=="malaria_tests"

     bys state district date_numeric (outcome): gen malaria_death_rate = total/total[_n-1] if outcome=="deaths_adults_malaria"
     bys state district date_numeric (outcome): gen malaria_death_rate_u = urban/urban[_n-1] if outcome=="deaths_adults_malaria"
     bys state district date_numeric (outcome): gen malaria_death_rate_r = rural/rural[_n-1] if outcome=="deaths_adults_malaria"

     bys state district date_numeric (outcome): gen malaria_child_rate = total/total[_n-1] if outcome=="childhood_malaria"
     bys state district date_numeric (outcome): gen malaria_child_rate_u = urban/urban[_n-1] if outcome=="childhood_malaria"
     bys state district date_numeric (outcome): gen malaria_child_rate_r = rural/rural[_n-1] if outcome=="childhood_malaria"

     bys state district date_numeric (outcome): gen encephalitis_rate = total/total[_n+1] if outcome=="encephalitis_positive"
     bys state district date_numeric (outcome): gen encephalitis_rate_u = urban/urban[_n+1] if outcome=="encephalitis_positive"
     bys state district date_numeric (outcome): gen encephalitis_rate_r = rural/rural[_n+1] if outcome=="encephalitis_positive"

     bys state district date_numeric (outcome): gen kalaazar_rate = total/total[_n+1] if outcome=="kalaazar_positive"
     bys state district date_numeric (outcome): gen kalaazar_rate_u = urban/urban[_n+1] if outcome=="kalaazar_positive"
     bys state district date_numeric (outcome): gen kalaazar_rate_r = rural/rural[_n+1] if outcome=="kalaazar_positive"

     *collapse (first) treatment cluster_* date year month (max) child_malaria_rate child_malaria_rate_u child_malaria_rate_r deaths_malaria_rate deaths_malaria_rate_u deaths_malaria_rate_r malaria_rate malaria_rate_u malaria_rate_r, by(state district date_numeric)
     collapse (first) treatment cluster_* date year month (max)  malaria_rate* malaria_tests* malaria_death_rate* malaria_child_rate* kalaazar_rate* encephalitis_rate*, by(state district date_numeric)
 

     * RECODE OUTLIERS TO MISSING
     foreach x of varlist malaria_rate malaria_rate_u malaria_rate_r malaria_rate_pub malaria_rate_pri malaria_tests malaria_tests_u malaria_tests_r malaria_death_rate malaria_death_rate_u malaria_death_rate_r malaria_child_rate malaria_child_rate_u malaria_child_rate_r kalaazar_rate kalaazar_rate_u kalaazar_rate_r encephalitis_rate encephalitis_rate_u encephalitis_rate_r {
          qui sum `x',d 
          recode `x' (*=.) if `x'>r(p99)
     }
      

     *drop if date_numeric == 22401

     * Campaign was ON AIR in Sep2020-Jan2021
     * Sep2020: 22159
     gen post = (date_numeric >= 22159)
     *gen post = (date_numeric >= 22281)
     *replace post = . if date_numeric < 22281 & date_numeric>=22159
     *aug 2020: 22128 
     *aug 2019: 21762


     gen treatment_post = treatment*post
    
     gen lcluster_population = log(cluster_population)
     *global controls cluster_kutcha cluster_university cluster_unemployed cluster_malaria5year cluster_sleepundernet //cluster_malaria2weeks  cluster_pucca
     global controls cluster_kutcha cluster_pucca cluster_university cluster_malaria5year cluster_sleepundernet //cluster_unemployed cluster_malaria2weeks 
  
     la var treatment_post "Treated*Post"
     la var treatment "Treated"
     la var post "Post"
     gen con = 1
   
     * 21793 = date Sep 2019
     eststo clear
     qui eststo: reghdfe malaria_rate treatment treatment_post post  if date_numeric>=21793, absorb(month year) cluster(district)
     qui sum malaria_rate if e(sample) == 1 & post == 0
     estadd scalar mean_pre =  r(mean)   
     estadd scalar sd_pre =  r(sd)   
     qui eststo: reghdfe malaria_rate treatment treatment_post post  lcluster_population $controls if date_numeric>=21793, absorb(month year) cluster(district)
     qui sum malaria_rate if e(sample) == 1 & post == 0
     estadd scalar mean_pre =  r(mean)   
     estadd scalar sd_pre =  r(sd)    
     qui eststo: reghdfe malaria_rate  treatment_post post con if date_numeric>=21793, absorb(district month year) cluster(district)
     qui sum malaria_rate if e(sample) == 1 & post == 0
     estadd scalar mean_pre =  r(mean)   
     estadd scalar sd_pre =  r(sd)   
   
      eststo: reghdfe malaria_rate_u treatment treatment_post post  if date_numeric>=21793, absorb(month year) cluster(district)
     qui sum malaria_rate_u if e(sample) == 1 & post == 0
     estadd scalar mean_pre =  r(mean)  
     estadd scalar sd_pre =  r(sd)   
     qui eststo: reghdfe malaria_rate_u treatment treatment_post post lcluster_population $controls if date_numeric>=21793, absorb(month year) cluster(district)
     qui sum malaria_rate_u if e(sample) == 1 & post == 0
     estadd scalar mean_pre =  r(mean)   
     estadd scalar sd_pre =  r(sd)   
     qui eststo: reghdfe malaria_rate_u  treatment_post post con if date_numeric>=21793, absorb(district month year) cluster(district)
     qui sum malaria_rate_u if e(sample) == 1 & post == 0
     estadd scalar mean_pre =  r(mean)   
     estadd scalar sd_pre =  r(sd)   
    
     qui eststo: reghdfe malaria_rate_r treatment treatment_post post  if date_numeric>=21793, absorb(month year) cluster(district)
     qui sum malaria_rate_r if e(sample) == 1 & post == 0
     estadd scalar mean_pre =  r(mean)   
     estadd scalar sd_pre =  r(sd)   
     qui eststo: reghdfe malaria_rate_r treatment treatment_post post  lcluster_population $controls if date_numeric>=21793, absorb(month year) cluster(district)
     qui sum malaria_rate_r if e(sample) == 1 & post == 0
     estadd scalar mean_pre =  r(mean)   
     estadd scalar sd_pre =  r(sd)   
     qui eststo: reghdfe malaria_rate_r  treatment_post post con if date_numeric>=21793, absorb(district month year) cluster(district)
     qui sum malaria_rate_r if e(sample) == 1 & post == 0
     estadd scalar mean_pre =  r(mean)   
     estadd scalar sd_pre =  r(sd)   

     esttab using "/Users/dantedonati/GitHub/malaria-vs-ads-india-data/tables/incidence_dd.tex",  star(* 0.1 ** 0.05 *** 0.01) nonumber nomtitles replace mlabels("(1)" "(2)" "(3)" "(4)" "(5)" "(6)" "(7)" "(8)" "(9)") ///
     label se compress nogaps depvars se(%9.3f) b(%9.3f) stats(N r2_a mean_pre sd_pre, fmt(%9.0f  %9.3f %9.3f %9.3f) labels("Observations" "Adj. R-squared" "Baseline Mean" "Baseline SD") layout("\num{@}"))  keep(treatment treatment_post) ///
     order(treatment_post treatment)  mgroups("Overall incidence" "Urban incidence" "Rural incidence", pattern(1 0 0 1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
     indicate("Month and year FE=post" "District FE=con" "Controls=lcluster_population", l($\checkmark$ "")) note("Standard errors are clustered at the district level. The panel includes observations between September 2019 and May 2021. Post takes value 1 after August 2020, i.e. when the Facebook campaign started. Controls include: (log) district population, shares of respondents living in kutcha and pucca dwellings, share of respondents with university degree, 5-year malaria prevalence, share of respondents sleeping under mosquito nets. Source: Health Management Information System.")


 
     * T/C comparison  
     *ttest malaria_rate_u if post == 1, by(treatment)
     eststo clear
     qui reg malaria_rate_u treatment lcluster_population $controls if date_numeric>= 22312, cluster(district)
     estimates store malaria_rate_u_after
     qui reg malaria_rate_u treatment lcluster_population $controls if date_numeric< 22312 & date_numeric>=22159, cluster(district)
     estimates store malaria_rate_u_during
     qui reg malaria_rate_u treatment lcluster_population $controls if date_numeric< 22159 & date_numeric>=22036, cluster(district)
     estimates store malaria_rate_u_before
     qui reg malaria_rate_u treatment lcluster_population $controls if date_numeric< 22036 & date_numeric>=21915, cluster(district)
      estimates store malaria_rate_u_before2

     qui reg malaria_rate_r treatment lcluster_population $controls if date_numeric>= 22312, cluster(district)
     estimates store malaria_rate_r_after
     qui reg malaria_rate_r treatment lcluster_population $controls if date_numeric< 22312 & date_numeric>=22159, cluster(district)
     estimates store malaria_rate_r_during
     qui reg malaria_rate_r treatment lcluster_population $controls if date_numeric< 22159 & date_numeric>=22036, cluster(district)
     estimates store malaria_rate_r_before
     qui reg malaria_rate_r treatment lcluster_population $controls if date_numeric< 22036 & date_numeric>=21915, cluster(district)
      estimates store malaria_rate_r_before2

coefplot (malaria_rate_u_before, rename(treatment="May-Aug 2020") drop(lcluster_population $controls _cons)  mlcolor(gs5) mfcolor(gs5)  ciopts(lcolor(gs5))) ///
(malaria_rate_u_during, rename(treatment="Sep2020-Jan2021") drop(lcluster_population $controls _cons) mlcolor(gs5) mfcolor(gs5)  ciopts(lcolor(gs5))) ///
(malaria_rate_u_after, rename(treatment="Feb-May 2021") drop(lcluster_population $controls _cons) mlcolor(gs5) mfcolor(gs5)  ciopts(lcolor(gs5))), bylabel(Urban incidence (treated vs. control districts)) ///
||  (malaria_rate_r_before, rename(treatment="May-Aug 2020") drop(lcluster_population $controls _cons) mlcolor(gs5) mfcolor(gs5)  ciopts(lcolor(gs5))) ///
(malaria_rate_r_during, rename(treatment="Sep2020-Jan2021") drop(lcluster_population $controls _cons) mlcolor(gs3) mfcolor(gs3)  ciopts(lcolor(gs3))) ///
(malaria_rate_r_after, rename(treatment="Feb-May 2021") drop(lcluster_population $controls _cons) mlcolor(gs5) mfcolor(gs5)  ciopts(lcolor(gs5))), bylabel(Rural incidence (treated vs. control districts)) ///
||,  yline(0, lpattern(dash) lcolor(gs8)) vertical nooffsets   byopts(rows(2)  legend(off) graphregion(color(white))) mlabel(cond(@pval<.05, string(@b,"%9.3f") + "**", string(@b,"%9.3f"))) format(%9.2g) mlabposition(3) mlabgap(*2) mlabcolor(gs4) ///
addplot(scatteri -0.02 1.5 -0.02 2.5 0.013 2.5 0.013 1.5, recast(area) lwidth(none) fcolor(gs5%25))
graph export "/Users/dantedonati/GitHub/malaria-vs-ads-india-data/tables/incidence.pdf", replace



/*coefplot (malaria_rate_u_before2, rename(treatment="Jan-Apr20") drop(lcluster_population $controls _cons) omit  mlcolor(gs5) mfcolor(gs5)  ciopts(lcolor(gs5))) ///
(malaria_rate_u_before, rename(treatment="May-Aug20") drop(lcluster_population $controls _cons) omit  mlcolor(gs5) mfcolor(gs5)  ciopts(lcolor(gs5))) ///
(malaria_rate_u_during, rename(treatment="Sep20-Jan21") drop(lcluster_population $controls _cons) omit mlcolor(gs5) mfcolor(gs5)  ciopts(lcolor(gs5))) ///
(malaria_rate_u_after, rename(treatment="Feb-May21") drop(lcluster_population $controls _cons) omit mlcolor(gs5) mfcolor(gs5)  ciopts(lcolor(gs5))), bylabel(Urban incidence (treated vs. control districts)) ///
||  (malaria_rate_r_before2, rename(treatment="Jan-Apr20") drop(lcluster_population $controls _cons) omit mlcolor(gs5) mfcolor(gs5)  ciopts(lcolor(gs5))) ///
(malaria_rate_r_before, rename(treatment="May-Aug20") drop(lcluster_population $controls _cons) omit mlcolor(gs5) mfcolor(gs5)  ciopts(lcolor(gs5))) ///
(malaria_rate_r_during, rename(treatment="Sep20-Jan21") drop(lcluster_population $controls _cons) omit mlcolor(gs5) mfcolor(gs5)  ciopts(lcolor(gs5))) ///
(malaria_rate_r_after, rename(treatment="Feb-May21") drop(lcluster_population $controls _cons) omit mlcolor(gs5) mfcolor(gs5)  ciopts(lcolor(gs5))), bylabel(Rural incidence (treated vs. control districts)) ///
||,  yline(0, lpattern(dash) lcolor(gs8)) xline(3.5) vertical nooffsets   byopts( rows(2)  legend(off) graphregion(color(white))) mlabel format(%9.2g) mlabposition(3) mlabgap(*2) mlabcolor(gs5)
*/


     reg malaria_rate_r treatment lcluster_population $controls if date_numeric>= 22312, cluster(district)
     reg malaria_rate_r treatment lcluster_population $controls if date_numeric< 22312 & date_numeric>=22159, cluster(district)
     reg malaria_rate_r treatment lcluster_population $controls if date_numeric< 22159 & date_numeric>=22036, cluster(district)


     ttest malaria_rate_r if post == 1, by(treatment)
     reg malaria_rate_r treatment if post == 1 
     reg malaria_rate_r treatment lcluster_population $controls if post == 1 

     



     *children
     reghdfe malaria_child_rate treatment treatment_post post  if date_numeric>=21793, absorb(month year) cluster(district)
     reghdfe malaria_child_rate treatment treatment_post post lcluster_population $controls if date_numeric>=21793, absorb(month year) cluster(district)
     reghdfe malaria_child_rate treatment treatment_post post if date_numeric>=21793, absorb(district month year) cluster(district)
     

     * check if more people test for malaria
     gen lmalaria_tests_u = log(malaria_tests_u+1)
     reghdfe lmalaria_tests_u treatment treatment_post post  if date_numeric>=21793, absorb(month year) cluster(district)
     reghdfe lmalaria_tests_u treatment treatment_post post lcluster_population $controls if date_numeric>=21793, absorb(month year) cluster(district)
     reghdfe lmalaria_tests_u treatment treatment_post post if date_numeric>=21793, absorb(district month year) cluster(district)
     
     gen lmalaria_tests_r = log(malaria_tests_r+1)
     reghdfe lmalaria_tests_r treatment treatment_post post  if date_numeric>=21793, absorb(month year) cluster(district)
     reghdfe lmalaria_tests_r treatment treatment_post post lcluster_population $controls if date_numeric>=21793, absorb(month year) cluster(district)
     reghdfe lmalaria_tests_r treatment treatment_post post if date_numeric>=21793, absorb(district month year) cluster(district)
     

     * mortality rate due to malaria
     reghdfe malaria_death_rate treatment treatment_post post  if date_numeric>=21793, absorb(month year) cluster(district)
     reghdfe malaria_death_rate treatment treatment_post post lcluster_population $controls if date_numeric>=21793, absorb(month year) cluster(district)
     reghdfe malaria_death_rate treatment treatment_post post if date_numeric>=21793, absorb(district month year) cluster(district)
        
     reghdfe malaria_death_rate_u treatment treatment_post post  if date_numeric>=21793, absorb(month year) cluster(district)
     reghdfe malaria_death_rate_u treatment treatment_post post lcluster_population $controls if date_numeric>=21793, absorb(month year) cluster(district)
     reghdfe malaria_death_rate_u treatment treatment_post post if date_numeric>=21793, absorb(district month year) cluster(district)
        
     reghdfe malaria_death_rate_r treatment treatment_post post  if date_numeric>=21793, absorb(month year) cluster(district)
     reghdfe malaria_death_rate_r treatment treatment_post post lcluster_population $controls if date_numeric>=21793, absorb(month year) cluster(district)
     reghdfe malaria_death_rate_r treatment treatment_post post if date_numeric>=21793, absorb(district month year) cluster(district)
        







     * dynamic DD
     tab date_numeric, gen(t)
     foreach t of varlist t1-t26 {
          gen treatment_`t' = treatment*`t'
     }
     reghdfe malaria_rate_u treatment_t3-treatment_t16 treatment_t18-treatment_t26 if date_numeric>=21701, absorb(district month#year)


/*
date date_numeric
Apr2019   21640
May2019   21670
Jun2019   21701
Jul2019   21731
Aug2019   21762
Sep2019   21793
Oct2019   21823
Nov2019   21854
Dec2019   21884
Jan2020   21915
Feb2020   21946
Mar2020   21975
Apr2020   22006
May2020   22036
Jun2020   22067
Jul2020   22097
Aug2020   22128
Sep2020   22159
Oct2020   22189
Nov2020   22220
Dec2020   22250
Jan2021   22281
Feb2021   22312
Mar2021   22340
Apr2021   22371
May2021   22401





/*
forval j = 1/14 {
     rename var`j' `=var`j'[1]'
 }

*foreach var of varlist _all {
*     replace `var'= `var'[2] in 1 if `var'=="" 
* }


foreach var of varlist _all {
     replace `var'= `var'[2] in 1 if `var'=="" 
 }


foreach var of varlist _all {
     replace `var'= `var'[2] in 1 if `var'=="" 
 }



foreach var of varlist _all {
     cap rename `var' district`var'
 }
