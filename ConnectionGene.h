#ifndef __ConnectionGene_h__
#define __ConnectionGene_h__

#include "Gene.h"

class Innovator;

class ConnectionGene: public Gene
{
public:

	ConnectionGene(Innovator& innovator, int input_id, int output_id);
	ConnectionGene(Innovator& innovator, int input_id, int output_id, float weight);

	void Mutate();

	void Disable();
	void Enable();
	bool IsEnabled() const;

	int GetInputNeuron() const;
	int GetOutputNeuron() const;
	float GetWeight() const;

	bool operator< (const ConnectionGene& rhs) const;
	bool operator== (const ConnectionGene& rhs) const;

private:

	int m_in_node;
	int m_out_node;
	float m_weight;
	bool m_enabled;
};

#endif // __ConnectionGene_h__

