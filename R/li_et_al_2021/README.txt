Scripts for:

STOAT - A cloud-based toolbox for the versatile environmental annotation of biodiversity data

Richard Li, Ajay Ranipeta, John Wilshire, Jeremy Malczyk, Michelle Duong, Robert Guralnick, Adam Wilson, Walter Jetz

1_stoat_data_prep.R

-takes in raw ebird database file (very large, not included, details below)
-filters down by occurrence type (still very large)
-data sampled to 20,000 points and then thinned, results included here as 'hummingbird_thinned' and 'titmouse_thinned' directories
-data reformatted, stored as ruby-throated_hummingbird.csv and tufted_titmouse.csv
-data uploaded to STOAT and annotation initiated, results downloaded manually, in 'annotated' directory 

2_stoat_data_analyses.R

-reads from 'annotated' directory, conducts analyses and generates figures in R

-------------------------

SOURCE DATA:

EBird Basic Dataset Version 1.12, July 2020. Retrieved 9/13/2020.
Link: https://ebird.org/data/download/ebd

Citation:
eBird Basic Dataset. Version: EBD_relJul-2020. Cornell Lab of Ornithology, Ithaca, New York. Jul 2020.

File 1:
Species: Tufted titmouse
Region: All Regions
Date Range: All Dates (Filtered later using auk)

File 2:
Species: Ruby-throated hummingbird
Region: All Regions
Date Range: All Dates