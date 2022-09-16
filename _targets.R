library(targets)
library(tidyverse)

options(tidyverse.quiet = TRUE)
tar_option_set(packages = c('readxl'))

source("data-src/s3_upload.R")
source("data-src/prep_logpile_data.R")

list(
  tar_target(
    # data as xlsx so manually editable
    water_volume_xlsx,
    # magnitude of pools and fluxes and filepaths/credits for images
    'in/abbott-pools-and-fluxes.xlsx'
  ),
  tar_target(
    # convert to csv to read into javascript page - should be json??
    water_volume_csv,
    read_xlsx(water_volume_xlsx) |> write_csv('out/water_volume_pools_and_fluxes.csv')
  ),
  tar_target(
    # push file to prod on s3 so accessible by vue
    water_volume_s3,
    s3_upload(filepath_s3 = "visualizations/data/water_volume_pools_and_fluxes.csv",
              on_exists = "replace",
              filepath_local = water_volume_xlsx
  )),
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
      s3_upload(filepath_s3 = file_s3,
                on_exists = "replace",
                filepath_local = file_local
      )
      },
    pattern = map(water_images)
  ),
  tar_target(
    upload_log_csv,{
      file_out <- 'out/upload_log.csv'
    bind_rows(water_volume_logpile_log, image_upload_log) %>%
      write_csv(file_out)
      return(file_out)
    },
    format = "file"
  )
)
