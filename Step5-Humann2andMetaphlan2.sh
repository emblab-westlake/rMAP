#!/bin/bash
##########################################################################
# Author: zhangguoqing
# Email: emblab@westlake.edu.cn
# Lab: EMBLab Westlake University
# Date:2019-9-7
# Version: 1.0
# Update:2019-9-17
#
# Function: Use Humann2 and Metaphlan2 to Annotating to species

# Copyright (C) 2019  EMBLab Westlake University
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
##########################################################################

#set -o nounset
help()
{
    cat <<- EOF
    Description: 
    The shell script uses Humann2 & Metaphlan2 to annotating to functions and species.
    Relative paths are used internally within the script, please run this script 
    under your PROJECT PATH.
    
    Usage:
    ./Step5-Humann2andMetaphlan2.sh -list list.txt -core 10
    
    Parameters:
    -h --help   Help information.
    -list       <list.txt>  Samplenames list file; 
    -core       specifies the number of concurrent tasks. 
                default 60, total thread is 60
    
    Email:      emblab@westlake.edu.cn
    Lab:        EMBLab westlake university
    License:    GPL
EOF
    exit 0

}

samplelist=$1
Nproc=60 #task num

while [ -n "$1" ]; do
    case $1 in
        -h) help;; # function help is called
        --help) help;; # function help is called
        --) shift;break;; # end of options
        -list) samplelist=$2;break;; #list.txt file
        -core) Nproc=$2;break;; #task
esac
done

while [ -n "$3" ]; do
    case $3 in
        -core) Nproc=$4;break;; #task
        -list) samplelist=$4;break;; #list.txt file
esac
done



Alignedpath="AlignedData" 

obojectpath="Humann2Result"
mkdir ${obojectpath}


echo "Metaphlan2 start ----------- `date`" > Metaphlan2-log.file

source $HOME/miniconda3/bin/activate metaphlan2
for samplename in `cat ${samplelist}`;do

humann2 --input ${Alignedpath}/${samplename}/${samplename}_merged.fastq --output ${obojectpath}/${samplename} \
--bowtie2 $HOME/miniconda3/envs/metaphlan2/bin --diamond $HOME/miniconda3/bin --threads ${Nproc}

# 添加具体名称
humann2_rename_table --input ${obojectpath}/${samplename}/${samplename}_genefamilies.tsv \
--output ${obojectpath}/${samplename}/${samplename}_genefamilies-names.tsv --names uniref90
humann2_renorm_table --input ${obojectpath}/${samplename}/${samplename}_genefamilies.tsv \
--output ${obojectpath}/${samplename}/${samplename}_genefamilies-cpm.tsv --units cpm --update-snames

echo "${samplename} has been classed ------------------------ `date`" >> Metaphlan2-log.file
done
echo "All samples have been classed ------------------------ `date`" >> Metaphlan2-log.file
source $HOME/miniconda3/bin/deactivate