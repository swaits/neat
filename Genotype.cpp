#include "Genotype.h"

#include <cassert>
#include <cmath>

#include "IteratorHelper.h"
#include "MathHelper.h"
#include "NEAT.h"
#include "Random.h"


Genotype::Genotype(Innovator& innovator, int num_inputs, int num_outputs)
{
	assert(num_inputs > 0 && num_inputs > 0);

	// create bias neuron
	Neurons.push_back( NeuronGene(innovator) );

	// create input neurons
	for (int i=0;i<num_inputs;++i)
	{
		Neurons.push_back( NeuronGene(innovator,NeuronGene::INPUT,i,num_inputs) );
	}

	// create output neurons
	for (int i=0;i<num_outputs;++i)
	{
		Neurons.push_back( NeuronGene(innovator,NeuronGene::OUTPUT,i,num_outputs) );
	}

	// connect the bias and each input to each output
	for (int i=0;i<(num_inputs+1);++i)
	{
		for (int j=(num_inputs+1);j<(num_inputs+num_outputs+1);++j)
		{
			Connections.push_back( ConnectionGene(innovator,Neurons[i].GetInnovation(),Neurons[j].GetInnovation()) );
		}
	}
}

Genotype::Genotype(const Genotype& mom, const Genotype& dad)
{
	// assuming that the mom is the more fit parent, NEAT crossover can
	// be simplified to:
	// 1. copy the mom
	// 2. for each shared mom/dad connection gene, randomly replace that gene in the mom with the one from the dad

	// step one, copy the mom directly
	Neurons     = mom.Neurons;
	Connections = mom.Connections;

	// step two, randomly replace shared connection genes from dad into mom
	iterate_each ( std::vector<ConnectionGene>::const_iterator, it_dad, dad.Connections )
	{
		// see if mom has matching gene, via brute force search
		iterate_each( std::vector<ConnectionGene>::iterator, it_mom, Connections )
		{
			// does this one match?  and, does the PRNG say we should do it?
			if ( RandomBool() && (*it_mom) == (*it_dad) )
			{
				// yes, there's a match, make the swap
				(*it_mom) = (*it_dad);
				break;
			}
		}
	}
	
	// TODO - handle case where mom & dad have the same fitness
}

void Genotype::MutateConnectionWeights()
{
	// mutate every connection
	iterate_each ( std::vector<ConnectionGene>::iterator, it, Connections )
	{
		(*it).Mutate();
	}
}

bool Genotype::MutateAddNeuron(Innovator& innovator, int retries)
{
	// pointers to the two neurons we're adding a neuron in between
	NeuronGene* input;
	NeuronGene* output;

	// figure out a connection to split
	size_t connection_id;
	int i;
	for (i=0;i<retries;++i)
	{
		// choose a random connection
		connection_id = RandomRange(0,(int)Connections.size()-1);

		// make certain this connection is enabled
		if ( !Connections[connection_id].IsEnabled() )
		{
			// don't split disabled connections
			continue;
		}

		// get the new neurons on either side of the chosen connection
		input  = GetNeuronByInnovation(Connections[connection_id].GetInputNeuron());
		output = GetNeuronByInnovation(Connections[connection_id].GetOutputNeuron());
		assert(input && output);

		// see if that node exists and is already in this genotype
		int new_id = innovator.FindNeuronInnovation((*input).GetInnovation(),(*output).GetInnovation());
		if ( new_id >= 0 && GetNeuronByInnovation(new_id) )
		{
			// neuron already exists in this individual
			continue;
		}

		// make sure we're not splitting a recurrent link
		// TODO

		// make sure we're not splitting a looped link
		if ( (*input) == (*output) )
		{
			// no sense in splitting a looped link
			continue;
		}

		// make sure we're not splitting a bias neuron
		if ( input->GetType() == NeuronGene::BIAS )
		{
			// no sense in splitting bias neurons
			continue;
		}

		// if we get here, we have a good split
		break;
	}

	// if we found nothing, bail out
	if ( i >= retries )
	{
		return false;
	}

	// disable it
	Connections[connection_id].Disable();

	// create a nueron splitting these two nodes
	NeuronGene new_neuron = NeuronGene(innovator,*input,*output);

	// link the new node in with two new connections
	float orig_weight = Connections[connection_id].GetWeight();
	Connections.push_back( ConnectionGene(innovator,(*input).GetInnovation(),new_neuron.GetInnovation(),1.0f) );
	Connections.push_back( ConnectionGene(innovator,new_neuron.GetInnovation(),(*output).GetInnovation(),orig_weight) );

	// finally, add neuron to our list
	// this invalidates the input, output pointers used above
	Neurons.push_back(new_neuron);

	return true;
}

