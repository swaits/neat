#ifndef __Innovator_h__
#define __Innovator_h__

#include <vector>

class Innovator
{
public:

	int GetConnectionInnovation(int input_id, int output_id);

	int GetNeuronInnovation(int prev_id, int next_id, float pos_x, float pos_y);

	int FindNeuronInnovation(int prev_id, int next_id);

	void Update();

private:

	// data structure used to track innovations
	struct Innovation
	{
		// data
		int in_id, out_id, innovation_id;
		int type;
		float pos_x, pos_y;
	
		// innovation types
		enum
		{
			UNKNOWN,
			NEURON,
			CONNECTION
		};

		// construct an innovation
		Innovation(int type, int in_id, int out_id, float pos_x = 0.0f, float pos_y = 0.0f);
	
		// used for sorting, searching
		bool operator<(const Innovation& rhs) const;
		bool operator==(const Innovation& rhs) const;
	};

private:

	// look in the list for a matching innovation to the one passed in
	Innovation GetInnovation(Innovation& target);

	// master list of our innovations
	std::vector<Innovation> m_innovations;

	// temporary (smaller) list of current new innovations, rolls into master list on calls to Update
	std::vector<Innovation> m_new_innovations;
};

#endif // __Innovator_h__

