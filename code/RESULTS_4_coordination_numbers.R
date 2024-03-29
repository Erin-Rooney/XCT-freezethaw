# Erin Rooney
# Aug 3 2020

source("code/0-packages.R")


# load data---------------------------------------------------------------------
#coornum_dat = read.csv("processed/coordination_number_aug32020.csv") 
coornum_dat2 = read.csv("processed/porecoor_fixed.csv")

# set data frames, factor, level order------------------------------------------

str(coornum_dat2)
levels(as.factor(coornum_dat2$trmt))


#coornum_dat2 = 
  #coornum_dat2 %>% 
  #mutate(trmt = factor(trmt, levels = c("before", "after")))
  
levels(as.factor(coornum_dat2$pore_coor))

coornum_dat2 = 
  coornum_dat2 %>% 
mutate(pore_coor = factor(pore_coor, levels = c("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16")))


levels(as.factor(coornum_dat2$sample))
str(coornum_dat2)

coornum_dat3 = 
  coornum_dat2 %>% 
  #recode sample names
  mutate(sample = recode(sample, "40_50_16" = "Core B, 16%", 
                         "40_50_28" = "Core B, 28%",
                         "28_38_12" = "Core A, 16%",
                         "28_38_28" = "Core A, 28%",
                         "41_50_16" = "Core C, 16%",
                         "41_50_28" = "Core C, 28%")) 
  #set sample levels
  #mutate(sample = factor(sample, levels = c("Aggregate-1", "Aggregate-2", "Aggregate-3", "Aggregate-4", "Aggregate-5", "Aggregate-6")))



## this tells you that `trmt` is a character varriable, and you can't look up levels for that
## you can only look up levels for a factor variable, 
## so first convert from char to factor, and then look at the levels

tool = 
  coornum_dat3 %>% 
  filter(site=="tool")%>% 
  mutate(trmt = factor(trmt, levels = c("before", "after")))

#Isolate by poor coordination number and calculate diff between before and after frequencies by aggregate

allcombo =
  tool %>% 
  dplyr::select(-count) %>% 
  spread(trmt, freq) %>% 
  dplyr::mutate(diff = (after - before)) %>% 
  dplyr::select(-before, -after)

allcombo_summary =
  allcombo %>%
  dplyr::select(-site) %>%
  #dplyr::summarise(total = sum(diff_freq))
  mutate(diff_perc = diff * 100) %>%
  dplyr::select(-diff) %>%
  #mutate(include = case_when(diff_perc > 10 ~ 'include'
  #)) %>%
  na.omit() 

pcn_table = 
  allcombo_summary %>% 
  pivot_wider(names_from = "pore_coor", values_from = diff_perc) %>% 
  print

write.csv(allcombo_summary, "processed/pcnsummary.csv", row.names = FALSE)

write.csv(pcn_table, "processed/pcnsummary.csv", row.names = FALSE)


allcombo_five =
  allcombo %>%
  dplyr::select(-site) %>%
  #dplyr::summarise(total = sum(diff_freq))
  mutate(diff_perc = diff * 100) %>%
  dplyr::select(-diff) %>%
  mutate(include = case_when(diff_perc < 5 ~ 'include'
  )) %>%
  na.omit() 

allcombo_five %>% 
  print



#low = coornum_dat[coornum_dat$water=="low",]
#high = coornum_dat[coornum_dat$water=="high",]

#Shapiro-Wilk normality test----------------------------

# before <- subset(tool, trmt == "before", freq, drop = TRUE)
# after <- subset(tool, trmt == "after", freq, drop = TRUE)
# pd <- paired(before, after)
# 
# 
# d <- with(tool,
#           freq[trmt == "before"] - freq[trmt == "after"])
# 
# shapiro.test(d) # p value = 4.011e-11, not normally distributed
# 
# # Wilcoxon test Method 1
# 
# res <- wilcox.test(freq ~ trmt, data = tool, paired = TRUE)
# res
# 
# res$p.value
# 
# #
# 
# res <- wilcox.test(freq ~ trmt, data = tool, paired = TRUE,
#                    alternative = "less")
# res
# 
# res$p.value




