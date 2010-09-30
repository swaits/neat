#include "NEAT.h"

#include <algorithm>
#include <cassert>

#include "IteratorHelper.h"
#include "NeuralNetwork.h"
#include "Random.h"


const int NEAT::kPopulation = 150; // size of population
const float NEAT::kC1 = 1.0f; // coefficient for excess genes in compatibility equation
const float NEAT::kC2 = 1.0f; // coefficient for disjoint genes in compatibility equation
const float NEAT::kC3 = 0.4f; // coefficient for weight delta in compatibility equation
const float NEAT::kCompatibilityThreshold = 3.0f; // used in speciation
const int NEAT::kNumUnimprovedGensAllowed = 15; // # generations a species is allowed to not improve
const int NEAT::kMinSpeciesSizeForChampionReproduction = 5; // species must be at least this big
const float NEAT::pWeightsMutated = 0.8f; // chance a genome has its weights mutated
const float NEAT::pUniformWeightPerturbation = 0.9f; // each weight's chance of uniform perturbation
const float NEAT::pAssignNewWeight = 0.1f; // each weight's chance of getting replaced
const float NEAT::pInheritedGeneDisabled = 0.75f; // chance gene disabled if it was disabled in either parent
const float NEAT::pMutationOnly = 0.25f; // chance of reproduction through mutation, without crossover
const float NEAT::kInterSpeciesRate = 0.001f; // inter-species mating rate
const float NEAT::pAddNeuron = 0.03f; // chance of adding a neuron (mutation)
const float NEAT::pAddConnection = 0.05f; // chance of adding a new connection (mutation)
const float NEAT::kMaxWeightPerturbation = 0.1f; // +/- weight perturbation (mutation)
const float NEAT::kMaxNewWeight = 0.5f; // +/- range for new weights


/*
trait_param_mut_prob 0.5 
trait_mutation_power 1.0
linktrait_mut_sig 1.0
nodetrait_mut_sig 0.5
weigh_mut_power 2.5
recur_prob 0.00
disjoint_coeff 1.0
excess_coeff 1.0
mutdiff_coeff 0.4
compat_thresh 3.0
age_significance 1.0
survival_thresh 0.20
mutate_only_prob 0.25
mutate_random_trait_prob 0.1
mutate_link_trait_prob 0.1
mutate_node_trait_prob 0.1
mutate_link_weights_prob 0.9
mutate_toggle_enable_prob 0.00
mutate_gene_reenable_prob 0.000
mutate_add_node_prob 0.03
mutate_add_link_prob 0.05
interspecies_mate_rate 0.001
mate_multipoint_prob 0.6
mate_multipoint_avg_prob 0.4
mate_singlepoint_prob 0.0
mate_only_prob 0.2
recur_only_prob 0.0
pop_size 150
dropoff_age 15
newlink_tries 20
print_every 30
babies_stolen 0
num_runs 100
*/


NEAT::NEAT(int num_inputs, int num_outputs) :
	m_next_species_id(0)
{
	// create initial population
	iterate_times(NEAT::kPopulation)
	{
		m_population.push_back( Genotype(m_innovator, num_inputs, num_outputs) );
	}

}

void NEAT::SortPopulation()
{
	std::sort(m_population.begin(),m_population.end());
}

void NEAT::SaveBestGenomes()
{
	// add best of current population to best ever
	assert(m_population.size() >= 4);
	for( unsigned int i = 0; i < 4; ++i )
	{
		m_best.push_back( m_population[i] );
	}
	
	// sort
	std::sort(m_best.begin(),m_best.end());
	
	// kill off all but 4
	while ( m_best.size() > 4 )
	{
		m_best.pop_back();
	}
}

void NEAT::SpeciatePopulation()
{
	// clear old members out of all species, and choose a representative member in each species
	iterate_each( std::vector<Species>::iterator, it_species, m_species )
	{
		// make sure species is not dead
		if ( !(*it_species).member_ids.empty() )
		{
			// has members, just choose random as representative for next generation
			int rep_id = RandomRange(0,(int)(*it_species).member_ids.size()-1);
			(*it_species).representative = m_population[rep_id];
			(*it_species).member_ids.clear();
		}
	}
	
	// add each genome into a species, or create a new species if necessary
	for ( int i=0; i<(int)m_population.size(); ++i )
	{
		// test every species for compatibility with genome i
		bool added = false;
		iterate_each( std::vector<Species>::iterator, it_species, m_species )
		{
			// test genotype for compatibility with this species
			if ( (*it_species).representative.GetCompatibility(m_population[i]) < NEAT::kCompatibilityThreshold )
			{
				// add it
				(*it_species).member_ids.push_back(i);
				added = true;
				break;
			}
		}
		
		// if we didn't add this genome to any species, create one now
		if ( !added )
		{
			m_species.push_back(Species(m_population[i],i,m_next_species_id++));
		}
	}

	// kill off any dead species
	iterate_each( std::vector<Species>::iterator, it_species, m_species )
	{
		if ( (*it_species).member_ids.empty() )
		{
			// erase it
			// TODO - need to actually remove it???
		}
	}

	printf("%d species\n",m_species.size());
}

