#!/usr/bin/env bash
# Run SAM-Alignment-Counter program in Unix-alike environment.

# OS type: Darwin for Mac and Linux for Linux, from command "uname -s".
OS_TYPE="$(uname -s)"
# Compiler type: gcc or clang.
COMPILER_TYPE="gcc"
# Set the suffix name of program file using compiler type and OS type.
PROG_NAME_SUFFIX=".${COMPILER_TYPE}.${OS_TYPE}"

# Counter program.
COUNTER_PROG_NAME="SAM-Alignment-Counter${PROG_NAME_SUFFIX}"
COUNTER_PROG_DIR="${HOME}/LINCSData/bin"
COUNTER_PROG_PATH="${COUNTER_PROG_DIR}/${COUNTER_PROG_NAME}"

# Top data directory.
DATA_NAME="mRNA-Seq-Dataset-Samples"
TOP_DATA_DIR="${HOME}/LINCSData/Datasets/Alignment/LINCS.Dataset/${DATA_NAME}"

# Name of main SAM/BAM file.
SAM_FILE_NAME="Test.1000000.sam"
SAM_FILE_MAIN_NAME="${SAM_FILE_NAME%.*}"

# Version of UCSC human genome: hg19 or hg38.
UCSC_HG_VER="hg38"

# Input SAM file.
INPUT_SAM_FILE_DIR="${TOP_DATA_DIR}/Counts/${UCSC_HG_VER}"
INPUT_SAM_FILE_NAME="${SAM_FILE_NAME}.featureCounts.sam"
INPUT_SAM_FILE_PATH="${INPUT_SAM_FILE_DIR}/${INPUT_SAM_FILE_NAME}"

# Output SAM file.
OUTPUT_SAM_FILE_DIR="${TOP_DATA_DIR}/Aligns/${UCSC_HG_VER}"
OUTPUT_SAM_FILE_NAME="${SAM_FILE_MAIN_NAME}.Unique.sam"
OUTPUT_SAM_FILE_PATH="${OUTPUT_SAM_FILE_DIR}/${OUTPUT_SAM_FILE_NAME}"

# Launch counter program.
echo "Counting the unique aligned and tagged alignments in" "${INPUT_SAM_FILE_PATH}..."
"${COUNTER_PROG_PATH}" "${INPUT_SAM_FILE_PATH}" "${OUTPUT_SAM_FILE_PATH}"

exit 0