# aov---------------------------------------------------------------------------
coornum_aov1 = aov(data = allcombo, diff ~ pore_coor.x)
summary(coornum_aov1)

aov1_hsd <- HSD.test(coornum_aov1, "pore_coor.x")
print(aov1_hsd)

# NONE OF THESE WORK OR MAKE SENSE, STATISTiCALLY

coornum_aov2 = aov(data = tool, co_num ~ sample)
summary(coornum_aov2)

coornum_aov3 = aov(data = tool, co_num ~ sample*trmt)
summary(coornum_aov3)

coornum_aov1 = aov(data = tool, co_num ~ trmt*water)
summary(coornum_aov1)

coornum_aov2 = aov(data = tool, co_num ~ sample*water)
summary(coornum_aov2)

coornum_aov3 = aov(data = tool, co_num ~ water)
summary(coornum_aov3)

# ggplot set up-----------------------------------------------------------------
library(soilpalettes)
library(PNWColors)
theme_er <- function() {  # this for all the elements common across plots
  theme_bw() %+replace%
    theme(legend.position = "right",
          #legend.key=element_blank(),
          legend.title = element_blank(),
          #legend.text = element_blank(),
          legend.key.size = unit(1.5, 'lines'),
          panel.border = element_rect(color="black",size=1, fill = NA),
          
          plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
          plot.subtitle = element_text(hjust = 0.5, size = 12, lineheight = 1.5),
          axis.text = element_text(size = 14, color = "black"),
          axis.title = element_text(size = 14, face = "bold", color = "black"),
          
          # formatting for facets
          panel.background = element_blank(),
          strip.background = element_rect(colour="white", fill="white"), #facet formatting
          panel.spacing.x = unit(1.5, "lines"), #facet spacing for x axis
          panel.spacing.y = unit(1.5, "lines"), #facet spacing for x axis
          strip.text.x = element_text(size=12, face="bold"), #facet labels
          strip.text.y = element_text(size=12, face="bold", angle = 270) #facet labels
    )
}
#ggplots-----------------------------------------------------------------------

#freq, not diff plot 

ggplot(tool, aes(x = pore_coor, y = freq, fill = trmt)) +
  geom_boxplot() + 
  scale_y_continuous(labels = scales::percent) +
  theme_er() +
  scale_fill_manual(values = pnw_palette("Anemone", 2, type = "discrete")) +
  labs (title = "Pore Coordination Number Frequency",
        #caption = "Caption",
        #tag = "A",
        x = expression (bold ("Pore Coordination Number")),
        y = expression (bold ("Frequency, %"))) +
   guides(fill = guide_legend(reverse = TRUE, title = NULL))

#all combo plot

allcombo %>%
  mutate(pore_coor = as.numeric(pore_coor)) %>% 
  ggplot(aes(x = pore_coor, y = diff, color = sample)) +
  geom_point(size = 4) + 
  geom_path(aes(group = sample), size = 1)+ 
  scale_x_continuous(limits = c(0,16), 
                     breaks = seq(0,16,4)) +
  theme_er() +
 # facet_wrap(~ sample) +
  scale_color_manual(values = pnw_palette("Bay", 6)) +
  labs (title = "Pore Coordination Number Frequency",
        #caption = "Caption",
        #tag = "A",
        x = expression (bold ("pore coordination number")),
        y = expression (bold ("difference in frequency"))) 
  
#guides(fill = guide_legend(reverse = TRUE, title = NULL)) 


#All combo shading

