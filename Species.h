#ifndef __Species_h__
#define __Species_h__

#include "Genotype.h"
#include <vector>

#if 0
class Species
{
public:
	
	Species(const Genotype& leader);
	
	void Reset();
	void AddMember(const Genotype& genome);
	bool AddIfCompatible(const Genotype& genome);
	void AdjustFitness();
	float GetFitness();
	
	Genotype Spawn() const;
	Genotype GetLeader() const;
	
private:
	
	Genotype m_leader;
	std::vector<Genotype> m_members;
	float m_spawn_amount;
};
#endif

#endif // __Species_h__
