library(auk)
library(plyr)
library(dplyr)
library(spThin)
library(rstoat)

# Source Data: EBird Basic Dataset Version 1.12, July 2020. Retrieved 9/13/2020.
# Link: https://ebird.org/data/download/ebd

# Citation:
# eBird Basic Dataset. Version: EBD_relJul-2020. Cornell Lab of Ornithology, Ithaca, New York. Jul 2020.

# File 1:
# Species: Tufted titmouse
# Region: All Regions
# Date Range: All Dates (Filtered later using auk)

# File 2:
# Species: Ruby-throated hummingbird
# Region: All Regions
# Date Range: All Dates (Filtered later using auk)

# Use auk r package to read EBird database files
titmouse_file <- auk_ebd("casestudy_RTHU+TUTI/ebd_tuftit_relJul-2020/ebd_tuftit_relJul-2020.txt")
hummingbird_file <- auk_ebd("casestudy_RTHU+TUTI/ebd_rthhum_relJul-2020/ebd_rthhum_relJul-2020.txt")

###########################
##### TUFTED TITMOUSE #####
###########################

# Filter using auk
titmouse_filtered <- titmouse_file %>% 
  # define filters
  auk_species(species = "Tufted Titmouse") %>% 
  auk_date(date = c("2013-01-01", "2017-12-31")) %>%
  auk_protocol(protocol = "Stationary") %>%
  # run filtering
  auk_filter(file = "titmouse_filtered.txt") %>% 
  # read text file into r data frame
  read_ebd()

# filter to only personal locations (can't in auk)
titmouse_filtered <- dplyr::filter(titmouse_filtered, locality_type == "P")

# reformat
titmouse_filtered <- data.frame(scientificName = titmouse_filtered$scientific_name, 
                                decimalLatitude = titmouse_filtered$latitude, 
                                decimalLongitude = titmouse_filtered$longitude, 
                                eventDate = titmouse_filtered$observation_date)

# sample records
set.seed(1)
titmouse_sampled <- titmouse_filtered[sample(nrow(titmouse_filtered), 20000),]

# spatial thinning using spThin
thin(titmouse_sampled, lat.col = "decimalLatitude", long.col = "decimalLongitude", 
     spec.col = "scientificName", thin.par = 5, reps = 1,
     out.dir = 'titmouse_thinned/', out.base = "titmouse", write.log.file = FALSE)
titmouse_thinned <- read.csv(paste0('casestudy_RTHU+TUTI/titmouse_thinned/', 'titmouse_thin1.csv'))

# event dates lost during thinning - merge with pre-thinned sample to retrieve data dates using Lat and Long
titmouse_thinned <- merge(titmouse_thinned, titmouse_sampled, by=c("decimalLongitude", "decimalLatitude"))

# merging to restore dates generates additional rows when multiple records have the same coordinates, keep one at random
# first scramble order of dataframe rows
titmouse_thinned <- titmouse_thinned[sample(nrow(titmouse_thinned)), ]
# then remove duplicates, keeps only the first record at a given coordinate
titmouse_thinned$id <- paste0(titmouse_thinned$decimalLatitude, titmouse_thinned$decimalLongitude)
titmouse_thinned <- titmouse_thinned[!duplicated(titmouse_thinned$id),]

# reformat (MOL upload format)
titmouse_thinned <- data.frame(scientificName = titmouse_thinned$scientificName.x,
                               decimalLatitude = titmouse_thinned$decimalLatitude,
                               decimalLongitude = titmouse_thinned$decimalLongitude,
                               eventDate = titmouse_thinned$eventDate)

write.csv(titmouse_thinned, 'tufted_titmouse.csv', row.names = FALSE)

# additional column renaming to make csv format compatible with the private annotator access point, see below

#####################################
##### RUBY-THROATED HUMMINGBIRD #####
#####################################

hummingbird_filtered <- hummingbird_file %>% 
  # define filters
  auk_species(species = "Ruby-throated Hummingbird") %>% 
  auk_date(date = c("2013-01-01", "2017-12-31")) %>%
  auk_protocol(protocol = "Stationary") %>%
  # run filtering
  auk_filter(file = "hummingbird_filtered.txt") %>% 
  # read text file into r data frame
  read_ebd()

# filter to only personal locations
hummingbird_filtered <- dplyr::filter(hummingbird_filtered, locality_type == "P")

# reformat
hummingbird_filtered <- data.frame(scientificName = hummingbird_filtered$scientific_name, 
                                decimalLatitude = hummingbird_filtered$latitude, 
                                decimalLongitude = hummingbird_filtered$longitude, 
                                eventDate = hummingbird_filtered$observation_date)

