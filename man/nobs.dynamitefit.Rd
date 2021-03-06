% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/nobs.R
\name{nobs.dynamitefit}
\alias{nobs.dynamitefit}
\title{Extract the Number of Observations used to fit a Dynamite Model}
\usage{
\method{nobs}{dynamitefit}(object, ...)
}
\arguments{
\item{object}{[\code{dynamitefit}]\cr The model fit object.}

\item{...}{Not used.}
}
\value{
Total number of observations as integer.
Missing values are not accounted for as the
number of complete cases may vary across
channels, time points and groups.
}
\description{
Extract the Number of Observations used to fit a Dynamite Model
}
\examples{
nobs(gaussian_example_fit)

}
