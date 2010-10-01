#!/usr/bin/perl -w

use strict;
use neat;

my $neat = new neat( "start.xor.pl" );

my $FINISHED = 0;

$SIG{INT} = sub { $FINISHED = 1 };

my $inputs = [
	{ 'bias' => 1, 'one' => 0, 'two' => 0, 'output' => 0, 'expected' => 0 },
	{ 'bias' => 1, 'one' => 1, 'two' => 0, 'output' => 0, 'expected' => 1 },
	{ 'bias' => 1, 'one' => 0, 'two' => 1, 'output' => 0, 'expected' => 1 },
	{ 'bias' => 1, 'one' => 1, 'two' => 1, 'output' => 0, 'expected' => 0 },
	];

sub EvaluateXOR
{
	my $net = shift;

	# why retest someone who hasn't changed?
	return $net->{'fitness'}
		if ( $net->{'elite'} );

	my $total = 0;
	my $values;
	my $average;
	my $i;
	my $difference;
	$total = 0;
	for ( $i = 0 ; $i < 4 ; $i++ )
	{
		$values = Copy( $inputs->[$i] );
		$neat->Activate( $net, $values );
#		printf( " %d%d=%lf", $values->{'one'}, $values->{'two'},
#				$values->{'output'} );
		$difference = abs( $values->{'output'} - $values->{'expected'} );
		$total += $difference;
	}
#	printf( "  [1m%lf[0m\n", 1 - $average );
	my $fitness = 1 - ( $total / 4 );
	$FINISHED = 1 if ( $total < 0.04 ); # close enough!
	return $fitness;
}

$neat->EvaluationFunction( \&EvaluateXOR );

# initial generation
$neat->EvaluateAll();

my $count = 0;
while ( ! $FINISHED )
{
	$neat->Epoch();
	printf( "%s\n", $neat->Stats() );
	$neat->EvaluateAll();
	#$FINISHED = 1 if ( ++$count == 100 );
}

$neat->Champions();
$neat->Save( "xor.final.pl" );

my $champion = $neat->ChampionNetwork();
my $code = $neat->ActivationFunction_C_PartialEval( $champion, 
		{ bias => 1 } );
open INDENT, "|indent -st > activate.xor.c";
print INDENT $code;
close INDENT;
#system "cat activate.xor.c";