allcombo %>%
  mutate(pore_coor = as.numeric(pore_coor)) %>% 
  ggplot(aes(x = pore_coor, y = diff, color = sample)) +
  geom_point(size = 3) + 
  geom_path(aes(group = sample), size = 1)+ 
  geom_area(aes(group = sample, fill = sample), alpha = 0.5, position = "identity")+
  scale_x_continuous(limits = c(0,16), 
                     breaks = seq(0,16,4)) +
  theme_er() +
  # facet_wrap(~ sample) +
  scale_color_manual(values = pnw_palette("Bay", 6)) +
  scale_fill_manual(values = pnw_palette("Bay", 6)) +
  labs (title = "Pore Coordination Number Frequency",
        #caption = "Caption",
        #tag = "A",
        x = expression (bold ("pore coordination number")),
        y = expression (bold ("difference in frequency"))) 
  #guides(fill = guide_legend(reverse = TRUE, title = NULL)) 

#before/after facet wrap 

tool %>%
  filter(sample == "Core C, 28%") %>% 
  mutate(pore_coor = as.numeric(pore_coor)) %>% 
  ggplot(aes(x = pore_coor, y = freq, color = trmt)) +
  geom_path(aes(group = trmt), size = 1, show.legend = FALSE)+ 
  geom_point(size = 3.5, alpha = 0.5) + 
  scale_x_continuous(limits = c(0,16), 
                     breaks = seq(0,16,4)) +
  scale_y_continuous(labels = (scales::percent),
                     limits = c(0.0,0.6),
                     breaks = seq(0,0.6,0.2))+
  theme_er1() +
  #facet_wrap(~ sample) +
  scale_color_manual(values = c("#b0986c", "#72e1e1"))+
  labs (#title = "Pore Coordination Number Frequency",
        #caption = "Caption",
        #tag = "A",
        x = expression (bold ("pore coordination number")),
        y = expression (bold ("frequency, %"))) 
  
  #guides(fill = guide_legend(reverse = TRUE, title = NULL)) 

#mixed model----------------------------------

#filter by sample, randomize by pore coordination
nlme::lme(log(freq) ~ trmt, random = ~1|as.character(pore_coor), data = tool %>% 
            filter(sample == "Core C, 28%" & freq > 0)) %>% 
  anova()

# filter by pore coordination, randomize by sample
nlme::lme(log(freq) ~ trmt, random = ~1|sample, data = tool %>% 
            #filter(pore_coor == 1 & sample != "Core B, 28%")) %>% 
            filter(pore_coor == 1)) %>% 
  anova()



aov(data = tool %>% 
      filter(pore_coor == 1),
    freq ~ trmt) %>% 
  summary()


# randomize by sample
nlme::lme(diff ~ pore_coor, random = ~1|sample, data = allcombo) %>% 
            #filter(sample == "Core C, 28%" & freq > 0)) %>% 
  anova()

a = aov(diff ~ pore_coor, data = allcombo) 

h = HSD.test(a, "pore_coor")

h
  
allcombo %>% 
  ggplot(aes(x = pore_coor, y = diff, color = sample, group = sample))+
  geom_path()+
  geom_point()

# boxplot + point + path 
allcombo %>%
  mutate(pore_coor = as.numeric(pore_coor)) %>% 
  ggplot(aes(x = pore_coor, y = diff, color = sample)) +
  #geom_boxplot() +
  geom_point(size = 3) + 
  geom_path(aes(group = sample), size = 1)+ 
  scale_x_continuous(limits = c(0,16), 
                     breaks = seq(0,16,4)) +
  theme_er() +
  facet_wrap(~ sample) +
  scale_color_manual(values = pnw_palette("Bay", 6)) +
  labs (title = "Pore Coordination Number Frequency",
        #caption = "Caption",
        #tag = "A",
        x = expression (bold ("pore coordination number")),
        y = expression (bold ("difference in frequency"))) +
  guides(fill = guide_legend(reverse = TRUE, title = NULL))


