rm(list = ls())
library(auk)
library(dplyr)
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
# Date Range: All Dates

titmouse_file <- auk_ebd("ebd_tuftit_relJul-2020/ebd_tuftit_relJul-2020.txt")
hummingbird_file <- auk_ebd("ebd_rthhum_relJul-2020/ebd_rthhum_relJul-2020.txt")

###########################
##### TUFTED TITMOUSE #####
###########################

titmouse_filtered <- titmouse_file %>% 
  # define filters
  auk_species(species = "Tufted Titmouse") %>% 
  auk_date(date = c("2013-01-01", "2017-12-31")) %>%
  auk_protocol(protocol = "Stationary") %>%
  # run filtering
  auk_filter(file = "titmouse_filtered.txt") %>% 
  # read text file into r data frame
  read_ebd()

# filter to only personal locations
titmouse_filtered <- dplyr::filter(titmouse_filtered, locality_type == "P")

# reformat
titmouse_filtered <- data.frame(scientificName = titmouse_filtered$scientific_name, 
                                decimalLatitude = titmouse_filtered$latitude, 
                                decimalLongitude = titmouse_filtered$longitude, 
                                eventDate = titmouse_filtered$observation_date)

# sample records
set.seed(1)
titmouse_sampled <- titmouse_filtered[sample(nrow(titmouse_filtered), 20000),]

# spatial thinning
thin(titmouse_sampled, lat.col = "decimalLatitude", long.col = "decimalLongitude", 
     spec.col = "scientificName", thin.par = 5, reps = 1,
     out.dir = 'titmouse_thinned/', out.base = "titmouse", write.log.file = FALSE)
titmouse_thinned <- read.csv(paste0('titmouse_thinned/', 'titmouse_thin1.csv'))

# event dates lost during thinning - merge with pre-thinned sample to retrieve data dates using Lat and Long
titmouse_thinned <- merge(titmouse_thinned, titmouse_sampled, by=c("decimalLongitude", "decimalLatitude"))

# merging to restore dates generates additional rows when multiple records have the same coordinates, keep one at random
# first scramble order of dataframe rows
titmouse_thinned <- titmouse_thinned[sample(nrow(titmouse_thinned)), ]
# then remove duplicates, keeps only the first record at a given coordinate
titmouse_thinned$id <- paste0(titmouse_thinned$decimalLatitude, titmouse_thinned$decimalLongitude)
titmouse_thinned <- titmouse_thinned[!duplicated(titmouse_thinned$id),]

# reformat
titmouse_thinned <- data.frame(scientificName = titmouse_thinned$scientificName.x,
                               decimalLatitude = titmouse_thinned$decimalLatitude,
                               decimalLongitude = titmouse_thinned$decimalLongitude,
                               eventDate = titmouse_thinned$eventDate)
write.csv(titmouse_thinned, 'tufted_titmouse.csv', row.names = FALSE)



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

# spatial thinning
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



#####################################
# Both datasets (.CSVs) uploaded to Map of Life using Map of Life Uploader
# www.mol.org/upload

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

