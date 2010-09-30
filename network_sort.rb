#!/usr/bin/env ruby

require 'pp'

# a single neuron
class Node
	attr_accessor :activation, :input_nodes
	attr_reader :id

	def initialize(id)
		@id = id
		@input_nodes = Array.new
		@activation = 0.0
	end

	def update 
		# activate unless this is an input node
		@activation = activate(sum_input) unless /i[0-9]+/.match(@id) 
	end

	def <=>(other)
		@id <=> other.id
	end

	private

	def sum_input
		@input_nodes.inject(0.0) { |sum,node| sum + node.activation }
	end

	def activate(x)
		Math.tanh(x)
	end
end

# a basic ANN (assumes all weights are 1.0)
class Network
	attr_accessor :nodes

	def initialize(n_in, n_hidden, n_out)
		@nodes = Hash.new
		n_in.times     { |i| @nodes["i#{i}"] = Node.new("i#{i}") }
		n_hidden.times { |i| @nodes["h#{i}"] = Node.new("h#{i}") }
		n_out.times    { |i| @nodes["o#{i}"] = Node.new("o#{i}") }
	end

	def connect(from_id, to_id)
		@nodes[to_id].input_nodes << @nodes[from_id]
		@order = nil # mark activation order as being dirty
	end

	def update
		# calculate activation order if it's 'nil'
		@order ||= activation_order

		# simply update each node in order
		@order.each do |layer|
			puts "Layer"
			layer.each { |node| puts "updating node #{node.id}"; node.update }
		end
	end

	private

	def activation_order
		# do the recursive search, starting with the output layer
		# then,  add the input nodes to the front
		[input_nodes] + a_o_bfs(output_nodes)
	end

	def find_nodes(re)
		# collect all of the output node ids, this is the end layer of the ANN
		node_ids = @nodes.keys.select { |k,v| re.match(k) }

		# use id's to get array of nodes, then sort
		node_ids.collect { |id| @nodes[id] }.sort
	end

	def input_nodes
		find_nodes(/i[0-9]+/)
	end

	def hidden_nodes
		find_nodes(/h[0-9]+/)
	end

	def output_nodes
		find_nodes(/o[0-9]+/)
	end

	def a_o_bfs(current_layer, seen=nil, order=nil)
		# setup some state for this recursion
		seen ||= Hash.new
		order ||= Array.new

		# mark current nodes as seen
		current_layer.each { |n| seen[n] = true }

		# prepend current layer to final order
		order = [current_layer.sort] + order

		# get next layer
		next_layer = current_layer.collect { |n| n.input_nodes }
		next_layer = next_layer.flatten.select { |n| not seen[n] and not /i[0-9]+/.match(n.id) }

		if not next_layer.empty?
			# recurse into next layer if it exists
			a_o_bfs(next_layer, seen, order)
		else
			# finished
			order
		end
	end
end



# create a network
n = Network.new(3,4,3)
n.connect('i0','h0')
n.connect('h0','o0')
n.connect('i1','h2')
n.connect('i2','h1')
n.connect('h1','h0')
n.connect('h2','h0')
n.connect('h2','h3')
n.connect('h3','o2')

# run some data through the network
10.times do
	# give network some data
	n.nodes['i0'].activation = (2.0 * Kernel.rand) - 1.0
	n.nodes['i1'].activation = (2.0 * Kernel.rand) - 1.0

	# update network
	n.update

	# read outputs
	puts n.nodes['o0'].activation
	puts
end