p = allcombo %>% 
  ggplot(aes(x = pore_coor, y = diff, fill = site)) +
  geom_boxplot() + 
  #geom_path(aes(group = sample))+ 
  #scale_y_continuous(labels = scales::percent) +
  theme_er() +
  scale_fill_manual(values = pnw_palette("Anemone", 4, type = "discrete")) +
  labs (#title = "Pore Coordination Number Frequency",
        #caption = "Caption",
        #tag = "A",
        x = expression (bold ("pore coordination number")),
        y = expression (bold ("difference in frequency"))) 


 p + theme(legend.position = "none")



###




p = ggplot(tool, aes(x=pore_coor, y=freq, fill=trmt)) + 
  geom_boxplot() +
  # scale_y_continuous(labels = scales::percent) +
  labs (title = "Change in Pore Coordination Number Frequency following Freeze/Thaw",
        #caption = "Caption",
       # tag = "Figure X",
        x = expression (bold ("Pore Coordination Number")),
        y = expression (bold ("Frequency, %"))) 
        #scale_color_manual(values = soil_palette("redox", 2))


p + theme_er() +
  facet_wrap(sample~.)


ggplot(tool, aes(x=factor(trmt,level_order), y=unconn_water_perc, fill=trmt)) + geom_boxplot() +
  labs (title = "Unconnected Water-Filled Pore Volume",
        #caption = "Permafrost Soil Aggregate from Toolik, Alaska",
        tag = "D",
        x = expression (bold (" ")),
        y = expression (bold ("Volume, %"))) + 
  theme_er() +
  scale_fill_manual(values=c("Black", "White")) +
  # annotate("text", x = 2.25, y = 0.070, label = "P value < 0.5") +
  guides(fill = guide_legend(reverse = TRUE, title = NULL))



p<-ggplot(tool, aes(x=co_num, color=trmt, fill=trmt)) + 
  geom_boxplot(aes(y = stat(count) / sum (count))) +
  scale_y_continuous(labels = scales::percent) +
  labs (title = "Impact of Freeze/Thaw Cycles on Pore Connectivity",
        caption = "Pore Coordination Number",
        tag = "Figure 8",
        x = expression (bold ("pore coordination number")),
        y = expression (bold ("frequency, %")))

p



p<-ggplot(low, aes(x=co_num, fill=trmt)) + 
  geom_histogram(aes(y = stat(count) / sum (count)), binwidth=0.5) +
  scale_y_continuous(labels = scales::percent) +
  labs (title = "Impact of Freeze/Thaw Cycles and Water Content on Pore Connectivity",
        subtitle = "Low Water Content, 12-16%",
        caption = "Pore Coordination Number",
        tag = "Figure X",
        x = expression (bold ("pore coordination number")),
        y = expression (bold ("frequency, %")))

p + scale_fill_manual(values=c("#00FFFF", "#996633"))


p<-ggplot(high, aes(x=co_num, fill=trmt)) + 
  geom_histogram(aes(y = stat(count) / sum (count)), binwidth=0.5) +
  scale_y_continuous(labels = scales::percent) +
  labs (title = "Impact of Freeze/Thaw Cycles and Water Content on Pore Connectivity",
        subtitle = "High Water Content, 28%",
        caption = "Pore Coordination Number",
        tag = "Figure X",
        x = expression (bold ("pore coordination number")),
        y = expression (bold ("frequency, %")))

p + scale_fill_manual(values=c("#00FFFF", "#996633"))



###

p<-ggplot(tool, aes(x=co_num, fill=water)) + 
  geom_histogram(aes(y = stat(count) / sum (count)), binwidth=0.5) +
  scale_y_continuous(labels = scales::percent) +
  labs (title = "Impact of Freeze/Thaw Cycles on Pore Connectivity",
        caption = "Pore Coordination Number",
        tag = "Figure 8",
        x = expression (bold ("pore coordination number")),
        y = expression (bold ("frequency, %")))

p + scale_fill_manual(values=c("#56B4E9", "#E69F00"))


###

before = coornum_dat[coornum_dat$trmt=="before",]
after = coornum_dat[coornum_dat$trmt=="after",]

