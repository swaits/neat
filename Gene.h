#ifndef __Gene_h__
#define __Gene_h__

class Gene
{
public:

	Gene();
	Gene(int innovation);
	virtual ~Gene();

	int GetInnovation() const;

	bool operator< (const Gene& rhs) const;
	bool operator== (const Gene& rhs) const;

protected:

	int m_innovation;
};

#endif // __Gene_h__

