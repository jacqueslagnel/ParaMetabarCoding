#!/bin/bash
#PBS -l walltime=24:00:00
# PBS -q bigmem
#PBS -d /home/jacques/j2t/metabarcoding/Panagiotis_run_290615/analysis/MetaCop2run1_v2_72cpus
#PBS -N ecotag_csv
#PBS -o ecotag_csv.out
#PBS -j oe
#PBS -m n
#PBS -l nodes=1:ppn=1
source /home/j2t/metabarcoding/pipeline/obipath.env

fasta=$1

base=${fasta%%.fasta}
nue=${base##*/}

#base="exp4_reformated.ali.assigned.uniq.c3.l20.clean.tag"

wd=`pwd`
cd $wd

rdd=$(date +%s.%N)

embldb=/mnt/big/Metagenomics/OBITools_dbs/embl/obiconverted_ori/embl_r124

echo "9 Generate the final result table"
echo "9a Some unuseful attributes can be removed at this stage."
/mnt/big/Metagenomics/OBITools-1.1.22/bin/obiannotate -d $embldb --without-progress-bar \
--with-taxon-at-rank=kingdom \
--with-taxon-at-rank=phylum \
--with-taxon-at-rank=class \
--with-taxon-at-rank=order \
--with-taxon-at-rank=family \
--with-taxon-at-rank=genus \
--with-taxon-at-rank=species \
--delete-tag=scientific_name_by_db \
--delete-tag=obiclean_samplecount \
--delete-tag=obiclean_count \
--delete-tag=obiclean_singletoncount \
--delete-tag=obiclean_cluster \
--delete-tag=obiclean_internalcount \
--delete-tag=obiclean_head \
--delete-tag=taxid_by_db \
--delete-tag=obiclean_headcount \
--delete-tag=id_status \
--delete-tag=rank_by_db \
${wd}/${base}.fasta > \
${wd}/${base}.ann.fasta

echo "9b The sequences can be sorted by decreasing order of count"
/mnt/big/Metagenomics/OBITools-1.1.22/bin/obisort --without-progress-bar -r -k count ${wd}/${base}.ann.fasta > \
${wd}/${base}.ann.sort.fasta
echo "9c Finally, a tab-delimited file that can be open by excel or R is generated"
/mnt/big/Metagenomics/OBITools-1.1.22/bin/obitab --without-progress-bar -o ${wd}/${base}.ann.sort.fasta > \
${wd}/${base}.ann.sort.csv

rf=$(date +%s.%N)
echo -en "RUNTIME	STEP7	1	"
/usr/local/bin/runtime.sh $rdd $rf

exit 0

