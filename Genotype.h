#ifndef __Genotype_h__
#define __Genotype_h__

#include <vector>

#include "ConnectionGene.h"
#include "NeuronGene.h"

class Innovator;

class Genotype
{
public:

	// construct a new random genotype
	Genotype(Innovator& innovator, int num_inputs, int num_outputs);
	
	// construct a new genotype via crossover
	Genotype(const Genotype& mom, const Genotype& dad);

	void Output();

	int CalculateLayers();
	
	void SetFitness(float fitness);
	float GetFitness() const;

	void Mutate(Innovator& innovator);
	
	bool operator< (const Genotype& rhs) const;
	
	// calculate compatibility with another genotype
	float GetCompatibility(const Genotype& genome) const;

private:

	// preturb weights
	void MutateConnectionWeights();

	// add a neuron
	bool MutateAddNeuron(Innovator& innovator, int retries=100);

	// add a connection
	bool MutateAddConnection(Innovator& innovator, int retries=100);



private:

	friend class NeuralNetwork;

	NeuronGene* GetNeuronByInnovation(int innovation); // todo could be a bool?
	ConnectionGene* GetConnectionByNeuron(int from_neuron, int to_neuron);
	bool IsRecurrent(int from_neuron, int to_neuron);

	std::vector<NeuronGene>     Neurons;
	std::vector<ConnectionGene> Connections;
	
	float Fitness;
};

#endif // __Genotype_h__

