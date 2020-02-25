#!/usr/bin/env bash
# This script aligns conventional mRNA sequence files.

# Set top directory.
DATASET_DIR="${HOME}/LINCSData/Datasets/Difference/LINCS.Dataset/Coen-Paper/Conv-GEO-Depot"

# Set executable program and its input arguments.
PROG_DIR_PATH="${DATASET_DIR}/Programs/Feature-Counts"
PROG_FILE_NAME="Count-RNAseq-Reads.GEO.sh"
PROG_FILE_PATH="${PROG_DIR_PATH}/${PROG_FILE_NAME}"

# Set input directories and files.
ALIGN_DIR="${DATASET_DIR}/Aligns"
COUNTS_DIR="${DATASET_DIR}/Counts"
REF_DIR="${DATASET_DIR}/References/UCSC/hg38"
ANNOT_DIR="${REF_DIR}/Annotation"
ANNOT_FILE="${ANNOT_DIR}/RefSeq.hg38.gtf"

# Set input arguments.
COUNTS_FILE_MAIN_NAME="Conv-RNAseq-Read-Counts"
SEQ_METHOD="conv"
ALIGN_FILE_SUFFIX="bam"
THREAD_NUMBER="8"

# Run the program.
echo "${PROG_FILE_PATH} ${ALIGN_DIR} ${COUNTS_DIR} ${ANNOT_FILE} ${COUNTS_FILE_MAIN_NAME} ${SEQ_METHOD} ${ALIGN_FILE_SUFFIX} ${THREAD_NUMBER}"
"${PROG_FILE_PATH}" ${ALIGN_DIR} ${COUNTS_DIR} ${ANNOT_FILE} "${COUNTS_FILE_MAIN_NAME}" "${SEQ_METHOD}" "${ALIGN_FILE_SUFFIX}" "${THREAD_NUMBER}"

# Exit with error code.
exit $?
