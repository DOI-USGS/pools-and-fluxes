library(targets)
library(dssecrets)
library(tidyverse)

options(tidyverse.quiet = TRUE)

source("data-src/s3_upload.R")
source("data-src/prep_logpile_data.R")

list(
  tar_target(
    abbott_data,
    read_csv('in/abbott-pools-and-fluxes.csv',
             skip = 1,
             col_types = c('ccccnnn'),
             col_names = c('Type','Category','Feature_group','Feature','Vol_1000km3','Vol_km3', "Vol_m3"))
  ),
  tar_target(
    water_volume_logpile_csv,
    prep_logpile_data(abbott_data, file_out = 'out/water_volume_logpile.csv')
  ),
  tar_target(
    water_volume_logpile_log,
    s3_upload(filepath_s3 = "visualizations/data/abbott_pools_and_fluxes.csv",
              on_exists = "replace",
              filepath_local = water_volume_logpile_csv,
              filepath_log = 'out/water_volume_logpile_log.csv'),
    format = "file"
  )
)
