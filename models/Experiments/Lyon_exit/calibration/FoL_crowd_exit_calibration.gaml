/**
* Name: FoLcrowdexitcalibration
* Based on the internal empty template. 
* Author: hdang
* Tags: 
*/


model FoLcrowdexitcalibration

/* Insert your model definition here */

//import '../../../global_variables.gaml'
import '../../../Individual/individual.gaml'
import '../../../Continuum_Crowds/high_density_zone.gaml'
import '../../../env.gaml'
import '../../../helpers/detection.gaml'
/* Insert your model definition here */
global {
	int nb_agents <- 3833;
			
	// ========================= PARAMETER TO CALIBRATE =========================	
	// hyper parameter
	float step <- 0.1;
	int MAX_DELAY <- 9;
	float PROB_CONSTANTINE <- 0.91;
	float PROB_CHENAVARD <- 0.76;
	
	// CC model
	float MAXIMUM_SPEED <- 1.35 #m/#s;
	float MINIMUM_SPEED <- 0.15 #m/#s;
	float MAXIMUM_DENSITY <- 6.36;
	float MINIMUM_DENSITY <- 0.11;

	// SFM model
	float A <- 2.5;  // 1.93
	float B <- 0.45;
	float preferred_speed <- 1.25 #m/#s;
	float reaction_time <- 0.57 #s;
	
	// ===========================================================================	
	// other parameters
	float A_ob <- 3.0;
	float B_ob <- 0.1;	
	
	int sim_idx <- 0;
	
	file building_shape_file <- shape_file('../../includes/place_des_Terreaux/ok.shp');
	//file building_shape_file <- shape_file('../../includes/place_des_Terreaux/building_improved.shp');
	file center_shape_file <- shape_file('../../includes/place_des_Terreaux/center3.shp');
	
	file nav_mesh_shape_file <- shape_file('../../includes/gen_map_official/mesh.shp');
	file mesh_centroid_shape_file <- shape_file('../../includes/gen_map_official/node.shp');
	
	geometry shape <- envelope(building_shape_file);
	geometry space <- copy(shape);
	point group_target <- {60, 60};
	
	float LENGTH_X;
	float LENGTH_Y;
		
	// csv files for real outlfow data
	file constantine_outflow_file <- csv_file("data/constantine_outflow_interpolated.csv", ",");
	file chenavard_outflow_file <- csv_file("data/chenavard_outflow_interpolated.csv", ",");
	
	float similarity_score <- 100.0;
	
	list<float> constantine_time;
	list<float> real_constantine_outflow;
	list<float> chenavard_time;
	list<float> real_chenavard_outflow;
	
	int time_duration_constantine;
	int time_duration_chenavard;
	int SAVE_FLOW_DURATION <- 200;
	
	// ========================= GLOBAL PARAMETERS =========================
	// behavior level ids
	int STRATEGIC_BEHAVIOR <- 0;
	int TACTICAL_BEHAVIOR <- 1;
	int OPERATIONAL_BEHAVIOR <- 2;
	
	// distance check for local target
	float DISTANCE_CHECK <- 2.0;
	
	// ----------- PARAMETERS FOR OPERATIONAL LEVEL -----------
	float INFINITY <- #infinity;
	float AGENT_RADIUS <- 0.15 #m;

	
	string MODEL_NAME;
	
	map<int, list<individual>> map_cell_individual;

	// ----------- PARAMETERS FOR ENVIRONMENTS -----------
	float STEP <- 0.1 #s;
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
	
	// ===========================================================================		
	
		
	init {
		MODEL_NAME <- 'FestivalofLightsexitmesh';
 
		// ENVIRONMENTS
		create building from: building_shape_file;
		create center from: center_shape_file;
		
		create nav_mesh from: nav_mesh_shape_file;
		create mesh_centroid from: mesh_centroid_shape_file;

		loop c over: mesh_centroid {
			loop my_mesh over: nav_mesh {
				if c.shape overlaps	my_mesh.shape {
					my_mesh.centroid <- c.shape.location;
				}
			}	
		}
		
		loop mesh_i over: nav_mesh {
			loop mesh_j over: nav_mesh {
				if (mesh_j != mesh_i) {
					if mesh_i.shape intersects mesh_j.shape {
						mesh_i.neighbors <- mesh_i.neighbors + [mesh_j];
					}
				}
			}
		}
		
		// HIGH-DENSITY ZONE
		create high_density_zone {
			//GRID_WIDTH <- 30;
			//GRID_HEIGHT <- 30;
			
			GRID_WIDTH <- 60;
			GRID_HEIGHT <- 60;
			
			nb_groups <- 1;
			boundary <- [15.5, 75.0, 32.0, 70.5];
			float x_min <- boundary[0];
			float x_max <- boundary[1];
			float y_min <- boundary[2];
			float y_max <- boundary[3];
			
			CELL_SIZE_X <- (x_max - x_min) / GRID_WIDTH;
			CELL_SIZE_Y <- (y_max - y_min) / GRID_HEIGHT;
			
			CELL_AREA <- CELL_SIZE_X * CELL_SIZE_Y;
			//group_goals <- [1::[[0, 29]]];
			group_goals <- [1::[[0, 59]]];
			
			do init_state;
			exit_meshes <- [1::nav_mesh(30)];
		}

		// INDIVIDUAL
		// operational level
		create avoiding_target number: 1;
//		create avoiding number: 1;
		create following number: 1;
		
		// tatical level
		create best_neighbor_mesh number: 1;
		
		// -----------------------------
		GET_NEIGHBOR <- true;
		
		// distance check for local target
		DISTANCE_CHECK <- 2.0;

		loop x from: 15 to: 23 {
			float y <- 0.92 * x + 50.56;
			create test_target {
				shape <- circle(0.2) at_location {x,y};
			}
		}
		
		create individual number: nb_agents {
			color <- #blue;
			target <- {17.68, 131.12};
			velocity <- (target - location) * rnd(0.3, MAXIMUM_SPEED)/ norm(target - location);
			
			group_id <- 1;
			
//			my_operational_behavior <- first(avoiding);
//			my_operational_behavior <- first(avoiding_target);
			my_operational_behavior <- first(following);
			
			//my_tactical_behavior <- first(best_neighbor_mesh);
			
			location <- any_location_in(first(center));
			
			is_at_dense_region <- true;
			color <- #red;
			my_zone <- first(high_density_zone);
		}
		
		// read real outflow from csv files
		list<list<float>> constantine_data <- list<list<float>>(columns_list(matrix(constantine_outflow_file)));
		constantine_time <- constantine_data[0];
		real_constantine_outflow <- constantine_data[1];
		//write real_constantine_outflow;
		
		list<list<float>> chenavard_data <- list<list<float>>(columns_list(matrix(chenavard_outflow_file)));
		chenavard_time <- chenavard_data[0];
		real_chenavard_outflow <- chenavard_data[1];
		//write real_chenavard_outflow;
	}
	
	// length(individual) = 0
	// nb_exit_pedestrians 
	
	reflex udpate_time_duration_2roads {
		time_duration_constantine <- time_duration_constantine + 1;
		time_duration_chenavard <- time_duration_chenavard + 1;
		//write sim_outflow_constantine;
	}
	
	reflex update_outflow_over_time when: mod(cycle, SAVE_FLOW_DURATION) = 0 and (cycle > 1) {
		//save [nb_instant_passed_people_constantine, (time_duration_constantine * step)] to: 'data/constantine_sim.csv' rewrite: false type: csv;
		//save [nb_instant_passed_people_chenavard, (time_duration_chenavard * step)] to: 'data/chenavard_sim.csv' rewrite: false type: csv;
		
		sim_outflow_constantine <- sim_outflow_constantine + nb_instant_passed_people_constantine / (time_duration_constantine * step);
		time_duration_constantine <- 0;
		nb_instant_passed_people_constantine <- 0;
		
		sim_outflow_chenavard <- sim_outflow_chenavard + nb_instant_passed_people_chenavard / (time_duration_chenavard * step);
		time_duration_chenavard <- 0;
		nb_instant_passed_people_chenavard <- 0;
		
	}
	
	reflex write_result when:cycle = 3801 or length(individual) = 1 {
		float constantine_similarity;
		float chenavard_similarity;
		
		// constantine road
		int min_length_constantine <- min(length(sim_outflow_constantine), length(real_constantine_outflow));
		
		loop i from: 0 to: min_length_constantine - 1 {
			constantine_similarity <- constantine_similarity + abs(sim_outflow_constantine[i] - real_constantine_outflow[i]) / real_constantine_outflow[i];
		}
		constantine_similarity <- constantine_similarity / min_length_constantine;
		
		// chenavard road
		int min_length_chenavard <- min(length(sim_outflow_chenavard), length(real_chenavard_outflow));
		loop i from: 0 to: min_length_chenavard - 1 {
			chenavard_similarity <- chenavard_similarity + abs(sim_outflow_chenavard[i] - real_chenavard_outflow[i]) / real_chenavard_outflow[i];
		}
		chenavard_similarity <- chenavard_similarity / min_length_chenavard;
				
		similarity_score <- constantine_similarity + chenavard_similarity;
		
		//write similarity_score 
		if 'test' in string(experiment) and cycle = 3801 {
			//SEQUENTIAL
			//save [sim_idx, MAX_DELAY, PROB_CONSTANTINE, PROB_CHENAVARD, MAXIMUM_SPEED, MINIMUM_SPEED, MAXIMUM_DENSITY, MINIMUM_DENSITY, A, B, preferred_speed, reaction_time, similarity_score]
		   	//	to: "results.csv" type: "csv" rewrite: false header: true;

			// PARALLEL
			save [sim_idx, MAX_DELAY, PROB_CONSTANTINE, PROB_CHENAVARD, MAXIMUM_SPEED, MINIMUM_SPEED, MAXIMUM_DENSITY, MINIMUM_DENSITY, A, B, preferred_speed, reaction_time, similarity_score] 
		   		to: "output/results_" + string(sim_idx) + ".csv" type: "csv" rewrite: true header: true;

			// save simulated outflow
		    save [sim_outflow_constantine] type: "csv" to: "output/constantine_road" + string(sim_idx) + ".txt" rewrite: false header: true;
		    save [sim_outflow_chenavard] type: "csv" to: "output/chenavard_road" + string(sim_idx) + ".txt" rewrite: false header: true;
			
		}
	}

	reflex check when: false {
		save [sim_idx, MAX_DELAY, PROB_CONSTANTINE, PROB_CHENAVARD, MAXIMUM_SPEED, MINIMUM_SPEED, MAXIMUM_DENSITY, MINIMUM_DENSITY, A, B, preferred_speed, reaction_time, similarity_score]
		   		to: "checked.csv" type: "csv" rewrite: false header: true;
	}

}


