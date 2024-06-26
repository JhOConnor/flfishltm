#' Calculate Mean Catch-per-unit Effort (CPUE)
#'
#' @param data `data.frame` or `tibble` containing samples as rows, and species counts as columns along with an effort columnt
#' @param species name of column (unquoted) for species for which CPUE is desired
#' @param effort name of column (unquoted) specifying the sample effort value (typically minutes)
#'
#' @return named vector containing "Mean CPUE" and "SE" estimates
#' @export
#'
#' @examples
#' fish_data <- tibble(
#'   site = c(1:5,3:7),
#'   species_name = c(rep("BLUE", 5), rep("RESU", 5)),
#'   ct = c(5, 2, 6, 4, 7,
#'          8, 6, 7, 2, 9),
#'   minutes = rep(10, 10))
#' 
#' fish_data %>% 
#'   cpue(ct, "minutes") # can specify column name as either a symbol or character
#'   
#' fish_data %>% 
#'   group_by(species_name) %>% # use dplyr::group_by to specify grouping variables.
#'   cpue(ct, "minutes")
#'   
#' # fish_data %>% 
#' #   add_zero_count(c(site,minutes), species_name, ct) %>% #use [add_zero_count()]to account for missing absence data
#' #   group_by(species_name) %>% 
#' #   cpue(ct, "minutes")
cpue <- function(data, count, effort) {
  data %>% 
    dplyr::mutate(sample_CPUE = !!rlang::ensym(count)/!!rlang::ensym(effort))  %>%
    dplyr::summarise("mean_CPUE" = mean(sample_CPUE),
              "SE" = sd(sample_CPUE) / sqrt(n()),
              "N" = dplyr::n(),
              .groups = "keep")
}