void NEAT::AdjustAndShareFitness()
{
	// fitness for each genome is divided by the total number of genomes in its species
	iterate_each( std::vector<Species>::iterator, it_species, m_species )
	{
		float divisor = (float)((*it_species).member_ids.size());
		iterate_each( std::vector<int>::iterator, it_member_id, (*it_species).member_ids )
		{
			float old_fitness = m_population[*it_member_id].GetFitness();
			float new_fitness = old_fitness / divisor;
			m_population[*it_member_id].SetFitness( new_fitness );
		}
	}
}


void NEAT::Reproduce()
{
	// get population size (we'll make sure it ends up with this many)
	size_t pop_size = m_population.size();
	
	// waste old population
	std::vector<Genotype> old_population(m_population);
	m_population.clear();
	
	// get total fitness (assumes already adjusted)
	float fitness_total = 0.0f;
	iterate_each( std::vector<Genotype>::iterator, it, old_population )
	{
		fitness_total += (*it).GetFitness();
	}
	
	// now have each species spawn amounts based on its share population average
	iterate_each( std::vector<Species>::iterator, it_species, m_species )
	{
		// ignore this species if it's dead
		if ( (*it_species).member_ids.empty() )
		{
			continue;
		}

		// sum total fitness for this species
		float species_fitness = 0.0f;
		iterate_each( std::vector<int>::iterator, it_member_id, (*it_species).member_ids )
		{
			species_fitness += old_population[*it_member_id].GetFitness();
		}

		// calculate how many to spawn
		float  fitness_share = species_fitness / fitness_total;
		size_t num_to_spawn  = (int)(fitness_share * (float)pop_size + 0.5f);
		
		// now do the reproductions
		// first one is simply the best in the species
		m_population.push_back( old_population[(*it_species).member_ids[0]] );

		// and fill up the rest with random based reproduction
		iterate_times(num_to_spawn-1)
		{
			// determine if this is sexual or asexual
			if ( RandomChance(NEAT::pMutationOnly) )
			{
				// asexual reproduction
				// choose one random genome from the species
				int survivor_count = (int)(*it_species).member_ids.size();
				if ( survivor_count < 1 )
				{
					survivor_count = 1;
				}
				int a = RandomZeroBiased(survivor_count-1);

				// copy
				Genotype g = old_population[a];

				// mutate
				g.Mutate(m_innovator);

				// add to population
				m_population.push_back(g);
			}
			else
			{
				// sexual reproduction
				// choose two random genomes from the species
				int survivor_count = (int)(*it_species).member_ids.size();
				if ( survivor_count < 1 )
				{
					survivor_count = 1;
				}
				int a = RandomZeroBiased(survivor_count-1);
				int b = RandomZeroBiased(survivor_count-1);
				if ( b < a )
				{
					std::swap(a,b);
				}

				// mate them
				Genotype g = Genotype(old_population[a], old_population[b]);

				// mutate
				g.Mutate(m_innovator);

				// add to population
				m_population.push_back( g );
			}
		}
	}
}

void NEAT::Run()
{
	iterate_times(10000)
	{
		// update the innovator
		m_innovator.Update();
		
		// build networks from genomes
		std::vector<NeuralNetwork> networks;
		iterate_each( std::vector<Genotype>::iterator, it_genotype, m_population )
		{
			networks.push_back( NeuralNetwork(*it_genotype) );
		}

		// test networks
		std::vector<float> fitness;
		bool finished = TestNetworks(networks,fitness);

		// store results
		assert(fitness.size() == m_population.size());
		for( unsigned int i = 0; i < fitness.size(); ++i )
		{
			m_population[i].SetFitness( fitness[i] );
		}

		// sort by fitness
		SortPopulation();

		// save off the best of the population
		SaveBestGenomes();
		
		// now quit if TestNetworks(..) returned true
		if ( finished )
		{
			return;
		}

		// speciate
		SpeciatePopulation();

		// adjust & share fitness
		AdjustAndShareFitness();

		// finally, create the new population
		Reproduce();
		
		printf("best fitness = %0.10f\n",m_best[0].GetFitness());
		m_best[0].Output();
	}
}

NEAT::Species::Species(const Genotype& originator, int originator_id, int species_id) :
	species_id(species_id),
	representative(originator)
{
	member_ids.push_back(originator_id);
}


