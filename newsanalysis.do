** Replication of web search volumes and news coverage of the shipwreck
* This version: March 2024

*** FIGURE 1 ***
import delimited "Replication/News_data/GoogleTrends/Trends/Italy - 2008-2018 - 'Lampedusa' 'Pantelleria'.csv", encoding(ISO-8859-9) clear 
gen ym=ym(year, month) 
format ym %tm
twoway line Lampedusa Pantelleria Date, xaxis(1 2) xla(19634 "Shipwreck", axis(2) grid glcolor(white)) xtitle("", axis(2)) 

*** FIGURE S1 ***
import excel "${folder}/Data/news_articles.xlsx", sheet("Sheet1") firstrow clear
drop if Day==.
destring Year, replace
destring camera_ratio, replace
twoway line factiva_ratio camera_ratio Date, xaxis(1 2) xla(19634 "Shipwreck", axis(2) grid glcolor(white)) xtitle("", axis(2)) 


** FIGURE S2 ***
import delimited "${folder}/Data/gtrends.csv", encoding(ISO-8859-9) clear 
gen ym=ym(year, month) 
format ym %tm
twoway line Lampedusa ym, xaxis(1 2) xla(645 "Shipwreck", axis(2) grid glcolor(white)) xtitle("", axis(2)) 