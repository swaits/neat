#ifndef __NeuronGene_h__
#define __NeuronGene_h__

#include "Gene.h"

class Innovator;

class NeuronGene: public Gene
{
public:

	// neuron types
	enum
	{
		UNKNOWN,
		BIAS,
		INPUT,
		OUTPUT,
		HIDDEN
	};

	// construct a bias neuron
	NeuronGene(Innovator& innovator);

	// construct in input or output neuron
	NeuronGene(Innovator& innovator, int type, int index, int total);

	// create a hidden neuron between two other neurons
	NeuronGene(Innovator& innovator, const NeuronGene& prev, const NeuronGene& next);

	bool operator< (const NeuronGene& rhs) const;
	bool operator== (const NeuronGene& rhs) const;
	
	int GetType() const;
	float GetX() const;
	float GetY() const;

private:

	float m_x_position;
	float m_y_position;
	int m_type;
};

#endif // __NeuronGene_h__

