#!/bin/bash
##########################################################################
# Author: zhangguoqing
# Email: emblab@westlake.edu.cn
# Lab: EMBLab Westlake University
# Date:2019-9-7
# Version: 1.0
# Update:2019-9-10
#
# Function: Quality control by Prinseq

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
    Desc: The shell script USES prinseq to filter low quality reads
          Relative paths are used internally within the script, please run this script under your PROJECT PATH.

    Usage: ./Step2-Multiqueue-Prinseq.sh list.txt
    
    list.txt is Samplenames list file; {--core} specifies the number of concurrent tasks. Task num is 56(default), you can modify script by VI/VIM
    Email: emblab@westlake.edu.cn
    Lab: EMBLab westlake university
    License: GPL
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

# path information（Modify as needed）
decompressed="Decompress" #DecomprerssFiles path,
cleanpath="CleanData" #cleandata saved path
Njob=`cat ${samplelist} | wc -l` #task num


# creat sample directory
mkdir ${cleanpath}
for samplename in `cat ${samplelist}`;do
mkdir ${cleanpath}/${samplename}
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

echo "Prinseq start ----------- `date`" > Prinseq-log.file
echo "Clean Data have SAVED in --------- `pwd`/${cleanpath}" >> Prinseq-log.file

for ((i=1; i<=$Njob; i++));do
dirname=`awk "NR==${i}" ${samplelist}`

#echo "Progress $i is sleeping for 3 seconds..." #Mission Content
# test command
#echo ${dirname} >> list.test.txt && sleep 3 &

# Quality control task
prinseq-lite.pl -fastq ${decompressed}/${dirname}/${dirname}_1.fastq \
-fastq2 ${decompressed}/${dirname}/${dirname}_2.fastq -out_good ${cleanpath}/${dirname}/${dirname} \
-out_bad null -log -min_len 60 -min_qual_mean 30 -ns_max_n 0 -trim_qual_right 20 -trim_qual_left 20 -derep 1 & 

PID=$!
PushQue $PID
# If Nrun is greater than Nproc, keep ChkQue
while [[ $Nrun -ge $Nproc ]];do
ChkQue
sleep 0.1
done
done
wait

for samplename in `cat ${samplelist}`;do
echo -e "`du -sh ${cleanpath}/${samplename}/${samplename}_1.fastq`/tfilesize" >> Prinseq-log.file
echo -e "`du -sh ${cleanpath}/${samplename}/${samplename}_2.fastq`/tfilesize" >> Prinseq-log.file
fq1=`du -sh ${cleanpath}/${samplename}/${samplename}_1.fastq | awk '{print $1}' | sed 's/G//;s/M//'`
fq2=`du -sh ${cleanpath}/${samplename}/${samplename}_2.fastq | awk '{print $1}' | sed 's/G//;s/M//'`
if [ $fq1 -ne $fq2 ];then
echo "Warning!!! ${samplename}_1.fastq ${samplename}_2.fastq not of the same magnitude" >> Prinseq-log.file
fi
rm ${cleanpath}/${samplename}/${samplename}_1_singletons.fastq
rm ${cleanpath}/${samplename}/${samplename}_2_singletons.fastq
done
echo "Prinseq down ----------- `date`" >> Prinseq-log.file
echo -e "time-consuming: $SECONDS seconds" >> Prinseq-log.file #Print the execution time of the script