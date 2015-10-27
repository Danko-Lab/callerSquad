#!/bin/bash
set -e
set -u
set -o pipefail

# NOTE: $runName, $MUTECT, $refGen, $tumorBam, $normalBam
# receive interval file from first commandline arg
regionInterval=$1
contig=$(echo $(basename $1) | sed 's/.intervals//')
echo 'calling mutect on contig '$contig
# call mutect
java -Xmx2g -jar $MUTECT --analysis_type MuTect \
--reference_sequence $refGen \
--intervals $regionInterval \
--input_file:tumor $tumorBam \
--input_file:normal $normalBam \
--vcf ${runName}.${contig}.mutect.vcf \
>> ${runName}.mutect.log

# post processing
bcftools view -i '%FILTER="PASS"' ${runName}.${contig}.mutect.vcf \
> ${runName}.${contig}.mutect.PASS.vcf
bgzip ${runName}.${contig}.mutect.PASS.vcf
bcftools index -t ${runName}.${contig}.mutect.PASS.vcf.gz
