$data = {
	# settings controlling the operation of the experiment
	'settings' => {
		'experiment' => 'xor',
		'population' => 100,	# desired number of networks
		'limit' => 10,			# max offspring per topology
		'penalty' => 10,		# max investment/stagnant topology	
		'retest-elites' => 0,
		'save-epochs' => 0,
		'activation' => 'perl',
		'max-weight' => 10,
		'gain' => 5,
		'debug' => 0,
		'topology-limit' => 50,
#		'allow-recurrent' => 1,
		},
	# the state of the experiment
	'save' => {
		'unique-id' => 0,			# innovation id
		'generation' => 0,			# which generation this is
		'max-fitness' => 0,
		'max-weight' => 0,
		'min-weight' => 0,
		},
	# nodes listed by the unique node-id
	'nodes' => {
		'one' => {
			'id' => 'one', 		# redundant, but useful 
			'type' => 'input',
			},
		'two' => {
			'id' => 'two', 		# redundant, but useful 
			'type' => 'input',
			},
		'bias' => {
			'id' => 'bias', 		# redundant, but useful 
			'type' => 'input',
			},
		'output' => {
			'id' => 'output', 		# redundant, but useful 
			'type' => 'output',
			'function' => 'sigmoid',
			'gain' => '5',
			},
		},
	# one entry per network in the population 
	'population' => {
		'initial' => {
			'id' => 'initial',
			'fitness' => 0,
			'elite' => 0,
			'nodes' => {
				'one' => {},
				'two' => {},
				'bias' => {},
				'output' => {},
				},
			},
		},
	# a record of all the topologies in the population
	# this tracks statistics about each one
	'topologies' => {},
	# for all nodes formed by splitting connections, the
	# mapping between the nodes connected and the node created
	# exists primarily for search-speed
	# can be removed before saving, 
	'node-lookup' => {},
	};
