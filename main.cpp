#include <cstdio>
#include <cstdlib>
#include <ctime>

#include "NEAT.h"

#include "IteratorHelper.h"

class MyNEAT: public NEAT
{
public:
	MyNEAT(int num_inputs, int num_outputs) : NEAT(num_inputs,num_outputs)
	{
		// empty
	}
	
	virtual bool TestNetworks(std::vector<NeuralNetwork>& networks, std::vector<float>& fitness)
	{
		bool solution_found = false;
		iterate_each( std::vector<NeuralNetwork>::iterator, it_network, networks )
		{
			std::vector<float> inputs;
			std::vector<float> outputs;
			float error_sum = 0.0f;
			float error;
			int hits = 0;

			#define ON  (1.0f)
			#define OFF (0.0f)

			// 0, 0 = 0
			inputs.push_back(OFF);
			inputs.push_back(OFF);
			(*it_network).Reset();
			(*it_network).Update(inputs,outputs);
			error = outputs[0] - OFF;
			error_sum += error * error;
			if ( outputs[0] < 0.44f )
			{
				++hits;
			}

			// 0, 1 = 1
			inputs.clear();
			inputs.push_back(OFF);
			inputs.push_back(ON);
			(*it_network).Reset();
			(*it_network).Update(inputs,outputs);
			error = outputs[0] - ON;
			error_sum += error * error;
			if ( outputs[0] > 0.6f )
			{
				++hits;
			}

			// 1, 0 = 1
			inputs.clear();
			inputs.push_back(ON);
			inputs.push_back(OFF);
			(*it_network).Reset();
			(*it_network).Update(inputs,outputs);
			error = outputs[0] - ON;
			error_sum += error * error;
			if ( outputs[0] > 0.6f )
			{
				++hits;
			}

			// 1, 1 = 0
			inputs.clear();
			inputs.push_back(ON);
			inputs.push_back(ON);
			(*it_network).Reset();
			(*it_network).Update(inputs,outputs);
			error = outputs[0] - OFF;
			error_sum += error * error;
			if ( outputs[0] < 0.5f )
			{
				++hits;
			}
			
			// average
			error_sum /= 4.0f;

			// store
			fitness.push_back(error_sum);
			//printf("error = %0.5f\n",error_sum);
			
			// did we solve it?
			if ( hits == 4 )
			{
				solution_found = true;
			}
		}		
		//printf("\n");
		return solution_found;
	}
	
};

int main (int argc, char * const argv[])
{
	MyNEAT n(2,1);

	srand( (unsigned)time( NULL ) );
  
	n.Run();
	
	return 0;
}
