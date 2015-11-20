#!/bin/bash
set -e
set -u
set -o pipefail

# NOTE: $runName, $MUTECT, $refGen, $tumorBam, $normalBam
# receive interval file from first commandline arg
regionInterval=$1
contig=$(echo $(basename $1) | sed 's/.intervals//')
echo 'calling mutect on contig '$contig >> $logFile

# call mutect
java -Xmx2g -jar $MUTECT --analysis_type MuTect \
--reference_sequence $refGen \
--intervals $regionInterval \
--input_file:tumor $tumorBam \
--input_file:normal $normalBam \
--enable_qscore_output \
--enable_extended_output \
--log_to_file ${runName}.${contig}.mutect.log \
--vcf ${runName}.${contig}.mutect.vcf \
--out ${runName}.${contig}.mutect.callStats.txt \
--coverage_file ${runName}.${contig}.wig 

# post processing
bcftools view -i '%FILTER="PASS"' ${runName}.${contig}.mutect.vcf \
> ${runName}.${contig}.mutect.PASS.vcf
bgzip ${runName}.${contig}.mutect.PASS.vcf
bcftools index -t ${runName}.${contig}.mutect.PASS.vcf.gz
