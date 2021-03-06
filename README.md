# Feature Counts

This step of analysis uses the *featureCounts* program from the *Subread* software to assign all the sequence reads uniquely aligned by the *STAR* aligner in the [Sequence Alignment](https://github.com/DToxS/Sequence-Alignment) analysis to their corresponding reference genes for each sequenced sample.

**Note:** the `[Type]` tag included in the file and directory names below refers to either `Conv` for conventional sequence data or `DGE` for 3'-DGE sequence data.

## Inputs

The inputs of this analysis include:

- A set of sequence alignment data files (`*.bam`) in the `Aligns` sub-directory of each dataset directory under the `[Type]-GEO-Depot` top directory.
- The annotation file of UCSC human genome reference library `RefSeq.hg38.gtf` in the `References` directory under the `[Type]-GEO-Depot` top directory.

## Procedure

The procedure of this analysis includes the following steps:

1. Set the variable `DATASET_DIR` in `Programs/Feature-Counts/Count-[Type]-RNAseq-Reads.GEO.sh` to the absolute path of the `[Type]-GEO-Depot` top directory, and launch the program to count the number of uniquely aligned sequence reads mapped to each reference gene.

2. Set the variable `dataset_dir` in the *R* program `Convert-[Type]-RNAseq-Reads.GEO.R` to the absolute path of the `[Type]-GEO-Depot` top directory, and launch the program with the command `Rscript Programs/Feature-Counts/Convert-[Type]-RNAseq-Reads.GEO.R` to convert the gene read-counts table generated by the *featureCounts* program to the format of the input data file used by the [Differential Comparison](https://github.com/DToxS/Differential-Comparison) analysis.


## Outputs

The outputs of this analysis include:

- A single table `Conv-RNAseq-Read-Counts.tsv` in the `Counts` directory under or multiple tables `DGE-RNAseq-Read-Counts-[Set]-[Subset].tsv` in the `Counts` sub-directory of each `[Set]` of dataset directory, under the corresponding `[Type]-GEO-Depot` top directory, which contain the uniquely aligned sequence reads for all reference genes and all sequenced samples.

  **Note:** the `[Set]` and `[Subset]` tags refer to [Analyzing 3'-DGE Random-Primed mRNA-Sequencing Data](https://github.com/DToxS/DGE-GEO-Depot) and they only apply to `DGE` type of sequence data where multiple `[Set]` of datasets are available.
