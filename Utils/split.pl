#!/usr/bin/perl -w

use strict;

my $line="";
my $x=1;
my $i=1;
my $outf1="";
my $lc=0;
my $linesbychunk=0;



my ($fq,$outbase, $cpus) = @ARGV;

 
if ( (not defined $fq) || (not defined $outbase) || (not defined $cpus) ) {
  die "Usage: $0 <fastq file with full path> <outs files base name with full path> <number of CPUs (3-96)>\n";
}

if(! -e $fq){
	die "file $fq doenst exist\n";
}

if($cpus<2 || $cpus>96 ){
	 die "# cpus must be >1 and <97\n";
}
	#nice but slower than wc
   # my $lines = 0;
   # my $buffer;
   # open(FILE, $fq) or die "ERROR: Can not open file: $fq";
   # while (sysread FILE, $buffer, 8192) {
   #     $lines += ($buffer =~ tr/\n//);
   # }
   # close FILE;
	#$lc=$lines;
   # print "perl=$lines\n";

$lc=`wc -l $fq|sed 's/ .*//g'`;

chomp($lc);
if($lc<4){
	die "$fq not fastq\n";
}
if(($lc%4)>0){
   die "$fq wrong fastq\n";
}

$lc=int($lc/4);
$linesbychunk=int($lc/$cpus);
print "nb of reads=$lc; reads/chunk=$linesbychunk\n";


$outf1=sprintf("${outbase}_%03d.fq",$i);
open OUT,">$outf1" or die "no w\n";
open(FILE, $fq) or die "ERROR: Can not open file: $!";
while($line=<FILE>){
	print OUT $line;
	$line=<FILE>;
	print OUT $line;
   $line=<FILE>;
   print OUT $line;
   $line=<FILE>;
   print OUT $line;

	$x++;
	if($x>=$linesbychunk){
		$x=1;
		$i++;
		if($i>=$cpus){
			$linesbychunk=$lc;
		}
		close(OUT);
		$outf1=sprintf("${outbase}_%03d.fq",$i);
		open OUT,">$outf1" or die "no w\n";
	}
}

close(OUT);
close(FILE);
exit (0);