p<-ggplot(before, aes(x=co_num, fill=water)) + 
  geom_histogram(aes(y = stat(count) / sum (count)), binwidth=0.5) +
  scale_y_continuous(labels = scales::percent) +
  labs (title = "Impact of Freeze/Thaw Cycles and Water Content on Pore Connectivity",
        subtitle = "Before Freeze/Thaw",
        caption = "Pore Coordination Number",
        tag = "Figure X",
        x = expression (bold ("pore coordination number")),
        y = expression (bold ("frequency, %")))

p + scale_fill_manual(values=c("#56B4E9", "#E69F00"))



p<-ggplot(after, aes(x=co_num, fill=water)) + 
  geom_histogram(aes(y = stat(count) / sum (count)), binwidth=0.5) +
  scale_y_continuous(labels = scales::percent) +
  labs (title = "Impact of Freeze/Thaw Cycles and Water Content on Pore Connectivity",
        subtitle = "After Freeze/Thaw",
        caption = "Pore Coordination Number",
        tag = "Figure X",
        x = expression (bold ("pore coordination number")),
        y = expression (bold ("frequency, %")))

p + scale_fill_manual(values=c("#56B4E9", "#E69F00"))


#########
before_fig_pcn=
tool %>%
  filter(sample %in% "Core C, 16%", trmt %in% "before") %>% 
  mutate(pore_coor = as.numeric(pore_coor)) %>% 
  ggplot(aes(x = pore_coor, y = freq, color = trmt)) +
  geom_path(aes(group = trmt), size = 1, show.legend = FALSE)+ 
  geom_area(aes(group = trmt, fill = trmt), alpha = 0.5, position = "identity")+
  #geom_point(size = 3.5, alpha = 0.5) + 
  scale_x_continuous(limits = c(0,16), 
                     breaks = seq(0,16,4)) +
  scale_y_continuous(labels = (scales::percent),
                     limits = c(0.0,0.6),
                     breaks = seq(0,0.6,0.2))+
  #facet_wrap(~ sample) +
  scale_color_manual(values = c("#023e8a")) +
  scale_fill_manual(values = c("#48cae4")) +
  labs (#title = "Pore Coordination Number Frequency",
    #caption = "Caption",
    #tag = "A",
    x = expression (bold ("pore coordination number")),
    y = expression (bold ("frequency, %"))) +
  theme_er() +
  theme(legend.position = "none", panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), panel.border = element_rect(color="gray",size=0.25, fill = NA))


ggsave("output/before_fig_pcn.png", before_fig_pcn, height = 3, width = 4)

after_fig_pcn =
tool %>%
  filter(sample %in% "Core C, 16%", trmt %in% "after") %>% 
  mutate(pore_coor = as.numeric(pore_coor)) %>% 
  ggplot(aes(x = pore_coor, y = freq, color = trmt)) +
  geom_path(aes(group = trmt), size = 1, show.legend = FALSE)+ 
  geom_area(aes(group = trmt, fill = trmt), alpha = 0.5, position = "identity")+
  #geom_point(size = 3.5, alpha = 0.5) + 
  scale_x_continuous(limits = c(0,16), 
                     breaks = seq(0,16,4)) +
  scale_y_continuous(labels = (scales::percent),
                     limits = c(0.0,0.6),
                     breaks = seq(0,0.6,0.2))+
  #facet_wrap(~ sample) +
  scale_color_manual(values = c("#9b2226")) +
  scale_fill_manual(values = c("#ca6702")) +
  labs (#title = "Pore Coordination Number Frequency",
    #caption = "Caption",
    #tag = "A",
    x = expression (bold ("pore coordination number")),
    y = expression (bold ("frequency, %"))) +
  theme_er() +
  theme(legend.position = "none", panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), panel.border = element_rect(color="gray",size=0.25, fill = NA))


ggsave("output/after_fig_pcn.png", after_fig_pcn, height = 3, width = 4)



