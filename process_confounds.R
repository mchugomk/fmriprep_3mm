# process_confounds.R
#
# Calculate summary statistics for motion parameters from fmriprep
# - Motion parameters: trans_x, trans_y, trans_z, rot_x, rot_y, rot_z, framewise_displacement, dvars
# - Summary stats: min, max, mean, sd, median
# 
# fmriprep_dir: Path to main fmriprep output directory
# returns: stats saved in confound_data_summary.csv in fmriprep_dir
# usage: process_confounds("/Volumes/bk/data/analysis/maureen/rto/data/bids_data/derivatives/fmriprep_3mm")
# 

library(tidyverse)  
library(readxl)     


rad2deg <- function(radians){radians*(180/pi)}

process_confounds <- function(fmriprep_dir){

  confound_data_filename <- file.path(fmriprep_dir, "confound_data_summary.csv")                # output file for data extracted from confound files
  confound_pattern <- ".*confounds_timeseries.tsv$"                                             # regexp pattern for fmriprep confound files
  
  ## Start in bids directory
  setwd(fmriprep_dir) 
  
  ## Process all confound files from fmriprep
  #   find all files in main data dir
  confound_files <- list.files(path=fmriprep_dir, pattern=confound_pattern, full.names = T, recursive = T, include.dirs = T) 
  
  ## Read in all confound files from fmriprep into data frame
  confound_data.df <- confound_files %>%
    set_names() %>%
    map_df(read_tsv, na="n/a", .id = "source") %>%
    mutate(fname=basename(source)) %>%
    separate(fname, c("subject_id","session_id","task_id","run_id","tmp1","tmp2"), sep = "_") %>%
    select(-c(source,tmp1,tmp2)) %>%
    mutate(rot_x_deg=rad2deg(rot_x), rot_y_deg=rad2deg(rot_y), rot_z_deg=rad2deg(rot_z))
  
  ## Calculate summary stats for motion parameters 
  confound_data.df.summary <- confound_data.df %>%
    select(c(subject_id:run_id, trans_x, trans_y, trans_z, rot_x, rot_y, rot_z, rot_x_deg, rot_y_deg, rot_z_deg, framewise_displacement, dvars)) %>%
    group_by(subject_id, session_id, task_id, run_id) %>%
    summarise_if(is.numeric, list(min=min, max=max, mean=mean, sd=sd, median=median), na.rm=T) 
  
  write_csv(confound_data.df.summary, confound_data_filename)
  
}
  