#include "Innovator.h"

#include <algorithm>

#include "IteratorHelper.h"

Innovator::Innovation::Innovation(int type, int in_id, int out_id, float pos_x, float pos_y) : 
	in_id(in_id),
	out_id(out_id),
	innovation_id(-1),
	type(type),
	pos_x(pos_x),
	pos_y(pos_y)
{
	// empty
}

bool Innovator::Innovation::operator<(const Innovation& rhs) const
{
	// this method is really only used for sorting and searching
	return
		(type < rhs.type) ||
		(type == rhs.type && in_id  < rhs.in_id) ||
		(type == rhs.type && in_id == rhs.in_id && out_id < rhs.out_id);
}

bool Innovator::Innovation::operator==(const Innovation& rhs) const
{
	// equality ignores the innovation number
	return (in_id == rhs.in_id) && (out_id == rhs.out_id) && (type == rhs.type);
}



int Innovator::GetConnectionInnovation(int input_id, int output_id)
{
	Innovation target = Innovation(Innovation::CONNECTION, input_id, output_id);
	Innovation result = GetInnovation(target);
	return result.innovation_id;
}



int Innovator::GetNeuronInnovation(int prev_id, int next_id, float pos_x, float pos_y)
{
	Innovation target = Innovation(Innovation::NEURON, prev_id, next_id, pos_x, pos_y);
	Innovation result = GetInnovation(target);
	return result.innovation_id;
}

int Innovator::FindNeuronInnovation(int prev_id, int next_id)
{
	// TODO: this code is duplicated in GetInnovation() - refactor

	// create a temp neuron to search for
	Innovation target(Innovation::NEURON, prev_id, next_id, 0.0f, 0.0f);

	// search master innovation list
	std::vector<Innovation>::iterator result;
	result = std::lower_bound(m_innovations.begin(), m_innovations.end(), target);
	if ( result != m_innovations.end() && (*result) == target )
	{
		// found in master list
		return (*result).innovation_id;
	}

	// search new innovation list
	result = std::find(m_new_innovations.begin(), m_new_innovations.end(), target);
	if ( result != m_new_innovations.end() )
	{
		// found in new temp list
		return (*result).innovation_id;
	}

	// not found!
	return -1;
}

void Innovator::Update()
{
	// make sure we have something to process
	if ( m_new_innovations.size() == 0 )
	{
		return;
	}

	// copy new innovations into global innovations
	iterate_each ( std::vector<Innovation>::iterator, it, m_new_innovations )
	{
		m_innovations.push_back(*it);
	}

	// clear new innovations
	m_new_innovations.clear();

	// sort global innovations
	std::sort(m_innovations.begin(), m_innovations.end());
}



Innovator::Innovation Innovator::GetInnovation(Innovation& target)
{
	// search master innovation list
	std::vector<Innovation>::iterator result;
	result = std::lower_bound(m_innovations.begin(), m_innovations.end(), target);
	if ( result != m_innovations.end() && (*result) == target )
	{
		// found in master list
		return (*result);
	}

	// search new innovation list
	result = std::find(m_new_innovations.begin(), m_new_innovations.end(), target);
	if ( result != m_new_innovations.end() )
	{
		// found in new temp list
		return (*result);
	}

	// innovation not found, create new innovation

	// first get an id
	target.innovation_id = (int)m_innovations.size() + (int)m_new_innovations.size();

	// finally, add the new innovation to the new innovation list
	m_new_innovations.push_back(target);

	// return new id
	return target;
}

