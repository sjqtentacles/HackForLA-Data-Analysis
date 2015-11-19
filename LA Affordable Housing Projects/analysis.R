library(RSocrata)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(pwr)

## Get data: HCIDLA Affordable Housing Projects Catalog And Listing (2003 To Present)
## More info on dataset: http://bit.ly/1RvuGSS
aff_housing <- read.socrata("https://data.lacity.org/resource/u4mj-cwbz.csv")

## Preview data.
print(head(aff_housing))
print(nrow(aff_housing))

####### START: INVESTIGATING TOTALS TO DATE (Across all years in dataset) ########

## Counts, per council district, to date.
d_counts <- count(aff_housing, COUNCIL.DISTRICT)

## After some cleaning and prettying (with descriptions), summarize by sum INVESTMENT to date.
aff_housing$HCIDLA.FUNDED <- gsub("[,$]", "", aff_housing$HCIDLA.FUNDED)
aff_housing$HCIDLA.FUNDED <- as.numeric(aff_housing$HCIDLA.FUNDED)
d_defs <- read.csv("data/district_definitions.csv")
names(d_defs) <- as.character(1:15)
d_INVESTMENT <- summarise(group_by(aff_housing, COUNCIL.DISTRICT), INVESTMENT=sum(HCIDLA.FUNDED))
d_totals <- cbind(d_counts, as.vector(t(d_defs[1,])), d_INVESTMENT[,-1])

## Print pretty totals per district to date.
d_totals <- d_totals[c(1,3,2,4)]
names(d_totals)[2] <- "DESCRIPTION"
print(d_totals)


## PLOTTING...

## Plot counts per council district.
d_count_bar <- ggplot(data=d_totals, aes(x=reorder(COUNCIL.DISTRICT, -COUNCIL.DISTRICT), y=n, 
                                         fill = as.factor(COUNCIL.DISTRICT))) +
    geom_bar(stat="identity") + coord_flip() +
    xlab("Council District") + ylab("") + guides(fill=FALSE) +
    scale_x_discrete(breaks=1:15) + 
    ggtitle("Number of Projects Initiated")

## Plot spend per council district.
## Start by setting up graphics device for local saving.
png(filename="figure/invest-totals.png", height=400, width=800, bg="white")

d_spend_bar <- ggplot(data=d_totals, aes(x=reorder(COUNCIL.DISTRICT, -COUNCIL.DISTRICT), y=INVESTMENT/1000000,
                                         fill = as.factor(COUNCIL.DISTRICT))) +
    geom_bar(stat="identity") + coord_flip() +
    xlab("Council District") + ylab("") + guides(fill=FALSE) +
    scale_x_discrete(breaks=1:15) + 
    ggtitle("Total Spend on Projects (in Millions $)")


