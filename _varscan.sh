#!/bin/bash
set -e
set -u
set -o pipefail

# receive bed file from commandline arg
regionBed=$1
contig=$(echo $(basename $1) | sed 's/.bed//')

normalPileup="samtools mpileup -q 1 -l $regionBed -r $contig -f $refGen $normalBam"
tumorPileup="samtools mpileup -q 1 -l $regionBed -r $contig -f $refGen $tumorBam"
java -jar $VARSCAN somatic <(${normalPileup}) <(${tumorPileup}) \
${runName}.${contig}.varscan --output-vcf 1 > ${runName}.varscan.log

# post processing
java -jar $VARSCAN processSomatic ${runName}.${contig}.varscan.snp.vcf
bgzip ${runName}.${contig}.varscan.snp.Somatic.hc.vcf
bcftools index -t ${runName}.${contig}.varscan.snp.Somatic.hc.vcf.gz
