#!/bin/bash

#version 1.0
#TODO add lisence
######################### parameters ########################################
#cpus=72
#dodemultiplex=1

#outpath=/home/jacques/j2t/metabarcoding/Panagiotis_run_290615/analysis
#fqdir=/home/jacques/j2t/metabarcoding/Panagiotis_run_290615/cleaned
#fastq1=Kasapidi_S3_L001_001_P_1.fq
#outbase=MetaCop2run1
#embldb=/mnt/big/Metagenomics/OBITools_dbs/embl/obiconverted_ori/embl_r124
#samples=/home/jacques/j2t/metabarcoding/Panagiotis_run_290615/MetaCop2run1.samples
#mydbfas=/home/j2t/metabarcoding/ecoPCR_dbs/copepods/db_CopF-CopRUn.fasta
#scoremin=40
#maxngsfiltererror=2
#mincount=3
#minlen=20
#minratio=0.05

##############################################################################
if [ $# -lt 1 ]
then
	echo "usage:"
	echo "$0 <config file>"
	exit 0
fi

conff=$1

if [ ! -s $conff ]
then
	echo "ERROR conf file not found: $conff"
	exit 0
fi

source $conff

if [ -z "$mydbfas" ]
then
	echo "ERROR no file: $mydbfas"
   exit 0
fi


#exit 0


wd=${outpath}/${outbase}_v2_${cpus}cpus
fq1=${fqdir}/${fastq1}
experim=$outbase
wdali=${wd}/chunks_ali
mkdir -p $wd
cd $wd

echo "output path:${wd}"
#to remove all spaces!!!!
#grep '^[^#$]' metacop2run2.samples.raw |awk -F '\t' '{gsub(/ /, "", $0);print "MetaCop2run2\t"$1"\t"$2":"$4"\t"$3"\t"$5"\tF\t@\t"$6}' >metacop2run2.samples
#cut -f 2 metacop2run2.samples|sort|uniq|wc -l
#cut -f 3 metacop2run2.samples|sort|uniq|wc -l

source /home/j2t/metabarcoding/pipeline/obipath.env
rp=/mnt/big/Metagenomics/OBITools-1.1.22/bin
splitme=/home/jacques/j2t/metabarcoding/Panagiotis_run_290615/analysis/test4all_parallel/split.pl
splitassignedfq=/home/jacques/j2t/metabarcoding/Panagiotis_run_290615/analysis/test4all_parallel/split_fq_bySample.pl

#-------------------------------------------------------------------------------------------
nopbar="--without-progress-bar"

base=${fq1%%_P_1.fq}
nue=${base##*/}
fq2=${base}_P_2.fq
echo "$nue"
rd=$(date +%s.%N)

#----- chunks path for the parallel merge/demultiplexing
#----- chunks path for the parallel merge/demultiplexing
if [ "$dodemultiplex" -ne "0" ]
then
   wdali=$wd/chunks_ali
   mkdir -p $wdali
fi
#----- chunks path for the parallel ecotags
ecotagschunks=${wd}/chunks_ecotags
mkdir -p $ecotagschunks
#----- chunk path for parallel cleaning based on sample names
chunk_samplesnames=${wd}/chunks_samplesnames
mkdir -p $chunk_samplesnames

sampleslist=$wd/samples.list
rm -f $sampleslist
awk -F '[\t ]{1,}' '{print $2}' $samples >$sampleslist

######################################################################################################
###################### Do reads merging and demultiplexing ###########################################
######################################################################################################
#-------- if we want to do it --------------------------------
if [ "$dodemultiplex" -ne "0" ]
then
rm -f $wdali/*
#----------- split fastq 1 & 2--------------------------------
str="#!/bin/bash
\n#PBS -l walltime=00:10:00
\n# PBS -q bigmem
\n#PBS -d ${wdali}
\n#PBS -N split1
\n#PBS -o split1.out
\n#PBS -j oe
\n#PBS -m n
\n#PBS -l nodes=1:ppn=1
\ncd $wdali
\n\nrd=\$(date +%s.%N)
\n\n$splitme $fq1 $wdali/${nue}_P_1 $cpus
\nrf=\$(date +%s.%N)
\necho -en \"RUNTIME\tSTEP1\t1\t\"
\n/usr/local/bin/runtime.sh \$rd \$rf
\n\nexit 0\n\n"
echo -en $str >${wdali}/split1.pbs
sed -i 's/ $//g' ${wdali}/split1.pbs
job1=`qsub ${wdali}/split1.pbs|sed 's/\..*//g'`

str="#!/bin/bash
\n#PBS -l walltime=00:10:00
\n# PBS -q bigmem
\n#PBS -d ${wdali}
\n#PBS -N split2
\n#PBS -o split2.out
\n#PBS -j oe
\n#PBS -m n
\n#PBS -l nodes=1:ppn=1
\ncd $wdali
\n\nrd=\$(date +%s.%N)
\n\n$splitme $fq2 $wdali/${nue}_P_2 $cpus
\nrf=\$(date +%s.%N)
\necho -en \"RUNTIME\tSTEP1\t2\t\"
\n/usr/local/bin/runtime.sh \$rd \$rf
\n\nexit 0\n\n"
echo -en $str >${wdali}/split2.pbs
sed -i 's/ $//g' ${wdali}/split2.pbs
job2=`qsub ${wdali}/split2.pbs|sed 's/\..*//g'`

#------------------ submit demulti in hold mode ---------------------------
listjobs="-W depend=afterok"
for  i in `seq 1 $cpus`
do
	nue2=$(printf "${outbase}_P_%03d" $i)
	rm -f ${wdali}/${nue2}.ali.finished.OK
	outf1=$(printf "$wdali/${nue}_P_1_%03d.fq" $i)
	outf2=$(printf "$wdali/${nue}_P_2_%03d.fq" $i)

str="#!/bin/bash
\n#PBS -l walltime=12:00:00
\n# PBS -q bigmem
\n#PBS -d $wdali
\n#PBS -N demul_${i}
\n#PBS -o obimerge_${nue2}.out
\n#PBS -j oe
\n#PBS -m n
\n#PBS -l nodes=1:ppn=1

\n\nsource /home/j2t/metabarcoding/pipeline/obipath.env
\ncd $wdali

\n\nrdd=\$(date +%s.%N)
\necho \"1 (11) Assembling pair-end reads and keep only well aligned pairs\"
\nrd=\$(date +%s.%N)
\n${rp}/illuminapairedend ${nopbar} --sanger --score-min=${scoremin} -r ${outf2} ${outf1} > ${wdali}/${nue2}.fastq
\nrf=\$(date +%s.%N)
\n/usr/local/bin/runtime.sh \$rd \$rf

\n\necho \"2  remove joined seq\"
\nrd=\$(date +%s.%N)
\n${rp}/obigrep ${nopbar} -p 'mode!=\"joined\"' ${wdali}/${nue2}.fastq > ${wdali}/${nue2}.ali.fastq
\nrf=\$(date +%s.%N)
\n/usr/local/bin/runtime.sh \$rd \$rf

\n\necho \"3 Assign each sequence record to the corresponding sample/marker combination\"
\nrd=\$(date +%s.%N)
\n${rp}/ngsfilter ${nopbar} -t ${samples} -e ${maxngsfiltererror} --sanger ${wdali}/${nue2}.ali.fastq > ${wdali}/${nue2}.ali.assigned.fastq
\nrf=\$(date +%s.%N)
\n/usr/local/bin/runtime.sh \$rd \$rf

\n\necho \"split it by sample name\"
\nrd=\$(date +%s.%N)
\n#${nue2}.ali.assigned.fastq -> ${nue2}.ali.assigned_AN3-0814.fq
\n$splitassignedfq ${wdali}/${nue2}.ali.assigned.fastq ${samples} ${wdali}
\nrf=\$(date +%s.%N)
\n/usr/local/bin/runtime.sh \$rd \$rf

\n\n#rm -f ${outf2} ${outf1}
\necho -en \"RUNTIME\tSTEP2\t${i}\t\"
\n\n/usr/local/bin/runtime.sh \$rdd \$rf
\n\nexit 0\n\n"

echo -en $str >${wdali}/${nue2}.pbs
sed -i 's/ $//g' ${wdali}/${nue2}.pbs
job=`qsub -W depend=afterok:$job1:$job2 ${wdali}/${nue2}.pbs|sed 's/\..*//g'`
listjobs=${listjobs}":"${job}
done
fi #end of if we want dodemultiplex=1

echo "OK Demultiplexing $cpus jobs created"
####################################### END reads merging and demultiplexing #########################


######################################################################################################
############### do cleaning assigned fastq file in parallel based on sample name #####################
######################################################################################################
#-------------- merge assigned reads and split the fastq file by sample mame ------------------------ 
str="#!/bin/bash
\n#PBS -l walltime=12:00:00
\n# PBS -q bigmem
\n#PBS -d $chunk_samplesnames
\n#PBS -N mergebysample
\n#PBS -o mergebysample.out
\n#PBS -j oe
\n#PBS -m n
\n#PBS -l nodes=1:ppn=1

\n\nwd=$chunk_samplesnames
\ncd \$wd

\n\nrdd=\$(date +%s.%N)
\necho \"merge all demultip chunk samples with outbase=${outbase}\"
\n#in:MetaCop2run2_P_032.ali.assigned_AN3-0614.fq
\n#rm -f \${wd}/*.fq
\n\nfor i in \`grep -sh '^[^#$]' $sampleslist\`
\ndo
\ncat ${wdali}/*_P_[0-9][0-9][0-9].ali.assigned_\${i}.fq >\${wd}/${outbase}.ali.assigned_\${i}.fq
\ndone

\n\nrf=\$(date +%s.%N)
\necho -en \"RUNTIME\tSTEP3\t1\t\"
\n\n/usr/local/bin/runtime.sh \$rdd \$rf
\n\nexit 0\n\n"

echo -en $str >${chunk_samplesnames}/split.pbs
sed -i 's/ $//g' ${chunk_samplesnames}/split.pbs
job=`qsub ${listjobs} ${chunk_samplesnames}/split.pbs|sed 's/\..*//g'`

#-------------- do cleaning in parallel based on the number of samples ----------------------------
listjobssamples="-W depend=afterok"
sc=0
while read line
do
sc=$(($sc + 1))
mysample=`echo $line|awk -F '[\t ]{1,}' '{print $2}'`
echo "OK sample [$mysample] job created"

str="#!/bin/bash
\n#PBS -l walltime=02:00:00
\n# PBS -q bigmem
\n#PBS -d $chunk_samplesnames
\n#PBS -N obiclean_${mysample}
\n#PBS -o obiclean_${mysample}.out
\n#PBS -j oe
\n#PBS -m n
\n#PBS -l nodes=1:ppn=1

\n\nsource /home/j2t/metabarcoding/pipeline/obipath.env
\nwd=$chunk_samplesnames
\ncd \$wd

\n\nrdd=\$(date +%s.%N)

\n\nrd=\$(date +%s.%N)
\necho \"4 Dereplicate reads into uniq sequences\"
\n#1 compare all the reads in a data set to each other
\n#2 group strictly identical reads together
\n#3 output the sequence for each group and its count in the original dataset (in this way, all duplicated reads are removed)
\n# run1exp2_parallel.ali.assigned_100A-CopF.fq
\n${rp}/obiuniq ${nopbar} -m sample \${wd}/${outbase}.ali.assigned_${mysample}.fq > \${wd}/${outbase}.ali.assigned.uniq.${mysample}.fasta
\nrf=\$(date +%s.%N)
\n/usr/local/bin/runtime.sh \$rd \$rf

\n\nrd=\$(date +%s.%N)
\necho \"4b To keep only these two key=value attributes with obiannotate\"
\n${rp}/obiannotate ${nopbar} -k count -k merged_sample \${wd}/${outbase}.ali.assigned.uniq.${mysample}.fasta > \$\$;mv \$\$ \${wd}/${outbase}.ali.assigned.uniq.${mysample}.fasta
\nrf=\$(date +%s.%N)
\n/usr/local/bin/runtime.sh \$rd \$rf

\n\nrd=\$(date +%s.%N)
\necho \"5 Denoise the sequence dataset\"
\necho \"5a Get the count statistics ((17)Getting the histogram of seq. count)\"
\n${rp}/obistat ${nopbar} -c count \${wd}/${outbase}.ali.assigned.uniq.${mysample}.fasta|sort -nk1|head -20
\nrf=\$(date +%s.%N)
\n/usr/local/bin/runtime.sh \$rd \$rf

\n\nrd=\$(date +%s.%N)
\necho \"6 Keep only the sequences having a count >= to ${mincount} and a length  min ${minlen} bp\"
\necho \"will be based on the previous step (histo)\"
\n${rp}/obigrep ${nopbar} -l ${minlen} -p \"count>=${mincount}\" \${wd}/${outbase}.ali.assigned.uniq.${mysample}.fasta > \${wd}/${outbase}.ali.assigned.uniq.${mysample}.c${mincount}.l${minlen}.fasta
\nrf=\$(date +%s.%N)
\n/usr/local/bin/runtime.sh \$rd \$rf

\n\nrd=\$(date +%s.%N)
\necho \"7 Clean the sequences for PCR/sequencing errors (sequence variants)\"
\n${rp}/obiclean ${nopbar} -s merged_sample -r ${minratio} -H \${wd}/${outbase}.ali.assigned.uniq.${mysample}.c${mincount}.l${minlen}.fasta > \${wd}/${outbase}.ali.assigned.uniq.${mysample}.c${mincount}.l${minlen}.clean.fasta
\nrf=\$(date +%s.%N)
\n/usr/local/bin/runtime.sh \$rd \$rf
\necho -en \"RUNTIME\tSTEP4\t${sc}\t\"
\n\n/usr/local/bin/runtime.sh \$rdd \$rf
\n\nexit 0\n\n"

echo -en $str >${chunk_samplesnames}/clean_${mysample}.pbs
sed -i 's/ $//g' ${chunk_samplesnames}/clean_${mysample}.pbs
joba=`qsub -W depend=afterok:$job ${chunk_samplesnames}/clean_${mysample}.pbs|sed 's/\..*//g'`
listjobssamples=${listjobssamples}":"${joba}
done <${samples}

##########################################################################################

##########################################################################################
################### do parallel ecotag cpus based ########################################
##########################################################################################
#------------------- split fasta in # of cpus ------------------------------------------
rm -f ${ecotagschunks}/*
str="#!/bin/bash
\n#PBS -l walltime=00:10:00
\n# PBS -q bigmem
\n#PBS -d ${ecotagschunks}
\n#PBS -N split4ecotag
\n#PBS -o split4ecotag.out
\n#PBS -j oe
\n#PBS -m n
\n#PBS -l nodes=1:ppn=1
\ncd ${ecotagschunks}
\n\nrdd=\$(date +%s.%N)
\ncat ${chunk_samplesnames}/${outbase}.ali.assigned.uniq.*.c${mincount}.l${minlen}.clean.fasta >${wd}/${outbase}.ali.assigned.uniq.c${mincount}.l${minlen}.clean.fasta
\n\n/mnt/big/blastdb/scripts/fasta-partition_v3a.pl $cpus ${wd}/${outbase}.ali.assigned.uniq.c${mincount}.l${minlen}.clean.fasta
\nrf=\$(date +%s.%N)
\necho -en \"RUNTIME\tSTEP5\t1\t\"
\n\n/usr/local/bin/runtime.sh \$rdd \$rf
\n\nexit 0\n\n"

echo -en $str >${ecotagschunks}/split4ecotag.pbs
sed -i 's/ $//g' ${ecotagschunks}/split4ecotag.pbs
job1=`qsub ${listjobssamples} ${ecotagschunks}/split4ecotag.pbs|sed 's/\..*//g'`

#--------------------- do parallel ecotag ----------------------------------------------------
cpum=$(( $cpus - 1 )) #fasta split outfiles 0 based
listjobs="-W depend=afterok"
for  i in `seq 0 $cpum`
do
	outfasbase=$(printf "${outbase}_ecotag_%03d" $i)
	infas=$(printf "${ecotagschunks}/Q_%03d.fasta" $i)

str="#!/bin/bash
\n#PBS -l walltime=24:00:00
\n# PBS -q bigmem
\n#PBS -d ${ecotagschunks}
\n#PBS -N ecotag$i
\n#PBS -o ecotag${i}.out
\n#PBS -j oe
\n#PBS -m n
\n#PBS -l nodes=1:ppn=1

\n\nsource /home/j2t/metabarcoding/pipeline/obipath.env
\n\nwd=${ecotagschunks}
\ncd \$wd

\n\nrdd=\$(date +%s.%N)

\n\necho \"8 Taxonomic assignment of sequences (ecotag)\"
\n${rp}/ecotag ${nopbar} -d ${embldb} \\
\n-R ${mydbfas} \\
\n${infas} > \\
\n${ecotagschunks}/${outfasbase}_clean.tag.fasta

\n\nrf=\$(date +%s.%N)
\necho -en \"RUNTIME\tSTEP6\t${i}\t\"
\n/usr/local/bin/runtime.sh \$rdd \$rf
\n\nexit 0\n\n"

echo -en $str >${ecotagschunks}/${outfasbase}.pbs
sed -i 's/ $//g' ${ecotagschunks}/${outfasbase}.pbs
job=`qsub -W depend=afterok:${job1} ${ecotagschunks}/${outfasbase}.pbs|sed 's/\..*//g'`
listjobs=${listjobs}":"${job}

done
########################################################################################

########################################################################################
##################### clean tags and build csv file ####################################
########################################################################################
str="#!/bin/bash
\n#PBS -l walltime=24:00:00
\n# PBS -q bigmem
\n#PBS -d ${wd}
\n#PBS -N ecotag_csv
\n#PBS -o ecotag_csv.out
\n#PBS -j oe
\n#PBS -m n
\n#PBS -l nodes=1:ppn=1

\n\nsource /home/j2t/metabarcoding/pipeline/obipath.env
\n\nwd=${wd}
\ncd \$wd

\n\nrdd=\$(date +%s.%N)
\necho \"merge all tags fasta file do cleaning and build csv the file\"
\n\ncat ${ecotagschunks}/${outbase}_ecotag_*_clean.tag.fasta >${wd}/${outbase}.ali.assigned.uniq.c${mincount}.l${minlen}.clean.tag.fasta

\n\necho \"9 Generate the final result table\"
\necho \"9a Some unuseful attributes can be removed at this stage.\"
\n${rp}/obiannotate ${nopbar} -d ${embldb} \\
\n--with-taxon-at-rank=kingdom \\
\n--with-taxon-at-rank=phylum \\
\n--with-taxon-at-rank=class \\
\n--with-taxon-at-rank=order \\
\n--with-taxon-at-rank=family \\
\n--with-taxon-at-rank=genus \\
\n--with-taxon-at-rank=species \\
\n--delete-tag=scientific_name_by_db \\
\n--delete-tag=obiclean_samplecount \\
\n--delete-tag=obiclean_count \\
\n--delete-tag=obiclean_singletoncount \\
\n--delete-tag=obiclean_cluster \\
\n--delete-tag=obiclean_internalcount \\
\n--delete-tag=obiclean_head \\
\n--delete-tag=taxid_by_db \\
\n--delete-tag=obiclean_headcount \\
\n--delete-tag=id_status \\
\n--delete-tag=rank_by_db \\
\n\${wd}/${outbase}.ali.assigned.uniq.c${mincount}.l${minlen}.clean.tag.fasta > \\
\n\${wd}/${outbase}.ali.assigned.uniq.c${mincount}.l${minlen}.clean.tag.ann.fasta


\n\necho \"9b The sequences can be sorted by decreasing order of count\"
\n${rp}/obisort ${nopbar} -k count -r \${wd}/${outbase}.ali.assigned.uniq.c${mincount}.l${minlen}.clean.tag.ann.fasta >  \\
\n\${wd}/${outbase}.ali.assigned.uniq.c${mincount}.l${minlen}.clean.tag.ann.sort.fasta

\necho \"9c Finally, a tab-delimited file that can be open by excel or R is generated\"
\n${rp}/obitab ${nopbar} -o \${wd}/${outbase}.ali.assigned.uniq.c${mincount}.l${minlen}.clean.tag.ann.sort.fasta > \\
\n\${wd}/${outbase}.ali.assigned.uniq.c${mincount}.l${minlen}.clean.tag.ann.sort.csv

\n/home/jacques/j2t/metabarcoding/reformatme_v2a.pl <\${wd}/${outbase}.ali.assigned.uniq.c${mincount}.l${minlen}.clean.tag.ann.sort.csv > \\
\n\${wd}/${outbase}.ali.assigned.uniq.c${mincount}.l${minlen}.clean.tag.ann.sort.reformated.csv


\n\nrf=\$(date +%s.%N)
\necho -en \"RUNTIME\tSTEP7\t1\t\"
\n/usr/local/bin/runtime.sh \$rdd \$rf
\n\nexit 0\n\n"

echo -en $str >${wd}/build_csv.pbs
sed -i 's/ $//g' ${wd}/build_csv.pbs
qsub ${listjobs} ${wd}/build_csv.pbs
##############################################################################################
echo "OK all jobs submitted"

exit 0

