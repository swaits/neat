#include "Gene.h"

Gene::Gene() :
	m_innovation(-1)
{
	// empty
}

Gene::Gene(int innovation) :
	m_innovation(innovation)
{
	// empty
}

Gene::~Gene()
{
	// empty
}

int Gene::GetInnovation() const
{
	return m_innovation;
}

bool Gene::operator< (const Gene& rhs) const
{
	return m_innovation < rhs.m_innovation;
}

bool Gene::operator== (const Gene& rhs) const
{
	return
		(m_innovation     != -1) && 
		(rhs.m_innovation != -1) && 
		(m_innovation     == rhs.m_innovation);
}

