#!/bin/bash

# Runs fmriprep using docker with the following options:
#	- output space for MNI152NLin6Asym (3mm) created for bic data
#	- ignore slice timing
#	- run ICA AROMA
# 	- dont use option to clean working dir when running in parallel


## Site specific variables to specify template data folders and license files
templateflow_dir=$HOME/.cache/templateflow					# templateflow directory with custom template
fs_license=$HOME/.licenses/freesurfer/license.txt			# freesurfer license location
work_dir=$HOME/work 										# working directory


## Define site specific options for fmriprep
# output_space="MNI152NLin6Asym:res-2 MNI152NLin2009cAsym" 	# normalization output space
fmriprep_version=22.0.0										# fmriprep version to run
nprocs=16 													# run with 16 cores
mem=24000													# run with 24GB memory
output_space=MNI152NLin6Asym3mm								# MNI template in 3mm resolution
template_resolution=res-01									# need to specify this to get 3mm resolution

date
now=`date +"%Y%m%d%H%M%S"` 


## Process command line arguments
usage(){ echo "Usage: `basename $0` -b <bids_dir> -p <participant_id> -t <task_id> 
b:	bids data dir
p:	bids ID for participant
t:	task id for fmriprep 

Runs fmriprep version ${fmriprep_version} for sessions of <participant_id> and <task_id> in <bids_dir>
Temporary files will be stored in $HOME/work and should be cleaned up manually
Output will be placed in <bids_dir>/derivatives/fmriprep_3mm

Example: `basename $0` -b /path/to/bids_data -p sub-235 -t foodpics 
" 1>&2; exit 1; }

if [ $# -ne 6 ]; then
	usage
fi
	
while getopts "b:p:t:" opt; do
    case "${opt}" in
    	b)
    		bids_dir=${OPTARG}
    		;;
        p)
            participant_id=${OPTARG}
            ;;
        t)
            task_id=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))


## Specify output folders
output_dir=$bids_dir/derivatives/fmriprep_3mm				# fmriprep output directory
log_dir=$bids_dir/derivatives/logs							# directory to save log file 


## Do basic check that data exists
# Check bids directory
if [ ! -e $bids_dir ]; then		
	echo "BIDS data directory does not exist: $bids_dir"
	exit 1
fi
# Check output directory
if [ ! -d $output_dir ]; then
	echo "Creating output directory: $output_dir"
	mkdir -p $output_dir
# 	exit 1
fi
# Check freesurfer license
if [ ! -e $fs_license ]; then
	echo "Freesurfer license does not exist: $fs_license"
	exit 1
fi
# Check participant directory
if [ ! -e $bids_dir/$participant_id ]; then
	echo "Folder missing for $participant_id in $bids_dir"
	exit 1
fi
# Check output log file directory
if [ ! -d $log_dir ]; then
	echo "Output log file directory does not exist: $log_dir"
	exit 1
fi


## Save output from command line to log file
fmriprep_logfile=$log_dir/fmriprep_output_${participant_id}_${task_id}_${now}.log



## Run fmriprep-docker and save output to fmriprep_logfile
date > $fmriprep_logfile # Overwrite existing log file

echo "Running $0 for $participant_id $task_id" >> $fmriprep_logfile

# remove for testing: --omp-nthreads $nprocs \
echo "docker run --rm -e DOCKER_VERSION_8395080871=20.10.17 -it \
-v ${fs_license}:/opt/freesurfer/license.txt:ro \
-v ${bids_dir}:/data:ro \
-v ${output_dir}:/out \
-v ${templateflow_dir}/tpl-${output_space}:/home/fmriprep/.cache/templateflow/tpl-${output_space}:ro \
-v ${output_dir}/sourcedata/freesurfer:/opt/subjects \
-v ${bids_filter_file}:/tmp/bids_filter_file.json \
-v ${work_dir}:/scratch \
nipreps/fmriprep:${fmriprep_version} /data /out participant \
--participant-label $participant_id \
--output-spaces ${output_space}:${template_resolution} \
-t $task_id \
--nprocs $nprocs \
--mem $mem \
--bids-filter-file /tmp/bids_filter_file.json \
--skip_bids_validation \
--fs-subjects-dir /opt/subjects \
--ignore slicetiming \
--use-aroma \
--notrack \
-v \
--stop-on-first-crash \
-w /scratch 
" >> $fmriprep_logfile


docker run --rm -e DOCKER_VERSION_8395080871=20.10.17 -it \
	-v ${fs_license}:/opt/freesurfer/license.txt:ro \
	-v ${bids_dir}:/data:ro \
	-v ${output_dir}:/out \
	-v ${templateflow_dir}/tpl-${output_space}:/home/fmriprep/.cache/templateflow/tpl-${output_space}:ro \
	-v ${output_dir}/sourcedata/freesurfer:/opt/subjects \
	-v ${bids_filter_file}:/tmp/bids_filter_file.json \
	-v ${work_dir}:/scratch \
	nipreps/fmriprep:${fmriprep_version} /data /out participant \
		--participant-label $participant_id \
		--output-spaces ${output_space}:${template_resolution} \
		-t $task_id \
		--nprocs $nprocs \
		--mem $mem \
		--bids-filter-file /tmp/bids_filter_file.json \
		--skip_bids_validation \
		--fs-subjects-dir /opt/subjects \
		--ignore slicetiming \
		--use-aroma \
		--notrack \
		-v \
		--stop-on-first-crash \
		-w /scratch 2>&1 | tee -a $fmriprep_logfile


date >> $fmriprep_logfile

date