# sample records
set.seed(1)
hummingbird_sampled <- hummingbird_filtered[sample(nrow(hummingbird_filtered), 20000),]

# spatial thinning using spThin
thin(hummingbird_sampled, lat.col = "decimalLatitude", long.col = "decimalLongitude", 
     spec.col = "scientificName", thin.par = 5, reps = 1,
     out.dir = 'hummingbird_thinned/', out.base = "hummingbird", write.log.file = FALSE)
hummingbird_thinned <- read.csv(paste0("hummingbird_thinned/", "hummingbird_thin1.csv"))

# event dates lost during thinning - merge with pre-thinned sample to retrieve data dates using Lat and Long
hummingbird_thinned <- merge(hummingbird_thinned, hummingbird_sampled, by=c("decimalLongitude", "decimalLatitude"))

# merging to restore dates generates additional rows when multiple records have the same coordinates, keep one at random
# first scramble order of dataframe rows
hummingbird_thinned <- hummingbird_thinned[sample(nrow(hummingbird_thinned)), ]
# then remove duplicates, keeps only the first record at a given coordinate
hummingbird_thinned$id <- paste0(hummingbird_thinned$decimalLatitude, hummingbird_thinned$decimalLongitude)
hummingbird_thinned <- hummingbird_thinned[!duplicated(hummingbird_thinned$id),]

# reformat
hummingbird_thinned <- data.frame(scientificName = hummingbird_thinned$scientificName.x,
                               decimalLatitude = hummingbird_thinned$decimalLatitude,
                               decimalLongitude = hummingbird_thinned$decimalLongitude,
                               eventDate = hummingbird_thinned$eventDate)
write.csv(hummingbird_thinned, "ruby-throated_hummingbird.csv", row.names = FALSE)

# additional column renaming to make csv format compatible with the private annotator access point, see below

#####################################
# Note: the following code was only run for the first submitted manuscript - the manuscript revisions required Landsat spatial
# buffering of ~1000m, which is larger than the public limit at time of manuscript release, and therefore the annotations
# were run through a private access point with no limits. The code for such a run would have been identical to that below,
# with the spatial buffer increased.

# Both datasets (.CSVs) uploaded to Map of Life using Map of Life Uploader
# www.mol.org/upload

mol_login("--LOGIN CREDENTIALS--")

# Then start annotation using rstoat. Can get dataset ids using my_datasets()

dataset_list <- my_datasets()

#start_annotation_batch("dataset_id", "Annotation Title", "Layer Code(s)")
start_annotation_batch(dataset_list$dataset_id[1], "TT_final", c("landsat8-evi-30-16", "modis-lst_day-1000-1", "modis-lst_day-1000-30"))
start_annotation_batch(dataset_list$dataset_id[2], "RTH_final", c("landsat8-evi-30-16", "landsat8-evi-250-16", "modis-lst_day-1000-1",
                                                 "earthenvhabhet-coefficient_variation-1000-0"))

# Check job status
my_jobs()

# Download results
download_annotation(job_list$annotation_id[1])
download_annotation(job_list$annotation_id[2])


#########################################################################################################################

# Source Data: EBird Basic Dataset Version 1.13, April 2021. Retrieved 6/4/2021.
# Link: https://ebird.org/data/download/ebd

# Citation:
# eBird Basic Dataset. Version: EBD_relApr-2021. Cornell Lab of Ornithology, Ithaca, New York. Jul 2020.

# File 3:
# Species: Anna's hummingbird
# Region: All Regions
# Date Range: All Dates (Filtered later using auk)

##############################
##### ANNA'S HUMMINGBIRD #####
##############################

# Use auk r package to read EBird database files
anna_file <- auk_ebd("casestudy_ANHU/ebd_annhum_relApr-2021/ebd_annhum_relApr-2021.txt")

# Filter using auk
anna_file %>% 
  # define filters
  auk_species(species = "Anna's Hummingbird") %>% 
  #auk_date(date = c("2013-01-01", "2017-12-31")) %>%
  auk_distance(distance = c(0, 7)) %>% # filter out records with more than 7km distance travelled
  # run filtering
  auk_filter(file = "casestudy_ANHU/anna_filtered.txt")

# read text file into r data frame
anna_filtered <- read_ebd("casestudy_ANHU/anna_filtered.txt")

# filter to only personal locations (can't in auk)
anna_filtered <- dplyr::filter(anna_filtered, locality_type == "P")

# filter into different datasets by distance travelled
#anna_stat <- dplyr::filter(anna_filtered, protocol_type == "Stationary")
anna_150 <- dplyr::filter(anna_filtered, (effort_distance_km < 0.25) & (effort_distance_km > 0.15))
anna_450 <- dplyr::filter(anna_filtered, (effort_distance_km < 0.75) & (effort_distance_km > 0.45))
anna_1350 <- dplyr::filter(anna_filtered, (effort_distance_km < 2.25) & (effort_distance_km > 1.35))
anna_4050 <- dplyr::filter(anna_filtered, (effort_distance_km < 6.75) & (effort_distance_km > 4.05))