grid.arrange(d_spend_bar, d_count_bar, ncol = 2, top = "L.A. City Affordable Housing:\r
Totals per City Council District Since 2003")

## Turn off graphics device.
dev.off()

####### START: PLOTTING ########

## Counts, per council district, to date.
d_counts <- count(aff_housing, COUNCIL.DISTRICT)

## After some cleaning and prettying (with descriptions), summarize by sum INVESTMENT to date.
## ---------------

## Start by removing dollar signs and making funding amounts numeric.
aff_housing$HCIDLA.FUNDED <- gsub("[,$]", "", aff_housing$HCIDLA.FUNDED)
aff_housing$HCIDLA.FUNDED <- as.numeric(aff_housing$HCIDLA.FUNDED)

## Get district descriptions.
d_defs <- read.csv("data/district_definitions.csv")
names(d_defs) <- as.character(1:15)

## Total investment, units, and jobs, per district.
## UNITS and JOBS use "-999" as their NAs, apparently, so let's filter those out.
d_INVESTMENT <- summarise(group_by(aff_housing, COUNCIL.DISTRICT), INVESTMENT=sum(HCIDLA.FUNDED))
d_units <- summarise(group_by(aff_housing[!(aff_housing$UNITS %in% "-999"),], COUNCIL.DISTRICT), TOTAL_UNITS=sum(UNITS))
d_jobs <- summarise(group_by(aff_housing[!(aff_housing$JOBS %in% "-999"),], COUNCIL.DISTRICT), TOTAL_JOBS=sum(JOBS))
d_totals <- cbind(d_counts, as.vector(t(d_defs[1,])), d_INVESTMENT[,-1], d_units[,-1], d_jobs[,-1])

## Grabbing potential economic predictor values from ESRI/LAEDC data (2012 district profiles, to be
## considered the average, until I can make full use of GIS data to cross-ref Census data with
## district geography).
d_econ <- read.csv("data/district_econ.csv")

## Binding to totals/outcomes from earlier, then prettying and previewing. 
d_profiles <- cbind(d_totals[c(1,3,2,4:6)], d_econ[,-1])
names(d_profiles)[2] <- "DESCRIPTION"
print(d_profiles[c(1,2,3,4,5,10)])

## --------------------------------------------------------------------
##
## LOOKING AT INVESTMENT VS. NEED AND INVESTMENT VS. PRODUCTIVITY.
## 
## For this, we can either look for a correlation between total funds invested and median
## household income, per year per district, OR we can look for a correlation between 
## total funds invested across all years and income averaged across all years, per district.
## 
## I believe the latter is the more conceptually responsible approach, because the former 
## assumes that HCIDLA management can respond to income figures within that same year. 
## The former also assumes that HCIDLA's total annual budget, across all districts, is infinite. 
##
## HOWEVER, this should result in substantially less generalizable -and less granular- 
## statistics, because with only 15 values for the predictor (avg. district income over the
## years) and 15 for the outcome (total INVESTMENT over the years), our "power" to predict will be 
## smaller than ideal.
##
## I hope to address this shortcoming upon gathering more data, specifically on HCIDLA 
## funding dates and funding horizon standards, from HCIDLA or elsewhere. Alternatively, I
## may use an arbitrary horizon formula (e.g. funding date = completion year - 2), then
## compute everything herein at a lower dimension with larger samples.

## Q1. How well does investment correspond to need in terms of income?
## Correlation between districts' total spend and median household income
inc_cor <- cor.test(d_profiles$INVESTMENT, d_profiles$med_house_income)
print(inc_cor)

## Q2. How predictive is avg. of median household income over the years to total spend over 
## the years, per district?
fit_inc_spend <- lm(INVESTMENT ~ med_house_income, data = d_profiles)
print(summary(fit_inc_spend)$r.squared)
print(summary(fit_inc_spend)$coefficients)

## Now, let's plot the predictor and outcome of concern, along with the regression line.
## For the pure R file, let's open up with the graphics device, for saving locally.
png(filename="figure/inc_spend.png", height=500, width=500, bg="white")
plot_inc_spend <- ggplot(d_profiles, aes(x = med_house_income, y = round(INVESTMENT/1000000, 3))) +
    geom_point(color="black") + 
    xlab("District Median Household Income") + 
    ylab("Total HCIDLA Investment (in Millions $)") + 
    scale_y_continuous(breaks=c(0,50,100,150,200)) +
    geom_text(aes(label=COUNCIL.DISTRICT),hjust=1.7, vjust=0) +
    geom_smooth(method = "lm", size = 1, col = "dodgerblue")
print(plot_inc_spend)
dev.off()

## Q5. Over the years, how well has number of units corresponded with HCIDLA dollars funded?
uni_cor <- cor.test(d_profiles$INVESTMENT, d_profiles$TOTAL_UNITS)
print(uni_cor)

## Q6. Over the years, how many units have we gotten per funding dollar?
fit_spend_units <- lm(TOTAL_UNITS ~ INVESTMENT, data = d_profiles)
print(summary(fit_spend_units)$coefficients[2,])

## Now, let's plot the predictor and outcome of concern, along with the regression line.
## For the pure R file, let's open up with the graphics device, for saving locally.
png(filename="figure/spend_units.png", height=500, width=500, bg="white")
plot_uni_spend <- ggplot(d_profiles, aes(x = round(INVESTMENT/1000000, 3), y = TOTAL_UNITS)) +
    geom_point(color="black") + 
    xlab("Total HCIDLA Investment (in Millions $)") + 
    scale_x_continuous(breaks=c(0,50,100,150,200)) +
    ylab("District Number of Units Developed") + 
    geom_text(aes(label=COUNCIL.DISTRICT),hjust=1.2, vjust=0) +
    geom_smooth(method = "lm", size = 1, col = "purple")
print(plot_uni_spend)
dev.off()

## Q7. Over the years, how well has job creation corresponded to HCIDLA dollars funded?
job_cor <- cor.test(d_profiles$INVESTMENT, d_profiles$TOTAL_JOBS)
print(job_cor)

## Q8. Over the years, how many jobs do we get per investment dollar?
fit_spend_jobs <- lm(TOTAL_JOBS ~ INVESTMENT, data = d_profiles)
print(summary(fit_spend_jobs)$coefficients[2,])

## Now, let's plot the predictor and outcome of concern, along with the regression line.
## For the pure R file, let's open up with the graphics device, for saving locally.
png(filename="figure/spend_jobs.png", height=500, width=500, bg="white")
plot_inc_spend <- ggplot(d_profiles, aes(x = round(INVESTMENT/1000000, 3), y = TOTAL_JOBS)) +
    geom_point(color="black") + 
    xlab("Total HCIDLA Investment (in Millions $)") + 
    scale_x_continuous(breaks=c(0,50,100,150,200)) +
    ylab("District Number of Jobs Created") + 
    geom_text(aes(label=COUNCIL.DISTRICT),hjust=1.2, vjust=0) +
    geom_smooth(method = "lm", size = 1, col = "#4AA02C")
print(plot_inc_spend)
dev.off()

## Q9. Have any districts been significantly better -or worse- than the whole of districts
##     for job creation from investments?

## Looping through t-tests (vs. list apply), because A) I want to handle an error, and
## B, I'd like to create a data frame of just the values.
## Need to start with a blank data frame...
jobs_t_df <- data.frame(DISTRICT = NA,
                        T_SCORE = NA, 
                        P_VALUE = NA, 
                        DEGREES = NA,
                        POWER = NA)
for(i in 1:15){
    
    ## Get current row count, for later use.
    og_rows <- nrow(clean_jobs)
        
    ## To handle the error of having only one element in a vector, duplicate the 
    ## relevant row. Sorry, quick band-aid to loop's stoppage, but it should make no practical
    ## difference.
    if(nrow(clean_jobs[clean_jobs$COUNCIL.DISTRICT == i,]) < 2){
        clean_jobs <- rbind(clean_jobs, clean_jobs[clean_jobs$COUNCIL.DISTRICT == i,])
    }
    
    ## Looped variable value t-test.
    clean_t1 <- t.test(clean_jobs[clean_jobs$COUNCIL.DISTRICT == i,]$JOBS,
                       # clean_jobs[!(clean_jobs$COUNCIL.DISTRICT == i),]$JOBS, # Against other dist values
                       clean_jobs$JOBS, # Against all dist values.
                       paired = F)
    
    clean_pow <- pwr.t2n.test(
                        n1 = length(clean_jobs[clean_jobs$COUNCIL.DISTRICT == i,]$JOBS), 
                        n2 = length(clean_jobs$JOBS), 
                        d = as.numeric(clean_t1$statistic), sig.level = .05)
    
    jobs_t <- c(
                i, 
                as.numeric(round(clean_t1$statistic, 3)), 
                as.numeric(round(clean_t1$p.value, 3)), 
                as.numeric(round(clean_t1$parameter, 3)),
                clean_pow$power
                )
    
    ## Append the t test data frame.
    jobs_t_df <- rbind(jobs_t_df, jobs_t)
    
    ## Remove duplicate row, if one was created for single-value t-test above.
    if(nrow(clean_jobs) > og_rows){
        clean_jobs <- clean_jobs[-nrow(clean_jobs),]
    }
}

## Clean jobs t test df and print only those rows with "significant" p-values.
jobs_t_df <- na.omit(jobs_t_df)
row.names(jobs_t_df) <- NULL
print(jobs_t_df[jobs_t_df$P_VALUE < .05,])

## Compare to total rows in clean_jobs df.
print(paste("Total records:",nrow(clean_jobs)))

## Now, plot job creation across the 15 districts. 
png(filename="figure/box_jobs.png", height=500, width=500, bg="white")
cd_jobs <- clean_jobs[,c(7,19)]
box_jobs <- ggplot(cd_jobs, aes(x=as.factor(COUNCIL.DISTRICT), y=JOBS, fill=as.factor(COUNCIL.DISTRICT))) + 
            geom_boxplot(outlier.shape = 18, outlier.size = 5, outlier.colour = "black") + 
            guides(fill=FALSE) +
            ggtitle("Jobs-Per-Project Distribution, by City Council District") +
            xlab("City Council District") + ylab("Jobs per Project")
print(box_jobs)
dev.off()

