rm(list = ls())
library(ggplot2)
library(cowplot)
library(ggExtra)
library(lubridate)
library(gridExtra)

# loads values from a specified layer from a STOAT result directory (uuid)
load_single <- function(path, uuid, layer, species){
  values <- read.csv(paste0(path, "/", uuid, "/", layer))
  events <- read.csv(paste0(path, "/", uuid, "/unique_events.csv"))
  merged <- merge(values, events, by = "event_id")
  merged$date <- as.Date(merged$date, format = "%Y-%m-%d")
  single <- data.frame(Species = species, Date = merged$date, Value = merged$value)
  return(single)
}

# loads values from all layers from a STOAT result directory (uuid)
load_multiple <- function(path, uuid){
  files <- list.files(paste0(path, '/', uuid), full.names = T)
  event_file <- files[grepl('events.csv$', files)]
  multiple <- read.csv(event_file)
  output_files <- files[grepl('results.csv$', files)]
  
  for (output_file in output_files) {
    current_file <- read.csv(output_file)
    current_file$event_id <- as.character(current_file$event_id)
    current_name <- basename(output_file)
    current_name <- sub("_results.csv", "", current_name)
    # create a new column in 'out' named after each output file
    current_file[current_name] <- current_file$value
    current_file <- current_file[, c("event_id", current_name)]
    multiple <- merge(multiple, current_file, by="event_id")
  }
  
  return(multiple)
}
  
path <- "annotated"
hummingbird_uuid <- "7cb51da4-6719-4eaa-8cb4-8a8f96ba3b70"
titmouse_uuid <- "a1771b6f-ff76-4fe6-b6e3-e4e1014e0c5d"



#######################################
##### EVI/LST OVER TIME: FIGURE 5 #####
#######################################

# EVI
hummingbird_evi <- load_single(path = path, uuid = hummingbird_uuid, 
                               layer = "landsat8_evi_30_16_results.csv", species = "Archilochus colubris")
titmouse_evi <- load_single(path = path, uuid = titmouse_uuid,
                            layer = "landsat8_evi_30_16_results.csv", species = "Baeolophus bicolor")
combined_evi <- rbind(hummingbird_evi, titmouse_evi)
eviplot <- ggplot(data = combined_evi, aes(x = Date, y = Value, color = Species)) +
  scale_color_manual(values = c("#e6aba3", "#4d709e")) +
  geom_point(size = 0.5, alpha = 0.6) + ylab("Landsat 8 EVI") +
  geom_smooth(aes(group=Species), span = 0.1, method = "loess", se = FALSE, size = 1.25,
              color = c(rep('#e86554', 80), rep('#4d709e', 80))) +
  theme(legend.position = 'none', axis.title.x=element_blank(),
        axis.text.x=element_blank(), axis.ticks.x=element_blank(),
        panel.background = element_rect(fill = "#ffffff", size = 2, linetype = "solid"),
        panel.grid.major = element_line(size = 0.70, linetype = 'solid', colour = "#e8e8e8"),
        panel.grid.minor = element_line(size = 0.70, linetype = 'solid', colour = "#e8e8e8"),
        panel.border = element_rect(linetype = "solid", fill = NA, colour = "grey")) +
  scale_x_date(date_breaks = "1 year", expand = c(0.02,0.02))

# LST
hummingbird_lst <- load_single(path = path, uuid = hummingbird_uuid,
                               layer = "modis_lst_day_1000_1_results.csv", species = "Archilochus colubris")
titmouse_lst <- load_single(path = path, uuid = titmouse_uuid,
                            layer = "modis_lst_day_1000_1_results.csv", species = "Baeolophus bicolor")
combined_lst <- rbind(hummingbird_lst, titmouse_lst)
combined_lst$Value <- (combined_lst$Value-273.15)
lstplot <- ggplot(data = combined_lst, aes(x = Date, y = Value, color = Species)) +
  scale_color_manual(values = c("#e6aba3", "#4d709e")) +
  geom_point(size = 0.5, alpha = 0.6) + ylab("MODIS LST Day (Celsius)") + xlab("Date of Occurrence") +
  geom_smooth(aes(group=Species), span = 0.1, method = "loess", se = FALSE, size = 1.25,
              color = c(rep('#e86554', 80), rep('#4d709e', 80))) +
  theme(legend.text = element_text(size = 10, face = "italic"), legend.position = "bottom",
        panel.background = element_rect(fill = "#ffffff", size = 2, linetype = "solid"),
        panel.grid.major = element_line(size = 0.70, linetype = 'solid', colour = "#e8e8e8"),
        panel.grid.minor = element_line(size = 0.70, linetype = 'solid', colour = "#e8e8e8"),
        panel.border = element_rect(linetype = "solid", fill = NA, colour = "grey")) +
  guides(colour = guide_legend(override.aes = list(size = 2))) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y", expand = c(0.02,0.02))

plot <- plot_grid(eviplot, lstplot, labels = 'AUTO', ncol = 1, align = 'v',
          rel_heights = c(0.75, 1))

# png("~/Fig5.png", width = 14, height = 16, units = 'cm', res = 600)
# grid.arrange(plot)
# dev.off()

