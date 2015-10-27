#!/bin/bash
set -e
set -u
set -o pipefail

################################################################################
# callerSquad: an intelligent ensembl somatic mutation caller from WGS
# Author: Xiaotong Yao
# PI: Charles Danko
# Contact: xy293@cornell.edu
################################################################################
# Util: return full file path
fullPath () {
    echo "$(cd $(dirname $1); pwd)/$(basename $1)"
}

# source code directory
srcDir=$(cd $(dirname $0); pwd)


# global usage
usage () {
echo "
Program: callerSquad
Version: 0.1.0
Author: Xiaotong Yao (xy293@cornell.edu)

usage: callerSquad tumor.bam normal.bam

positional args:
    tumor.bam	path to bam file of tumor sample sequence read alignments,
		with index (.bam.bai) in the same dir
    normal.bam	path to bam file of normal sample sequence read alignments,
		with index (.bam.bai) in the same dir

options:
    -o, --outBasename
	All results will be saved to currentRunningDir/outBasename/. (default: 'defaultRun')

    -R, --reference
	FASTA-format reference genome with BW index in same directory. (required)

    -B, --regionBed
	BED file of target genomic regions for calling, 0-based start position 
	and 1-based end position. (required)

    -t, --numberOfthreads
	Maximum number of threads to use for each caller program. (default 1)

    --help, -h
	Print this message.

Documentations of callerSquad can be found at:
    https://github.com/Danko-Lab/callerSquad
"
}

# source the paths to the binaries used in the script
checkDependencies () {

    echo "Auto-source dependencies ..."
    SAMTOOLS=$(which samtools || true)
    BCFTOOLS=$(which bcftools || true)
    BGZIP=$(which bgzip || true)
    TABIX=$(which tabix || true)
    PYTHON=$(which python || true)
    JAVA=$(which java || true)
    if [[ -e ${srcDir}/callerSquad.config ]]
    then
	echo "Sourcing executables from .config ..."
	source ${srcDir}/callerSquad.config
    fi

    case "" in
	"$SAMTOOLS")
	    echo "ERROR: samtools not found."
	    exit 1
	    ;;
	"$BCFTOOLS")
	    echo "ERROR: bcftools not found."
	    exit 1
	    ;;
	"$BGZIP")
	    echo "ERROR: bgzip not found."
	    exit 1
	    ;;
	"$TABIX")
	    echo "ERROR: tabix not found."
	    exit 1
	    ;;
	"$PYTHON")
	    echo "ERROR: python not found."
	    exit 1
	    ;;
	"$JAVA")
	    echo "ERROR: java not found."
	    exit 1
	    ;;
	"")
	    echo "Dependencies checked."
    esac
}
checkDependencies


# options, default
export runName="defaultRun"
export refGen="/shared_data/genome_db/Homo_sapiens/Ensembl/GRCh37/Sequence/WholeGenomeFasta/genome.fa"
regionInterval="19:1-59128983"
regionBed=${srcDir}/chr19.bed
export nt=1
# show help msg if no arg given
if test "$#" -lt 1
then
    usage
    exit 0
fi
# optional args
while [[ $1 == -* ]]
do
    case "$1" in
	--reference | -R)
	    if [[ $2 == -* ]]
	    then
		usage
		exit 1
	    else
		export refGen=$2
	    fi
	    shift; shift;
	    ;;
	--regionBed | -B)
	    if [[ $2 == -* ]]
	    then
		usage
		exit 1
	    else
		regionBed=$2
	    fi
	    shift; shift;
	    ;;
	--outBasename | -o)
	    if [[ $2 == -* ]]
	    then
		usage
		exit 1
	    else
		runName=$2
	    fi
	    shift; shift;
	    ;;
	--numberOfThreads | -t)
	    if [[ $2 -lt 1 ]]
	    then
		usage
		exit 1
	    else nt=$2
	    fi
	    shift; shift;
	    ;;
	--help | -h)
	    usage
	    exit 0
	    shift
	    ;;
    esac
done
# ensure sufficient positional args
if test -z "$2"
then
   echo "ERROR: two bam files required."
   usage
   exit 1
fi

# build running directory
resultDir=./${runName}_result
logFile=${runName}.log
# source bam files with index
export tumorBam=$(fullPath $1)
export normalBam=$(fullPath $2)
# disect given regionBed file to 1contig1bed
refGenDir=$(cd $(dirname $refGen); pwd)
refGenFai=${refGen}.fai
contigNames=($(awk '{print $1}' ${refGenFai}))
mkdir $resultDir; cd $resultDir; mkdir tmpRegion
# for each contig involved in the bed, create an intervals
for contig in ${contigNames[@]}; do
    echo 'making contig bed '$contig
    awk '$1=='$contig $regionBed > tmpRegion/${contig}.bed
    if [ -s tmpRegion/${contig}.bed ]
    then
	java -jar $PICARD BedToIntervalList INPUT=tmpRegion/${contig}.bed \
	SD=$(echo $refGen | sed 's/.fa/.dict/') OUTPUT=tmpRegion/${contig}.intervals
    else
	rm tmpRegion/${contig}.bed
    fi
done


# run mutect, varscan, speedseq
echo "$(date): all set, start calling" >> $logFile
#source ${srcDir}/_mutect.sh &
#source ${srcDir}/_varscan.sh &
#source ${srcDir}/_speedseq.sh &

# pass intervals files to mutect --intervals option
find tmpRegion/ -name '*.intervals' | xargs -n 1 -P $nt -I {} ${srcDir}/_mutect.sh {} &
find tmpRegion/ -name '*.bed' | xargs -n 1 -P $nt -I {} ${srcDir}/_varscan.sh {} &
find tmpRegion/ -name '*.bed' | xargs -n 1 -P $nt -I {} ${srcDir}/_speedseq.sh {} &
wait
#xargs --arg-file=${srcDir}/_callers --max-procs=3 --replace /bin/bash -c "{}"
echo "$(date): calling done" >> $logFile

# concat all results
find . -name '*.mutect.PASS.vcf.gz' | xargs \
bcftools concat -O z -o ${runName}.mutect.final.vcf.gz
find . -name '*.varscan.snp.Somatic.hc.vcf.gz' | xargs \
bcftools concat -O z -o ${runName}.varscan.final.vcf.gz
find . -name '*.speedseq.snp.PASS.vcf.gz' | xargs \
bcftools concat -O z -o ${runName}.speedseq.final.vcf.gz
echo "$(date): concatenation done" >> $logFile

# Given output vcf files from different callers on the same data, create a
# directory containing majority voted result
bcftools isec -p ${runName} -n+2 \
${runName}.mutect.final.vcf.gz \
${runName}.varscan.final.vcf.gz \
${runName}.speedseq.final.vcf.gz
# transform the sites.txt result into BED and raw VCF
python sites2bed.py ${runName}/sites.txt
mv ${runName}/sites.bed ${runName}/${runName}.bed
# bedops bed2vcf ${runName}.bed ${runName}.vcf
