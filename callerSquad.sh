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
		with index in the same dir
    normal.bam	path to bam file of normal sample sequence read alignments,
		with index in the same dir

options:
    -o, --outBasename
    -R, --reference
		FASTA-format reference genome with BW index in same directory
    -L, --interval
		GATK interval format of target genomic region
    
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
runName="defaultRun"
refGen="/shared_data/genome_db/Homo_sapiens/Ensembl/GRCh37/Sequence/WholeGenomeFasta/genome.fa"
ntMuTect=1
ntSpeedseq=1
regionInterval="19:1-59128983"
regionBed=${srcDir}/chr19.bed
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
		refGen=$2
	    fi
	    shift; shift;
	    ;;
	--interval | -L)
	    if [[ $2 == -* ]]
	    then
		usage
		exit 1
	    else
		regionInterval=$2
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
	--ntMuTect)
	    if [[ $2 -lt 1 ]]
	    then
		usage
		exit 1
	    else ntMuTect=$2
	    fi
	    shift; shift;
	    ;;
	--ntSpeedseq)
	    if [[ $2 -lt 1 ]]
	    then
		usage
		exit 1
	    else ntSpeedseq=$2
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
# source tumor bam file with index
# precond:
tumorBam=$(fullPath $1)
#echo "$(date): tumor bam checked $tumorBam"
# precond:
# source normal bam file with index
normalBam=$(fullPath $2)
#echo "$(date): normal bam checked $normalBam"
mkdir $resultDir; cd $resultDir

# run mutect, varscan, speedseq
echo "$(date): all set, start calling" >> $logFile
source ${srcDir}/_mutect.sh &
source ${srcDir}/_varscan.sh &
source ${srcDir}/_speedseq.sh &
wait
#xargs --arg-file=${srcDir}/_callers --max-procs=3 --replace /bin/bash -c "{}"
echo "$(date): calling done" >> $logFile

# Given output vcf files from different callers on the same data, create a
# directory containing majority voted result

