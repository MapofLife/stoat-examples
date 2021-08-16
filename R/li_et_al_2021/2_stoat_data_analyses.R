library(dplyr)
library(ggplot2)
library(cowplot)
library(ggExtra)
library(lubridate)
library(gridExtra)
library(data.table)

# Annotated outputs - do not have dates, only event_id
RTHU_evi <- read.csv("casestudy_RTHU+TUTI/annotated/rl_RTHU_evi.csv")
RTHU_lst <- read.csv("casestudy_RTHU+TUTI/annotated/rl_RTHU_lst.csv")
RTHU_habhet <- read.csv("casestudy_RTHU+TUTI/annotated/rl_RTHU_habhet.csv")
TUTI_evi <- read.csv("casestudy_RTHU+TUTI/annotated/rl_TUTI_evi.csv")
TUTI_lst <- read.csv("casestudy_RTHU+TUTI/annotated/rl_TUTI_lst.csv")

RTHU_combined <- rbind(RTHU_evi, RTHU_lst, RTHU_habhet)
TUTI_combined <- rbind(TUTI_evi, TUTI_lst)

# Original dataset including dates, merge using event_id
RTHU_records <- read.csv("casestudy_RTHU+TUTI/annotated/ruby-throated_hummingbird.csv")
TUTI_records <- read.csv("casestudy_RTHU+TUTI/annotated/tufted_titmouse.csv")

RTHU_combined <- left_join(RTHU_combined, RTHU_records, by = "event_id")
TUTI_combined <- left_join(TUTI_combined, TUTI_records, by = "event_id")

all_combined <- rbind(RTHU_combined, TUTI_combined) %>%
  select(c(-"X"))
all_combined$date <- as.Date(all_combined$date)

#######################################
##### EVI/LST OVER TIME: FIGURE 5 #####
#######################################
# EVI
eviplot_dat <- all_combined %>%
  filter(variable == "derived:evi") %>%
  filter(s_buff == 30)

eviplot <- ggplot(data = eviplot_dat, aes(x = date, y = value, color = scientificName)) +
  scale_color_manual(values = c("#e6aba3", "#4d709e")) +
  geom_point(size = 0.5, alpha = 0.6) + ylab("Landsat 8 EVI") +
  geom_smooth(aes(group=scientificName), span = 0.1, method = "loess", se = FALSE, size = 1.25,
              color = c(rep('#e86554', 80), rep('#4d709e', 80))) +
  theme(legend.position = 'none', axis.title.x=element_blank(),
        axis.text.x=element_blank(), axis.ticks.x=element_blank(),
        panel.background = element_rect(fill = "#ffffff", size = 2, linetype = "solid"),
        panel.grid.major = element_line(size = 0.70, linetype = 'solid', colour = "#e8e8e8"),
        panel.grid.minor = element_line(size = 0.70, linetype = 'solid', colour = "#e8e8e8"),
        panel.border = element_rect(linetype = "solid", fill = NA, colour = "grey")) +
  scale_x_date(limits = c(as.Date("2013-01-01"), as.Date("2017-12-31")), date_breaks = "1 year", date_labels = "%Y", expand = c(0.02,0.02))

# LST
lstplot_dat <- all_combined %>%
  filter(variable == "lst_day_1km") %>%
  filter(t_buff == 1)
lstplot_dat$value <- lstplot_dat$value - 273.15 # convert from K to C

