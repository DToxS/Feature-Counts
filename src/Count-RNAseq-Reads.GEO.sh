#!/usr/bin/env bash
# This script counts the number of gene reads of multiple samples,
# by using featureCounts from Subread.

#
# Function definitions
#

help_msg ()
{
	echo "Usage: "$1" [Align Dir] [Counts Dir] [Annot Dir] [Counts File Main Name] [Sequencing Method] [Alignment File Suffix] [Number of Threads]" 1>&2
	echo "       [Align Dir]: the directory for sequence alignment files" 1>&2
	echo "       [Counts Dir]: the directory for read counts file" 1>&2
	echo "       [Annot File]: the annotation file for human genome reference library in GTF format" 1>&2
	echo "       [Counts File Main Name]: the main name of read-counts file" 1>&2
	echo "       [Sequencing Method]: the type of mRNA sequencing method [Value: conv, dge]" 1>&2
	echo "       [Alignment File Suffix]: the suffix of Alignment file name [Default: bam]" 1>&2
	echo "       [Number of Threads]: the number of parallel threads to use [Default: 4]" 1>&2
	return 1
}

cpus ()
{
	local N_THREADS_MAX="$1"
	if [ "${N_THREADS_MAX}" -gt 0 ]; then
		local CPUS=`getconf _NPROCESSORS_ONLN 2>/dev/null`
		[ -z "$CPUS" ] && CPUS=`getconf NPROCESSORS_ONLN`
		[ -z "$CPUS" ] && CPUS=`ksh93 -c 'getconf NPROCESSORS_ONLN'`
		[ -z "$CPUS" ] && CPUS=1
		[ "$CPUS" -gt "${N_THREADS_MAX}" ] && CPUS="${N_THREADS_MAX}"
		echo "${CPUS}"
		return 0
	else
		echo "ERROR: The number of threads must be greater than zero!" 1>&2
		return 1
	fi
}

check_seq_method ()
{
	local SEQ_METHOD="$(echo "$1" | tr "[:upper:]" "[:lower:]")"
	if [ "${SEQ_METHOD}" != "conv" ] && [ "${SEQ_METHOD}" != "dge" ]; then
		echo "ERROR: The sequencing method must be one of: conv and dge (case insensitive)!" 1>&2
		return 1
	else
		return 0
	fi
}

check_align_file_suffix ()
{
	local ALIGN_SUFFIX="$(echo "$1" | tr "[:upper:]" "[:lower:]")"
	if [ "${ALIGN_SUFFIX}" != "bam" ] && [ "${ALIGN_SUFFIX}" != "sam" ]; then
		echo "ERROR: The suffix of alignment file name must be one of: bam and sam (case insensitive)!" 1>&2
		return 1
	else
		return 0
	fi
}

check_dir ()
{
	if [ ! -d "$1" ]; then
		echo "ERROR: Directory "$1" is not found!" 1>&2
		return 1
	else
		return 0
	fi
}

check_file ()
{
	if [[ ! -f "$1" && ! -h "$1" ]] || [[ ! -r "$1" ]]; then
		echo "ERROR: File "$1" is not found or not accessible!" 1>&2
		return 1
	else
		return 0
	fi
}

#
# Main program
#

# Initialize error code.
EXIT_CODE=0

# Obtain and check program path.
PROG_PATH="$0"
PROG_DIR="$(dirname "${PROG_PATH}")"
PROG_NAME="$(basename "${PROG_PATH}")"

