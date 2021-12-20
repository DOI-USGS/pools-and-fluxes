library(targets)
library(tarchetypes)
library(dssecrets)
library(tidyverse)

options(tidyverse.quiet = TRUE)

source("data-src/s3_upload.R")
source("data-src/prep_logpile_data.R")

list(
  tar_target(
    abbott_data,
    # magnitude of pools and fluxes
    read_csv('in/abbott-pools-and-fluxes.csv',
             skip = 1,
             col_types = c('ccccnnn'),
             col_names = c('Type','Category','Feature_group','Feature','Vol_1000km3','Vol_km3', "Vol_m3"))
  ),
  tar_target(
    image_data,
    # contains image file names that correspond to pools and fluxes.
    # derived from sheet Bekah is working on, so keeping separate from main data
    read_csv('in/abbott-pools-and-fluxes_images.csv',
             skip = 1,
             col_types = c('cccccc'),
             col_names = c('Type','Category','Feature_group','Feature',"image_file", "image_credit"))
  ),
  tar_target(
    water_volume_logpile_csv,
    prep_logpile_data(abbott_data, image_data, file_out = 'out/water_volume_logpile.csv'),
    format = "file"
  ),
  tar_target(
    water_volume_logpile_log_csv,
    s3_upload(filepath_s3 = "visualizations/data/abbott_pools_and_fluxes.csv",
              on_exists = "replace",
              filepath_local = water_volume_logpile_csv,
              filepath_log = 'out/water_volume_logpile_log.csv'),
    format = "file"
  ),
  tar_target(
    # images to upload to s3
    water_images,
    image_data %>%
      distinct(Feature, image_file, image_credit) %>%
      filter(!is.na(image_file))
  ),
  tar_target(
    image_upload_log, {
      file_name <- water_images$image_file
      file_s3 <- sprintf('visualizations/images/%s', file_name)
      file_local <- sprintf('Images/%s', file_name)
      file_parse <- gsub('.', '_', file_name, fixed = TRUE)
      file_log <- sprintf("out/image_%s_log.csv", file_parse)
      s3_upload(filepath_s3 = file_s3,
                on_exists = "replace",
                filepath_local = file_local,
                filepath_log = file_log)
      },
    format = "file",
    pattern = map(water_images)
  )
)
