#!/bin/bash
set -e
set -u
set -o pipefail

normalPileup="samtools mpileup -q 1 -l $regionBed -f $refGen $normalBam"
tumorPileup="samtools mpileup -q 1 -l $regionBed -f $refGen $tumorBam"
java -jar $VARSCAN somatic <(${normalPileup}) <(${tumorPileup}) \
${runName}.varscan --output-vcf 1 > ${runName}.varscan.log

# post processing
java -jar $VARSCAN processSomatic ${runName}.varscan.snp.vcf
bgzip ${runName}.varscan.snp.Somatic.hc.vcf
bcftools index -t ${rnName}.varscan.snp.Somatic.hc.vcf.gz
