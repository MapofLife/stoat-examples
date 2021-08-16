Scripts and data for:

A cloud-based toolbox for the versatile environmental annotation of biodiversity data

Richard Li, Ajay Ranipeta, John Wilshire, Jeremy Malczyk, Michelle Duong, Robert Guralnick, Adam Wilson, Walter Jetz

--------------------------------------------------------------------------------------------------------------------

1_stoat_data_prep.R
------------
-RTHU + TUTI
-takes in raw ebird database file (very large, not included, retrieve using details below)
-filters down by occurrence type (still very large, files not included)
-data sampled to 20,000 points and then thinned, results written, included here as 'hummingbird_thinned' and 'titmouse_thinned' directories
-data reformatted, stored as ruby-throated_hummingbird.csv and tufted_titmouse.csv
-data sent to STOAT and annotation initiated, results downloaded, put in 'annotated' directory 
------------
-ANHU
-takes in raw ebird database file (very large, not included, retrieve using details below)
-filters down by occurrence type (still very large, files not included)
-data sorted into spatial grain bins, each bin thinned
-thinned data trimmed to 2500 records per spatial grain bin
-data compiled into two CSVs, one with just the records to send for annotation- "annas_hummingbird_all.csv" and one with all the necessary metadata needed for later analysis - "annas_humminbird_all_ref.csv"
-data sent to STOAT and annotation initiated, results downloaded, named "rl_anno_evi_final.csv"
-data uploaded to Google Earth Engine and annotation initiated, results downloaded, in the 'gee' directory
-gee script included in 'gee' directory
------------

2_stoat_data_analyses.R
------------
-RTHU + TUTI
-reads from 'annotated' directory, conducts analyses and generates figures in R
------------
-ANHU
-reads annotated values from 'gee' directory, "rl_anno_evi_final.csv", joins using "annas_hummingbird_all_ref.csv", conducts analyses and generates figures in R

--------------------------------------------------------------------------------------------------------------------

CONTENTS:
---------
Data are sorted into two directories by case study
-casestudy_RTHU+TUTI <- Ruby-throated hummingbird and tufted titmouse (Figures 5-7)
 -hummingbird_thinned/titmouse_thinned: intermediate outputs from spatial thinning step
 -ruby-throated_hummingbird.csv: final occurrence record set for the ruby-throated hummingbird, goes into STOAT
 -tufted_titmouse.csv: final occurrence record set for the tufted titmouse, goes into STOAT
 -annotated: annotated results from STOAT, used in stoat_data_analyses.R

-casestudy_ANHU <- Anna's hummingbird (Figure 8)
 -annas_hummingbird_all: final occurrence record set for the Anna's hummingbird, goes into STOAT and GEE
 -annas_hummingbird_all_ref: final occurrence records + extra metadata columns important in analysis
 -rl_anno_evi_final.csv: annotated results from STOAT, used in stoat_data_analyses.R
 -gee: annotated results from GEE, used in stoat_data_analyses.R, also GEE script used

--------------------------------------------------------------------------------------------------------------------

SOURCE DATA:
------------
Raw datasets were gigabytes large and were not included here. To replicate results, please download the raw datasets from the Ebird basic dataset as specified below.

----------------------------------------------
Ruby-throated hummingbird and tufted titmouse:

EBird Basic Dataset Version 1.12, July 2020. Retrieved September 13, 2020.
Link: https://ebird.org/data/download/ebd
Citation: eBird Basic Dataset. Version: EBD_relJul-2020. Cornell Lab of Ornithology, Ithaca, New York. Jul 2020.

File 1:
Species: Tufted titmouse
Region: All Regions
Date Range: All Dates (Filtered later using auk)

File 2:
Species: Ruby-throated hummingbird
Region: All Regions
Date Range: All Dates (Filtered later using auk)

----------------------------------------------
Anna's hummingbird:

EBird Basic Dataset Version 1.13, April 2021. Retrieved June 4, 2021.
Link: https://ebird.org/data/download/ebd
Citation: eBird Basic Dataset. Version: EBD_relApr-2021. Cornell Lab of Ornithology, Ithaca, New York. Apr 2021.

File 3:
Species: Anna's hummingbird
Region: All Regions
Date Range: All Dates (Filtered later using auk)
