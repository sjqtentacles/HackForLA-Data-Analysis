library(RSocrata)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(RColorBrewer)

## Get data: HCIDLA Affordable Housing Projects Catalog And Listing (2003 To Present)
## More info on dataset: http://bit.ly/1RvuGSS
aff_housing <- read.socrata("https://data.lacity.org/resource/u4mj-cwbz.csv")

## Preview data.
print(head(aff_housing))
print(nrow(aff_housing))

## Counts and sum spent per council district.
d_counts <- count(aff_housing, COUNCIL.DISTRICT)
aff_housing$HCIDLA.FUNDED <- gsub("[,$]", "", aff_housing$HCIDLA.FUNDED)
aff_housing$HCIDLA.FUNDED <- as.numeric(aff_housing$HCIDLA.FUNDED)
d_spent <- summarise(group_by(aff_housing, COUNCIL.DISTRICT), SPENT=sum(HCIDLA.FUNDED))
d_totals <- cbind(d_counts, d_spent[,-1])

## Preview counts and sum spend, first, in order of counts, then in order of spend.
print(head(arrange(d_totals, desc(n))))
print(head(arrange(d_totals, desc(SPENT))))


##### PLOTTING TOTALS THUS FAR ######

## Start by making a custom color palette equal to the size of our # of districts.
## Here, I use Color Brewer's colorRampPalette function, with our base palette of choice
## and its max # of colors, as its arguments prior to recalling it for our specified length.
color_count <- length(d_totals$COUNCIL.DISTRICT)
d_palette <- colorRampPalette(brewer.pal(11, "Spectral"))

## Plot counts per council district.
d_count_bar <- ggplot(data=d_totals, aes(x=reorder(COUNCIL.DISTRICT, -COUNCIL.DISTRICT), y=n, 
                                         fill = d_palette(color_count))) +
    geom_bar(stat="identity") + coord_flip() +
    xlab("Council District") + ylab("") + guides(fill=FALSE) +
    scale_x_discrete(breaks=1:15) + 
    ggtitle("Number of Projects Initiated")

## Plot spend per council district.
d_spend_bar <- ggplot(data=d_totals, aes(x=reorder(COUNCIL.DISTRICT, -COUNCIL.DISTRICT), y=SPENT/1000000,
                                         fill = d_palette(color_count))) +
    geom_bar(stat="identity") + coord_flip() +
    xlab("Council District") + ylab("") + guides(fill=FALSE) +
    scale_x_discrete(breaks=1:15) + 
    ggtitle("Total Spend on Projects (in Millions $)")

grid.arrange(d_count_bar, d_spend_bar, ncol = 2, top = "L.A. City Affordable Housing:\r
Totals per City Council District Since 2003")