lstplot <- ggplot(data = lstplot_dat, aes(x = date, y = value, color = scientificName)) +
  scale_color_manual(values = c("#e6aba3", "#4d709e")) +
  geom_point(size = 0.5, alpha = 0.6) + ylab("MODIS LST Day (Celsius)") + xlab("Date of Occurrence") +
  geom_smooth(aes(group=scientificName), span = 0.1, method = "loess", se = FALSE, size = 1.25,
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
# first convert from long to wide table to make analysis easier, will use the habhet table as base
# habhet table has 22 more rows for a few records before Landsat8 start date (thus no evi data),
# excluded anyway so no issue.
plot_dat_evi30 <- all_combined %>%
  filter(variable == "derived:evi") %>%
  filter(scientificName == "Archilochus colubris") %>%
  filter(s_buff == 30) %>%
  rename(evi30 = value)
plot_dat_evi120 <- all_combined %>%
  filter(variable == "derived:evi") %>%
  filter(scientificName == "Archilochus colubris") %>%
  filter(s_buff == 120) %>%
  rename(evi120 = value)
plot_dat_evi240 <- all_combined %>%
  filter(variable == "derived:evi") %>%
  filter(scientificName == "Archilochus colubris") %>%
  filter(s_buff == 240) %>%
  rename(evi240 = value)
plot_dat_evi990 <- all_combined %>%
  filter(variable == "derived:evi") %>%
  filter(scientificName == "Archilochus colubris") %>%
  filter(s_buff == 990) %>%
  rename(evi990 = value)

plot_dat <- all_combined %>%
  filter(variable == "coefficient_variation") %>%
  filter(scientificName == "Archilochus colubris") %>%
  rename(cv = value)
# join mini tables together to make a wide table, then select only a few columns
plot_dat <- left_join(plot_dat, plot_dat_evi30, by = "event_id") %>%
  left_join(plot_dat_evi120, by = "event_id") %>%
  left_join(plot_dat_evi240, by = "event_id") %>%
  left_join(plot_dat_evi990, by = "event_id")

plot_dat <- plot_dat %>%
  select(event_id, evi30, evi120, evi240, evi990, cv) %>%
  na.omit() # only complete cases!

plot_dat$delta_evi <- plot_dat$evi120 - plot_dat$evi990
plot_dat$abs_delta_evi <- abs(plot_dat$delta_evi)

# set colors for indicating density
plot_dat$color <- densCols(plot_dat$abs_delta_evi,
                           log10(plot_dat$cv), # x axis log transformed later, colors adjusted
                           colramp = colorRampPalette(hcl.colors(5, palette = "viridis", rev = T)))

plot <- ggplot(plot_dat) +
  geom_point(aes(y = abs_delta_evi, x = cv, col = color)) +
  scale_color_identity() +
  scale_x_log10() + annotation_logticks(sides = 'b') + # x axis is log transformed
  geom_quantile(aes(y = abs_delta_evi, x = cv, color = 'black'),
                quantiles = c(0.10,0.50,0.90)) +
  ylab('Absolute Value of Delta EVI (120-990m)') + xlab('Habitat Heterogeneity (Coefficient of Variation)') +
  ylim(c(0,0.7))
plot <- ggMarginal(plot, type = 'histogram', bins = 50, size = 10, fill = 'light grey')

# png("~/Fig6.png", width = 14, height = 14, units = 'cm', res = 600)
# grid.arrange(plot)
# dev.off()

# proportion of deltas > 0.2 (using delta evis between 120-990m buffers)
sum(na.omit(plot_dat$abs_delta_evi) > 0.2) / length(na.omit(plot_dat$abs_delta_evi))
# proportion of deltas > 0.2 (using delta evis between 120-240m buffers)
plot_dat$abs_delta_evi2 <- abs(plot_dat$evi120 - plot_dat$evi240)
sum(na.omit(plot_dat$abs_delta_evi2) > 0.2) / length(na.omit(plot_dat$abs_delta_evi2))
# proportion of deltas > 0.2 (using delta evis between 30-990m buffers)
plot_dat$abs_delta_evi3 <- abs(plot_dat$evi30 - plot_dat$evi990)


# median delta (120-990m)
median(na.omit(plot_dat$abs_delta_evi))
# median delta (120-240m)
median(na.omit(plot_dat$abs_delta_evi2))
# median delta (30-990m)
median(na.omit(plot_dat$abs_delta_evi3))

# spearman correlation
cor(plot_dat$cv, plot_dat$abs_delta_evi, method = "spearman")
nrow(plot_dat)


##########################################
##### TEMPORAL GRAIN (LST): FIGURE 7 #####
##########################################
# first convert from long to wide table to make analysis easier
plot_dat_lst1 <- all_combined %>%
  filter(variable == "lst_day_1km") %>%
  filter(scientificName == "Baeolophus bicolor") %>%
  filter(t_buff == 1) %>%
  rename(lst1 = value)
plot_dat_lst30 <- all_combined %>%
  filter(variable == "lst_day_1km") %>%
  filter(scientificName == "Baeolophus bicolor") %>%
  filter(t_buff == 30) %>%
  rename(lst30 = value)
plot_dat <- left_join(plot_dat_lst1, plot_dat_lst30, by = "event_id")

plot_dat <- plot_dat %>%
  select(event_id, date.x, lst1, lst30) %>%
  na.omit() # only complete cases!

plot_dat$delta_lst <- plot_dat$lst1 - plot_dat$lst30
plot_dat$abs_delta_lst <- abs(plot_dat$delta_lst)
# change all years to same year for collective visualization
plot_dat$date_oneyear <- as.Date(paste0("2000",substr(plot_dat$date.x, 5, 20)))

# set colors for indicating density
plot_dat$color <- densCols(plot_dat$abs_delta_lst,
                           plot_dat$date_oneyear,
                           colramp = colorRampPalette(hcl.colors(5, palette = "viridis", rev = T)))

plot <- ggplot(data = plot_dat, aes(y = abs_delta_lst, x =  date_oneyear, col = color)) +
  geom_point() +
  scale_color_identity() +
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
sum(na.omit(plot_dat$abs_delta_lst) > 5) / length(na.omit(plot_dat$abs_delta_lst))
# median delta
median(na.omit(plot_dat$abs_delta_lst))
# U test
plot_dat$month <- as.numeric(substr(plot_dat$date.x, 6,7))
season <- setNames( rep(c('winter/summer', 'spring/fall'),each=6), c(12, 1, 2, 6, 7, 8, 3, 4, 5, 9, 10, 11))
plot_dat$season <- unname(season[as.character(plot_dat$month)])
wilcox.test(plot_dat$abs_delta_lst~plot_dat$season)
# standard deviation
spring_fall <- plot_dat[plot_dat$season=="spring/fall",]
median(spring_fall$abs_delta_lst)
winter_summer <- plot_dat[plot_dat$season=="winter/summer",]
median(winter_summer$abs_delta_lst)
# boxplot
boxplot(plot_dat$abs_delta_lst~plot_dat$season)


##################################################################
##### GRAIN-SPECIFIC VS. GRAIN-AGNOSTIC ANNOTATION: FIGURE 8 #####
##################################################################
# results from grain-specific run: index with metadata and actual data
index <- read.csv("casestudy_ANHU/annas_hummingbird_all_ref.csv")
anna <- read.csv('casestudy_ANHU/rl_anno_evi_final.csv', stringsAsFactors = FALSE) %>%
  select(-X) %>%
  arrange(event_id, s_buff) %>%
  left_join(index, by = "event_id")

# some records missing of the 10,000 for missing data, since Landsat8 does not start exactly in January 2018  
anna <- anna %>%
  filter(!is.na(value)) %>%
  filter(s_buff == run) # in the annotations, all occurrences were annotated against all spatial buffers, but
                        # we only want the values when the buffer matches data grain

# GEE annotations representing grain-agnostic runs - only monthly30m and overall30m were used in the end
anna_monthly_30m <- read.csv("casestudy_ANHU/gee/anna_monthly_30m.csv") %>%
  rename(monthly30m = value)
anna_monthly_1km <- read.csv("casestudy_ANHU/gee/anna_monthly_1km.csv") %>%
  rename(monthly1km = value)
anna_overall_30m <- read.csv("casestudy_ANHU/gee/anna_overall_30m.csv") %>%
  rename(overall30m = value)
anna_overall_1km <- read.csv("casestudy_ANHU/gee/anna_overall_1km.csv") %>%
  rename(overall1km = value)

# join grain-agnostic run results to the same dataframe holding the grain-specific results
anna <- left_join(anna, anna_monthly_30m, by = c("event_id" = "id"))
anna <- left_join(anna, anna_monthly_1km, by = c("event_id" = "id"))
anna <- left_join(anna, anna_overall_30m, by = c("event_id" = "id"))
anna <- left_join(anna, anna_overall_1km, by = c("event_id" = "id"))

# cut down and reorganize columns into a new dataframe containing all data and relevant metadata
anna2 <- anna %>%
  select(event_id, date, latitude, longitude, s_buff, run, effort_distance_km,
                         value, monthly30m, monthly1km, overall30m, overall1km) %>%
  rename(grainspecific = value) %>%
  na.exclude()

# sample sizes for each group
anna2 %>%
  group_by(run) %>%
  count()

# calculate different metrics used in plots
anna2$date_oneyear <- as.Date(paste0("2000",substr(anna2$date, 5, 20))) # combine all years into one year
# delta EVI between grain-specific and agnostic, monthly
anna2$delta_to_monthly1km <- (anna2$grainspecific - anna2$monthly1km)
anna2$abs_delta_to_monthly1km <- (abs(anna2$grainspecific - anna2$monthly1km))
# delta EVI between grain-specific and agnostic, overall
anna2$delta_to_overall1km <- (anna2$grainspecific - anna2$overall1km)
anna2$run <- as.factor(anna2$run)

# set colors for plot density for both following plots
anna2$plot1_color <- densCols(anna2$abs_delta_to_monthly1km,
                              log10(anna2$effort_distance_km), # x axis log transformed later, colors adjusted
                              colramp = colorRampPalette(hcl.colors(5, palette = "viridis", rev = T)))
anna2$plot2_color <- densCols(anna2$delta_to_overall1km,
                              anna2$date_oneyear, # x axis log transformed later, colors adjusted
                              colramp = colorRampPalette(hcl.colors(5, palette = "viridis", rev = T)))

# delta evi by record grain/bin
plot1 <- ggplot(anna2, aes(x = effort_distance_km, y = abs_delta_to_monthly1km, color = plot1_color)) +
  scale_color_identity() +
  ylim(c(0,0.5)) +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  geom_point() +
  geom_smooth(span = 0.4, method = "loess", se = FALSE, size = 1.25, color = 'black') +
  geom_vline(xintercept = 1, color = "black", linetype = "dashed") +
  annotate(geom = "text",
           label = "1km annotation grain",
           size = 4,
           x = 1,
           y = 0.35,
           angle = 90, 
           vjust = 1.25) +
  xlab("Occurrence Spatial Grain (m)") +
  ylab("Absolute Value of Delta EVI")

# delta evi by date - all bins together
plot2 <- ggplot(anna2, aes(x = date_oneyear, y = delta_to_overall1km, color = plot2_color)) +
  scale_color_identity() +
  ylim(c(-0.4,0.4)) +
  geom_point(alpha = 0.4) +
  geom_smooth(span = 0.4, method = "loess", se = FALSE, color = 'black', level = 0.95) +
  scale_x_date(date_breaks = "1 month",
               date_labels = "%B",
               expand = c(0,0)) +
  theme(axis.text.x = element_text(angle = -60, hjust = 0, vjust = 0.5, size = 10)) +
  xlab("Season") +
  ylab("Delta EVI")

plot <- plot_grid(plot1, plot2,labels = 'AUTO', ncol = 2, align = 'h',
                  rel_heights = c(1, 1))

# png("~/Fig8.png", width = 22, height = 14, units = 'cm', res = 600)
# grid.arrange(plot)
# dev.off()

# Statistical analysis - spatial
# sort 4 grain bins into 2 (near/far) by proximity to 1km grain
anna2$run_cat <- as.factor(ifelse(anna2$run %in% c(450, 1350) , "near" , "far"))
anna2_near <- anna2 %>% filter(run_cat == "near")
anna2_far <- anna2 %>% filter(run_cat == "far")

# median delta
median(na.omit(anna2_near$abs_delta_to_monthly1km))
median(na.omit(anna2_far$abs_delta_to_monthly1km))

# proportion of deltas > 0.1
sum(na.omit(anna2_near$abs_delta_to_monthly1km) > 0.1) / length(na.omit(anna2_near$abs_delta_to_monthly1km))
sum(na.omit(anna2_far$abs_delta_to_monthly1km) > 0.1) / length(na.omit(anna2_far$abs_delta_to_monthly1km))
# proportion of deltas > 0.2
sum(na.omit(anna2_near$abs_delta_to_monthly1km) > 0.2) / length(na.omit(anna2_near$abs_delta_to_monthly1km))
sum(na.omit(anna2_far$abs_delta_to_monthly1km) > 0.2) / length(na.omit(anna2_far$abs_delta_to_monthly1km))

# U test
test <- wilcox.test(anna2$abs_delta_to_monthly1km~anna2$run_cat)
test$p.value

# Statistical analysis - temporal
anna2$month <- as.numeric(substr(anna2$date, 6,7))
anna2 %>% group_by(month) %>% summarise(median(delta_to_overall1km))
anna2$season <- ifelse(anna2$month %in% c(6, 7, 8), "summer", NA)
anna2$season <- ifelse(anna2$month %in% c(12, 1, 2), "winter", anna2$season)

# U test
test2 <- wilcox.test(anna2$delta_to_overall1km~anna2$season)
test2$p.value
