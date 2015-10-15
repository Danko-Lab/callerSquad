#!/bin/bash
set -e
set -u
set -o pipefail

$SPEEDSEQ somatic \
-o $runName.speedseq \
-w $regionBed \
-t $ntSpeedseq \
-v \
$refGen $normalBam $tumorBam #> ${runName}.speedseq.log
# post processing
bcftools view -i 'TYPE="snp" & %FILTER="PASS" & STRLEN(ALT)=1' ${runName}.speedseq.vcf.gz > ${runName}.speedseq.snp.PASS.vcf
bgzip ${runName}.speedseq.snp.PASS.vcf
bcftools index -t ${runName}.speedseq.snp.PASS.vcf.gz
