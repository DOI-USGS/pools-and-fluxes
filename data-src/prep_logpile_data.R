prep_logpile_data <- function(abbott_data, file_out) {
  abbott_data %>%
    mutate(Vol_km3_log10 = log10(Vol_km3),
           Vol_row = as.numeric(substr(Vol_km3_log10, 1, 1)),
           Vol_prefix = Vol_km3/(10^Vol_row),
           row_start = 10^Vol_row,
           row_end = 10^(Vol_row+1)) %>%
    write_csv(file_out)

  return(file_out)
}
