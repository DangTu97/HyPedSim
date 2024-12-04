/**
* Name: globalvariables
* Based on the internal empty template. 
* Author: hdang
* Tags: 
*/


model globalvariables
import 'Individual/individual.gaml'
/* Insert your model definition here */

global {
	// behavior level ids
	int STRATEGIC_BEHAVIOR <- 0;
	int TACTICAL_BEHAVIOR <- 1;
	int OPERATIONAL_BEHAVIOR <- 2;
	
	// distance check for local target
	float DISTANCE_CHECK <- 2.0;
	
	// ----------- PARAMETERS FOR OPERATIONAL LEVEL -----------
	float INFINITY <- #infinity;
	float AGENT_RADIUS <- 0.15 #m;
	float MAXIMUM_SPEED <- 1.4 #m/#s;
	float MINIMUM_SPEED <- 0.5 #m/#s;
	float MAXIMUM_DENSITY <- 8.0;
	float MINIMUM_DENSITY <- 0.5;
	
	string MODEL_NAME;
	
	map<int, list<individual>> map_cell_individual;
//	list<list<int>> obstacle_cells <- [];
	//list<list<list<float>>> wall_repulsion_velocity; // size: GRID_WIDTH x GRID_HEIGHT x 2
	
	// ----------- PARAMETERS FOR ENVIRONMENTS -----------
	float STEP <- 0.1 #s;
	int MAX_DELAY <- 5;
	graph graph_network;
	
	bool GET_NEIGHBOR;
	
	// Lyon case
	list<building> obstacle_list;
	
	// additional information
	int nb_exit_pedestrians <- 0;
	float evacuation_time <- 0.0;
	float average_speed <- 0.0; // average speed at the transition area
	
	map<int,float> simulated_outflow_constantine;
	map<int,float> simulated_outflow_chenavard;
	
	list<float> sim_outflow_constantine;
	list<float> sim_outflow_chenavard;
	
	int nb_instant_passed_people_constantine;
	int nb_instant_passed_people_chenavard;
	
}

