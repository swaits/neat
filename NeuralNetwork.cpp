#include "NeuralNetwork.h"

#include <algorithm>
#include <cassert>
#include <cmath>

#include "IteratorHelper.h"

NeuralNetwork::Neuron::Neuron(int id, float x, float y, bool fixed, float activation):
	ID(id),
	X(x),
	Y(y),
	Fixed(fixed),
	Activation(activation)
{
	// empty
}

bool NeuralNetwork::Neuron::operator< (const NeuralNetwork::Neuron& rhs) const
{
	return
		(Y < rhs.Y) ||
		((Y == rhs.Y) && (X < rhs.X));
}

NeuralNetwork::NeuralNetwork(const Genotype& genotype)
{
	// reset out input/output count
	NumInputs = NumOutputs = 0;

	// copy the neurons
	for ( std::vector<NeuronGene>::const_iterator it = genotype.Neurons.begin(); it != genotype.Neurons.end(); ++it )
	{
		switch ( (*it).GetType() )
		{
			case NeuronGene::BIAS:
				Neurons.push_back(Neuron((*it).GetInnovation(),(*it).GetX(),(*it).GetY(),true,1.0));
				break;

			case NeuronGene::INPUT:
				++NumInputs;
				Neurons.push_back(Neuron((*it).GetInnovation(),(*it).GetX(),(*it).GetY(),true,0.0));
				break;

			case NeuronGene::OUTPUT:
				++NumOutputs;
				// fall through

			case NeuronGene::HIDDEN:
				Neurons.push_back(Neuron((*it).GetInnovation(),(*it).GetX(),(*it).GetY()));
				break;
		}
	}

	// sort neurons by position
	std::sort(Neurons.begin(), Neurons.end());

	// copy the connections
	for ( std::vector<ConnectionGene>::const_iterator it = genotype.Connections.begin(); it != genotype.Connections.end(); ++it )
	{
		if ( (*it).IsEnabled() )
		{
			// figure out which two neurons this thing connects
			int index_a = GetNeuronIndexFromID((*it).GetInputNeuron());
			int index_b = GetNeuronIndexFromID((*it).GetOutputNeuron());
			assert(index_a < (int)Neurons.size() && index_b < (int)Neurons.size());

			// now add to the neuron
			Neurons[index_b].Inputs.push_back( Connection(index_a,(*it).GetWeight()) );
		}
	}

	// print out this network
	#if 0
	int i = 0;
	iterate_each ( std::vector<Neuron>::iterator, it_neuron, Neurons )
	{
		printf("Neuron %2d (%2d) %0.2f %0.2f\n",i,(*it_neuron).ID,(*it_neuron).X,(*it_neuron).Y);
		iterate_each ( std::vector<Connection>::iterator, it_connection, (*it_neuron).Inputs )
		{
			printf("       %d %0.5f\n",(*it_connection).id,(*it_connection).weight);
		}
		++i;
	}
	#endif
}


NeuralNetwork::~NeuralNetwork()
{
}

void NeuralNetwork::Reset()
{
	iterate_each ( std::vector<Neuron>::iterator, it_neuron, Neurons )
	{
		if ( !(*it_neuron).Fixed )
		{
			(*it_neuron).Activation = 0.0;
		}
	}
}

void NeuralNetwork::Update(const std::vector<float>& inputs, std::vector<float>& outputs)  // TODO make input STL-like, begin(), end() & array compatible
{
	// assign inputs
	for ( int i=0;i<NumInputs;++i )
	{
		// TODO range check this!!!
		Neurons[i+1].Activation = inputs[i];  // +1 is because Bias is #0 - this is messy TODO: clean up, make safer
		// TODO make sure this is really an input Neuron!!!  and its ID matches up, etc.
	}

	// update each neuron
	iterate_each ( std::vector<Neuron>::iterator, it_neuron, Neurons )
	{
		// if this is a fixed neuron, skip
		if ( (*it_neuron).Fixed )
		{
			continue;
		}

		// sum the inputs into this neuron
		float sum = 0.0f;
		iterate_each ( std::vector<Connection>::iterator, it_connection, (*it_neuron).Inputs )
		{
			sum += Neurons[(*it_connection).id].Activation * (*it_connection).weight;
		}

		// activate
		(*it_neuron).Activation = 1.0f / (1.0f + (expf(-4.9f * sum)));
	}

	// clear outputs
	outputs.clear();

	// copy outputs
	for ( int i=0;i<NumOutputs;++i )
	{
		size_t index = Neurons.size() - NumOutputs + i;
		outputs.push_back( Neurons[index].Activation );
	}
}


int NeuralNetwork::GetNeuronIndexFromID(int id)
{
	for ( int i=0;i<(int)Neurons.size();++i )
	{
		if ( Neurons[i].ID == id )
		{
			return i;
		}
	}
	assert(0);
	return 0;
}


