#!/usr/bin/perl -w
use strict;

my $line="";
my %haplos=();
my %listspecies=();
my @defs=();
my $x=0;
my $sampd=0;
my $sampf=0;
my $nextfield=0;
my $hid=0;

$line=<>;
chomp($line);
@defs=split(/\t/,$line);
if($defs[-1] ne 'sequence'){
	die "\nERROR no sequence at the end\n";
}
$x=0;
while($x<scalar(@defs)){
	$defs[$x] =~ s/[\{\}'\[\]]//g;
	$x++;
}

while($line=<>){
	chomp($line);
	my @a=split(/\t/,$line);
	$x=0;
	while($x<scalar(@a)){
   	$a[$x] =~ s/[\{\}'\[\]]//g;
   	$x++;
	}

	if(length($a[-1])<5){
		  die "\nERROR seq len to short ([$a[-1]])\n";
	}
	$haplos{$a[-1]}{$defs[0]} .="$a[0],"; #id
	$haplos{$a[-1]}{$defs[1]}=$a[1]; #definition
	$haplos{$a[-1]}{$defs[2]}=$a[2]; #best_identity:db_CopF-CopRUn
	$haplos{$a[-1]}{$defs[3]}=$a[3]; #best_match
	$haplos{$a[-1]}{$defs[6]}+=$a[6]; #count
	$haplos{$a[-1]}{$defs[5]}=$a[5]; #class_name
	$haplos{$a[-1]}{$defs[8]}=$a[8]; #family_name
	$haplos{$a[-1]}{$defs[10]}=$a[10]; #genus_name
	$haplos{$a[-1]}{$defs[12]}=$a[12]; #kingdom_name
	$haplos{$a[-1]}{$defs[13]}+=$a[13]; #match_count:db_CopF-CopRUn
	$x=0;
	while($x<scalar(@defs) && $defs[$x] !~ /^sample:/){$x++;}
	$sampd=$x;
	while($x<scalar(@defs) && $defs[$x] =~ /^sample:/){
		#if($a[$x]>0){
		#	$haplos{$a[-1]}{$defs[$x]}=$a[$x];
		#}else{
		#	$haplos{$a[-1]}{$defs[$x]}=0;
		#}
		$haplos{$a[-1]}{$defs[$x]} +=$a[$x];
		$x++;
	}
	$sampf=$x; #+1
	$x=0;
   while($x<scalar(@defs) && $defs[$x] !~ /^obiclean_status:/){$x++;}
   while($x<scalar(@defs) && $defs[$x] =~ /^obiclean_status:/){$x++;}
	$nextfield=$x;
	$haplos{$a[-1]}{$nextfield+1}=$a[$nextfield+1]; #order_name
	$haplos{$a[-1]}{$nextfield+3}=$a[$nextfield+3]; #phylum_name
	$haplos{$a[-1]}{$nextfield+4}=$a[$nextfield+4]; #rank

	$haplos{$a[-1]}{$nextfield+5}=$a[$nextfield+5]; #scientific_name
	$haplos{$a[-1]}{$nextfield+9}=$a[$nextfield+9]; #taxid

	if(!exists($haplos{$a[-1]}{$nextfield+7})){
		$a[$nextfield+7]=~s/, /,/g;
		#$a[$nextfield+3]=~s/[\[\]]//g;
		$haplos{$a[-1]}{$nextfield+7}=$a[$nextfield+7];
	}
	while($x<(scalar(@defs)-1)){
		$haplos{$a[-1]}{$defs[$x]}=$a[$x];
		$x++;
	}
}

#best_identity:db_CopF-CopRUn

my $db=$defs[2];
$db=~s/^.*:(.*)/$1/g;
print "HaplotypeID\t$defs[-1]\t$defs[12]\t$defs[$nextfield+3]\t$defs[5]\t$defs[$nextfield+1]\t$defs[8]\t$defs[10]\t$defs[$nextfield+5]\t$defs[$nextfield+4]\t$defs[$nextfield+9]\t$defs[2]\t$defs[3]:$db\t$defs[13]\t$defs[6]";
for ($x=$sampd;$x<$sampf;$x++){
	my $s=$defs[$x];
	$s=~s/^sample://g;
	$s=~s/^ //g;
	print "\t",$s;
}
print "\t",$defs[0];
print "\t",$defs[$nextfield+7];
print "\n";
$hid=0;
foreach my $v (sort keys %haplos){
	$hid++;
	print "$hid\t";
	print "$v\t";
	print $haplos{$v}{$defs[12]},"\t"; #kingdom_name
	print $haplos{$v}{$defs[$nextfield+3]},"\t"; #phylum_name
	print $haplos{$v}{$defs[5]},"\t"; #class_name
	print $haplos{$v}{$defs[$nextfield+1]},"\t"; #order_name
	print $haplos{$v}{$defs[8]},"\t"; #family_name
	print $haplos{$v}{$defs[10]},"\t"; #genus_name
	print $haplos{$v}{$defs[$nextfield+5]},"\t"; #scientific_name
	print $haplos{$v}{$defs[$nextfield+4]},"\t"; #rank
	#print $haplos{$v}{},"\t"; #
	print $haplos{$v}{$defs[$nextfield+9]},"\t"; #taxid
	print $haplos{$v}{$defs[2]},"\t"; #best_identity 4 db
	my $bm=$haplos{$v}{$defs[3]}; #best match 4 db
	$bm=~s/^.*:(.*)/$1/g;
	print "$bm\t";
	#print $haplos{$v}{$defs[3]},"\t";
	print $haplos{$v}{$defs[13]},"\t"; #match_count 4 db
	print $haplos{$v}{$defs[6]}; #count
	for ($x=$sampd;$x<$sampf;$x++){
		print "\t",$haplos{$v}{$defs[$x]};
	}
	$haplos{$v}{$defs[0]}=~s/,$//g;
	print "\t",$haplos{$v}{$defs[0]};
	print "\t",$haplos{$v}{$defs[$nextfield+7]}; #species_list:db_CopF-CopRUn
	print "\n";
}


exit(0);