#########################################
##### SPATIAL GRAIN (EVI): FIGURE 6 #####
#########################################
hummingbird_all <- load_multiple(path = path, uuid = hummingbird_uuid)
hummingbird_all$delta_evi <- hummingbird_all$landsat8_evi_30_16 - hummingbird_all$landsat8_evi_250_16
hummingbird_all$abs_delta_evi <- abs(hummingbird_all$delta_evi)
hummingbird_all$log_cov <- log(hummingbird_all$earthenvhabhet_coefficient_variation_1000_0)
# set colors for indicating density
hummingbird_all$cov_density_color <- densCols(hummingbird_all$abs_delta_evi,
                                              log10(hummingbird_all$earthenvhabhet_coefficient_variation_1000_0),
                                              colramp = colorRampPalette(hcl.colors(5, palette = "viridis", rev = T)))

plot <- ggplot(hummingbird_all) +
  geom_point(aes(y = abs_delta_evi, x = earthenvhabhet_coefficient_variation_1000_0, col = cov_density_color)) +
  scale_color_identity() +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  #geom_smooth(aes(y = abs_delta_evi, x = log_cov), method = 'lm', se = F, color = 'black') +
  geom_quantile(aes(y = abs_delta_evi, x = earthenvhabhet_coefficient_variation_1000_0, color = 'black'),
                quantiles = c(0.10,0.50,0.90)) +
  ylab('Absolute Value of Delta EVI (30-250m)') + xlab('Habitat Heterogeneity (Coefficient of Variation)')
plot <- ggMarginal(plot, type = 'histogram', bins = 50, size = 10, fill = 'light grey')

# png("~/Fig6.png", width = 14, height = 14, units = 'cm', res = 600)
# grid.arrange(plot)
# dev.off()

# proportion of deltas > 0.2
sum(na.omit(hummingbird_all$abs_delta_evi) > 0.2) / length(na.omit(hummingbird_all$abs_delta_evi))
# median delta
median(na.omit(hummingbird_all$abs_delta_evi))
# spearman correlation
spearman_dat <- data.frame(abs_delta_evi = hummingbird_all$abs_delta_evi, cov = hummingbird_all$earthenvhabhet_coefficient_variation_1000_0)
spearman_dat <- na.omit(spearman_dat)
cor(spearman_dat$cov, spearman_dat$abs_delta_evi, method = "spearman")
nrow(spearman_dat)



##########################################
##### TEMPORAL GRAIN (LST): FIGURE 7 #####
##########################################
titmouse_all <- load_multiple(path = path, uuid = titmouse_uuid)
titmouse_all$modis_lst_day_1000_1 <- titmouse_all$modis_lst_day_1000_1 - 273.15
titmouse_all$modis_lst_day_1000_30 <- titmouse_all$modis_lst_day_1000_30 - 273.15
titmouse_all$delta_lst <- titmouse_all$modis_lst_day_1000_1 - titmouse_all$modis_lst_day_1000_30
titmouse_all$abs_delta_lst <- abs(titmouse_all$modis_lst_day_1000_1 - titmouse_all$modis_lst_day_1000_30)
# change all years to same year for collective visualization
titmouse_all$date_oneyear <- as.Date(paste0("2000",substr(titmouse_all$date, 5, 20)))

plot <- ggplot(data = titmouse_all, aes(y = abs_delta_lst, x =  date_oneyear)) +
  geom_point(color = 'turquoise') +
  scale_x_date(date_breaks = "1 month",
               date_labels = "%B",
               expand = c(0,0)) +
  theme(axis.text.x = element_text(angle = -45, hjust = 0, vjust = 0.5, size = 10)) +
  geom_smooth(span = 0.4, method = "loess", se = FALSE, size = 1.25, color = 'black') +
  ylab('Absolute Value of Delta LST (1 day-30 day)') + xlab('Season')

plot <- ggMarginal(plot, type = 'histogram', bins = 50, size = 10, fill = 'light grey')
# marginal plot doesn't work with expand(), no workaround, had to rescale x axis marginal plot manually using image editor, see:
# https://github.com/daattali/ggExtra/issues/145

# png("~/Fig7.png", width = 14, height = 14, units = 'cm', res = 600)
# grid.arrange(plot)
# dev.off()

# proportion of deltas > 5
sum(na.omit(titmouse_all$abs_delta_lst) > 5) / length(na.omit(titmouse_all$abs_delta_lst))
# median delta
median(na.omit(titmouse_all$abs_delta_lst))
# U test
wilcox_dat <- data.frame(abs_delta_lst = titmouse_all$abs_delta_lst, date = titmouse_all$date)
wilcox_dat <- na.omit(wilcox_dat)
wilcox_dat$month <- as.numeric(substr(wilcox_dat$date, 6,7))
season <- setNames( rep(c('winter/summer', 'spring/fall'),each=6), c(12, 1, 2, 6, 7, 8, 3, 4, 5, 9, 10, 11))
wilcox_dat$season <- unname(season[as.character(wilcox_dat$month)])
wilcox.test(wilcox_dat$abs_delta_lst~wilcox_dat$season)
# standard deviation
spring_fall <- wilcox_dat[wilcox_dat$season=="spring/fall",]
median(spring_fall$abs_delta_lst)
winter_summer <- wilcox_dat[wilcox_dat$season=="winter/summer",]
median(winter_summer$abs_delta_lst)
# boxplot
boxplot(wilcox_dat$abs_delta_lst~wilcox_dat$season)

