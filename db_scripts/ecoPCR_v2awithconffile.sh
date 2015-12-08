#!/bin/bash

source $1

pbs="#!/bin/bash
\n#PBS -l walltime=24:00:00
\n#PBS -q batch
\n#PBS -N ${base}_ecoPCR
\n#PBS -d ${outpath}
\n#PBS -o ${base}.ecopcr.out
\n#PBS -j oe
\n#PBS -m n
\n#PBS -l nodes=1:ppn=1

\n\nsource /home/j2t/metabarcoding/pipeline/obipath.env

\n\nwd=${outpath}
\ncd \$wd

\nrp=/mnt/big/Metagenomics/OBITools-1.1.22/bin
\nembldb=${embldb}

\n\necho \"1)------------- do ecoPCR --------------------\"

\n\${rp}/ecoPCR -d \$embldb -e $er -l $lmin -L $lmax $pf $pr > ${base}.ecopcr

\n\necho \"---- Cleaning the database --------\"
\n\necho \"2) filter sequences so that they have a good taxonomic description at the species, genus, and family levels\"
\n\${rp}/obigrep -d \$embldb \\
\n-t /mnt/big/blastdb/ncbi_taxa \\
\n--require-rank=species \\
\n--require-rank=genus \\
\n--require-rank=family \\
\n--require-rank=order \\
\n--require-rank=class \\
\n--require-rank=phylum \\
\n${base}.ecopcr > ${base}_clean.fasta

\n\necho \"3) remove redundant sequences\"
\n\${rp}/obiuniq -d \$embldb \\
\n${base}_clean.fasta > ${base}_clean_uniq.fasta

\n\necho \"4) ensure that the dereplicated sequences have a taxid at the family level\"
\n\${rp}/obigrep -d \$embldb \\
\n--require-rank=family \\
\n${base}_clean_uniq.fasta > ${base}_clean_uniq_clean.fasta

\n\necho \"5) ensure that sequences each have a unique identification\"
\n\${rp}/obiannotate -d \$embldb \\
\n--with-taxon-at-rank=kingdom \\
\n--with-taxon-at-rank=phylum \\
\n--with-taxon-at-rank=class \\
\n--with-taxon-at-rank=order \\
\n--with-taxon-at-rank=family \\
\n--with-taxon-at-rank=genus \\
\n--with-taxon-at-rank=species \\
\n--uniq-id \\
\n${base}_clean_uniq_clean.fasta > db_${base}.fasta

\n\nexit 0\n"

echo -en $pbs >ecoPCR_job_${base}.pbs
sed -i 's/ $//g' ecoPCR_job_${base}.pbs
qsub ecoPCR_job_${base}.pbs

exit 0

