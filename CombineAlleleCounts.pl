#!/usr/bin/perl
# written by E Meyer, eli.meyer@science.oregonstate.edu
# distributed without any guarantees or restrictions

# -- check arguments and print usage statement
$scriptname=$0; $scriptname =~ s/.+\///g;
$usage = <<USAGE;
Counts the number of times each allele was observed, for each locus, in a collection of 
2bRAD data describing nucleotide frequencies for each locus and sample (the output from
SAMBasecaller.pl). 

This script identifies major and minor alleles across samples, and combines these
into a single file containing two columns for each sample (number of times, major allele
was observed, number of times minor allele was observed). 

Output format: columns 1=tag, 2=position, 3=major allele, 4=minor allele,
5=major allele counts for sample A, 6=minor allele counts for sample A, etc.

Missing data are shown as "NA" for both alleles, and the minor allele is reported as 
"NA" for monomorphic loci.

Usage: $scriptname file_1 file_2 ... file_n > output_file
Where:
	files 1-n:	nucleotide frequencies (output from SAMBasecaller.pl) for each sample
	output_file:	a name for the output; tab-delimited text
USAGE
if ($#ARGV < 1 || $ARGV[0] eq "-h") {print "\n", "-"x60, "\n", $scriptname, "\n", $usage, "-"x60, "\n\n"; exit;}

my %bigh;
my $maxthird = 2;

print "Tag\tLocus\tMajor\tMinor\t";
foreach $argi (0..$#ARGV)
	{
	$tmpname = $ARGV[$argi];
	$tmpname =~ s/\/[a-zA-Z0-9_]+\.tab//;
	$tmpname =~ s/.+\///g;
	print $tmpname.".maj", "\t", $tmpname.".min", "\t";
	print STDERR "reading ", $ARGV[$argi], "\n";
	open(TAB, $ARGV[$argi]);
	$rownum = 0;
	while(<TAB>)
		{
		chomp;
		$rownum++; if ($rownum==1) {next;}
		@cols = split("\t", $_);
		$bigh{$cols[1]}{$cols[2]}{$argi}{"A"} = $cols[3];		
		$bigh{$cols[1]}{$cols[2]}{$argi}{"C"} = $cols[4];		
		$bigh{$cols[1]}{$cols[2]}{$argi}{"G"} = $cols[5];		
		$bigh{$cols[1]}{$cols[2]}{$argi}{"T"} = $cols[6];		
		}
	}
print "\n";

foreach $r (sort(keys(%bigh)))
	{
	%ch = %{$bigh{$r}};
	foreach $l (sort{$a<=>$b}(keys(%ch)))
		{
		my %th;
		foreach $argi (0..$#ARGV)
			{
			$th{"A"} += $bigh{$r}{$l}{$argi}{"A"};
			$th{"C"} += $bigh{$r}{$l}{$argi}{"C"};
			$th{"G"} += $bigh{$r}{$l}{$argi}{"G"};
			$th{"T"} += $bigh{$r}{$l}{$argi}{"T"};
			}
		@stha = sort{$th{$b}<=>$th{$a}}(keys(%th));
		if ($th{$stha[2]}>$maxthird) {print STDERR $r, "\t", $l, "\t", "bad locus! third allele found\n"; next;}
		print $r, "\t", $l, "\t", $stha[0], "\t";
		if ($th{$stha[1]}<1) {print "NA", "\t";}
		else	{print $stha[1], "\t";}
		foreach $argi (0..$#ARGV)
			{
			if (exists($bigh{$r}{$l}{$argi}{$stha[0]}) || exists($bigh{$r}{$l}{$argi}{$stha[1]})) 
				{
				print $bigh{$r}{$l}{$argi}{$stha[0]}, "\t", $bigh{$r}{$l}{$argi}{$stha[1]}, "\t";
				}
			else {print "NA\tNA\t";}
			}
		print "\n";
		}
	}
exit;