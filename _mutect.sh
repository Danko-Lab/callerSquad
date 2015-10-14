#!/bin/bash
set -e
set -u
set -o pipefail

java -Xmx2g -jar $MUTECT --analysis_type MuTect \
--reference_sequence $refGen \
--intervals $regionInterval \
--num_threads $ntMuTect \
--input_file:tumor $tumorBam \
--input_file:normal $normalBam \
--vcf ${runName}.mutect.vcf \
2> ${runName}.mutect.log
# post processing
bcftools view -i '%FILTER="PASS"' ${runName}.mutect.vcf > ${runName}.mutect.PASS.vcf
bgzip ${runName}.mutect.PASS.vcf
bcftools index -t ${runName}.mutect.PASS.vcf.gz
