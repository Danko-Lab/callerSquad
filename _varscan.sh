#!/bin/bash
set -e
set -u
set -o pipefail

normalPileup="samtools mpileup -q 1 -r $regionInterval -f $refGen $normalBam"
tumorPileup="samtools mpileup -q 1 -r $regionInterval -f $refGen $tumorBam"
#samtools mpileup -q 1 -r $regionInterval -f $refGen \
#-o tmpNormal.pileup $normalBam &
#samtools mpileup -q 1 -r $regionInterval -f $refGen \
#-o tmpTumor.pileup $tumorBam &
#java -jar $VARSCAN somatic tmpNormal.pileup tmpTumor.pileup ${runName}.varscan \
#--output-vcf 1 > ${runName}.varscan.log
java -jar $VARSCAN somatic <(${normalPileup}) <(${tumorPileup}) \
${runName}.varscan --output-vcf 1 2> ${runName}.varscan.log

# post processing
java -jar $VARSCAN processSomatic ${runName}.varscan.snp.vcf
bgzip ${runName}.varscan.snp.Somatic.hc.vcf
bcftools index -t ${rnName}.varscan.snp.Somatic.hc.vcf.gz
