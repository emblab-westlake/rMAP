#!/bin/bash
##########################################################################
# Author: zhangguoqing
# Email: emblab@westlake.edu.cn
# Lab: EMBLab Westlake University
# Date:2019-9-7
# Version: 1.0
# Update:2019-9-10
#
# Function: pigz decompress FASTQ.GZ files to FASTQ files

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
    Desc: The shell script USES pigz to decompress the .gz files into .fastq files.
          Relative paths are used internally within the script, please run this script under your PROJECT PATH.

   Usage of (default TASK num): ./Step1-Multi-Decompress.sh list.txt
   Usage of (Custom TASK num Parameters): ./Step1-Multi-Decompress.sh -list list.txt -core 10
    
    list.txt is Samplenames list file; {--core} specifies the number of concurrent tasks. Task num is 55(default), total thread is 55
    Email: emblab@westlake.edu.cn
    Lab: EMBLab westlake university
    License: GPL
EOF
    exit 0

}


samplelist=$1
corenum=55 # core=55; YOU CAN MPDIFY IT by -core appoint
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
        -core) corenum=$4;break;; #list.txt file
esac
done


# Create object directory
objectpath='Decompress'


mkdir ${objectpath}


# create every sample directory
echo "pigz decompress start----------- `date`" > DeCompress-log.file
echo "Decompress Files have SAVED in --------- `pwd`/${objectpath}" >> DeCompress-log.file

for samplename in `cat ${samplelist}`;do
mkdir ${objectpath}/${samplename}

# decompress
echo "${samplename}_1.fq.gz is decompressing " >> DeCompress-log.file
pigz -dc -p ${corenum} Raw_Data/${samplename}/${samplename}_1.fq.gz > ${objectpath}/${samplename}/${samplename}_1.fastq
echo -e "`du -sh ${objectpath}/${samplename}/${samplename}_1.fastq`/tfilesize\t${samplename} has been decompressed" >> DeCompress-log.file

echo "${samplename}_2.fq.gz is decompressing " >> DeCompress-log.file
pigz -dc -p ${corenum} Raw_Data/${samplename}/${samplename}_2.fq.gz > ${objectpath}/${samplename}/${samplename}_2.fastq
echo -e "`du -sh ${objectpath}/${samplename}/${samplename}_2.fastq`/tfilesize\t${samplename} has been decompressed" >> DeCompress-log.file
done

# Check Data
echo "Files size check" > DecompressFiles-Check.txt
grep "filesize" DeCompress-log.file >> DecompressFiles-Check.txt
sed 's/G//' DecompressFiles-Check.txt > DF-Check-tmp
echo "File Size May Be Abnormal, Please Check!!!" > DecompressFiles-Warning.txt
awk -v OFS='\t' '{if($1>10) print $0,"WARNING!!!"}' DF-Check-tmp >> > DecompressFiles-Warning.txt
rm DF-Check-tmp
echo "pigz decompress down ----------- `date`" >> DeCompress-log.file
echo -e "time-consuming: $SECONDS seconds" >> DeCompress-log.file