#####################################################################################################################
#' Catch-Per-Unit-Effort Timeseries Plot
#' 
#' Create CPUE timeseries for species and years selected
#' @param datafile data, should be output from ltm.data.summary function
#' @param speciesList list of selected species, can specify by common name, scientific name or species code
#' @param species_size_strata optional argument, specifies size strata groups for which CPUEs should be calculated, see example below for proper convention. 
#' @param years list of years to include in figure
#' @param seasons ---currently functionless, will update in future version, to avoid errors make sure that all seasons in input dataset are the same---
#' @param print boolean, if TRUE figure will be saved to file
#' @param figure_filename if print=TRUE, figure will be saved to this filename
#' @param fig_scale adjust to scale output figure size
#' @param return_object *string* if "data" then function returns the dataset 
#'   that is used to generate the figure, else if "ggplot" then function returns
#'   ggplot object
#' @return either summarised data or a ggplot object. Specify the return object type with `return_object`
#' @examples
#' # import and format data
#' data(newnans)
#' newn_sum <- ltm.data.summary("Newnans Lake", newnans)
#' # CPUE plots for bluegill, largemouth bass, and brown bullheads
#' newnans_cpue <- cpue_plot(newn_sum,
#'  speciesList=c("BLUE","LMB", "BRBU"),
#'  years = c(2016:2020))
#' # CPUE plots by size class
#' newnans_cpue2 <- cpue_plot(newn_sum,
#'  speciesList=c("BLUE","LMB","BRBU"),
#'  species_size_strata = list(
#'   BLUE = list(
#'    YOY = c(0,8),
#'    Quality = c(18,50)),
#'   LMB = list(
#'    YOY = c(0,20),
#'    Quality = c(30,50),
#'    Trophy = c(51,100))
#'  ),
#'  years = c(2016:2020)
#' )
#' @export
cpue_plot   <- function(datafile,
                        speciesList = list(),
                        species_size_strata = list(),
                        years = list(),
                        seasons = list(),
                        print = FALSE,
                        figure_filename = NA,
                        fig_scale = 1,
                        return_object = "data") {
  

  if(length(speciesList) == 0) {stop("No species list")} else {species = speciesList}
  
  # Internal Functions -----------------------------------------------------------
  internal_get_year <- function(data, date_field) {
    formats <- 
      data %>% 
      pull({{ date_field }}) %>% 
      lubridate::guess_formats(orders = c("mdy", "ymd")) %>% 
      unique() %>% 
      .[!stringr::str_detect(.,"O")]
    
    if(length(formats) > 1) {
      cli::cli_abort("more than 1 date format detected")
    } else if (formats[[1]] == "%m/%d/%Y") {
      return(data %>%
               mutate(yr = lubridate::year(lubridate::mdy({{ date_field }}))) %>%
               pull(yr))
    } else if (formats[[1]] == "%Y-%m-%d") {
      return(data %>%
               mutate(yr = lubridate::year(lubridate::ymd({{ date_field }}))) %>%
               pull(yr))
    } else {
      cli::cli_abort("date format not recognized")
    }
    
  }
  
  internal_get_month <- function(data, date_field) {
    formats <- 
      data %>% 
      pull({{ date_field }}) %>% 
      lubridate::guess_formats(orders = c("mdy", "ymd")) %>% 
      unique() %>% 
      .[!stringr::str_detect(.,"O")]
    
    if(length(formats) > 1) {
      cli::cli_abort("more than 1 date format detected")
    } else if (formats[[1]] == "%m/%d/%Y") {
      return(data %>%
               mutate(yr = lubridate::month(lubridate::mdy({{ date_field }}))) %>%
               pull(yr))
    } else if (formats[[1]] == "%Y-%m-%d") {
      return(data %>%
               mutate(yr = lubridate::month(lubridate::ymd({{ date_field }}))) %>%
               pull(yr))
    } else {
      cli::cli_abort("date format not recognized")
    }
    
  }
  
  # Process ---------------------------------------------------------------------  
  workingdat <- 
    datafile$RawData %>% 
    mutate(Year = ifelse(internal_get_month(., Date) == 1, 
                         internal_get_year(., Date) - 1, 
                         internal_get_year(., Date))) %>%
    mutate(SeasYr = base::paste0(Season,"-", Year))
  
  
  od = workingdat
  
  if(length(years)==0) {years = as.numeric(unique(workingdat$Year))}
  
  #Create Year-Site-list
  YSL = workingdat %>% dplyr::select(WaterBody, Year, Site, Season) %>% distinct()
  
  #create species lookup table
  Species_lookup = workingdat %>% dplyr::select(SpeciesCode, SpeciesCommon, SpeciesScientific) %>% distinct()
  
  #create sizeStrata
  
  
  if(length(species_size_strata) != 0) {
    #print("Adding Specified Size Strata")
    workingdat$sizeStrata = NA
    #loop species within strata list
    for(ss in 1:length(species_size_strata)) {
      speciesSS = names(species_size_strata)[[ss]]
      #loop size classes within species slots
      for(sc in 1:length(species_size_strata[[ss]])) {
        sclass = names(species_size_strata[[ss]])[[sc]]
        # print(base::paste("Adding ", speciesSS, " size class: ", sclass))
        workingdat[which(workingdat$SpeciesCode == speciesSS & 
                           workingdat$TL_CM_Group <= max(species_size_strata[[ss]][[sc]]) &
                           workingdat$TL_CM_Group >= min(species_size_strata[[ss]][[sc]])
        ),c("sizeStrata")] = sclass
        
      }
    }
    #Identify species with No strata designated and assign "All"
    for(spi in 1:length(unique(workingdat$SpeciesCode))) {
      temp_species = unique(workingdat$SpeciesCode)[[spi]]
      if(!(temp_species %in% names(species_size_strata))) {
        workingdat[which(workingdat$SpeciesCode == temp_species), c("sizeStrata")] = "All"
      }
    }
  } else {workingdat$sizeStrata = "All"}
  
  # print("Done adding size strata")
  
  #print(base::paste("data rows:", nrow(workingdat)))
  
  #Subset target species
  # print("subset target species")
  workingdat = workingdat %>% 
    dplyr::filter((SpeciesCode %in% species)|(SpeciesCommon %in% species)|(SpeciesScientific %in% species))
  # 
  
  #         #Subset out by years and seasons specified in function call arguments
  # print("Subset out years and seasons specified in function call")
  if(length(years) != 0) {workingdat = workingdat[which(workingdat$Year %in% years), ]}
  if(length(seasons) != 0) { workingdat = workingdat[which(workingdat$Season %in% seasons), ]}
  
  # Need to create CPUE by size group # then feed that into CTFigs which needs to be modified
  workingdat2 = workingdat %>% 
    dplyr::group_by(WaterBody, Site, Year, Season, SpeciesCode, sizeStrata) %>% 
    dplyr::summarise(Count = sum(Count, na.rm=T), Effort = mean(Effort, na.rm=T)) 
  
  spst_lkup <- workingdat2 %>% ungroup() %>%
    dplyr::select(SpeciesCode, sizeStrata) %>% distinct() %>%
    unite("Species_strata", c(SpeciesCode,sizeStrata),remove=FALSE)
  
  wd = workingdat2 %>% full_join(YSL, 
                                 by = join_by(WaterBody, Site, Year, Season))
  
  #Calculate CPUE by WaterBody, Year, Season, Species and Size Strata
  CPUE_Sum_sizeStrata = wd %>% 
    unite("Species_strata", c(SpeciesCode,sizeStrata),remove=TRUE) %>%
    dplyr::select(-Effort) %>%
    pivot_wider(names_from = Species_strata,
                values_from = Count,
                values_fill = 0) %>% 
    tidyr::pivot_longer(-c(WaterBody, Site, Year, Season),
                        names_to = "Species_strata", 
                        values_to = "Count") %>% 
    dplyr::left_join(spst_lkup, 
                     by = join_by(Species_strata)) %>%
    dplyr::filter(Species_strata != "NA_NA") %>%
    dplyr::left_join(Species_lookup, 
                     by = join_by(SpeciesCode)) %>%
    dplyr::left_join(od %>%
                       dplyr::group_by(WaterBody, Site, Year, Season) %>% 
                       summarize(Effort = mean(Effort)/60),
                     by = join_by(WaterBody, Site, Year, Season)) %>%
    mutate(SampleCPUE = Count/Effort) %>%
    #average cpue across sites within Waterbody-Year-Season-Species-sizeStrata groups 
    dplyr::group_by(WaterBody, Year, Season, SpeciesCode, SpeciesCommon, SpeciesScientific, sizeStrata) %>%
    summarize(mean_CPUE = mean(SampleCPUE, na.rm=T),
              sd_CPUE = sd(SampleCPUE, na.rm=T ),
              se_CPUE = sd(SampleCPUE,  na.rm=T)/sqrt(n()),
              max_CPUE = max(SampleCPUE,  na.rm=T),
              min_CPUE = min(SampleCPUE,  na.rm=T),
              cv_CPUE = sd(SampleCPUE, na.rm=T)/mean(SampleCPUE, na.rm=T))
  
  #Create CPUE Summary, without size strata
  workingdat3 = workingdat %>% 
    dplyr::group_by(WaterBody, Site, Year, Season, SpeciesCode) %>% 
    dplyr::summarise(Count = sum(Count, na.rm=T), Effort = mean(Effort, na.rm=T))
  
  wd2 = workingdat3 %>% full_join(YSL, 
                                  by = join_by(WaterBody, Site, Year, Season))
  
  CPUE_Sum = wd2 %>% dplyr::select(-Effort) %>% 
    pivot_wider(names_from = c(SpeciesCode),
                values_from = Count,
                values_fill = 0) %>% 
    tidyr::pivot_longer(-c(WaterBody, Site, Year, Season),
                        names_to = "SpeciesCode", 
                        values_to = "Count") %>% 
    dplyr::filter(SpeciesCode != "NA" & !is.na(SpeciesCode)) %>%
    dplyr::left_join(Species_lookup,
                     by = join_by(SpeciesCode)) %>%
    dplyr::left_join(od %>% dplyr::group_by(WaterBody, Site, Year, Season) %>% summarize(Effort = mean(Effort)/60),
                     by = join_by(WaterBody, Site, Year, Season)) %>%
    mutate(SampleCPUE = Count/Effort) %>%
    #average cpue across sites within Waterbody-Year-Season-Species groups 
    dplyr::group_by(WaterBody, Year, Season, SpeciesCode, SpeciesCommon, SpeciesScientific) %>%
    summarize(mean_CPUE = mean(SampleCPUE, na.rm=T),
              sd_CPUE = sd(SampleCPUE, na.rm=T),
              se_CPUE = sd(SampleCPUE, na.rm=T)/sqrt(n()),
              max_CPUE = max(SampleCPUE, na.rm=T),
              min_CPUE = min(SampleCPUE, na.rm=T),
              cv_CPUE = sd(SampleCPUE,na.rm=T)/mean(SampleCPUE, na.rm=T)) %>%
    mutate(sizeStrata = "All_Sizes")
  
  CPUE_Sum <- rbind(CPUE_Sum, CPUE_Sum_sizeStrata)
  
  ci_limits <- function(x) {lower = x$mean_CPUE - 2*x$se_CPUE
  upper = x$mean_CPUE + 2*x$se_CPUE
  return(cbind(x,lower = lower,upper = upper))}
  
  CPUE_Sum = ci_limits(CPUE_Sum)
  CPUE_Sum = CPUE_Sum %>% dplyr::filter((!(sizeStrata %in% c(1,"All_Sizes", NA, "NA"))) & (Year %in% years))
  
  
  xmn = min(na.omit(years))
  xmx =  max(na.omit(years))
  
  xlims = seq(xmn,xmx,1)
  
  hist_avg = CPUE_Sum %>% dplyr::group_by(WaterBody, Season, SpeciesCode, SpeciesScientific, SpeciesCommon, sizeStrata) %>% 
    summarize(upperQ = quantile(na.omit(mean_CPUE),0.75),
              lowerQ = quantile(na.omit(mean_CPUE),0.25),
              med = median(na.omit(mean_CPUE))) %>% 
    crossing(xlims)
  
  
  Fig <- ggplot2::ggplot(data = CPUE_Sum,ggplot2::aes(color=sizeStrata,
                                                      pch=sizeStrata,
                                                      fill=sizeStrata))  + 
    
    facet_wrap(~SpeciesCommon, scales = "free_y", ncol=2) +
    scale_y_continuous(expand = expansion(mult = c(0,0.05))) +
    coord_cartesian(ylim = c(0,NA)) +
    labs(x = "Year", y = "Mean Catch Per Unit Effort by Number (#/minute \u00b1 2 SE)") +
    theme_bw() +
    scale_x_continuous(breaks= scales::breaks_width(2)) +
    geom_errorbar(ggplot2::aes(x = Year, 
                               ymin = lower,
                               ymax = upper, 
                               width = 0.2),
                  #size = 1
                  linewidth = 1) + 
    geom_point(ggplot2::aes(x = Year,
                            y = mean_CPUE), color = "black", size =2) +
    geom_ribbon(data = hist_avg, ggplot2::aes(x=xlims, ymax=upperQ,ymin=lowerQ, fill=sizeStrata),
                alpha=0.2, stat="identity") +
    theme(plot.title = element_text(hjust = 0.5),
          legend.title = element_blank())
  
  print(Fig)
  
  
  
  if(print == TRUE) {
    if(is.na(figure_filename)){figure_filename="cpue.plot.tiff"}
    if(substr(figure_filename,-6,-1) != ".tiff") {figure_filename = base::paste(figure_filename,".tiff",collapse="")}
    figHt = ceiling(length(speciesList)/2)
    figWid = ifelse(length(speciesList)>1,2,1)
    scale=fig_scale
    tiff(figure_filename, res = 300, height = (figHt*scale*300), width = (figWid*scale*300), compression = 'lzw')
    print(Fig)
    dev.off()
  }
  
  if(return_object == "data") {
    return(CPUE_Sum)
  } else if(return_object == "ggplot") {
    return(Fig)
  } else {
    cli::abort("return object: {return_object} not recognized. 
               Please choose either 'data' or 'ggplot'")
  }
  
}

