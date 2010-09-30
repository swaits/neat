#include "Species.h"

#include "IteratorHelper.h"
#include "Random.h"

#if 0

Species::Species(const Genotype& leader):
	m_leader(leader)
{
	m_members.push_back(m_leader);
}

void Species::Reset()
{
	m_members.clear();
}

void Species::AddMember(const Genotype& genome)
{
	m_members.push_back(genome);
	if ( genome < m_leader )
	{
		m_leader = genome;
	}
}

bool Species::AddIfCompatible(const Genotype& genome)
{
	if ( m_leader.GetCompatibility(genome) < 3.0f )
	{
		// yes, it's compatible, add it to this species
		AddMember(genome);
		return true;
	}

	// default case, not added
	return false;
}

void Species::AdjustFitness()
{
	float total_members = (float)m_members.size();
	iterate_each( std::vector<Genotype>::iterator, it, m_members )
	{
		(*it).SetFitness( (*it).GetFitness() / total_members );
	}
}

float Species::GetFitness()
{
	float total = 0.0f;
	iterate_each( std::vector<Genotype>::iterator, it, m_members )
	{
		total += (*it).GetFitness();
	}
	return total;
}

Genotype Species::Spawn() const
{
	int a = RandomRange(0,(int)m_members.size()-1);
	int b = RandomRange(0,(int)m_members.size()-1);
	return Genotype(m_members[a],m_members[b]);
}

Genotype Species::GetLeader() const
{
	return m_leader;
}

#endif

