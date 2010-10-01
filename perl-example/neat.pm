#!/usr/bin/perl -w
package neat;
# NEAT - Neuro-Evolution of Augmenting Topologies

use strict;
use warnings;
use Data::Dumper;

my $DEBUG = 0;

BEGIN {
	use Exporter ();
	our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

	$VERSION = 1.0;
	@ISA = qw( Exporter );
	@EXPORT = qw( 
		Copy
		SaveData
		LoadData
		);
}

# interface methods
sub new 
{
	my $self = {};
	$self->{CLASSNAME} = shift;
	bless $self;
	$self->Init( @_ );
	return $self;
}
sub DESTROY 
{
	my $self = shift;
	# nothing important to be done
}
sub Init 
{
	my $self = shift;
	my $file = shift;
	my $fast = shift;

	die "MUST specify an initial experiment configuration file!"
	 unless defined $file;

	# load the experiment file
	my $data = LoadData( $file );
	foreach my $key ( keys %$data ) {
		$self->{$key} = $data->{$key};
	}

	if ( ! defined $fast ) {
		# re-init topology activation functions
		foreach my $t ( values %{$self->{'topologies'}} ) {
			delete $t->{'code'};
			delete $t->{'func'};
		}
		$self->InitTopologies();
	}

	$DEBUG = $self->{'settings'}->{'debug'};
}
sub InitTopologies
{
	my $self = shift;
	my $net;
	foreach $net ( values %{$self->{'population'}} ) {
		my $t = NetworkTopology( $net );
		$self->AddTopology( $t, $net );
	}
}
sub EvaluationFunction
{
	my ( $self, $func ) = @_;
	$self->{'settings'}->{'eval-func'} = $func;
}
sub EvaluateAll
{
	my $self = shift;

	my @networks = values %{$self->{'population'}};
	my $func = $self->{'settings'}->{'eval-func'};
	foreach my $net ( @networks ) {
		$net->{'fitness'} = &$func( $net );
	}
}
sub Save
{
	my ( $self, $file ) = @_;
	if ( ! defined $file ) {
		$file = $self->{'settings'}->{'experiment'} . "."
			  . $self->{'save'}->{'generation'} . ".pl";
	}
	SaveData( $self, $file );
}
sub Champions
{
	my $self = shift;
	my @champions;
	my ($top,$net,$fitness);

	# initialize the toplogy records
	foreach $top ( values %{$self->{'topologies'}} ) {
		$top->{'members'} = [];
		$top->{'min'} = 1e+99;
		$top->{'max'} = -1e+99;
		$top->{'total'} = 0;
		$top->{'count'} = 0;
		$top->{'last'} = $top->{'avg'};
		$top->{'avg'} = 0;
		$top->{'offspring'} = 0;
	}
	my $min = 1e+99;
	my $max = -1e+99;
	my $total = 0;
	my $count = 0;
	# update topologies with total fitness values
	foreach $net ( values %{$self->{'population'}} ) {
		my $f = $net->{'fitness'};
		# update population min/max/total/count
		$min = $f if $f < $min;
		$max = $f if $f > $max;
		$total += $f;
		$count++;
		
		# update topology min/max/total/count
		$top = $self->{'topologies'}->{ $net->{'topology'} };
		$top->{'min'} = $f if $f < $top->{'min'};
		$top->{'max'} = $f if $f > $top->{'max'};
		$top->{'total'} += $f;
		$top->{'count'}++;
		push @{$top->{'members'}}, $net->{'id'};

		# if this is better than the historical max, save it
		if ( $f > $self->{'save'}->{'max-fitness'} ) {
			$self->{'save'}->{'max-fitness'} = $f;
			$self->{'save'}->{'max-fitness-generation'} = 
				$self->{'save'}->{'generation'};
			$self->{'save'}->{'champion'} = Copy( $net );
		}
	}

	# update global statistics
	$self->{'save'}->{'gen-min'} = $min;
	$self->{'save'}->{'gen-max'} = $max;
	$self->{'save'}->{'gen-avg'} = $total / $count;
	
	# calculate average fitness for each topology
	foreach $top ( values %{$self->{'topologies'}} ) {
		if ( $top->{'count'} > 0 ) {
			$top->{'avg'} = $top->{'total'} / $top->{'count'};
		} else {
			$top->{'avg'} = 0;
		}
	}

	# calculate an adjusted average after throwing out all below-average values
	foreach $top ( values %{$self->{'topologies'}} ) {
		$top->{'adj-total'} = $top->{'total'};
		$top->{'adj-count'} = $top->{'count'};
	}
	foreach $net ( values %{$self->{'population'}} ) {
		my $f = $net->{'fitness'};
		my $top = $self->{'topologies'}->{ $net->{'topology'} };
		if ( $f < $top->{'avg'} ) {
			$top->{'adj-total'} -= $f;
			$top->{'adj-count'}--;
		}
	}
	foreach $top ( values %{$self->{'topologies'}} ) {
		if ( $top->{'adj-count'} > 0 ) {
			$top->{'adj-avg'} = $top->{'adj-total'} / $top->{'adj-count'};
		} else {
			$top->{'adj-avg'} = 0;
		}
	}
	
	# sort members by fitness
	# adjust penalty
	# save best to champions list
	foreach $top ( values %{$self->{'topologies'}} ) {
		# sort members by fitness, descending
		@{$top->{'members'}} = sort {
			$self->{'population'}->{$b}->{'fitness'} <=> 
			$self->{'population'}->{$a}->{'fitness'};
			} @{$top->{'members'}};

		# update 'best' fitness
		if ( defined( $top->{'members'}->[0] ) ) {
			# lookup the fitness of the topology leader
			$fitness = $self->{'population'}->{
				$top->{'members'}->[0] }->{'fitness'};
		
			# add the fitness to the history record (limit 100)
			$top->{'history'} = [] if ( ! exists $top->{'history'} );
			unshift @{$top->{'history'}}, $fitness;
			pop @{$top->{'history'}} if @{$top->{'history'}} > 100;
			
=huh
			# calculate a weighted average
			my $total = 0;
			my $weight = 100;
			my $count = 0;
			foreach my $f ( @{$top->{'history'}} ) {
				$total += $f * $weight;
				$count += $weight;
				$weight--;
			}
			my $avg = $total / $count;
=cut

			# require at least X generations before we start looking
			# at the penalty, to give it a chance to establish itself 
			if ( @{$top->{'history'}} < 5 ) {
				$top->{'penalty'} = 0;
				$top->{'best'} = 0;
			} else {
				# adjust penalty based on improvement
				if ( $fitness > $top->{'best'} ) {
					$top->{'penalty'} *= 0.9; # 90% of what it was
					$top->{'best'} = $fitness;
				} else {
					$top->{'penalty'}++;
				}
			} 

			# save this member as a champion
			push @champions, $top->{'members'}->[0]; 
		}
		# save the second-place member, too, if there is one
		push @champions, $top->{'members'}->[1] 
			if ( defined( $top->{'members'}->[1] ) );
	}
	@champions = sort @champions;
	$self->{'champions'} = \@champions;
	return @champions;
}
sub Epoch
{
	my $self = shift;

	my @champs = Champions( $self );
	my $t; # topology

	# save the experiment data, if requested
	$self->Save() if ( $self->{'settings'}->{'save-epochs'} );

	# calculate minimum/maximum weights and active topology search count
	my %active;
	my $min = $self->{'settings'}->{'max-weight'};
	my $max = - $min;
	foreach my $net ( values %{$self->{'population'}} ) {
		$active{$net->{'topology'}}++;
		next if $net->{'fitness'} < $self->{'topologies'}->{ $net->{'topology'} }->{'avg'};
		foreach my $node ( values %{$net->{'nodes'}} ) {
			foreach my $c ( values %$node ) {
				$min = $c if $c < $min;
				$max = $c if $c > $max;
			}
		}
	}
	$self->{'save'}->{'min-weight'} = $min;
	$self->{'save'}->{'max-weight'} = $max;
	
	$self->{'save'}->{'generation'}++;

	$self->AllocateOffspring();
	my $remaining;

	$self->{'offspring'} = {}; # keep the new offspring here

	# create the new generation. 
	foreach $t ( values %{$self->{'topologies'}} ) {
		$remaining = int( $self->{'settings'}->{'population'} 
					- scalar( keys %{$self->{'offspring'}} ) );
		$remaining = 0 if $remaining < 0;

		# how many offspring are allowed
		# special case for offspring less than 1 but non-zero
		# or where the population limit is exceeded
		my $limit = $self->{'settings'}->{'limit'};
		my $o = abs($t->{'offspring'});
		$o = 3 if ( $o > 0 && $o < 1 );
		$o = int ( $o );
		$o = $limit if ( $o > $limit );
		$o = $remaining if ( $o > $remaining );
		$o = 3 if ( $o < 1 && $t->{'offspring'} > 0 );

		# first place champion
		next unless defined $t->{'members'}->[0];
		my $one = $self->{'population'}->{ $t->{'members'}->[0] };
		$t->{'champion'} = Copy( $one );

		# pass the best one on to the next generation
		next unless $o--; $self->Elite( $one );

		# focus the first few offspring on potentially profitable 
		# changes so that if it is our last chance, we have a 
		# CHANCE of making an improvement during this generation
		next unless $o--; $self->WeightAdjust( $one );  # only change ONE weight
		next unless $o--; $self->WeightsAdjust( $one );  # change all weights
		next unless $o--; $self->WeightsRandom( $one );  # choose all new weights

		# make a list of all members within the topology
		my @members;
		foreach my $m ( @{$t->{'members'}} ) {
			my $n = $self->{'population'}->{$m};
#			next if $n->{'fitness'} < 
#				$self->{'topologies'}->{ $n->{'topology'} }->{'avg'};
			push @members, $m;
		}

		# focus the next group of offspring around 2nd place
		if ( @members > 1 ) {
			my $two = $self->{'population'}->{ $members[1] };
			next unless $o--; $self->Elite( $two );
			next unless $o--; $self->WeightAdjust( $two );  
			next unless $o--; $self->WeightsAdjust( $two );  
			next unless $o--; $self->CrossoverAverage( $one, $two );  # only change ONE weight
			next unless $o--; $self->CrossoverRandom( $one, $two );  # only change ONE weight
			next unless $o--; $self->CrossoverRandom( $one, $two );  # only change ONE weight
		}

		# use this function for a weighted selection of 
		# who to act on
		sub Choose {
			my $self = shift;
			return $self->{'population'}->{ $_[int( rand() * @_ )] };
		}
		
		# for the rest of the offspring, do something at random
		while ( $o-- >= 1 ) {
			# 50% chance of just modifying an existing 
			if ( rand() < 0.5 ) {
				my $net = &Choose( $self, @members );
				my $r = rand();
				   if ( $r < 0.50 ) { $self->WeightsAdjust( $net ); }
			#	elsif ( $r < 0.80 ) { $self->WeightAdjust( $net ); }
				else                { $self->WeightsRandom( $net );  }
			} else {
			# crossover two
				my $one = &Choose( $self, @members );
				my $two = &Choose( $self, @members );
				if ( $one == $two ) {
					# crossover of an individual with itself is useless
					$o++;
					next;
				}
				if ( rand() < 0.5 ) { $self->CrossoverRandom( $one, $two ); }
				else                { $self->CrossoverAverage( $one, $two ); }
			}
		}
	}

	# if we have room left in the population
	# create a topological mutation
	$remaining = ( $self->{'settings'}->{'population'} 
				- scalar( keys %{$self->{'offspring'}} ) );
	my $active = scalar keys %active;
	if ( $remaining && $active < $self->{'settings'}->{'topology-limit'} ) {

		my $net;
		if ( rand() < 0.75 ) {
			# mutate the current champion network
			$net = $self->{'save'}->{'champion'};
		} else {
			# mutate some poor unsuspecting topology champion 
			my ( $which ) = RandomOrder( keys %{$self->{'topologies'}} );
			$net = $self->{'topologies'}->{$which}->{'champion'};
		}

		my $r = rand();
		   if ( $r < 0.05 ) { $self->ConnectionRemove( $net ); }
		elsif ( $r < 0.25 ) { $self->ConnectionSplit( $net );  }
		else                { $self->ConnectionAdd( $net );    }
	}

	# replace the current population with the offspring
	$self->{'population'} = $self->{'offspring'};
	delete $self->{'offspring'};
}
sub Activate
{
	my ( $self, $net, $values ) = @_;
	if ( ! exists( $net->{'topology'} ) ) {
		$self->AddTopology( NetworkTopology( $net ), $net );
	}
	my $func = $self->{'topologies'}->{ $net->{'topology'} }->{'func'};
	&$func( $net, $values );
}
sub Stats
{
	my $self = shift;
	my %seen;
	my $active = 0;
	my $best = 0;
	foreach my $net ( values %{$self->{'population'}} ) {
		$best = $net->{'fitness'} if ( $net->{'fitness'} > $best );
		next if exists $seen{$net->{'topology'}};
		$seen{$net->{'topology'}} = 1;
		$active++;
	}
	return sprintf( "%s: g%04d p%04d t%03d/%04d f%10.10f m%10.10f n%10.10f",
		$self->{'settings'}->{'experiment'},
		$self->{'save'}->{'generation'},
		scalar( keys %{$self->{'population'}} ),
		$active,
		scalar( keys %{$self->{'topologies'}} ),
		$self->{'save'}->{'max-fitness'},
		$self->{'save'}->{'max-weight'},
		$self->{'save'}->{'min-weight'} );
}
sub ChampionNetwork
{
	my $self = shift;
	return $self->{'save'}->{'champion'};
}
# private methods
sub UniqueID
{
	my $self = shift;
	return ++($self->{'save'}->{'unique-id'});
}
sub AddTopology
{
	my ( $self, $topology, $net ) = @_;
	# lookup id
	my ( $id, $n );
	if ( exists $self->{'topology-lookup'}->{$topology} ) {
		$id = $self->{'topology-lookup'}->{$topology};
	} else {
		$id = $self->UniqueID();
		$self->{'topology-lookup'}->{$topology} = $id;
	}

	# init topology record
	$net->{'topology'} = $id;
	if ( ! exists $self->{'topologies'}->{$id} ) {
		$self->{'topologies'}->{$id} = {
			'members' => [],
			'count' => 0,
			'total' => 0,
			'last' => 0,
			'avg' => 0,
			'best' => 0,
			'penalty' => 0,
			'offspring' => 0,
			};
	} else {
		# new blood, reduce any existing penalty
		my $t = $self->{'topologies'}->{$id};
		$t->{'penalty'} /= 2;
		# if was dead, resurrect the elite member
		if ( $t->{'offspring'} == 0 ) {
			$t->{'offspring'} = 2;
			# the one that was just 'created' and
			# the old topology champion/elite
			my $new = Copy( $t->{'champion'} );
			$new->{'elite'} = 1;
			$self->{'offspring'}->{ $new->{'id'} } = $new;
		}
	}
	# lookup and save the activation order
	my @order;
	ActivationOrder( $net, undef, \@order, {} );
	$self->{'topologies'}->{$id}->{'order'} = \@order;

	# identify any non-contributing nodes
	my %useless = $self->UselessNodes( $net );
	$self->{'topologies'}->{$id}->{'ignore'} = \%useless;

	# remove non-contributing nodes from the activation order
	$self->{'topologies'}->{$id}->{'order'} = [];
	foreach $n ( @order ) {
		push @{$self->{'topologies'}->{$id}->{'order'}}, $n
			if ( ! exists( $self->{'topologies'}->{$id}->{'ignore'}->{$n} ) );
	}

	# if using perl activation, add activation function
	if ( $self->{'settings'}->{'activation'} eq 'perl' 
	  && ! exists $self->{'topologies'}->{$id}->{'code'} ) {
		my $code = $self->ActivationFunction_Perl( $net );
		$self->{'topologies'}->{$id}->{'code'} = $code;
		eval "\$self->{'topologies'}->{'$id'}->{'func'} = $code;";
	}
}
sub UselessNodes
{
	my ( $self, $net ) = @_;
	my ( %input, %output, %useless );
	my @order;
	my ( $n, $c );

	@order = @{$self->{'topologies'}->{ $net->{'topology'} }->{'order'}};

	my @list;
	# start by finding all output nodes;
	foreach $n ( @order ) {
		next unless $self->{'nodes'}->{$n}->{'type'} eq 'output';
		push @list, $n;
		$output{$n} = 1;
	}
	# now find all nodes connected to an output node
	while ( @list ) {
		$n = shift @list;
		my @connections = keys %{$net->{'nodes'}->{$n}};
		while ( @connections ) {
			$c = shift @connections;
			next if exists $output{$c};
			$output{$c} = 1;
			push @list, $c;
		}
	}
	# now work the other way...find all input nodes
	@list = ();
	foreach $n ( @order ) {
		next unless $self->{'nodes'}->{$n}->{'type'} eq 'input';
		push @list, $n;
		$input{$n} = 1;
	}
	# now find all nodes connected to an input node
	my $count = 1;
	while ( $count ) {
		$count = 0;
		foreach $n ( @order ) {
			next if exists $input{$n};
			foreach $c ( keys %{$net->{'nodes'}->{$n}} ) {
				next unless exists $input{$c};
				$input{$n} = 1;
				$count++;
				last;
			}
		}
	}
	# all nodes that do not appear in both lists are useless
	foreach $n ( @order ) {
		if ( ! ( exists $input{$n} && exists $output{$n} ) ) {
			$useless{$n} = 1;
		}
	}
	return %useless;
}
sub AllocateOffspring
{
	my $self = shift;
	my $top;
	my ( $total, $temp, $count );
	my $penalty;

	# NOTE: Assumes that $self->Champions() called already

	# calculate a total population fitness adjusted for penalties
	$total = 0;
	foreach $top ( values %{$self->{'topologies'}} ) {
		# penalty is 0..100
		# avg fitness is reduced 1% for each penalty point
		$temp = $top->{'adj-avg'};
		$penalty = $temp * ( $top->{'penalty'} / 
							$self->{'settings'}->{'penalty'} )**10;
		$penalty = $temp if $penalty > $temp;
		$temp -= $penalty;
		$top->{'adjusted'} = $temp;
		$total += $temp;
	}

	# each is allocated offspring based on contribution to total
	$count = $self->{'settings'}->{'population'};
	if ( $total < 1 ) {
		my $offspring = $count / scalar keys %{$self->{'topologies'}};
		foreach $top ( values %{$self->{'topologies'}} ) {
			$top->{'offspring'} = $offspring;
		}
	} else {
		foreach $top ( values %{$self->{'topologies'}} ) {
#			if ( $top->{'total'} < 1 ) {
#				# keep it alive long enough to optimize
#				$top->{'offspring'} = 3;
#			} else {
				$top->{'offspring'} = $count * ( $top->{'adjusted'} / $total );
#			}
		} 
	}
}
sub AvailableConnections
{
	my ( $self, $net ) = @_;
	my $node;
	my $connection;
	my @nodes;
	my @list;
	# make a list of all possible NEW connections
	@nodes = keys %{$net->{'nodes'}};
	foreach $node ( @nodes ) {
		# omit input nodes, they can't have any dependencies
		next if $self->{'nodes'}->{$node}->{'type'} eq 'input';
		foreach $connection ( @nodes ) {
			next if exists( $net->{'nodes'}->{$node}->{$connection} );
			push @list, "${node}:${connection}";
		}
	}
	return RandomOrder( @list );
}
sub ActivationFunction_Perl
{
	my ( $self, $net ) = @_;
	my @nodes;
	@nodes = @{$self->{'topologies'}->{ $net->{'topology'} }->{'order'}};
	my $code = 'sub { my ( $n, $v ) = @_; ';
#			 . 'foreach my $node ( keys %{$n->{\'nodes\'}} ) '
#			 .  '{ $v->{$node} = 0 unless exists $v->{$node}; } ';
	foreach my $node ( @nodes ) {
		my @params;
		foreach my $dep ( sort keys %{$net->{'nodes'}->{$node}} ) {
			# make sure the node we depend on has dependancies,
			# or is an input node
			if ( $self->{'nodes'}->{$dep}->{'type'} eq 'input' 
			  || scalar( keys %{$net->{'nodes'}->{$dep}} ) ) {
				push @params, "(\$v->{'$dep'}*\$n->{'nodes'}->{'$node'}->{'$dep'})";
			}
		}
		if ( @params ) {
			$code .= "\$v->{'$node'} = " 
					. $self->{'nodes'}->{$node}->{'function'}
					. '( ' . join( '+', @params )
					. ", $self->{'nodes'}->{$node}->{'gain'} ); ";
		}
	}
	$code .= '}';
	return $code;
}
sub ActivationFunction_C_PartialEval
{
	# generates a C function that activates a specific network
	# with specific weights and some inputs, pre-calculating as much
	# of the calculations as humanly possible
	# 
	# as of right now, assumes there is only one output
	my ( $self, $net, $values ) = @_;
	
	my $code = '';
	my ( @nodes, @conn );
	my ( $n, $c );
	my $value = Copy( $values ); # don't want to modify the caller's data
	my $accum = {};

	# get the activation order
	@nodes = @{$self->{'topologies'}->{ $net->{'topology'} }->{'order'}};

	# initialize the node accumulators
	foreach $n ( @nodes ) {
		$accum->{$n} = 0;
	}

	# make a copy of the network so we can prune as we pre-calculate
	$net = Copy( $net );

	# pre-calculate the values of any nodes we can
	my $changes = 1;
	while ( $changes ) {
		$changes = 0;
		foreach $n ( @nodes ) {
			next if exists $value->{$n};
			next if $self->{'nodes'}->{$n}->{'type'} eq 'input';
			@conn = keys %{$net->{'nodes'}->{$n}};
			foreach $c ( @conn ) {
				next unless exists $value->{$c};
				$accum->{$n} += $value->{$c} * $net->{'nodes'}->{$n}->{$c};
				delete $net->{'nodes'}->{$n}->{$c};
			}
			# if the node is now complete, calculate its value
			if ( ! scalar( keys %{$net->{'nodes'}->{$n}} ) ) {
				$value->{$n} = eval(
					$self->{'nodes'}->{$n}->{'function'}
					. '( '
					. $accum->{$n}
					. ', '
					. $self->{'nodes'}->{$n}->{'gain'}
					. ');'
				);
				$changes++;
			}
		}
	}

	# make a list of inputs whose value is not passed in (variable)
	# don't need this right now, because the experiment defines the function prototype
=disabled
	my @inputs;
	foreach $n ( @nodes ) {
		next unless ( $self->{'nodes'}->{$n}->{'type'} eq 'input' );
		next if ( exists $values->{$n} );
		push @inputs, $n;
	}

	# if nothing ever changes, just die, but chastise the user first.
	if ( ! @inputs ) {
		printf( "you attempted to form code that calculates a network " .
				"that has no variable inputs.  What's the point?\n" );
		printf( join ",", @inputs );
		die;
	}
=cut

	##### Start of generated code #####
	$code .= "{\n";

	# declare the variables to hold the values of nodes
	my @vars;
	foreach $n ( @nodes ) {
		next if ( $value->{$n} );
		next if ( $self->{'nodes'}->{$n}->{'type'} eq 'input' );
		push @vars, $n;
	}
	$code .= 'double n_' . join( ",n_", @vars ) . ";\n";

	# perform the summation and sigmoid for every node
	foreach $n ( @vars ) {
		my @values;
		foreach $c ( keys %{$net->{'nodes'}->{$n}} ) {
			my $temp = "( ";
			# this should NEVER happen, but just in case...
			if ( exists $value->{$c} ) {
				$temp .= sprintf( "%55.55f", $value->{$c} );
			} else {
				$temp .= "n_$c";
			}
			$temp .= sprintf( " * %55.55f )\n", $net->{'nodes'}->{$n}->{$c} );
			push @values, $temp;
		}
		if ( @values ) {
			my $func = $self->{'nodes'}->{$n}->{'function'};
			if ( $func eq 'sigmoid' ) {
				$code .= 'n_' . $n . ' = 1/(1+exp( -1 * '
					. $self->{'nodes'}->{$n}->{'gain'} 
					. " * (\n" 
					. sprintf( "%55.55f\n+", $accum->{$n} );
				$code .= join "+", @values;
				$code .= ")));\n";
			} elsif ( $func eq 'sum' ) {
				$code .= 'n_' . $n . ' = '
					. sprintf( "%55.55f\n+", $accum->{$n} )
					. join( '+', @values )
					. ";\n";
			} else { die "What kind of activation function is $func?"; }
		}
	}
	# find and 'return' the output node value
	# start looking at the back, because that one SHOULD be it!
	my $found = 0;
	foreach $n ( reverse @vars ) {
		next unless $self->{'nodes'}->{$n}->{'type'} eq 'output';
		$found = 1;
		$code .= "return n_$n;\n}\n";
	}
#	if ( ! $found ) {
#		printf( "attempted to generate code for a network with no obvious output." .
#				"  That was dumb...  " );
#		die;
#	}
#	$net->{'code'} = $code;
	return $code;
}
# offspring producing methods
sub Elite
{
	my ( $self, $net ) = @_;
	# network is copied, unchanged
	my $new = Copy( $net );
	$new->{'elite'} = 1;
	$self->{'offspring'}->{ $new->{'id'} } = $new;
}
sub WeightAdjust
{
	my ( $self, $net ) = @_;
	my $new = Copy( $net );
	$new->{'id'} = $self->UniqueID();
	$new->{'elite'} = 0;
	
	# adjust ONE weight by up to 10 percent in either direction
	my @existing = ExistingConnections( $new );
	my $key = $existing[0];
	return if ( ! defined( $key ) );
	my ( $n, $c ) = split( ":", $key );
	$new->{'nodes'}->{$n}->{$c} = $self->NewWeight( $new->{'nodes'}->{$n}->{$c} );
	$self->{'offspring'}->{ $new->{'id'} } = $new;
}
sub WeightsAdjust
{
	my ( $self, $net ) = @_;
	my $new = Copy( $net );
	$new->{'id'} = $self->UniqueID();
	$new->{'elite'} = 0;
	
	# adjust each weight by up to 10 percent in either direction
	my ( $n, $c );
	foreach $n ( keys %{$new->{'nodes'}} ) {
		foreach $c ( keys %{$new->{'nodes'}->{$n}} ) {
			$new->{'nodes'}->{$n}->{$c} = 
				$self->NewWeight( $new->{'nodes'}->{$n}->{$c} );
		}
	}
	$self->{'offspring'}->{ $new->{'id'} } = $new;
}
sub WeightsRandom
{
	my ( $self, $net ) = @_;
	my $new = Copy( $net );
	$new->{'id'} = $self->UniqueID();
	$new->{'elite'} = 0;

	# give every connection a new weight, chosen at random
	my ( $n, $c );
	foreach $n ( keys %{$new->{'nodes'}} ) {
		foreach $c ( keys %{$new->{'nodes'}->{$n}} ) {
			$new->{'nodes'}->{$n}->{$c} = $self->NewWeight();
		}
	}
	$self->{'offspring'}->{ $new->{'id'} } = $new;
}
sub CrossoverAverage
{
	my ( $self, $one, $two ) = @_;
	my $new = Copy( $one );
	$new->{'id'} = $self->UniqueID();
	$new->{'elite'} = 0;

	# adjust weights to be the average of the two parents
	my ( $n, $c );
	foreach $n ( keys %{$new->{'nodes'}} ) {
		foreach $c ( keys %{$new->{'nodes'}->{$n}} ) {
			if ( exists $two->{'nodes'}->{$n}->{$c} ) {
				$new->{'nodes'}->{$n}->{$c} =  
					( $one->{'nodes'}->{$n}->{$c} 
					+ $two->{'nodes'}->{$n}->{$c} )
					/ 2;
			}
		}
	}
	$self->{'offspring'}->{ $new->{'id'} } = $new;
}
sub CrossoverRandom
{
	my ( $self, $one, $two ) = @_;
	my $new = Copy( $one );
	$new->{'id'} = $self->UniqueID();
	$new->{'elite'} = 0;

	# adjust each weight to be the same as one of the parents,
	# selected at random
	my ( $n, $c );
	foreach $n ( keys %{$new->{'nodes'}} ) {
		foreach $c ( keys %{$new->{'nodes'}->{$n}} ) {
			if ( exists $two->{'nodes'}->{$n}->{$c} 
			  && rand() < 0.5 ) {
				$new->{'nodes'}->{$n}->{$c} = $two->{'nodes'}->{$n}->{$c};
			}
		}
	}
	$self->{'offspring'}->{ $new->{'id'} } = $new;
}
sub ConnectionAdd
{
	my ( $self, $net ) = @_;
	my $id = $self->UniqueID();
	my $topology;
	my $new;
	my @available = $self->AvailableConnections( $net ); # randomized

	print STDERR "c ";

	do {
		$new = Copy( $net );
		$new->{'id'} = $id;
		$new->{'elite'} = 0;

		my ( $n, $c );
		my @nodes = keys %{$new->{'nodes'}};

		# if recurrency not allowed, find first non-recurrent 
		if ( ! $self->{'settings'}->{'allow-recurrent'} ) {
			my $found = 0;
			while ( @available && ! $found ) {
				( $n, $c ) = split( ":", $available[0] );
				if ( IsRecurrent( $new, $c, $n, 1 ) ) {
					shift @available;
				} else {
					$found = 1;
				}
			}
		}

		# if there is NOT one to be added, then split, instead.
		if ( ! defined( $available[0] ) ) {
			return $self->ConnectionSplit( $net );
		}
			
		( $n, $c ) = split ":", $available[0];
		$new->{'nodes'}->{$n}->{$c} = ( rand() - 0.5 ) * 2;
		$topology = NetworkTopology( $new );
		shift @available;
	} while ( exists $self->{'topology-lookup'}->{$topology} );
	$self->AddTopology( $topology, $new );
	$self->{'offspring'}->{ $new->{'id'} } = $new;
	print STDERR "+ ";
}
sub ConnectionRemove
{
	my ( $self, $net ) = @_;
	my $id = $self->UniqueID();
	my $new;
	my $topology;
	my ( $n, $c );
	my @existing = ExistingConnections( $net ); # randomized

	print STDERR "x ";
	do {
		return if ( ! defined( $existing[0] ) );
		$new = Copy( $net );
		$new->{'id'} = $id;
		$new->{'elite'} = 0;

		( $n, $c ) = split ":", $existing[0];
		delete $new->{'nodes'}->{$n}->{$c};
		$topology = NetworkTopology( $new );

		shift @existing;
	} while ( exists $self->{'topology-lookup'}->{$topology} );
	$self->AddTopology( $topology, $new );
	$self->{'offspring'}->{ $new->{'id'} } = $new;
	print STDERR "- ";
}
sub ConnectionSplit
{
	my ( $self, $net ) = @_;
	my $id = $self->UniqueID();
	my $new;
	my $topology;
	my $key;

	my ( $n, $c );
	my @existing = ExistingConnections( $net );
	
	print STDERR "n ";
	
	do {
		$key = $existing[0];  
		shift @existing;
		return unless defined $key;

		$new = Copy( $net );
		$new->{'id'} = $id;
		$new->{'elite'} = 0;

		if ( exists( $self->{'node-lookup'}->{$key} ) ) {
			# re-use old node ID
			$id = $self->{'node-lookup'}->{$key};
		} else {
			# make a new node ID
			$id = $self->UniqueID();
			$self->{'node-lookup'}->{$key} = $id;
			$self->{'nodes'}->{$id} = {
				'id' => $id,
				'type' => 'hidden',
				'function' => 'sigmoid',
				'gain' => $self->{'settings'}->{'gain'},
				'formed' => $key
				};
		}
		# identify endpoints of connection to split
		( $n, $c ) = split ":", $key;
		# make a connection between $n and the new node
		$new->{'nodes'}->{$n}->{$id} = $new->{'nodes'}->{$n}->{$c};
		# between the new and the old connection end point
		$new->{'nodes'}->{$id} = { $c => 1 };
		# delete the old connection
		delete $new->{'nodes'}->{$n}->{$c};
		# if there isn't a connection between the old node and the BIAS node
		# make one
		if ( ! exists $new->{'nodes'}->{$n}->{'bias'} ) {
			$new->{'nodes'}->{$n}->{'bias'} = 0;
		}
		# if there isn't a connection between the new node and the bias,
		# create one
		if ( ! exists $new->{'nodes'}->{$id}->{'bias'} ) {
			$new->{'nodes'}->{$id}->{'bias'} = 0;
		}
		$topology = NetworkTopology( $new );
	} while ( exists $self->{'topology-lookup'}->{$topology} );
	$self->AddTopology( $topology, $new );
	$self->{'offspring'}->{ $new->{'id'} } = $new;
	print STDERR "+ ";
}
# support functions
sub NewWeight
{
	my ( $self, $old ) = @_;
	my $new;
	if ( defined ( $old ) ) {
		# adjust up or down by up to 10 percent
		$new = $old + ( $old * ( ( rand() - 0.5 ) * 0.2 ) );
	} else {
		my $min = $self->{'save'}->{'min-weight'};
		my $range = $self->{'save'}->{'max-weight'} - $min;
		$new = ( rand() * $range ) + $min;
	}
	my $limit =	$self->{'settings'}->{'max-weight'};
	$new = $limit if ( $new > $limit );
	$limit *= -1;
	$new = $limit if ( $new < $limit );
	$self->{'save'}->{'max-weight'} = $new if ( $new > $self->{'save'}->{'max-weight'} );
	$self->{'save'}->{'min-weight'} = $new if ( $new < $self->{'save'}->{'min-weight'} );
	return $new;
}
sub LoadData
{
	my ( $file ) = @_;
	my $def;
	my $data;
	local $/; # load entire file at once
	open FILE, "<$file" or
		die "failed to open file for input:\n  $file\n Error: $!\n";
	$def = <FILE>;
	close FILE;
	eval $def;  # SHOULD set $data if saved via SaveData
	return $data;
}
sub SaveData
{
	my ( $data, $file ) = @_;
	open SAVE, ">$file" or 
		die "failed to open file for output:\n  $file\n Error: $!\n";
	$Data::Dumper::Indent = 1;
	print SAVE Data::Dumper->Dump( [$data], ["data"] );
	close SAVE;
}
sub Copy
{
	my $data = shift;
	my $copy;
	eval Data::Dumper->Dump( [$data], ["copy"] );
	return $copy;
}
sub RandomOrder
{
	my @list = @_;
	my ( $i, $j, $temp );

	for ( $i = 0 ; $i <= $#list ; $i++ ) {
		$j = int( rand() * @list );
		$temp = $list[$i];
		$list[$i] = $list[$j];
		$list[$j] = $temp;
	}
	return @list;
}
sub NetworkTopology
{
	my $net = shift;
	my $node;
	my $cx;
	my @nodes;
	my @connections;

	# make a list of nodes
	@nodes = sort keys %{$net->{'nodes'}};
	# make a list of connections
	foreach $node ( @nodes ) {
		foreach $cx ( keys %{$net->{'nodes'}->{$node}} ) {
			push @connections, "${node}:${cx}";
		}
	}
	# sort the connection list
	@connections = sort @connections;

	# return the topology string
	return "N=" . (join ",", @nodes) . ";" .
			"C=" . ( join ",", @connections);
}
sub ActivationOrder
{
	my ( $net, $node, $order, $seen ) = @_;
	if ( defined( $node ) ) {
		foreach my $next ( sort keys %{$net->{'nodes'}->{$node}} ) {
			if ( ! exists $seen->{$next} ) {
				$seen->{$next} = 1;
				ActivationOrder( $net, $next, $order, $seen );
			}
		}
		push @{$order}, $node;
	}
	else
	{
		foreach $node ( sort keys %{$net->{'nodes'}} ) {
			next if $seen->{$node};
			$seen->{$node} = 1;
			ActivationOrder( $net, $node, $order, $seen );
		}
	}
}
sub ExistingConnections
{
	my $net = shift;
	my $node;
	my $connection;
	my @list;
	# make a list of all existing connections
	foreach $node ( keys %{$net->{'nodes'}} ) {
		foreach $connection ( keys %{$net->{'nodes'}->{$node}} ) {
			push @list, "${node}:${connection}";
		}
	}
	return RandomOrder( @list );
}
sub IsRecurrent
{
	# %seen should only include ancestors, not siblings, in the tree
	my ( $net, $start, %seen ) = @_;

	return 1 if ( $seen{$start} ); # handles directly recurrent
	$seen{$start} = 1;
	my @list = keys %{$net->{'nodes'}->{$start}};
	my $n;
	foreach $n ( @list ) {
		return 1 if ( exists( $seen{$n} ) );
		return 1 if ( IsRecurrent( $net, $n, %seen ) );
	}
	return 0;
}
sub DebugOut
{
	printf( @_ ) if ( $DEBUG );
}
# activation functions
sub sigmoid
{
	my ( $x, $a ) = @_;
	return 1 / ( 1 + exp( - $a * $x ) );
}
sub sum
{
	my ( $x, $a ) = @_;
	return $x * $a;
}

1;
