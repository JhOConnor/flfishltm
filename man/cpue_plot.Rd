% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cpue.R
\name{cpue_plot}
\alias{cpue_plot}
\title{Catch-Per-Unit-Effort Timeseries Plot}
\usage{
cpue_plot(
  datafile,
  speciesList = list(),
  species_size_strata = list(),
  years = list(),
  seasons = list(),
  print = FALSE,
  figure_filename = NA,
  fig_scale = 1,
  return_object = "data"
)
}
\arguments{
\item{datafile}{data, should be output from ltm.data.summary function}

\item{speciesList}{list of selected species, can specify by common name, scientific name or species code}

\item{species_size_strata}{optional argument, specifies size strata groups for which CPUEs should be calculated, see example below for proper convention.}

\item{years}{list of years to include in figure}

\item{seasons}{---currently functionless, will update in future version, to avoid errors make sure that all seasons in input dataset are the same---}

\item{print}{boolean, if TRUE figure will be saved to file}

\item{figure_filename}{if print=TRUE, figure will be saved to this filename}

\item{fig_scale}{adjust to scale output figure size}

\item{return_object}{\emph{string} if "data" then function returns the dataset
that is used to generate the figure, else if "ggplot" then function returns
ggplot object}
}
\value{
either summarised data or a ggplot object. Specify the return object type with \code{return_object}
}
\description{
Create CPUE timeseries for species and years selected
}
\examples{
# import and format data
data(newnans)
newn_sum <- ltm.data.summary("Newnans Lake", newnans)
# CPUE plots for bluegill, largemouth bass, and brown bullheads
newnans_cpue <- cpue_plot(newn_sum,
 speciesList=c("BLUE","LMB", "BRBU"),
 years = c(2016:2020))
# CPUE plots by size class
newnans_cpue2 <- cpue_plot(newn_sum,
 speciesList=c("BLUE","LMB","BRBU"),
 species_size_strata = list(
  BLUE = list(
   YOY = c(0,8),
   Quality = c(18,50)),
  LMB = list(
   YOY = c(0,20),
   Quality = c(30,50),
   Trophy = c(51,100))
 ),
 years = c(2016:2020)
)
}