bool Genotype::MutateAddConnection(Innovator& innovator, int retries)
{
	// decide if this will be a looped, recurrent, or forward connection
	
	while (retries--)
	{
		// choose two random neurons
		int neuron_a_id = RandomRange(0,(int)Neurons.size()-1);
		int neuron_b_id = RandomRange(0,(int)Neurons.size()-1);
		
		// make sure target is not bias or input neuron
		if ( Neurons[neuron_b_id].GetType() == NeuronGene::BIAS || Neurons[neuron_b_id].GetType() == NeuronGene::INPUT )
		{
			// TODO could skip this if we'd just select from (m_num_inputs+1,num_neurons) instead of (0,num_neurons)
			continue;
		}
		
		// check for loop
		if ( neuron_a_id == neuron_b_id )
		{
			// TODO this could actually be allowed
			continue;
		}

		// check for recurrent
		if ( IsRecurrent(neuron_a_id,neuron_b_id) )
		{
			// make forward
			std::swap(neuron_a_id,neuron_b_id);
		}
		
		// see if this connection exists
		if ( GetConnectionByNeuron(Neurons[neuron_a_id].GetInnovation(),Neurons[neuron_b_id].GetInnovation()) )
		{
			// exists
			continue;
		}
		
		// we got a match, add the connection
		Connections.push_back( ConnectionGene(innovator,Neurons[neuron_a_id].GetInnovation(),Neurons[neuron_b_id].GetInnovation()) );
		return true;
	}
	
	// nothing found
	return false;
}


NeuronGene* Genotype::GetNeuronByInnovation(int innovation)
{
	// search every neuron for this innovation
	iterate_each ( std::vector<NeuronGene>::iterator, it, Neurons )
	{
		if ( (*it).GetInnovation() == innovation )
		{
			return &(*it);
		}
	}

	return 0;
}

ConnectionGene* Genotype::GetConnectionByNeuron(int from_neuron, int to_neuron)
{
	// search for every connection that matches these neurons
	iterate_each ( std::vector<ConnectionGene>::iterator, it, Connections )
	{
		if ( (*it).GetInputNeuron() == from_neuron && (*it).GetOutputNeuron() == to_neuron )
		{
			return &(*it);
		}
	}
	
	// nothing found
	return 0;
}

bool Genotype::IsRecurrent(int from_neuron, int to_neuron)
{
	return
		(Neurons[to_neuron].GetY() < Neurons[from_neuron].GetY()) ||
		(Neurons[to_neuron].GetY() == Neurons[from_neuron].GetY() && Neurons[to_neuron].GetY() < Neurons[from_neuron].GetY());
}

void Genotype::Output()
{
	static char* typestr[5] = { "unknown", "bias", "input", "output", "hidden" };

	printf("\n");
	for (size_t i=0;i<Neurons.size();++i)
	{
		printf("neuron %d %s\n",Neurons[i].GetInnovation(),typestr[Neurons[i].GetType()]);
	}
	for (size_t i=0;i<Connections.size();++i)
	{
		if ( Connections[i].IsEnabled() )
		{
			printf("connection %3d %3d %0.10f\n",Connections[i].GetInputNeuron(),Connections[i].GetOutputNeuron(),Connections[i].GetWeight());
		}
	}
}

void Genotype::SetFitness(float fitness)
{
	Fitness = fitness;
}

float Genotype::GetFitness() const
{
	return Fitness;
}

bool Genotype::operator< (const Genotype& rhs) const
{
	return Fitness < rhs.Fitness;
}

float Genotype::GetCompatibility(const Genotype& genome) const
{
	int disjoint_excess = 0, common = 0;
	float weight_diff = 0.0f;

	iterate_each ( std::vector<ConnectionGene>::const_iterator, it_lhs, Connections )
	{
		bool match = false;
		iterate_each ( std::vector<ConnectionGene>::const_iterator, it_rhs, genome.Connections )
		{
			if ( (*it_lhs) == (*it_rhs) )
			{
				weight_diff += fabs((*it_lhs).GetWeight() - (*it_rhs).GetWeight());
				match = true;
				break;
			}
		}
		if ( match )
		{
			++common;
		}
		else
		{
			++disjoint_excess;
		}
	}

	size_t lhs_size = Connections.size() + Neurons.size();
	size_t rhs_size = genome.Connections.size() + genome.Neurons.size();
	size_t N = std::max(lhs_size, rhs_size);
	float weight_diff_avg = weight_diff / (float)common;
	return ((float)disjoint_excess/(float)N) + (0.4f * weight_diff_avg);
}

void Genotype::Mutate(Innovator& innovator)
{
	switch ( Roulette(3,NEAT::pAddConnection,NEAT::pAddNeuron,NEAT::pWeightsMutated))
	{
		case 0:
			MutateAddConnection(innovator);
			break;
			
		case 1:
			MutateAddNeuron(innovator);
			break;
			
		case 2:
			MutateConnectionWeights();
			break;
			
		default:
			break;
	}
}

