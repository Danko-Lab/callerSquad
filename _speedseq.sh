#!/bin/bash
set -e
set -u
set -o pipefail

# receive bed file from commandline arg
regionBed=$1
contig=$(echo $(basename $1) | sed 's/.bed//')

$SPEEDSEQ somatic \
-o ${runName}.${contig}.speedseq \
-w $regionBed \
-v \
$refGen $normalBam $tumorBam

# post processing
bcftools view -i 'TYPE="snp" & %FILTER="PASS" & STRLEN(ALT)=1' \
${runName}.${contig}.speedseq.vcf.gz > ${runName}.${contig}.speedseq.snp.PASS.vcf
bgzip ${runName}.${contig}.speedseq.snp.PASS.vcf
bcftools index -t ${runName}.${contig}.speedseq.snp.PASS.vcf.gz
