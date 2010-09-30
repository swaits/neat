#!/usr/bin/env ruby

# BFS method
def ao_bfs(net, cur_layer, seen=nil, order=nil)
	# setup some state for this recursion
	seen ||= Hash.new
	order ||= Array.new

	# mark current nodes as seen
	cur_layer.each { |n| seen[n] = true }

	# prepend current layer to final order
	order = [cur_layer.sort] + order

	# get next layer
	next_layer = cur_layer.collect { |n| net[n] }
	next_layer = next_layer.flatten.select { |n| not seen[n] }

	if not next_layer.empty?
		# recurse into next layer if it exists
		ao_bfs(net, next_layer, seen, order)
	else
		# finished
		order
	end
end

# network format is a reverse digraph, so if node 0 feeds into node 1, you'd have 1 => [0]
# ... in other words, node 1 directly depends upon node 0

# 0,1,2 = inputs; 7,8,9 = outputs
net = { 0 => [], 1 => [4], 2 => [], 3 => [0,4,5], 4 => [2,6], 5 => [1], 6 => [5], 7 => [3], 8 => [5], 9 => [6] }

# call ao_bfs with output layer (or last layer)
puts ao_bfs(net, [7,8,9]).inspect


# DFS method
# use DFS to find terminal nodes
# as each terminal node is encountered, push it on the end of the order
# and as each node becomes terminal node (i.e. all leaves explored), push it on

