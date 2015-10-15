# callerSquad
Group voting based ensembl somatic mutation caller.

![callerSquad workflow](etc/callerSquadWorkflow.png)

## Table of Contents
1. [Installation](#installation)
2. [Before running](#preparation)
3. [Running callerSquadd](#usage)
4. [Examples](#examples)

## Installation
	```
	git clone --recursive https://github.com/Danko-Lab/callerSquad
	```
## Before running
#### Prerequisites
* samtools suite, including samtools, bcftools, and all of their dependencies (http://www.htslib.org/)
* Java 6 or up
* Python 2.7 (https://www.python.org/)
	* numpy
	* pysam 0.8.0+
	* scipy
* successfully deployed MuTect
* successfully deployed Varscan (http://sourceforge.net/projects/varscan/files/VarScan.v2.3.9.jar/download)
* successfully installed speedseq somatic functionality, no need for whole software (https://github.com/hall-lab/speedseq)

#### Tumor and normal BAM files
These bam files should be whole/targeted genome sequencing of tumor/normal samples from the same patient aligned to the same reference genome, e.g. TCGA WGS.

#### Reference genome
IMPORTANT: in the BAM header lines tagged @, 

## Running callerSquad

## Examples
