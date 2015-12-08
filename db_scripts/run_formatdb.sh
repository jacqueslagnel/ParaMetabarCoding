#!/bin/bash
rp=/mnt/big/Metagenomics/OBITools-1.1.16/bin
#/mnt/big/Metagenomics/obitools
source ~/metabarcoding/obipath.env

#NCBI
#from NCBI taxonomy
#txid6830[Organism:exp] AND 16S
#get seq in gb full format
#set --genbank

#ENA:
#http://www.ebi.ac.uk/ena/data/warehouse/search
#description="*16S*" AND tax_tree(6830) (sometimes doenst work..!!)
#save as text (EMBL format)
#set --embl


#6a) Build a reference database
#1 Download the whole set of EMBL sequences (available from: ftp://ftp.ebi.ac.uk/pub/databases/embl/release/)
#2 taxdump.tar.gz in /mnt/big/blastdb/ncbi_taxa
#3 Format them into the ecoPCR format (see obiconvert for how you can produce ecoPCR compatible files)
#4 Use ecoPCR to simulate amplification and build a reference database based on putatively amplified barcodes together with their recorded taxonomic information

#> mkdir EMBL
#> cd EMBL
#> wget -nH --cut-dirs=4 -Arel_std_\*.dat.gz -m ftp://ftp.ebi.ac.uk/pub/databases/embl/release/
#> cd ..

#pipe gz works ok:
#zcat /mnt/big/EMBL/ftp.ebi.ac.uk/pub/databases/embl/release/std/rel_std_hum_06_r123.dat.gz |${rp}/obiconvert --embl -t /mnt/big/blastdb/ncbi_taxa --ecopcrdb-output=embl_test --
#${rp}/obiconvert --embl -t /mnt/big/blastdb/ncbi_taxa --ecopcrdb-output=copepoda_embl_last ENA_copepoda_txid6830_16S.embl

#6b) Use ecoPCR to simulate an in silico PCR
#ecoPCR -d ./ECODB/embl_last -e 3 -l 50 -L 150 TTAGATACCCCACTATGC TAGAACAGGCTCCTCTAG > v05.ecopcr
#ecoPCR -d copepoda_embl_last -e 3 -l 50 -L 150 TTAGATACCCCACTATGC TAGAACAGGCTCCTCTAG > copepoda_embl_last.ecopcr

#gygacctcgatgttgaatt	tcgrtyttaactcaratcatgta
${rp}/ecoPCR -d copepoda_embl_last -e 3 -l 20 -L 120 gygacctcgatgttgaatt tcgrtyttaactcaratcatgta > copepoda_embl_last.ecopcr
#${rp}/ecoPCR -d copepoda_embl_last -e 3 -l 50 -L 150 GRTACYYTAGGGATAACAGC CGRTYTTAACTCARATCATGTAA > copepoda_embl_last.ecopcr
#Note that the primers must be in the same order both in *ngsfilter.txt and in the ecoPCR command.

#7) Clean the database
${rp}/obigrep -d copepoda_embl_last --require-rank=species --require-rank=genus --require-rank=family copepoda_embl_last.ecopcr > copepoda_embl_last_clean.fasta

${rp}/obiuniq -d copepoda_embl_last copepoda_embl_last_clean.fasta > copepoda_embl_last_clean_uniq.fasta

${rp}/obigrep -d copepoda_embl_last --require-rank=family copepoda_embl_last_clean_uniq.fasta > copepoda_embl_last_clean_uniq_clean.fasta

${rp}/obiannotate --uniq-id copepoda_embl_last_clean_uniq_clean.fasta > db_copepoda_embl_last.fasta

exit 0

