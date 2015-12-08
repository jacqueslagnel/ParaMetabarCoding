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
my ($fas,$samplesf,$outpath) = @ARGV;
my $cpus=0;
my %lfs=();
my $pos = 0;
my $fdef="";
my $seq="";

if ( (not defined $fas) || (not defined $samplesf) || (not defined $outpath)) {
  die "Usage: $0 <fastq file with full path> <sample file> <out full path>\n";
}

if(! -e $fas){
	die "file $fas doenst exist\n";
}

if(! -e $samplesf){
   die "file $samplesf doenst exist\n";
}

`mkdir -p $outpath`;

my($fasbase, $dirs, $ext) = fileparse($fas,qr/\.[^.]*/);

print "[$fasbase] [$dirs] [$ext]\n";

#---------- read sample file -----------------
#exp2	SG1-0414-Tax-CopF	ggaatgag:aacaagcc	grtacyytagggataacagc	tcgrtyttaactcaratcatgta	F	@	Tag2F-Tag1R
open(FILE, $samplesf) or die "ERROR: Can not open file: $!";
while($line=<FILE>){
	chomp($line);
	@a=split(/\t/,$line);
	$sample2exp{$a[1]}=$a[0];
}
close(FILE);


#-------- remove all outfiles and open them ----------------
foreach my $sample (sort keys %sample2exp){
	my $fo="${outpath}/${fasbase}.${sample}.fasta";
	`rm -f $fo`;
	open ($lfs{$sample},">$fo") or die "no w file $sample\n";
}

#------- we read fatsa file ---------------------
open(SEQ, "<$fas") or die "ERROR: Can not open file: $!";
#>M02852:22:000000000-AEEHG:1:1101:17843:1591_CONS_SUB_SUB_CMP count=2689; merged_sample={'Pseudo02-CopF': 2689}; 
while($line=<SEQ>){
	if($line =~/^>/){
		$fdef=$line;
		$pos = tell();
		$seq="";
		while($line=<SEQ>){
			if ($line =~/^>/){
				seek SEQ, $pos, 0;
				last;
			}
			$pos = tell();
			chomp($line);
			$seq .=$line;
		}
		foreach my $sample (sort keys %sample2exp){
         if($fdef =~ /merged_sample=\{\'$sample\':/){
				print {$lfs{$sample}} "${fdef}$seq\n";
				last;
			}
		}
	}
}
close (SEQ);

#---------- we close all files ----------------------
foreach my $sample (sort keys %sample2exp){
   my $fo="${outpath}/${fasbase}_${sample}.fq";
	close($lfs{$sample});
}

exit (0);

