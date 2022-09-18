library(targets)
library(tidyverse)

options(tidyverse.quiet = TRUE)
tar_option_set(packages = c('readxl', 'aws.s3', 'magick'))

source("data-src/s3_upload.R")

list(
  tar_target(
    water_volume_csv,
    # magnitude of pools and fluxes and file paths/credits for images
    'public/data/pools-fluxes-examples-limited.csv',
    format = 'file'
  ),
  tar_target(
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
      distinct(feature_label, feature_class, image_file, image_credit) %>%
      filter(!(is.na(image_file) | image_file == "NA")) |>
      pull(image_file)
  ),

  # compress images via rescaling size and reduce dpi (density) output
  tar_target(
    ## export as png
    image_scaled_png,{
      out_file <- sprintf('tmp/%s', water_images)
      image_read(sprintf('Images/%s', water_images)) |>
        image_scale("x300") |>
        image_write(out_file, density = 100)
      return(out_file)
    },
    pattern = map(water_images),
    format = 'file'
  ),
  tar_target(
    ## export as webp to optimize browser delivery
    image_scaled_webp,{
      file_name <- str_extract(water_images, ".+\\.")
      out_file <- sprintf('tmp/%swebp', file_name)
      image_read(sprintf('Images/%s', water_images)) |>
        image_scale("x200") |>
        image_write(out_file, density = 92)
      return(out_file)
    },
    pattern = map(water_images),
    format = 'file'
  ),
  tar_target(
    image_list,
    c(image_scaled_png, image_scaled_webp)
  ),
  # store compressed images in s3
  tar_target(
    image_upload_s3, {
      file_local <- image_list
      file_name <- gsub('tmp/', '', file_local)
      file_s3 <- sprintf('visualizations/images/%s', file_name)
      s3_upload(filepath_s3 = file_s3,
                on_exists = "replace",
                filepath_local = file_local
      )
      },
    pattern = map(image_list)
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
