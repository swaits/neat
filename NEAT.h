#ifndef __NEAT_h__
#define __NEAT_h__

#include "Genotype.h"
#include "Innovator.h"
#include "NeuralNetwork.h"

class NEAT
{
public:
	const static int   kPopulation; // size of population
	const static float kC1; // coefficient for excess genes in compatibility equation
	const static float kC2; // coefficient for disjoint genes in compatibility equation
	const static float kC3; // coefficient for weight delta in compatibility equation
	const static float kCompatibilityThreshold; // used in speciation
	const static int   kNumUnimprovedGensAllowed; // # generations a species is allowed to not improve
	const static int   kMinSpeciesSizeForChampionReproduction; // species must be at least this big
	const static float pWeightsMutated; // chance a genome has its weights mutated
	const static float pUniformWeightPerturbation; // each weight's chance of uniform perturbation
	const static float pAssignNewWeight; // each weight's chance of getting replaced
	const static float pInheritedGeneDisabled; // chance gene disabled if it was disabled in either parent
	const static float pMutationOnly; // chance of reproduction through mutation, without crossover
	const static float kInterSpeciesRate; // inter-species mating rate
	const static float pAddNeuron; // chance of adding a neuron (mutation)
	const static float pAddConnection; // chance of adding a new connection (mutation)
	const static float kMaxWeightPerturbation; // +/- weight perturbation (mutation)
	const static float kMaxNewWeight; // +/- range for new weights
	
	NEAT(int num_inputs, int num_outputs);

	void Run();
		
protected:
	
	virtual bool TestNetworks(std::vector<NeuralNetwork>& networks, std::vector<float>& fitness) = 0;
	
private:

	struct Species
	{
		Species(const Genotype& originator, int originator_id, int species_id);

		int              species_id;
		Genotype         representative;
		std::vector<int> member_ids;
	};

	Innovator m_innovator;
	std::vector<Genotype> m_population;
	std::vector<Genotype> m_best;
	std::vector<Species> m_species;
	int m_next_species_id;
	
	void SortPopulation();
	void SaveBestGenomes();
	void SpeciatePopulation();
	void AdjustAndShareFitness();
	void Reproduce();
};

#endif // __NEAT_h__