# reformat
anna_150 <- data.frame(scientificName = anna_150$scientific_name, 
                       decimalLatitude = anna_150$latitude, 
                       decimalLongitude = anna_150$longitude, 
                       eventDate = anna_150$observation_date,
                       effort_distance_km = anna_150$effort_distance_km)
anna_450 <- data.frame(scientificName = anna_450$scientific_name, 
                       decimalLatitude = anna_450$latitude, 
                       decimalLongitude = anna_450$longitude, 
                       eventDate = anna_450$observation_date,
                       effort_distance_km = anna_450$effort_distance_km)
anna_1350 <- data.frame(scientificName = anna_1350$scientific_name, 
                        decimalLatitude = anna_1350$latitude, 
                        decimalLongitude = anna_1350$longitude, 
                        eventDate = anna_1350$observation_date,
                        effort_distance_km = anna_1350$effort_distance_km)
anna_1350 <- anna_1350[1:10000,] # 1350 bin is 26k records, too large to thin
anna_4050 <- data.frame(scientificName = anna_4050$scientific_name, 
                        decimalLatitude = anna_4050$latitude, 
                        decimalLongitude = anna_4050$longitude, 
                        eventDate = anna_4050$observation_date,
                        effort_distance_km = anna_4050$effort_distance_km)

# perform spatial thinning using spThin - thin all datasets to 1km
for(distance in c("150","450","1350","4050")){
  current_run <- paste0("anna_", distance)
  thin(get(current_run), lat.col = "decimalLatitude", long.col = "decimalLongitude", 
       spec.col = "scientificName", thin.par = 1, reps = 1,
       out.dir = 'casestudy_ANHU/anna_thinned/', out.base = distance, write.log.file = FALSE)
}

# read thinned datasets and reformat
for(distance in c("150","450","1350","4050")){
  current_run <- paste0("anna_", distance)
  thinned <- read.csv(paste0('casestudy_ANHU/anna_thinned/', distance, '_thin1.csv'))
  
  # event dates lost during thinning - merge with pre-thinned sample to retrieve data dates using Lat and Long
  thinned <- merge(thinned, get(current_run), by=c("decimalLongitude", "decimalLatitude"))
  
  # merging to restore dates generates additional rows when multiple records have the same coordinates, keep one at random
  # first scramble order of dataframe rows
  thinned <- thinned[sample(nrow(thinned)), ]
  # then remove duplicates, keeps only the first record at a given coordinate
  thinned$id <- paste0(thinned$decimalLatitude, thinned$decimalLongitude)
  thinned <- thinned[!duplicated(thinned$id),]
  
  # reformat
  thinned <- data.frame(scientificName = thinned$scientificName.x,
                        decimalLatitude = thinned$decimalLatitude,
                        decimalLongitude = thinned$decimalLongitude,
                        eventDate = thinned$eventDate,
                        effort_distance_km = thinned$effort_distance_km)
  
  assign(paste0(current_run, "_thinned"), thinned)
}

# trim each distance bin to 2500 occurrence records - records previously shuffled in spatial thinning step
anna_150_thinned <- anna_150_thinned[1:2500,]
anna_450_thinned <- anna_450_thinned[1:2500,]
anna_1350_thinned <- anna_1350_thinned[1:2500,]
anna_4050_thinned <- anna_4050_thinned[1:2500,]

# combine all into one dataset
annas_hummingbird_all_ref <- rbind(anna_150_thinned, anna_450_thinned,
                                   anna_1350_thinned, anna_4050_thinned)
annas_hummingbird_all_ref$run <- c(rep("150", 2500), rep("450", 2500), rep("1350", 2500), rep("4050", 2500))
annas_hummingbird_all_ref$event_id <- 1:nrow(annas_hummingbird_all_ref)

# rename columns and format for annotation through private STOAT access point, due to being beyond
# spatial buffer limits of public annotator
annas_hummingbird_all_ref <- annas_hummingbird_all_ref %>%
  dplyr::rename(latitude = decimalLatitude,
                longitude = decimalLongitude, date = eventDate)

write.csv(annas_hummingbird_all_ref, "casestudy_ANHU/annas_hummingbird_all_ref.csv", row.names = FALSE)

annas_hummingbird_all <- annas_hummingbird_all_ref[,c(1:4,7)]

write.csv(annas_hummingbird_all, "casestudy_ANHU/annas_hummingbird_all.csv", row.names = FALSE)
