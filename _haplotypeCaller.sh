#!/bin/bash
set -e
set -u
set -o pipefail
 
# Exported: $runName, $GATK, $refGen, $tumorBam, $normalBam, $logFile
# receive interval file from first commandline arg
regionInterval=$1
contig=$(echo $(basename $1) | sed 's/.intervals//')
echo 'calling haplotypeCaller on contig '$contig >> $logFile
# call haplotypeCaller
java -Xmx2g -jar $GATK --analysis_type HaplotypeCaller \
--reference_sequence $refGen \
--intervals $regionInterval \
--input_file $normalBam \
--out ${runName}.${contig}.haplotypeCaller.vcf \
>> ${runName}.haplotypeCaller.log
