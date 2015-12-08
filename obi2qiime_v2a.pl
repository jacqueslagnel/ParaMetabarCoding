#!/usr/bin/perl -w
use strict;

my $line="";
my $x=0;
my $sid=0;
my @defs=();
my $as=0;
my @a=();
my $tax="";
$line=<>;
chomp($line);
@a=split(/\t/,$line);
$as=scalar(@a);
open OTXT,">otu.txt" or die "no w otu\n";
open OFNA,">otu.fna" or die "no w fna\n";

print OTXT "#Full OTU Counts\n";
print OTXT "#OTU ID";
for ($x=15;$x<$as-2;$x++){
		 print OTXT "\t$a[$x]";
}
print OTXT "\tConsensus Lineage\n";

while($line=<>){
		  $tax="";
		  @a=split(/\t/,$line);
			if( (length($a[1])>89 && length($a[1])<131) && $a[14]>99){
		  for ($x=2;$x<8;$x++){
					 if($a[$x] ne 'NA'){
								$tax .="$a[$x];";
					 }else{
								last;
					 }
		  }
		  $tax =~ s/;$//g;
		  if($tax ne ""){
					 print OTXT $a[0];
					 for ($x=15;$x<$as-2;$x++){
								print OTXT "\t$a[$x]";
					 }
					 print OTXT "\t$tax\n";
					print OFNA ">$a[0]\n$a[1]\n";
					#$sid++;
		  }
	}
	$sid++;
}

close(OTXT);
close(OFNA);

