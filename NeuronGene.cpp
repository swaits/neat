#include "NeuronGene.h"

#include <cassert>

#include "Innovator.h"

// construct a bias neuron
NeuronGene::NeuronGene(Innovator& innovator) :
	Gene( innovator.GetNeuronInnovation(-1,-1,m_x_position,m_y_position) ),
	m_x_position(0.0f),
	m_y_position(0.0f),
	m_type(BIAS)
{
	// empty
}

// construct input|output neuron
NeuronGene::NeuronGene(Innovator& innovator, int type, int index, int total) :
	m_type(type)
{
	assert(type == INPUT || type == OUTPUT);

	if ( type == INPUT )
	{
		m_x_position = (float)(index+1)/(float)(total);
		m_y_position = 0.0f;
		m_innovation = innovator.GetNeuronInnovation(-(index+2),-1,m_x_position,m_y_position);
	}
	else
	{
		m_x_position = (float)(index+1)/(float)(total+1); // TODO this isn't in the right position
		m_y_position = 1.0f;
		m_innovation = innovator.GetNeuronInnovation(-1,-(index+2),m_x_position,m_y_position);
	}
}

// construct hidden neuron
NeuronGene::NeuronGene(Innovator& innovator, const NeuronGene& prev, const NeuronGene& next) :
	Gene( innovator.GetNeuronInnovation(prev.m_innovation,next.m_innovation,m_x_position,m_y_position) ),
	m_x_position((prev.m_x_position+next.m_x_position)/2.0f),
	m_y_position((prev.m_y_position+next.m_y_position)/2.0f),
	m_type(HIDDEN)
{
	// empty
}

bool NeuronGene::operator< (const NeuronGene& rhs) const
{
	return static_cast<Gene>(*this) < rhs;
}

bool NeuronGene::operator== (const NeuronGene& rhs) const
{
	return static_cast<Gene>(*this) == rhs;
}


int NeuronGene::GetType() const
{
	return m_type;
}

float NeuronGene::GetX() const
{
	return m_x_position;
}

float NeuronGene::GetY() const
{
	return m_y_position;
}
