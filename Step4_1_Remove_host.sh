#!/bin/bash
##########################################################################
# Author: zhangguoqing
# Email: emblab@westlake.edu.cn
# Lab: EMBLab Westlake University
# Date:2019-9-7
# Version: 1.0
# Update:2019-9-10
#
# Function: Use Samtools to remove host pollution from SAM files

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
    The shell script uses Samtools to remove host pollution from SAM files.
    Relative paths are used internally within the script, please run this script 
    under your PROJECT PATH.


    Usage:
    ./Step4-1-Remove-host.sh -list list.txt -core 10
    
    Parameters:
    -h --help   Help information.
    -list       <list.txt> is Samplenames list file; 
    -core       specifies the number of concurrent tasks.
                    defalult 56, total thread is 56

    Email:      emblab@westlake.edu.cn
    Lab:        EMBLab westlake university
    License:    GPL
EOF
    exit 0

}

samplelist=$1
Nproc=56 #max concurrent process num


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

echo "Remove host start ----------- `date`" > Remove-host-log.file
echo "Bowtie2 aligned Result have SAVED in --------- `pwd`/${Bowtie}" >> Remove-host-log.file
for ((i=1; i<=$Njob; i++));do
dirname=`awk "NR==${i}" ${samplelist}`

#echo "Progress $i is sleeping for 3 seconds..." #Mission Content
# test command
#echo ${dirname} >> list.test.txt && sleep 3 &
# SAM convert to BAM

samtools view -bS ${Bowtie}/${dirname}/${dirname}_map2hg19.sam > ${Bowtie}/${dirname}/${dirname}_map2hg19.bam &

PID=$!
PushQue $PID
# If Nrun is greater than Nproc, keep ChkQue
while [[ $Nrun -ge $Nproc ]];do
ChkQue
sleep 0.1
done
done
wait
echo "==========SAM format have been converted to BAM format==========`date`" >> Remove-host-log.file

for ((i=1; i<=$Njob; i++));do
dirname=`awk "NR==${i}" ${samplelist}`
samtools view -b -f 12 -F 256 ${Bowtie}/${dirname}/${dirname}_map2hg19.bam > ${Bowtie}/${dirname}/${dirname}_Unmapped.bam &

PID=$!
PushQue $PID
# If Nrun is greater than Nproc, keep ChkQue
while [[ $Nrun -ge $Nproc ]];do
ChkQue
sleep 0.1
done
done
wait

echo "==========BAM files have been removed host reads==========`date`" >> Remove-host-log.file

# Sorted by names
for ((i=1; i<=$Njob; i++));do
dirname=`awk "NR==${i}" ${samplelist}`
samtools sort -n ${Bowtie}/${dirname}/${dirname}_Unmapped.bam ${Bowtie}/${dirname}/${dirname}_Unmapped_sorted &

PID=$!
PushQue $PID
# If Nrun is greater than Nproc, keep ChkQue
while [[ $Nrun -ge $Nproc ]];do
ChkQue
sleep 0.1
done
done
wait
echo "==========BAM files have been sorted==========`date`" >> Remove-host-log.file

echo "Remove host down ----------- `date`" >> Remove-host-log.file
echo -e "time-consuming: $SECONDS seconds" >> Remove-host-log.file #Print the execution time of the script