# Process input arguments.
if [ ${EXIT_CODE} -eq 0 ]; then
	# Specify the range of the number of input arguments.
	N_ARGS_MIN=5
	N_ARGS_MAX=7
	# Check and assign input arguments.
	if [ $# -ge "${N_ARGS_MIN}" ] && [ $# -le "${N_ARGS_MAX}" ]; then
		ALIGN_FILE_SUFFIX="bam"
		THREAD_NUMBER=4
		if [ ${EXIT_CODE} -eq 0 ] && [ $# -ge $((N_ARGS_MIN)) ] && [ "${N_ARGS_MIN}" -ge 1 ]; then
			ALIGN_DIR="${@:((N_ARGS_MIN-4)):1}"
			COUNTS_DIR="${@:((N_ARGS_MIN-3)):1}"
			ANNOT_FILE="${@:((N_ARGS_MIN-2)):1}"
			COUNTS_FILE_MAIN_NAME="${@:((N_ARGS_MIN-1)):1}"
			SEQ_METHOD="$(echo "${@:((N_ARGS_MIN)):1}" | tr "[:upper:]" "[:lower:]")"
			check_dir "${ALIGN_DIR}" && \
				check_dir "${COUNTS_DIR}" && \
				check_file "${ANNOT_FILE}" && \
				check_seq_method "${SEQ_METHOD}"
			EXIT_CODE=$?
		fi
		if [ ${EXIT_CODE} -eq 0 ] && [ $# -ge $((N_ARGS_MIN+1)) ]; then
			ALIGN_FILE_SUFFIX="${@:((N_ARGS_MIN+1)):1}"
			check_align_file_suffix "${ALIGN_FILE_SUFFIX}"
			EXIT_CODE=$?
		fi
		if [ ${EXIT_CODE} -eq 0 ] && [ $# -ge $((N_ARGS_MIN+2)) ]; then
			THREAD_NUMBER="$(cpus "${@:((N_ARGS_MIN+2)):1}")"
			EXIT_CODE=$?
		fi
	else
		# Print help message for the wrong number of input arguments.
		help_msg "${PROG_NAME}"
		EXIT_CODE=$?
	fi
fi

# Count aligned sequence reads from the alignment files.
if [ ${EXIT_CODE} -eq 0 ]; then
	# Set the output read-counts file.
	COUNTS_FILE_EXT_NAME="txt"
	COUNTS_FILE_NAME="${COUNTS_FILE_MAIN_NAME}.${COUNTS_FILE_EXT_NAME}"
	COUNTS_FILE_PATH="${COUNTS_DIR}/${COUNTS_FILE_NAME}"
	# Set the paramters for a four-step reads counting procedure.
	UMI_SAM_ALIGN_SUFFIX="umi.sam"
	UMI_BAM_ALIGN_SUFFIX="$(basename "${UMI_SAM_ALIGN_SUFFIX}" | sed "s/sam/bam/g")"
	FEATURE_ALIGN_SUFFIX="featureCounts.sam"
	if [ "${SEQ_METHOD}" == "conv" ]; then
		REPORTS=(0)
		ALIGN_SUFFIXES=("${ALIGN_FILE_SUFFIX}")
	elif [ "${SEQ_METHOD}" == "dge" ]; then
		REPORTS=(1 0)
		ALIGN_SUFFIXES=("${ALIGN_FILE_SUFFIX}" "${UMI_BAM_ALIGN_SUFFIX}")
	else
		echo "ERROR: The sequencing method must be one of: conv and dge (case insensitive)!" 1>&2
	fi
	N_REPEATS="${#REPORTS[@]}"
	for (( IDX=0; IDX<N_REPEATS; IDX++ )); do
		REPORT="${REPORTS[${IDX}]}"
		ALIGN_SUFFIX="${ALIGN_SUFFIXES[${IDX}]}"
		# Retrieve the names of a set of sequence alignment files.
		readarray -t -d $'\0' ALIGN_FILES < <(find -L "${ALIGN_DIR}" -maxdepth 1 -type f -name "*\.${ALIGN_SUFFIX}" -print0)
		EXIT_CODE=$?
		# Count aligned sequence reads from two types of alignment files:
		if [ ${EXIT_CODE} -eq 0 ]; then
			N_ALIGN_FILES="${#ALIGN_FILES[@]}"
			if [ ${N_ALIGN_FILES} -gt 0 ]; then
				# Step 1: Count the aligned reads from the bam files (*.bam) generated by STAR.
				# Step 4: Count the aligned reads with unique UMI taggs (*.umi.bam) in the BAM
				#         format generated by SAM-Alignment-Counter and converted from samtools.
				echo "featureCounts is counting aligned reads ${ALIGN_SUFFIX} alignment files in ${ALIGN_DIR} ..."
				featureCounts \
					-a "${ANNOT_FILE}" \
					-F "GTF" \
					-t "exon" \
					-g "gene_id" \
					$([ "${REPORT}" -eq 1 ] && echo "-R SAM" || :) \
					-T "${THREAD_NUMBER}" \
					-o "${COUNTS_FILE_PATH}" \
					"${ALIGN_FILES[@]}"
				EXIT_CODE=$?
				# Clean up the read-counts files as needed.
				if [ ${EXIT_CODE} -eq 0 ]; then
					if [ ${IDX} -eq 0 ] && [ ${N_REPEATS} -eq 2 ]; then
						# Clean up the read-counts files generated from the bam files.
						echo "Removing the read-counts file ..."
						rm "${COUNTS_FILE_PATH}"
					fi
					echo "Removing the read-counts summary file ..."
					rm "${COUNTS_FILE_PATH}.summary"
				fi
			else
				echo "ERROR: No ${ALIGN_SUFFIX} alignment file is found in ${ALIGN_DIR}!" 1>&2
				EXIT_CODE=1
			fi
		fi
		# Between step 1 and 4, run the SAM-Alignment-Counter program to remove
		# the sequence reads with duplicate UMI tags.
		if [ ${EXIT_CODE} -eq 0 ] && [ ${REPORT} -eq 1 ]; then
			# Move the featurecounts.sam files generated by the report mode of
			# featureCounts with detailed alignment information from COUNTS_DIR
			# to ALIGN_DIR.
			readarray -t -d $'\0' FEATURE_ALIGN_FILES < <(find -L "${COUNTS_DIR}" -maxdepth 1 -type f -name "*\.${FEATURE_ALIGN_SUFFIX}" -print0)
			EXIT_CODE=$?
			# Move the featurecounts.sam files from COUNTS_DIR to ALIGN_DIR.
			if [ ${EXIT_CODE} -eq 0 ]; then
				N_FEATURE_ALIGN_FILES="${#FEATURE_ALIGN_FILES[@]}"
				if [ ${N_FEATURE_ALIGN_FILES} -gt 0 ]; then
					echo "Moving the ${FEATURE_ALIGN_SUFFIX} alignment files from ${COUNTS_DIR} to ${ALIGN_DIR} ..."
					mv -t "${ALIGN_DIR}" "${FEATURE_ALIGN_FILES[@]}"
					EXIT_CODE=$?
				else
					echo "ERROR: No ${FEATURE_ALIGN_SUFFIX} alignment file is found in ${COUNTS_DIR}!" 1>&2
					EXIT_CODE=1
				fi
			fi
			# Step 2: Remove the aligned reads containing duplicate UMI taggs and generate
			# the sequence aligment files containing the reads with unique UMI tags.
			if [ ${EXIT_CODE} -eq 0 ]; then
				# Retrieve the names of a set of sequence alignment files.
				readarray -t -d $'\0' FEATURE_ALIGN_FILES < <(find -L "${ALIGN_DIR}" -maxdepth 1 -type f -name "*\.${FEATURE_ALIGN_SUFFIX}" -print0)
				EXIT_CODE=$?
				if [ ${EXIT_CODE} -eq 0 ]; then
					N_FEATURE_ALIGN_FILES="${#FEATURE_ALIGN_FILES[@]}"
					if [ ${N_FEATURE_ALIGN_FILES} -gt 0 ]; then
						# Run the SAM-Alignment-Counter program to generate the sequence reads
						# with unique UMI tags for each sequemence aligment file.
						for FEATURE_ALIGN_FILE in "${FEATURE_ALIGN_FILES[@]}"; do
							UMI_ALIGN_FILE_NAME="$(basename "${FEATURE_ALIGN_FILE}" | sed "s/${ALIGN_FILE_SUFFIX}.${FEATURE_ALIGN_SUFFIX}$/${UMI_SAM_ALIGN_SUFFIX}/g")"
							UMI_ALIGN_FILE="${ALIGN_DIR}/${UMI_ALIGN_FILE_NAME}"
							echo "SAM-Alignment-Counter is counting unique UMI reads in ${FEATURE_ALIGN_FILE} ..."
							SAM-Alignment-Counter "${FEATURE_ALIGN_FILE}" "${UMI_ALIGN_FILE}"
							EXIT_CODE=$?
						done
						if [ ${EXIT_CODE} -eq 0 ]; then
							echo "Removing the sequence aligment files generated by featureCounts ..."
							rm "${FEATURE_ALIGN_FILES[@]}"
						fi
					else
						echo "ERROR: No ${FEATURE_ALIGN_SUFFIX} alignment file is found in ${ALIGN_DIR}!" 1>&2
						EXIT_CODE=1
					fi
				fi
			fi
			# Step 3: Convert the sequence aligment files of unique UMI reads from SAM to BAM format.
			if [ ${EXIT_CODE} -eq 0 ]; then
				# Retrieve the names of a set of sequence alignment files.
				readarray -t -d $'\0' UMI_SAM_ALIGN_FILES < <(find -L "${ALIGN_DIR}" -maxdepth 1 -type f -name "*\.${UMI_SAM_ALIGN_SUFFIX}" -print0)
				EXIT_CODE=$?
				if [ ${EXIT_CODE} -eq 0 ]; then
					N_UMI_SAM_ALIGN_FILES="${#UMI_SAM_ALIGN_FILES[@]}"
					if [ ${N_UMI_SAM_ALIGN_FILES} -gt 0 ]; then
						# Use Samtools to convert sequence aligment files from SAM to BAM format.
						for UMI_SAM_ALIGN_FILE in "${UMI_SAM_ALIGN_FILES[@]}"; do
							UMI_BAM_ALIGN_FILE_NAME="$(basename "${UMI_SAM_ALIGN_FILE}" | sed "s/${UMI_SAM_ALIGN_SUFFIX}$/${UMI_BAM_ALIGN_SUFFIX}/g")"
							UMI_BAM_ALIGN_FILE="${ALIGN_DIR}/${UMI_BAM_ALIGN_FILE_NAME}"
							echo "samtools is converting ${UMI_SAM_ALIGN_FILE} to BAM format ..."
							samtools view -b "${UMI_SAM_ALIGN_FILE}" > "${UMI_BAM_ALIGN_FILE}"
							EXIT_CODE=$?
						done
						if [ ${EXIT_CODE} -eq 0 ]; then
							echo "Removing the unique UMI aligment files in SAM format ..."
							rm "${UMI_SAM_ALIGN_FILES[@]}"
						fi
					else
						echo "ERROR: No ${UMI_SAM_ALIGN_SUFFIX} alignment file is found in ${ALIGN_DIR}!" 1>&2
						EXIT_CODE=1
					fi
				fi
			fi
		fi
		# Quit if error occurs.
		if [ ${EXIT_CODE} -ne 0 ]; then
			break
		fi
	done
fi

# Exit with error code.
exit ${EXIT_CODE}