species center {
	aspect default {
		draw shape color: #yellow;
	}
}

species test_target {
	aspect default {
		draw shape color: #green;
	}
}

species mesh_centroid {
	aspect default {
		draw circle(0.1) at: shape.location color: #red border: #green;
	}
}

//length(individual) = 0

//parallel: true
//
experiment FoL_calibration_GAMA_genetic type: batch repeat: 1 keep_seed: true until: length(individual) = 0  or cycle > 3801  {
	// until: length(individual) = 0 
	// repeat: 3 keep_seed: false/true => same simulated results, dont know why ?
	
	// parameters in CC model
	//parameter 'MAXIMUM_SPEED' var: MAXIMUM_SPEED min: 0.8 max: 1.6 step: 0.05;
	//parameter 'MINIMUM_SPEED' var: MINIMUM_SPEED min: 0.05 max: 0.3 step: 0.05;
	//parameter 'MAXIMUM_DENSITY' var: MAXIMUM_DENSITY min: 4.0 max: 8.0 step: 1.0;
	//parameter 'MINIMUM_DENSITY' var: MINIMUM_DENSITY min: 0.0 max: 0.5 step: 0.1;
	
	// parameters in SFM 
	//parameter 'A' var: A min: 0.5 max: 5.0 step: 0.25;
	//parameter 'B' var: B min: 0.1 max: 0.6 step: 0.1;
	//parameter 'preferred_speed' var: preferred_speed min: 0.8 max: 1.5 step: 0.1;
	//parameter 'reaction_time' var: reaction_time min: 0.4 max: 0.6 step: 0.05;
	
	// hyperparameters
	parameter 'MAX_DELAY' var: MAX_DELAY min: 0 max: 10 step: 1;
	parameter 'PROB_CONSTANTINE' var: PROB_CONSTANTINE min: 0.0 max: 1.0 step: 0.05;
	parameter 'PROB_CHENAVARD' var: PROB_CHENAVARD min: 0.0 max: 1.0 step: 0.05;	
	
	// repeat: n // run n simulations for each parameter value 
	// time: cycle in simulation?
	// step: x // udpate new value  value +  x 
	// doesnot assign values for parameters for calibration in init because values would not change, should do it in global
	
	method genetic 
    	minimize: similarity_score 
        pop_dim: 10 crossover_prob: 0.7 mutation_prob: 0.1 
        nb_prelim_gen: 1 
        max_gen: 1000; 
    
	output {
		display my_display {
			species building;
			species individual;
		}
	}
	
	reflex save_results_explo when: true {
		ask simulations {
			//save [MAXIMUM_SPEED, MINIMUM_SPEED, MAXIMUM_DENSITY, MINIMUM_DENSITY, 
			//	  A, B, preferred_speed, reaction_time, similarity_score] 
				  
			save [MAX_DELAY, PROB_CONSTANTINE, PROB_CHENAVARD, similarity_score] 
				  
		   		to: "output/results.csv" type: "csv" rewrite: (int(self) = 0) ? true : false header: true;
		}		
	}
}

experiment calibration_test {
	parameter 'PROB_CONSTANTINE' var: PROB_CONSTANTINE;
	parameter 'PROB_CHENAVARD' var: PROB_CHENAVARD;
	parameter "sim_idx" var: sim_idx;
	parameter 'MAX_DELAY' var: MAX_DELAY;

	// parameters in CC model
	parameter 'MAXIMUM_SPEED' var: MAXIMUM_SPEED;
	parameter 'MINIMUM_SPEED' var: MINIMUM_SPEED;
	parameter 'MAXIMUM_DENSITY' var: MAXIMUM_DENSITY;
	parameter 'MINIMUM_DENSITY' var: MINIMUM_DENSITY;

	// parameters in SFM 
	parameter 'A' var: A;
	parameter 'B' var: B;
	parameter 'preferred_speed' var: preferred_speed;
	parameter 'reaction_time' var: reaction_time;

	output {
		display my_display  {
			species building;
			species individual;
		}
	}

}
