# MAP-Emblab
Readbase Metagenomics general analysis pipline (rMAP) is a read level generic analysis pipline developed by EMB Labs at Westlake University. It is suitable for the metagenomics data of paired-end sequencing.  
This script integrates several professional and commonly used metagenomic open source analysis software, and it had preset the default recommendation parameters for easy and fast analysis.  

### How to Reference?  
The following published software is used in our script.   
If you have used this script in your research, please use the following link for references to our script: https://github.com/emblab-westlake/MAP-Emblab   
And please also cite to the corresponding software.  

Prinseq:     http://prinseq.sourceforge.net/  
Bowtie2:     http://bowtie-bio.sourceforge.net/bowtie2/manual.shtml  
MetaPhlAn2:  http://huttenhower.sph.harvard.edu/metaphlan2  
HUMAnN2:     http://huttenhower.sph.harvard.edu/humann2  

### Open source licenses
This project licensed under the GNU General Public License v3.0, Please refer to the detailed terms [LICENCE](https://github.com/emblab-westlake/MAP-Emblab/blob/master/LICENSE).  
If you have any questions, please contact our Email.

## User Manual
### Preparation
In order to complete the analysis tasks smoothly and accurately, please install the necessary software and dependent environment in advance.  
1. pigz   
2. PRINSEQ
3. Bowtie2
4. MetaPhlAn2
5. HUMAnN2
At the same time, please prepare the required database according to the requirements of each software.  
For example, H. sapiens, UCSC hg19(for Bowtie2);  UniRef90 database(for HUMAnN2); et al.  
### Raw data
The paired-end sequences data which suffix with fastq.gz should be stored in the Raw_Data under the project path.   
For more information, see Example.  

Now! When you have finished all your preparation, you can start your analysis.  
### Formal Analysis
This script takes a relative path to accommodate the different host naming conventions. Be sure to run the following command under the project path.  
Each script can view help information using -h/--help.
##### Step1-Decompress
Most of our raw data is in fastq.gz or fq.gz format. But some of the software in our process requires the data format to be FASTQ. Decompressed data will be saved to Decompress folder.   
If your data format is already fastq, you can skip this step.
```
bash Step1_Multi_Decompress.sh -list list.txt -core 10
```
##### Step2-PRINSEQ
Use PRINSEQ for quality control of raw data. Clean data will be saved to CleanData folder.
```
bash Step2_Multiqueue_Prinseq.sh -list list.txt -core 10
```
##### Step3-Bowtie2
Use Bowtie2 to mapping the clean data to hg19 aims to get rid of host genes. Aligned data will be saved to AlignedData folder.  
```
bash Step3_Multiqueue_Bowtie2.sh -list list.txt -core 2
```
##### Step4-1-Remove-host
Remove host genes. BAM without host genes will be saved to AlignedData folder. 
```
bash Step4_1_Remove_host.sh -list list.txt -core 10
```
##### Step4-2-BAM-tO-FASTQ
 Convert BAM to fastq. FASTQ-merged without host genes will be saved to AlignedData folder.  
 ```
 bash Step4_2_BAM2Fastq.sh -list list.txt -core 10
 ```
##### Step5 Humann2
Use Humann2 to obtain gene function and species annotation. Function and annotation results will be saved to Humann2Result folder.
```
bash Step5_Humann2andMetaphlan2.sh -list list.txt -core 10
```
The function and annotation data obtained after the above analysis can be used for subsequent statistical analysis.  






