![](la-affordable-housing_data.jpg)

## Los Angeles: Affordable Housing Development Analysis

by [Jude Calvillo](http://linkd.in/1BGeytb)

### Qualifier / Status (as of 11/5/15)
I just started this project on Nov. 4, 2015, but I hope to complete it by Nov. 8, 2015. For better examples of my capacity for market research and data science, [please see the other directories in this repo](http://bit.ly/1LwfHq7).

***

### Introduction
This is an analysis of how well L.A. City's Affordable Housing Trust Fund is doing at meeting resident need for affordable housing. In addition to descriptive stats comparing needs to investment, it employs inferential stats to determine whether there have been any biases in resource allocation, per council district, to date.  

Sources:  
* [HCIDLA Affordable Housing Projects Catalog And Listing (2003 To Present)](http://bit.ly/1RYxurG)  
* [Some dataset of econ profile per district (it's coming!)](http://#)  

### Data Analysis

We'll begin with a few exploratory analyses, with plots, and then up-shift to more advanced, inferential statistics.

#### Development vs. Need

Let's see how much L.A. City's Affordable Housing Trust Fund has invested in housing projects since 2003, first by total spend, then by project count.

*Plots*



```r
## Get data: HCIDLA Affordable Housing Projects Catalog And Listing (2003 To Present)
## More info on dataset: http://bit.ly/1RvuGSS
aff_housing <- read.socrata("https://data.lacity.org/resource/u4mj-cwbz.csv")

## Counts and sum spent per council district.
d_counts <- count(aff_housing, COUNCIL.DISTRICT)
aff_housing$HCIDLA.FUNDED <- gsub("[,$]", "", aff_housing$HCIDLA.FUNDED)
aff_housing$HCIDLA.FUNDED <- as.numeric(aff_housing$HCIDLA.FUNDED)
d_spent <- summarise(group_by(aff_housing, COUNCIL.DISTRICT), SPENT=sum(HCIDLA.FUNDED))
d_totals <- cbind(d_counts, d_spent[,-1])

##### PLOTTING TOTALS THUS FAR ######

## Start by making a custom color palette equal to the size of our # of districts.
## Here, I use Color Brewer's colorRampPalette function, with our base palette of choice
## and its max # of colors, as its arguments prior to recalling it for our specified length.
color_count <- length(d_totals$COUNCIL.DISTRICT)
d_palette <- colorRampPalette(brewer.pal(11, "Spectral"))

## Plot spend per council district.
d_spend_bar <- ggplot(data=d_totals, aes(x=reorder(COUNCIL.DISTRICT, -COUNCIL.DISTRICT), y=SPENT/1000000,
                                         fill = d_palette(color_count))) +
    geom_bar(stat="identity") + coord_flip() +
    xlab("Council District") + ylab("") + guides(fill=FALSE) +
    scale_x_discrete(breaks=1:15) + 
    ggtitle("Total Spend (in Millions $)")

## Plot counts per council district.
d_count_bar <- ggplot(data=d_totals, aes(x=reorder(COUNCIL.DISTRICT, -COUNCIL.DISTRICT), y=n, 
                                         fill = d_palette(color_count))) +
    geom_bar(stat="identity") + coord_flip() +
    xlab("Council District") + ylab("") + guides(fill=FALSE) +
    scale_x_discrete(breaks=1:15) + 
    ggtitle("Number of Projects Initiated")

grid.arrange(d_spend_bar, d_count_bar, ncol = 2, top = "L.A. City Affordable Housing:\r
Totals per City Council District Since 2003")
```

![plot of chunk unnamed-chunk-2](figure/unnamed-chunk-2-1.png) 

*Actual Values*


```r
## Full table of counts.
d_pretty <- arrange(d_totals, desc(SPENT))
names(d_pretty) <- c("Council_District", "Project_Count", "Total_Spend")
d_pretty <- d_pretty[c(1,3,2)]
kable(d_pretty)
```



| Council_District| Total_Spend| Project_Count|
|----------------:|-----------:|-------------:|
|                1|   194193529|            71|
|               13|   119969095|            51|
|               14|   118016791|            33|
|                9|   101038161|            43|
|               10|    67590817|            26|
|                6|    61518197|            23|
|                8|    61149277|            38|
|               15|    38787487|            18|
|                7|    30526966|            14|
|                3|    28706467|             6|
|                2|    25546962|             8|
|               11|    10139134|             2|
|                4|     9988644|             5|
|                5|     2400000|             1|
|               12|     1931627|             2|

### Footnote
Thanks for your time and consideration. I'll be completing this as soon as possible!

Sincerely,
*Jude C.*


