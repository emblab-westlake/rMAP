#!/bin/bash
##########################################################################
# Author: zhangguoqing
# Email: emblab@westlake.edu.cn
# Lab: EMBLab Westlake University
# Date:2019-9-7
# Version: 1.0
# Update:2019-9-10
#
# Function: Use Bowtie2 to mapping reads to hg19

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
    Desc: The shell script USES Bowtie2 to mapping reads to hg19
          Relative paths are used internally within the script, please run this script under your PROJECT PATH. PS. Task thread = core*14

    Usage of (default TASK num): ./Step3-Multiqueue-Bowtie2.sh list.txt
    Usage of (Custom TASK num Parameters): ./Step3-Multiqueue-Bowtie2.sh -list list.txt -core 10
    
    list.txt is Samplenames list file; {--core} specifies the number of concurrent tasks. Task num is 5 (default), Bowtie2 have 14 thread default, So total thread is 60
    Email: emblab@westlake.edu.cn
    Lab: EMBLab westlake university
    License: GPL
EOF
    exit 0

}

samplelist=$1
Nproc=5 #max concurrent process num


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


cleandata="CleanData" #cleandata path
Bowtie="AlignedData" #Bowtie2 saved path
Njob=`cat ${samplelist} | wc -l` #task num


# creat sample directory
mkdir ${Bowtie}
for samplename in `cat ${samplelist}`;do
mkdir ${Bowtie}/${samplename}
done

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

echo "Bowtie2 start ----------- `date`" > Bowtie2-log.file
echo "Bowtie2 aligned Result have SAVED in --------- `pwd`/${Bowtie}" >> Bowtie2-log.file
for ((i=1; i<=$Njob; i++));do
dirname=`awk "NR==${i}" ${samplelist}`
#echo "Progress $i is sleeping for 3 seconds..." #Mission Content
# test command
#echo ${dirname} >> list.test.txt && sleep 3 &
# bowtie mapping

bowtie2 -p 14 -x hg19 -1 ${cleandata}/${dirname}/${dirname}_1.fastq -2 ${cleandata}/${dirname}/${dirname}_2.fastq \
--reorder --no-contain --dovetail -S ${Bowtie}/${dirname}/${dirname}_map2hg19.sam & 

PID=$!
PushQue $PID
# If Nrun is greater than Nproc, keep ChkQue
while [[ $Nrun -ge $Nproc ]];do
ChkQue
sleep 0.1
done
done
wait

echo "Bowtie2 down ----------- `date`" >> Bowtie2-log.file
echo -e "time-consuming: $SECONDS seconds" >> Bowtie2-log.file #Print the execution time of the script

