#!/usr/bin/env bash
# This script counts the number of gene reads of multiple samples,
# by using featureCounts from Subread.

help_msg ()
{
	echo "Usage: "$1" [multi mapping] [number of threads]" 1>&2
	exit 1
}

cpus ()
{
	local MAX_CPUS=4
	local CPUS=`getconf _NPROCESSORS_ONLN 2>/dev/null`
	[ -z "$CPUS" ] && CPUS=`getconf NPROCESSORS_ONLN`
	[ -z "$CPUS" ] && CPUS=`ksh93 -c 'getconf NPROCESSORS_ONLN'`
	[ -z "$CPUS" ] && CPUS=1
	[ "$CPUS" -gt "$MAX_CPUS" ] && CPUS=$MAX_CPUS
	echo "${CPUS}"
}

check_multi_mapping ()
{
	if [ "$1" -ne 0 ] && [ "$1" -ne 1 ] ; then
		echo "ERROR: Multi mapping must be either 0 or 1!" 1>&2
		exit 1
	fi
}

check_thread_number ()
{
	if [ "$1" -lt 1 ]; then
		echo "ERROR: The number of threads must be greater than zero!" 1>&2
		exit 1
	fi
}

check_dir ()
{
	if [ ! -d "$1" ]; then
		echo "ERROR: Directory "$1" is not found!" 1>&2
		exit 1
	fi
}

check_file ()
{
	if [[ ! -f "$1" && ! -h "$1" ]] || [[ ! -r "$1" ]]; then
		echo "ERROR: File "$1" is not found or not accessible!" 1>&2
		exit 1
	fi
}

# The main program begins here

PROG_NAME="$(basename "$0")"
if [ $# -lt 1 ]; then
	MULTI_MAPPING=0
	THREAD_NUMBER="$(cpus)"
elif [ $# -lt 2 ]; then
	MULTI_MAPPING="$1"
	THREAD_NUMBER="$(cpus)"
elif [ $# -lt 3 ]; then
	MULTI_MAPPING="$1"
	THREAD_NUMBER="$2"
else
	help_msg "${PROG_NAME}"
fi
check_multi_mapping "${MULTI_MAPPING}"
check_thread_number "${THREAD_NUMBER}"

# Global directories
DATASET_DIR="$HOME/LINCSData/Datasets/Difference/LINCS.Dataset/Coen-Paper/Conv-GEO-Depot"

# Alignment datasets.
ALIGN_DIR="${DATASET_DIR}/Aligns"
check_dir "${ALIGN_DIR}"
COUNT_DIR="${DATASET_DIR}/Counts"
check_dir "${COUNT_DIR}"

# Reference library.
REF_DIR="${DATASET_DIR}/References/UCSC/hg38"
check_dir "${REF_DIR}"
ANNOT_DIR="${REF_DIR}/Annotation"
check_dir "${ANNOT_DIR}"
ANNOT_FILE="${ANNOT_DIR}/RefSeq.hg38.gtf"
check_file "${ANNOT_FILE}"
ALIGN_FILE_SUFFIX="bam"

# featureCounts settings.
GTF_FEATURE_TYPE="exon"
GTF_ATTR_TYPE="gene_id"
OUTPUT_FILE_MAIN_NAME="Conv-RNAseq-Read-Counts"
OUTPUT_FILE_EXT_NAME="txt"
OUTPUT_FILE_NAME="${OUTPUT_FILE_MAIN_NAME}.${OUTPUT_FILE_EXT_NAME}"
OUTPUT_FILE="${COUNT_DIR}/${OUTPUT_FILE_NAME}"

# Get a list of all alignment files.
readarray -t -d $'\0' ALIGN_FILES < <(find -L "${ALIGN_DIR}" -maxdepth 1 -type f -name "*\.${ALIGN_FILE_SUFFIX}" -print0)

# Count the number of gene reads.
featureCounts \
	$([ "${MULTI_MAPPING}" -eq 1 ] && echo "-M" || :) \
	-a "${ANNOT_FILE}" \
	-F "GTF" \
	-t "${GTF_FEATURE_TYPE}" \
	-g "${GTF_ATTR_TYPE}" \
	-s 0 \
	-T "${THREAD_NUMBER}" \
	-o "${OUTPUT_FILE}" \
	"${ALIGN_FILES[@]}"

exit $?
