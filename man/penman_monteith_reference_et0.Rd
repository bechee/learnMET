% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/etp_functions.R
\name{penman_monteith_reference_et0}
\alias{penman_monteith_reference_et0}
\title{Calculates reference ET0 based on the Penman-Monteith model (FAO-56 Method)}
\usage{
penman_monteith_reference_et0(
  doy,
  latitude,
  elevation,
  tmin,
  tmax,
  tmean,
  solar_radiation,
  wind_speed,
  rhmean,
  rhmax,
  rhmin,
  tdew,
  use_rh = TRUE
)
}
\description{
This function calculates the potential evapotranspiration rate from
a reference crop canopy (ET0) in mm/d.

For these calculations the
}