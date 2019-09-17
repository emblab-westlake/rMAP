#!/bin/bash
##########################################################################
# Author: zhangguoqing
# Email: emblab@westlake.edu.cn
# Lab: EMBLab Westlake University
# Date:2019-9-7
# Version: 1.0
# Update:2019-9-10
#
# Function: Use bedtools to converting BAM to fastq

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
    Desc: The shell script USES bedtools to converting BAM to fastq
          Relative paths are used internally within the script, please run this script under your PROJECT PATH.

    Usage of (default TASK num): ./Step4-2-BAM2Fastq.sh list.txt
    Usage of (Custom TASK num Parameters): ./Step4-2-BAM2Fastq.sh -list list.txt -core 10
    
    list.txt is Samplenames list file; {--core} specifies the number of concurrent tasks. Task num is 56(default), total thread is 56
    Email: emblab@westlake.edu.cn
    Lab: EMBLab westlake university
    License: GPL
EOF
    exit 0

}

samplelist=$1
Nproc=56 #max concurrent process numm


while [ -n "$1" ]; do
    case $1 in
        -h) help;; # function help is called
        --help) help;; # function help is called
        --) shift;break;; # end of options
        -list) samplelist=$2;break;; #list.txt file
esac
done

while [ -n "$3" ]; do
    case $3 in
        -core) Nproc=$4;break;; #list.txt file
esac
done


Bowtie="AlignedData" #Bowtie RESULT saved path, bam files will be created in there too.
Njob=`cat ${samplelist} | wc -l` #task num



#ADD the PID to the queue
function PushQue {
Que="$Que $1"
Nrun=$(($Nrun+1))
}
#Update the queue information，first clear the queue information
#And then retrieve and generate new queue information
function GenQue {
OldQue=$Que
Que="";Nrun=0
for PID in $OldQue;do
if [[ -d /proc/$PID ]];then
PushQue $PID
fi
done
}

#Check queue information，If there is a PID for a process that has ended, update the queue information
function ChkQue {
OldQue=$Que
for PID in $OldQue;do
if [[ ! -d /proc/$PID ]];then
GenQue;break
fi
done
}

echo "========== Step 4.2 BAM to Fastq Start ==========`date`" >> Remove-host-log.file
# BAM to Fastq
for ((i=1; i<=$Njob; i++));do
dirname=`awk "NR==${i}" ${samplelist}`
bamToFastq -i ${Bowtie}/${dirname}/${dirname}_Unmapped_sorted.bam -fq ${Bowtie}/${dirname}/${dirname}_filtered1.fastq \
-fq2 ${Bowtie}/${dirname}/${dirname}_filtered2.fastq &

PID=$!
PushQue $PID
# If Nrun is greater than Nproc, keep ChkQue
while [[ $Nrun -ge $Nproc ]];do
ChkQue
sleep 0.1
done
done
wait

# remove SAM Files
for ((i=1; i<=$Njob; i++));do
dirname=`awk "NR==${i}" ${samplelist}`
rm ${Bowtie}/${dirname}/${dirname}_map2hg19.sam &

PID=$!
PushQue $PID
# If Nrun is greater than Nproc, keep ChkQue
while [[ $Nrun -ge $Nproc ]];do
ChkQue
sleep 0.1
done
done
wait
echo "==========SAM files have been removed==========`date`" >> Remove-host-log.file

# Remove BAM Files
for samplename in `cat ${samplelist}`;do
rm ${Bowtie}/${samplename}/${samplename}_map2hg19.bam
rm ${Bowtie}/${samplename}/${samplename}_Unmapped.bam
done
echo "==========BAM files have been removed==========`date`" >> Remove-host-log.file

#merge FASTQ files
for samplename in `cat ${samplelist}`;do
cat ${Bowtie}/${dirname}/${dirname}_filtered1.fastq ${Bowtie}/${dirname}/${dirname}_filtered2.fastq > ${Bowtie}/${dirname}/${dirname}_merged.fastq
done
echo "========== Step 4.2 BAM to Fastq Down ==========`date`" >> Remove-host-log.file