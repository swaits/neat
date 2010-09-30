#ifndef __NeuralNetwork_h__
#define __NeuralNetwork_h__

#include "Genotype.h"


class NeuralNetwork
{
public:
	
	NeuralNetwork(const Genotype& genotype);
	virtual ~NeuralNetwork();

	void Reset();
	void Update(const std::vector<float>& inputs, std::vector<float>& outputs);  // TODO make input STL-like, begin(), end() & array compatible

private:

	struct Connection
	{
		Connection(int id, float weight):
			id(id),
			weight(weight)
		{
			// empty
		}

		int id;
		float weight;
	};

	struct Neuron
	{
		Neuron(int id, float x, float y, bool fixed=false, float activation=0.0);

		bool operator< (const Neuron& rhs) const;

		int ID;
		float X,Y;
		bool Fixed;
		float Activation;
		std::vector<Connection> Inputs;
	};

	std::vector<Neuron> Neurons;
	int NumInputs, NumOutputs;

	int GetNeuronIndexFromID(int id);

};

#endif // __NeuralNetwork_h__

