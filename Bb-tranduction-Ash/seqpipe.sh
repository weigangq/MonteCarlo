#!/bin/bash
set -euo pipefail

#A pipeline to align fastq sequences to a reference fasta genome
#This is for nanopore long reads and uses the b. burgdorferi genome along with raw sequence data found
#from this paper: Faith DR, Kinnersley M, Brooks DM, Drecktrah D, Hall LS, Luo E, et al. (2024) 
#Characterization and genomic analysis of the Lyme disease spirochete bacteriophage phiBB-1. 
#PLoS Pathog 20(4): e1012122. https://doi.org/10.1371/journal.ppat.1012122 

#Download fastq sequence files and fasta genome based on what the methods state.

#Required tools:
#   - conda environment with minimap2, samtools, and filtlong.
#conda activate bio_env
#conda install -c bioconda minimap2
#conda install -c bioconda samtools
#conda install -c bioconda filtlong

#Ensure directory is correct

conda activate bio_env

#Unzip files to acquire fastq. Three replicates.

gunzip SRR27421011.fastq.gz 
gunzip SRR27421012.fastq.gz 
gunzip SRR27421013.fastq.gz

#setup conda env

conda activate bio_env

#Nanopore long reads were said to be sorted by quality score greater/equal to 7 and length greater/equal to 5000. 
#Repeated for all three replicates
# -q quality score, -l read length

filtlong -q 7 -l 5000 SRR27421011.fastq > SRR27421011_filtered.fastq
filtlong -q 7 -l 5000 SRR27421012.fastq > SRR27421012_filtered.fastq
filtlong -q 7 -l 5000 SRR27421013.fastq > SRR27421013_filtered.fastq

#Align filtered fastq to reference genome listed in paper and created a SAM file.

minimap2 -ax map-ont borrelia.fna SRR27421011_filtered.fastq > aln1.sam
minimap2 -ax map-ont borrelia.fna SRR27421012_filtered.fastq > aln2.sam
minimap2 -ax map-ont borrelia.fna SRR27421013_filtered.fastq > aln3.sam

#Convert to bam file

samtools view -bS aln1.sam > aln1.bam
samtools view -bS aln2.sam > aln2.bam
samtools view -bS aln3.sam > aln3.bam

#Sort bam file
#-o file output

samtools sort aln1.bam -o aln1.sorted.bam
samtools sort aln2.bam -o aln2.sorted.bam
samtools sort aln3.bam -o aln3.sorted.bam

#Filter bam file by MAPQ > 20 and primary mapping
#-b refers to a bam output, -q 21 approximates MAPQ > 20
#-F 0x900 filters out both secondary and supplementary mapping, leaving only primary mapping

samtools view -b -q 21 -F 0x900 aln1.sorted.bam > aln1.filtered.bam
samtools view -b -q 21 -F 0x900 aln2.sorted.bam > aln2.filtered.bam
samtools view -b -q 21 -F 0x900 aln3.sorted.bam > aln3.filtered.bam

#index filtered bam file

samtools index aln1.filtered.bam
samtools index aln2.filtered.bam
samtools index aln3.filtered.bam 

#Convert to tsv

samtools idxstats aln1.filtered.bam  > aln1_filtered_idxstats.tsv
samtools idxstats aln2.filtered.bam  > aln2_filtered_idxstats.tsv
samtools idxstats aln3.filtered.bam  > aln3_filtered_idxstats.tsv
samtools coverage aln1.filtered.bam > aln1_filtered_coverage.tsv
samtools coverage aln2.filtered.bam > aln2_filtered_coverage.tsv
samtools coverage aln3.filtered.bam > aln3_filtered_coverage.tsv

# Files do not have plasmid and Chromosome names listed, acquired and extracted from reference genome
# grep "^>" means starts with > 
# extracts ">NC_012157.1 Borreliella burgdorferi CA-11.2A plasmid CA-11.2A_cp26, complete sequence"
#cut to extract reference number and replicon name
#seds remove > at beginning (^), , at end($), and the CA-11.2A_ and replaces it with nothing.
#spacing changed to tabs for tsv

grep "^>" borrelia.fna > reference_headers.txt
cut -d " " -f 1,6 reference_headers.txt | sed "s/^>//"|sed "s/,$//"|sed "s/CA-11.2A_//" > reference_lookup.tsv
sed "s/ /\t/" reference_lookup.tsv > reference_lookup_tabs.tsv

#For Figure 5D, raw reads are required to create violin plots
#echo commands prints out column titles separated by tabs for a tsv
#awk command prints out 1st, 3rd, and 10th variable and adds them to the tsv.

echo -e "ReadID\tReference\tReadLength" > aln1_read_lengths.tsv
samtools view aln1.filtered.bam| awk 'BEGIN{OFS="\t"} {print $1, $3, length($10)}'>> aln1_read_lengths.tsv 
echo -e "ReadID\tReference\tReadLength" > aln2_read_lengths.tsv
samtools view aln2.filtered.bam| awk 'BEGIN{OFS="\t"} {print $1, $3, length($10)}'>> aln2_read_lengths.tsv
echo -e "ReadID\tReference\tReadLength" > aln3_read_lengths.tsv
samtools view aln3.filtered.bam| awk 'BEGIN{OFS="\t"} {print $1, $3, length($10)}'>> aln3_read_lengths.tsv

#This completes the Unix commands that can be done under a shell. Because this pipeline is extremely specific to
#this project, the variables are left in as a reference.
#Please see R Markdown for further workup of the tsv's into Figures 5B, 5C, and 5D.