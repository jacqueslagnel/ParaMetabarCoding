#!/usr/bin/perl -w

use strict;
use File::Basename;

my $line="";
my $x=1;
my $i=1;
my $outf1="";
my $lc=0;
my $linesbychunk=0;
my %sample2exp=();
my @a=();
my $fqoutbase="";
my ($fq,$samplesf,$outpath) = @ARGV;
my $cpus=0;
my %lfs=();

if ( (not defined $fq) || (not defined $samplesf) || (not defined $outpath)) {
  die "Usage: $0 <fastq file with full path> <sample file> <out full path>\n";
}

if(! -e $fq){
	die "file $fq doenst exist\n";
}

if(! -e $samplesf){
   die "file $samplesf doenst exist\n";
}

`mkdir -p $outpath`;

my($fqbase, $dirs, $ext) = fileparse($fq,qr/\.[^.]*/);

print "[$fqbase] [$dirs] [$ext]\n";

#---------- read sample file -----------------
#exp2	SG1-0414-Tax-CopF	ggaatgag:aacaagcc	grtacyytagggataacagc	tcgrtyttaactcaratcatgta	F	@	Tag2F-Tag1R
open(FILE, $samplesf) or die "ERROR: Can not open file: $!";
while($line=<FILE>){
	chomp($line);
	@a=split(/\t/,$line);
	$sample2exp{$a[1]}=$a[0];
}
close(FILE);

#----------- check the fq file ------------
$lc=`wc -l $fq|sed 's/ .*//g'`;
chomp($lc);
if($lc<4){
	die "$fq not fastq\n";
}
if(($lc%4)>0){
   die "$fq wrong fastq\n";
}
$lc=int($lc/4);
print "nb of reads=$lc\n";
#--------------------------------------------

#`rm -f ${outpath}/*`;
#-------- remove all outfiles ----------------
foreach my $sample (sort keys %sample2exp){
	my $fo="${outpath}/${fqbase}_${sample}.fq";
	`rm -f $fo`;
	open ($lfs{$sample},">$fo") or die "no w file $sample\n";
}

open(FILE, "<$fq") or die "ERROR: Can not open file: $!";
#@M02852:22:000000000-AEEHG:1:1101:15042:1365_CONS_SUB_SUB_CMP sample=RD1a-0514-Tax-CopF; experiment=exp2; seq_length=112; forward_score=80.0; forward_tag=ggaatgag; reverse_tag=atgctgac; forward_match=ggtactttagggataacagc; forward_primer=grtacyytagggataacagc; reverse_score=92.0; status=full; direction=reverse; reverse_match=tcgattttaactcaaatcatgta; reverse_primer=tcgrtyttaactcaratcatgta; ali_length=150; seq_ab_match=150; sminR=40.0; seq_b_mismatch=0; seq_a_mismatch=0; tail_quality=36.1; seq_b_deletion=0; mid_quality=73.3121019108; seq_a_deletion=0; score_norm=3.98890855263; score=598.336282895; seq_a_insertion=0; mode=alignment; seq_length_ori=177; head_quality=35.3; avg_quality=69.0621468927; sminL=40.0; seq_a_single=14; seq_b_single=13; seq_b_insertion=0; 
#ataatgataataagagtccttatcagttttatcgcttatgacctcgatgttgaattaagacccgatttgtgcagaaacaagccacgggctgtctgttcgacagaacttttct
#+
#oomnmoonoonhilmolnoominmnkmlnnonnlkoolYiVTVllnmoonkmoooloolmnknnllnnmongkommllojllkmjmjfmjljkmononfnVlnnklooonjo

while($line=<FILE>){
	foreach my $sample (sort keys %sample2exp){
		if($line =~ /sample=$sample;/){
   		print  {$lfs{$sample}} $line;
   		$line=<FILE>;
   		print  {$lfs{$sample}} $line;
   		$line=<FILE>;
   		print  {$lfs{$sample}} $line;
   		$line=<FILE>;
   		print  {$lfs{$sample}} $line;
			last;
		}
	}
}
close(FILE);

foreach my $sample (sort keys %sample2exp){
   my $fo="${outpath}/${fqbase}_${sample}.fq";
	#print {$lfs{$sample}} "$sample\n";
	close($lfs{$sample});
}

#--------------- check outputs fq files ---------------------
foreach my $sample (sort keys %sample2exp){
   my $fo="${outpath}/${fqbase}_${sample}.fq";
   open (IN,"<$fo") or die "no r file $sample\n";
   while($line=<IN>){
      chomp($line);
      if (length($line)>5 && $line !~ /sample=$sample/){
         print "ERROR $sample:$line\n";
			last;
      }
      $line=<IN>;$line=<IN>;$line=<IN>;
   }
   close(IN);
}

exit (0);

