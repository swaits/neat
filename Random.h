#ifndef __Random_h__
#define __Random_h__

int RandomRange(int min, int max); // [min,max]
float RandomFloatRange(float min, float max);
float RandomWeight();
float RandomPreturbation();
bool RandomBool();
bool RandomChance(float pSuccess);
int RandomZeroBiased(int max);
int Roulette(int n, ...);

#endif // __Random_h__

