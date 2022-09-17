library(targets)
library(tidyverse)

options(tidyverse.quiet = TRUE)
tar_option_set(packages = c('readxl', 'aws.s3'))

source("data-src/s3_upload.R")

list(
  tar_target(
    # data as xlsx so manually editable
    water_volume_csv,
    # magnitude of pools and fluxes and file paths/credits for images
    'public/data/pools-fluxes-examples-limited.csv',
    format = 'file'
  ),
  tar_target(
    # data as xlsx so manually editable
    water_volume_data,
    # magnitude of pools and fluxes and file paths/credits for images
    read_csv(water_volume_csv)
  ),
  tar_target(
    # push file to prod on s3 so accessible by vue
    water_volume_s3,
    s3_upload(filepath_s3 = "visualizations/data/water_volumes.csv",
              on_exists = "replace",
              filepath_local = water_volume_csv)
  ),
  tar_target(
    # find images to put in s3
    water_images,
    water_volume_data %>%
      distinct(type, feature_label, feature_class, image_file, image_credit) %>%
      filter(!(is.na(image_file) | image_file == "NA"))
  ),
  tar_target(
    image_upload_s3, {
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
    bind_rows(water_volume_s3, image_upload_s3) %>%
      write_csv(file_out)
      return(file_out)
    },
    format = "file"
  )
)
