#include "ConnectionGene.h"

#include "Innovator.h"
#include "NEAT.h"
#include "Random.h"

ConnectionGene::ConnectionGene(Innovator& innovator, int input_id, int output_id) :
	Gene(innovator.GetConnectionInnovation(input_id,output_id)),
	m_in_node(input_id),
	m_out_node(output_id),
	m_weight(RandomWeight()),
	m_enabled(true)
{
}

ConnectionGene::ConnectionGene(Innovator& innovator, int input_id, int output_id, float weight) :
	Gene(innovator.GetConnectionInnovation(input_id,output_id)),
	m_in_node(input_id),
	m_out_node(output_id),
	m_weight(weight),
	m_enabled(true)
{
}

void ConnectionGene::Mutate()
{
	if ( RandomChance(NEAT::pUniformWeightPerturbation) )
	{
		m_weight += RandomPreturbation();
	}
	else 
	{
		m_weight = RandomWeight();
	}
}

void ConnectionGene::Disable()
{
	m_enabled = false;
}

void ConnectionGene::Enable()
{
	m_enabled = true;
}

bool ConnectionGene::IsEnabled() const
{
	return m_enabled;
}

int ConnectionGene::GetInputNeuron() const
{
	return m_in_node;
}

int ConnectionGene::GetOutputNeuron() const
{
	return m_out_node;
}

bool ConnectionGene::operator< (const ConnectionGene& rhs) const
{
	return static_cast<Gene>(*this) < rhs;
}

bool ConnectionGene::operator== (const ConnectionGene& rhs) const
{
	return static_cast<Gene>(*this) == rhs;
}

float ConnectionGene::GetWeight() const
{
	return m_weight;
}

