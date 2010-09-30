#include "Random.h"

#include <algorithm>
#include <cstdarg>
#include <cstdlib>

#include "IteratorHelper.h"
#include "NEAT.h"

static float Random()
{
	return (float)rand() / (float)RAND_MAX;
}

float RandomFloatRange(float min, float max)
{
	if ( max < min )
	{
		std::swap(min,max);
	}

	return (Random() * (max - min)) + min;
}

float RandomWeight()
{
	return RandomFloatRange(-NEAT::kMaxNewWeight,NEAT::kMaxNewWeight);
}

bool RandomBool()
{
	return ((rand() % 2) == 0);
}

float RandomPreturbation()
{
	return RandomFloatRange(-NEAT::kMaxWeightPerturbation,NEAT::kMaxWeightPerturbation);
}

int RandomRange(int min, int max)
{
	return (rand() % (max - min + 1)) + min;
}

bool RandomChance(float pSuccess)
{
	return Random() <= pSuccess;
}

int RandomZeroBiased(int max)
{
	float fmin = (float)-max;
	float fmax = (float)max;
	float fsum = 0.0f;

	for (int i=0;i<6;++i)
	{
		fsum += RandomFloatRange(fmin,fmax);
	}
	if ( fsum < 0.0f )
	{
		fsum = -fsum;
	}
	return (int)(fsum / 6.0f);
}

int Roulette(int n, ...)
{
	// store the arguments so we can use them more easily
	va_list args;
	va_start(args,n);
	std::vector<float> weights;
	iterate_times(n)
	{
		weights.push_back((float)va_arg(args,double));
	}
	va_end(args);
	
	// sum them
	float sum = 0.0;
	iterate_each(std::vector<float>::iterator, it, weights)
	{
		sum += (*it);
	}
	
	// roll the dice
	float roll = RandomFloatRange(0.0f, sum);
	
	// see where it falls
	sum = 0.0f;
	for( unsigned int i = 0; i < weights.size(); ++i )
	{
		sum += weights[i];
		if ( roll <= sum )
		{
			return i;
		}
	}
	
	// failure, should not get here!
	assert(0);
	return -1;
}
