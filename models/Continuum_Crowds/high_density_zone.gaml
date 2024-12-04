/**
* Name: highdensityzone
* Based on the internal empty template. 
* Author: hdang
* Tags: 
*/


model highdensityzone

import "../Experiments/Lyon_exit/calibration/FoL_crowd_exit_calibration.gaml"
// import '../global_variables.gaml'
/* Insert your model definition here */

species high_density_zone {
	// CONSTANTS
	float alpha <- 0.2;
	float beta <- 0.2;
	float phi <- 1.0;
	float gamma <- 1.0;
	
	float AGENT_DENSITY_CONTRIBUTION <- 1.0; //
	
	int GRID_WIDTH;
	int GRID_HEIGHT;
	float CELL_SIZE_X;
	float CELL_SIZE_Y;
	float CELL_AREA;
	
	list<float> boundary; // rectangular boundary [x_min, x_max, y_min, y_max]
	map<int, nav_mesh> exit_meshes; // group vs mesh
	
	// variables
	list<list<int>> obstacle_cells <- [];
	// density field, average velocity field
	list<list<float>> density_field; // size: GRID_WIDTH x GRID_HEIGHT
	list<list<list<float>>> average_velocity_field; // size: GRID_WIDTH x GRID_HEIGHT x 2
	
	// flow_field, speed_field
	list<list<list<float>>> flow_field_NESW; // size: GRID_WIDTH x GRID_HEIGHT x 4
	list<list<list<float>>> speed_field_NESW; // size: GRID_WIDTH x GRID_HEIGHT x 4
	
	// cost, potential
	list<list<float>> discomfort_field;

	int nb_groups;
	map<int, list<list<list<float>>>> group_cost_field_NESW;
	map<int, list<list<float>>> group_potential_field;
	map<int, list<list<list<float>>>> group_gradient_field_WE_SN;
	map<int, list<list<int>>> group_goals;
	list<list<list<float>>> wall_repulsion_velocity; // size: GRID_WIDTH x GRID_HEIGHT x 2
	
	action initialize {
		// initialize all fields
		loop id from: 1 to: nb_groups {
			list<list<float>> groupid_potential_field;
			list<list<list<float>>> groupid_cost_field_NESW;
			list<list<list<float>>> groupid_gradient_field_WE_SN;
			
			loop i from: 0 to: GRID_WIDTH - 1 {
				groupid_potential_field <- groupid_potential_field + [list_with(GRID_HEIGHT, INFINITY)];
				
				list<list<float>> cost_field_NESW_row;
				list<list<float>> gradient_field_NESW_row;
				
				loop j from: 0 to: GRID_HEIGHT - 1 {
					cost_field_NESW_row <- cost_field_NESW_row + [list_with(4, 0.0)]; // store cost field with direction
					gradient_field_NESW_row <- gradient_field_NESW_row + [list_with(2, 0.0)]; // gradient field x 2
				}

				groupid_cost_field_NESW <- groupid_cost_field_NESW + [cost_field_NESW_row];
				groupid_gradient_field_WE_SN <- groupid_gradient_field_WE_SN + [gradient_field_NESW_row];
	
			}
			
			group_potential_field[id] <- groupid_potential_field;
			group_cost_field_NESW[id] <- groupid_cost_field_NESW;
			group_gradient_field_WE_SN[id] <- groupid_gradient_field_WE_SN;
		}
		
		loop i from: 0 to: GRID_WIDTH - 1 {
			density_field <- density_field + [list_with(GRID_HEIGHT, 0.0)];
			discomfort_field <- discomfort_field + [list_with(GRID_HEIGHT, 0.0)];
			
			list<list<float>> average_velocity_field_row;
			list<list<float>> wall_repulsion_row;
			list<list<float>> flow_field_NESW_row;
			list<list<float>> speed_field_NESW_row;
			list<list<float>> cost_field_NESW_row;
			list<list<float>> gradient_field_NESW_row;
			
			loop j from: 0 to: GRID_HEIGHT - 1 {
				map_cell_individual[i * GRID_WIDTH + j] <- [];
				average_velocity_field_row <- average_velocity_field_row + [list_with(2, 0.0)]; // store velocity (x, y)
				wall_repulsion_row <- wall_repulsion_row + [list_with(2, 0.0)]; // store wall-repulsion velocity (x, y)
				flow_field_NESW_row <- flow_field_NESW_row + [list_with(4, 0.0)]; // store flow speed (N, E, S, W)
				speed_field_NESW_row <- speed_field_NESW_row + [list_with(4, 0.0)]; // store speed with direction (x, y) x (N, E, S, W)
				cost_field_NESW_row <- cost_field_NESW_row + [list_with(4, 0.0)]; // store cost field with direction
				gradient_field_NESW_row <- gradient_field_NESW_row + [list_with(2, 0.0)]; // gradient field x 2
			}
			
			average_velocity_field <- average_velocity_field + [average_velocity_field_row];
			wall_repulsion_velocity <- wall_repulsion_velocity + [wall_repulsion_row];
			flow_field_NESW <- flow_field_NESW + [flow_field_NESW_row];
			speed_field_NESW <- speed_field_NESW + [speed_field_NESW_row];
	
		}
		
	}
	
	action compute_discomfort_field {
		loop cell over: obstacle_cells {
			discomfort_field[cell[0]][cell[1]] <- INFINITY;
		}
	}
	
	action compute_wall_repulsion_velocity {
		loop i from: 0 to: GRID_WIDTH - 1 {
			loop j from: 0 to: GRID_HEIGHT - 1 {
				list<list<int>> neighbors <- [ [i + 1, j], [i-1, j], [i, j + 1], [i, j - 1] ];
				
				loop n over: neighbors {
					if n in obstacle_cells {
						float factor <- 0.7;
						wall_repulsion_velocity[i][j] <- [(i - n[0]) * factor, (j - n[1]) * factor];
					}	
				}
			}
		}
	}
	
	action compute_density_average_velocity_field {
		// clear density field, average velocity field 
		
		loop i from: 0 to: GRID_WIDTH - 1 {
			loop j from: 0 to: GRID_HEIGHT - 1 {
				density_field[i][j] <- 0.0;
				average_velocity_field[i][j] <- [0.0, 0.0];
			}
		}
		
		// compute new  density field, velocity field
		ask individual parallel: true {
			do add_contribution_to_fields(self.my_zone);
		}

		loop i from: 0 to: GRID_WIDTH - 1 {
			loop j from: 0 to: GRID_HEIGHT - 1 {
				if (density_field[i][j]) > 0 {
					average_velocity_field[i][j][0] <- average_velocity_field[i][j][0] / density_field[i][j];
					average_velocity_field[i][j][1] <- average_velocity_field[i][j][1] / density_field[i][j];
				}
			}
		}
		
	}
	
	float get_speed (float flow_speed, float density) {
		if (density = 0) { return MAXIMUM_SPEED; }
		if (density >= 0.95 * MAXIMUM_DENSITY) { return MINIMUM_SPEED; }
		return MAXIMUM_SPEED * (1 - exp(- 1.913 * (1 / density - 1 / MAXIMUM_DENSITY )));
	}
	
//	float get_speed (float flow_speed, float density) {
//		if (density = 0) { return MAXIMUM_SPEED; }
//		if (density >= 0.5 * MAXIMUM_DENSITY) { return MINIMUM_SPEED; }
//		return MAXIMUM_SPEED * (1 - exp(- 1.913 * (1 / density - 1 / MAXIMUM_DENSITY )));
//	}

//	float get_speed (float flow_speed, float density) {
//		if (density <= 0.5) { return MAXIMUM_SPEED; }
//		else if (density <= 2.0) {
//			return MINIMUM_SPEED + (MAXIMUM_SPEED - MINIMUM_SPEED) * (2.0 - density) / (2.0 - 0.5);
//		}
//		else {
//			return MINIMUM_SPEED;
//		} 
//	}

	action compute_flow_speed_field_NESW {
		loop i from: 0 to: GRID_WIDTH - 1 {
			loop j from: 0 to: GRID_HEIGHT - 1 {

			    float flow_N <- (j + 1 > GRID_HEIGHT - 1) ? MINIMUM_SPEED : max( average_velocity_field[i][j+1][1], MINIMUM_SPEED );
				float flow_E <- (i + 1 > GRID_WIDTH - 1) ? MINIMUM_SPEED : max( average_velocity_field[i+1][j][0], MINIMUM_SPEED );
				float flow_S <- (j - 1 < 0) ? - MINIMUM_SPEED : - max( average_velocity_field[i][j-1][1], MINIMUM_SPEED );
				float flow_W <- (i - 1 < 0) ? - MINIMUM_SPEED : - max( average_velocity_field[i-1][j][0], MINIMUM_SPEED );
				
				flow_field_NESW[i][j] <- [flow_N, flow_E, flow_S, flow_W];

				float speed_N <- (j + 1 > GRID_HEIGHT - 1) ? MINIMUM_SPEED : get_speed( abs(flow_field_NESW[i][j][0]), density_field[i][j+1] );
				float speed_E <- (i + 1 > GRID_WIDTH - 1) ? MINIMUM_SPEED : get_speed( abs(flow_field_NESW[i][j][1]), density_field[i+1][j] );
				float speed_S <- (j - 1 < 0) ? MINIMUM_SPEED : get_speed( abs(flow_field_NESW[i][j][2]), density_field[i][j-1] );
				float speed_W <- (i - 1 < 0) ? MINIMUM_SPEED : get_speed( abs(flow_field_NESW[i][j][3]), density_field[i-1][j] );
				
				speed_field_NESW[i][j] <- [speed_N, speed_E, speed_S, speed_W];

			}
	
		}
	}
	
	action compute_cost_field {
		loop id from: 1 to: nb_groups {
			loop i from: 0 to: GRID_WIDTH - 1 {
				loop j from: 0 to: GRID_HEIGHT - 1 {
					
					if ([i, j] in obstacle_cells) {
						group_cost_field_NESW[id][i][j] <- [INFINITY, INFINITY, INFINITY, INFINITY];
					} else {
//						float cost_N <- (j + 1 > GRID_HEIGHT - 1) ? INFINITY : (speed_field_NESW[i][j][0] * alpha + beta + phi * discomfort_field[i][j + 1]) / speed_field_NESW[i][j][0];
//						float cost_E <- (i + 1 > GRID_WIDTH - 1) ? INFINITY : (speed_field_NESW[i][j][1] * alpha + beta + phi * discomfort_field[i + 1][j]) / speed_field_NESW[i][j][1];
//						float cost_S <- (j - 1 < 0) ? INFINITY : (speed_field_NESW[i][j][2] * alpha + beta + phi * discomfort_field[i][j - 1]) / speed_field_NESW[i][j][2];
//						float cost_W <- (i - 1 < 0) ? INFINITY : (speed_field_NESW[i][j][3] * alpha + beta + phi * discomfort_field[i - 1][j]) / speed_field_NESW[i][j][3];
//						group_cost_field_NESW[id][i][j] <- [cost_N, cost_E, cost_S, cost_W];
						
//						float cost_N <- (j + 1 > GRID_HEIGHT - 1) ? INFINITY : (speed_field_NESW[i][j][0] * alpha + beta + phi * density_field[i][j + 1]) / speed_field_NESW[i][j][0];
//						float cost_E <- (i + 1 > GRID_WIDTH - 1) ? INFINITY : (speed_field_NESW[i][j][1] * alpha + beta + phi * density_field[i + 1][j]) / speed_field_NESW[i][j][1];
//						float cost_S <- (j - 1 < 0) ? INFINITY : (speed_field_NESW[i][j][2] * alpha + beta + phi * density_field[i][j - 1]) / speed_field_NESW[i][j][2];
//						float cost_W <- (i - 1 < 0) ? INFINITY : (speed_field_NESW[i][j][3] * alpha + beta + phi * density_field[i - 1][j]) / speed_field_NESW[i][j][3];
//						group_cost_field_NESW[id][i][j] <- [cost_N, cost_E, cost_S, cost_W];

						float cost_N <- (j + 1 > GRID_HEIGHT - 1) ? INFINITY : (speed_field_NESW[i][j][0] * alpha + beta + phi * density_field[i][j + 1]) / speed_field_NESW[i][j][0];
						float cost_E <- (i + 1 > GRID_WIDTH - 1) ? INFINITY : (speed_field_NESW[i][j][1] * alpha + beta + phi * density_field[i + 1][j]) / speed_field_NESW[i][j][1];
						float cost_S <- (j - 1 < 0) ? INFINITY : (speed_field_NESW[i][j][2] * alpha + beta + phi * density_field[i][j - 1]) / speed_field_NESW[i][j][2];
						float cost_W <- (i - 1 < 0) ? INFINITY : (speed_field_NESW[i][j][3] * alpha + beta + phi * density_field[i - 1][j]) / speed_field_NESW[i][j][3];
						group_cost_field_NESW[id][i][j] <- [cost_N, cost_E, cost_S, cost_W];
						
					}
				}
			}
		}
		
	}
	
	float solve_quadratic (float potential_X, float potential_Y, float cost) {
		float difference <- potential_X - potential_Y;
		float solution <- cost > abs(difference) ? (potential_X + potential_Y + sqrt(2 * cost * cost - difference * difference)) / 2 
										   : min(potential_X, potential_Y) + cost; 
		
		return solution;
	}
	
	// compute potenial at step k
	float compute_simple (float potential, // potential at step k - 1
                    	  float potential_N, float potential_S, float potential_W, float potential_E,
                     	  float cost_N, float cost_S, float cost_W, float cost_E) {
                    	   	
    	bool is_less_than_WE <- (potential_W + cost_W) <= (potential_E + cost_E);
		float potential_X  <- is_less_than_WE ? potential_W : potential_E;
		float cost_X  <- is_less_than_WE ? cost_W : cost_E;
		
		bool is_less_than_SN <- (potential_S + cost_S) <= (potential_N + cost_N);
		float potential_Y  <- is_less_than_SN ? potential_S : potential_N;
		float cost_Y  <- is_less_than_SN ? cost_S : cost_N;
		
		float cost <- cost_X + cost_Y;
		float solution <- solve_quadratic(potential_X, potential_Y, cost);
		 // Should be decreased or same
		solution <- min(solution, potential);
		
		return solution;
	}
	
	action compute_potential {
		loop id from: 1 to: nb_groups {
			list<list<int>> goals <- group_goals[id];
			loop goal_cell over: goals {
				list<list<int>> known;
				list<list<int>> candidates;
				list<float> candidates_potential;
				list<list<int>> unknown;
				
				loop i from: 0 to: GRID_WIDTH - 1 {
					loop j from: 0 to: GRID_HEIGHT - 1 {
						unknown <- unknown + [[i, j]];
					}
				}
				
				// add goal cell to known set
				// assgin potential at goal cell to 0
				known <- [goal_cell];
				group_potential_field[id][goal_cell[0]][goal_cell[1]] <- 0.0;
				
				// add neighbor of goal cell to candidates
				list<list<int>> potential_candidates <- [ [goal_cell[0] + 1, goal_cell[1]],
															[goal_cell[0] - 1, goal_cell[1]],
															[goal_cell[0], goal_cell[1] + 1],
															[goal_cell[0], goal_cell[1] - 1] ];			
				
				loop potential_candidate over: potential_candidates {
					if potential_candidate[0] >= 0 and potential_candidate[0] <= GRID_WIDTH - 1 
					and potential_candidate[1] >= 0 and potential_candidate[1] <= GRID_HEIGHT - 1 {
						candidates <- candidates + [potential_candidate];
					}
				} 
		
				loop c over: candidates {
					int i <- c[0];
					int j <- c[1];
					
					float originalPotential <- group_potential_field[id][i][j];
		
					float cost_N <- group_cost_field_NESW[id][i][j][0];
				    float cost_E <- group_cost_field_NESW[id][i][j][1];
				    float cost_S <- group_cost_field_NESW[id][i][j][2];
				    float cost_W <- group_cost_field_NESW[id][i][j][3];
			    
				    float potential_N <- (j + 1 > GRID_HEIGHT - 1) ? INFINITY : group_potential_field[id][i][j + 1];
				    float potential_S <- (j - 1 < 0) ? INFINITY : group_potential_field[id][i][j - 1];
				    float potential_W <- (i - 1 < 0) ? INFINITY : group_potential_field[id][i - 1][j];
				    float potential_E <- (i + 1 > GRID_WIDTH - 1) ? INFINITY : group_potential_field[id][i + 1][j];
			    		
					float solution <- compute_simple(originalPotential, potential_N, potential_S, potential_W, potential_E, cost_N, cost_S, cost_W, cost_E);
		
					candidates_potential <- candidates_potential + [solution];
				}
				
				unknown <- unknown - goal_cell - candidates;
				
				//-----------------------------------------------------
				
				loop while: length(candidates) > 0 {
					// get min potential and corresponding index in candidates
					float min_potential <- min(candidates_potential);
					int idx <- candidates_potential index_of min_potential;
					
					// remove min candidate from candidates set
					// remove candidate potential
					list min_candidate <- candidates[idx];
					remove from: candidates index: idx;
					remove from: candidates_potential index: idx;
					
					// add min_candidate to known set
					known <- known + [min_candidate];
					// and update potential
					group_potential_field[id][min_candidate[0]][min_candidate[1]] <- min_potential;
					
					// find neighbors of min candidate in unknow set
					// add them to candidates set
					list<list<int>> min_candidate_neighbors <- [ [min_candidate[0] + 1, min_candidate[1]],
																 [min_candidate[0] - 1, min_candidate[1]],
																 [min_candidate[0], min_candidate[1] + 1],
																 [min_candidate[0], min_candidate[1] - 1] ];
					if length(unknown) > 0 {
						loop c over: min_candidate_neighbors {
							int i <- c[0];
							int j <- c[1];
							
							if (i >= 0 and i <= GRID_WIDTH - 1) and (j >= 0 and j <= GRID_HEIGHT - 1) and ([i, j] in unknown) { 
								float originalPotential <- group_potential_field[id][i][j];
								
								float cost_N <- group_cost_field_NESW[id][i][j][0];
							    float cost_E <- group_cost_field_NESW[id][i][j][1];
							    float cost_S <- group_cost_field_NESW[id][i][j][2];
							    float cost_W <- group_cost_field_NESW[id][i][j][3];	
							    
							    float potential_N <- (j + 1 > GRID_HEIGHT - 1) ? INFINITY : group_potential_field[id][i][j + 1];
							    float potential_S <- (j - 1 < 0) ? INFINITY : group_potential_field[id][i][j - 1];
							    float potential_W <- (i - 1 < 0) ? INFINITY : group_potential_field[id][i - 1][j];
							    float potential_E <- (i + 1 > GRID_WIDTH - 1) ? INFINITY : group_potential_field[id][i + 1][j];		  
							    
								float solution <- compute_simple(originalPotential, potential_N, potential_S, potential_W, potential_E, cost_N, cost_S, cost_W, cost_E);
		
								candidates_potential <- candidates_potential + [solution];
								candidates <- candidates + [[i, j]];
								unknown <- unknown - [[i, j]];
								
							}
						}			
					}						
				}
			}
		}
	}
	
	action compute_gradient {
		loop id from: 1 to: nb_groups {
			loop i from: 0 to: GRID_WIDTH - 1 {
				loop j from: 0 to: GRID_HEIGHT - 1 {	
					// gradient at boundary -> potential outside of the grid is equal to potential(i, j)
					float potentialN <- (j + 1 > GRID_HEIGHT - 1) ? group_potential_field[id][i][j] : group_potential_field[id][i][j + 1];
				    float potentialS <- (j - 1 < 0) ? group_potential_field[id][i][j] : group_potential_field[id][i][j - 1];
				    float potentialW <- (i - 1 < 0) ? group_potential_field[id][i][j] : group_potential_field[id][i - 1][j];
				    float potentialE <- (i + 1 > GRID_WIDTH - 1) ? group_potential_field[id][i][j] : group_potential_field[id][i + 1][j];
				    
				    float potential <- group_potential_field[id][i][j];
					
					float gradient_WE <- potentialW < potentialE ? potential - potentialW : potentialE - potential;
					float gradient_SN <- potentialS < potentialN ? potential - potentialS : potentialN - potential;
					list gradient <- [gradient_WE, gradient_SN];
					group_gradient_field_WE_SN[id][i][j] <- gradient;
					
				}	
			}
		}
	}
	
	action init_state {
		do initialize;
		do compute_density_average_velocity_field;
		do compute_flow_speed_field_NESW;
		do compute_cost_field;
		
//		max(GRID_WIDTH, GRID_HEIGHT)
		loop k from: 0 to: 30 {
//		loop k from: 0 to: 1 {
			do compute_potential;
		}
		do compute_gradient;
		do compute_wall_repulsion_velocity;
		
		//write wall_repulsion_velocity;
	}
	
	reflex step when: every(10#cycle) {
		// clear map 
		loop i from: 0 to: GRID_WIDTH - 1 {
			loop j from: 0 to: GRID_HEIGHT - 1 {
				int idx <- i * GRID_WIDTH + j;
				map_cell_individual[idx] <- [];
			}
		}
		
		do compute_density_average_velocity_field;
		do compute_flow_speed_field_NESW;
		do compute_cost_field;
		do compute_potential;
		do compute_gradient;
	}

	aspect default {
		draw polyline([ {boundary[0], boundary[2]}, {boundary[1], boundary[2]}, {boundary[1], boundary[3]}, {boundary[0], boundary[3]}, {boundary[0], boundary[2]} ]) border: #black color: #green;
	}
}
