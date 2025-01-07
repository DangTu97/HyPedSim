/**
* Name: individual
* Based on the internal empty template. 
* Author: hdang
* Tags: 
*/


model individual

import "../Experiments/Lyon_exit/calibration/FoL_crowd_exit_calibration.gaml"
//import '../global_variables.gaml' 
import "operational_level.gaml"
import "tactical_level.gaml"
import '../env.gaml'
import '../Continuum_Crowds/high_density_zone.gaml'

/* Insert your model definition here */

species individual {
	rgb color;
	point velocity;
	point target;
	
	point local_target;
	
	nav_mesh old_mesh;
	nav_mesh current_mesh;
	
	int group_id; // group id of agent
	
	operational_behavior my_operational_behavior;
	tactical_behavior my_tactical_behavior;
	
	bool is_at_dense_region;
	
	high_density_zone my_zone;
	
	// attributes for only SFM simulation
	list<individual> neighbors;
	list<building> obstacles;
		
	bool is_saved;
	
	int step_delay <- MAX_DELAY;
	
	bool already_passed_exit_line <- false;
	
	// --------------------- ACTION AT HIGH-DENSITY REGION ---------------------
	bool is_in_zone_boundary (point p, high_density_zone zone) {
		if (p.x < zone.boundary[0]) {
			return false;
		}
		if (p.x > zone.boundary[1]) {
			return false;
		}
		if (p.y < zone.boundary[2]) {
			return false;
		}
		if (p.y > zone.boundary[3]) {
			return false;
		}
		
		return true;
	}

	action count_exit_pedestrians {
		nb_exit_pedestrians <- nb_exit_pedestrians + 1;
	}

	bool is_in_dense_area (point p, high_density_zone zone) {
		if (p.x >= zone.boundary[0] and p.x <= zone.boundary[1]) and (p.y >= zone.boundary[2] and p.y <= zone.boundary[3]) {
			// exit condition

			if (- 0.92 * location.x + location.y > 50.56) and MODEL_NAME = 'FestivalofLightsexitmesh' {
				if is_at_dense_region {
					// add max_delay = 0
					//if step_delay = 1  {
					if step_delay = 1 or MAX_DELAY = 0 {
						// choose an exit
						
						// closest exit
						//target <- location.x < 19.84 ? {5, rnd(65.5, 69.5)} : {rnd(16.5, 21), 88};
						
						// random
						//target <-  one_of([{5, rnd(65.5, 69.5)}, {rnd(16.5, 21), 88}]);
						
						// choose nearest exit with a probability
						if location.x < 18.84 { // closer to CONSTANTINE road
							target <- flip(PROB_CONSTANTINE) ? {5, rnd(65.5, 69.5)} : {rnd(16.5, 21), 88};
						} else {  // closer to CHENAVARD road
							target <- flip(PROB_CHENAVARD) ? {rnd(16.5, 21), 88} : {5, rnd(65.5, 69.5)};
						}
						
						do count_exit_pedestrians;
					} 
					
					step_delay <- step_delay > 0 ? step_delay - 1 : step_delay;
				}
				
				if step_delay = 0 { return false; }
	
			} 
			
			if (- 0.92 * location.x + location.y > 50.56) and MODEL_NAME = 'all_CC' and zone = high_density_zone(0) {
				if is_at_dense_region  {
					my_zone <- location.x < 19.84 ? high_density_zone(1) : high_density_zone(2);
				}
				
				do count_exit_pedestrians;
				
				return true;
			} 
			
			return true;
			
		} else if MODEL_NAME = 'all_CC' and zone != high_density_zone(0) {
			do die;
		} else if  MODEL_NAME = 'one_CC' {
			do die;
		} 
		
		return false;
	}
	
	action add_density_velocity(high_density_zone zone, int i, int j,  point v, float density_contribution) {
		zone.density_field[i][j] <- zone.density_field[i][j] + density_contribution;
		zone.average_velocity_field[i][j][0] <- zone.average_velocity_field[i][j][0] + density_contribution * v.x;
		zone.average_velocity_field[i][j][1] <- zone.average_velocity_field[i][j][1] + density_contribution * v.y;
	}

	action add_contribution_to_fields (high_density_zone zone) {
		if is_at_dense_region {
			float delta_x <- location.x - floor(location.x);
			float delta_y <- location.y - floor(location.y);
			
			// because list index from 0 to length - 1
			// calculate i, j index for cell

			float x_min <- zone.boundary[0];
			float y_min <- zone.boundary[2];
			
			int i <- int( (location.x - x_min) / zone.CELL_SIZE_X );
			int j <- int( (location.y - y_min) / zone.CELL_SIZE_Y );
			
			if (i > 0 and i < my_zone.GRID_WIDTH - 1) and (j > 0 and j < my_zone.GRID_HEIGHT - 1) {	
				do add_density_velocity(my_zone, i-1, j-1, velocity, min(1 - delta_x, 1 - delta_y) ^ my_zone.gamma / my_zone.CELL_AREA);
				do add_density_velocity(my_zone, i, j-1, velocity, min(delta_x, 1 - delta_y) ^ my_zone.gamma / my_zone.CELL_AREA);
				do add_density_velocity(my_zone, i, j, velocity, min(delta_x, delta_y) ^ my_zone.gamma / my_zone.CELL_AREA);
				do add_density_velocity(my_zone, i-1, j, velocity, min(1 - delta_x, delta_y) ^ my_zone.gamma / my_zone.CELL_AREA);
			} else {
				if ((i = 0 or i = my_zone.GRID_WIDTH - 1) and (j = 0 or j = my_zone.GRID_HEIGHT - 1)) { // on boundary cell
					do add_density_velocity(my_zone, i, j, velocity, 0.8);
				}
			}
		} 
	}
	
	point handle_collision (high_density_zone zone, int x, int y, point potential_location){
		point delta;
		int idx <- zone.GRID_WIDTH * x + y;
		if (x >= 0 and x <= zone.GRID_WIDTH - 1) and (y >= 0 and y <= zone.GRID_HEIGHT - 1) {
			loop p over: map_cell_individual[idx] {
				if !dead(p) and p != self {
					point p_ij <- potential_location - p.location;
					float distance <- norm(p_ij);
					// if collision happends => push them back
					if distance < (2 * AGENT_RADIUS) {
						float overlapped_distance <- 2 * AGENT_RADIUS - distance;
						point n_ij <- p_ij / distance;
						delta <- delta + n_ij * overlapped_distance ;
					}
				}
			}
		}
		
		return delta;
	}

	// --------------------- ACTION MULTI-LEVEL ---------------------
	// TACTICAL LEVEL
	action set_tactical_behavior (tactical_behavior new_tactical_level) {
			my_tactical_behavior <- new_tactical_level;
	}
	
	action perform_tactical_behavior {
		local_target <- my_tactical_behavior.get_local_target(self);
//		write local_target;
	}
	
	// OPERATIONAL LEVEL
	action set_operational_behavior (operational_behavior new_operational_level) {
			my_operational_behavior <- new_operational_level;
	}
	
	action perform_operational_behavior {
				
		if step_delay > 0 and step_delay < MAX_DELAY and MODEL_NAME = "FestivalofLightsexitmesh" {
			velocity <- velocity * 0.05 / norm(velocity) ;
			location <- location + velocity * step;
		} else {
			velocity <- my_operational_behavior.move(self);
			location <- location + velocity * step;
		}
		
		// update location of pedestrians
//		velocity <- my_operational_behavior.move(self);
//		location <- location + velocity * step;
	}
	
	// multizone
	action check_zone {
		if (is_at_dense_region = false) and (my_zone = nil) {
			loop z over: high_density_zone {
				if is_in_zone_boundary(location, z) {
					my_zone <- z;
					break;
				}
			}
		}
	}
	
	// ----------------------------------------
	// just Lyon simulation
//	reflex do_tactical_behavior when: ((local_target = nil or (- 0.92 * location.x + location.y > 50.56))
//		and (is_at_dense_region = false)) {
//		target <- location.x < 18.6 ? {5, rnd(65.5, 69.5)} : {rnd(16.5, 21), 88};
//		do perform_tactical_behavior;
//	}
	
	// in general
	//reflex do_tactical_behavior when: ((local_target = nil or distance_to(location, local_target) < DISTANCE_CHECK) 
	//	and (is_at_dense_region = false)) {
	// for "all_SFM" case study
	reflex do_tactical_behavior when: ((local_target = nil or distance_to(location, local_target) < DISTANCE_CHECK) 
		and (is_at_dense_region = false)) or ((MODEL_NAME = "all_SFM") and (- 0.92 * location.x + location.y > 50.56)) {
		do perform_tactical_behavior;
	}
	
	reflex do_operational_behavior {
		 do perform_operational_behavior;
	}
	
	// when: every(2#cycle)
	reflex update_status {
		if MODEL_NAME = "one_CC" and (location.x < 6.5 or location.y > 84.5) {
			do die;
		}
		
		if distance_to(location, target) < 0.5 {
			do die;
//			do stop;
		}
		
		// for all_SFM
		if (MODEL_NAME = "all_SFM" or MODEL_NAME = "FestivalofLightsexitmesh") and (location.x < 5 or location.y > 85) {
			do die;
		}
		
		if is_at_dense_region {
			// handle local collision
			neighbors <- individual at_distance (2 * AGENT_RADIUS) - self;
			point delta;
			loop neighbor over: neighbors {
				if !dead(neighbor) {
					point p_ij <- location - neighbor.location;
					float distance <- norm(p_ij);
					// push them back
					float overlapped_distance <- 2 * AGENT_RADIUS - distance;
					point n_ij <- p_ij / distance;
					//delta <- delta + n_ij * overlapped_distance / 2;
					//delta <- delta + n_ij * overlapped_distance * 2;
					delta <- delta + n_ij * overlapped_distance;
				}
			}
			location <- location + delta;
			
			if (int( (location.y - my_zone.boundary[2]) / my_zone.CELL_SIZE_Y ) = my_zone.GRID_HEIGHT) and is_in_dense_area(location, my_zone) = false {
				location <- location - delta;
			}
			
		} else {
			neighbors <- individual at_distance 1.0 - self;
			//obstacles <- building at_distance 3.0;     // error with nill value here, dont know why
			try {
			    obstacles <- building at_distance 3.0; 
			} catch {}
		}
		
//		trajectory <- trajectory + [location];
		
		if is_in_dense_area (location, my_zone) != is_at_dense_region { // change to new region
			is_at_dense_region <- !is_at_dense_region;
			if is_at_dense_region { // from low-density region to high-density region
				my_operational_behavior <- first(following);
				color <- #red;
				
				current_mesh <- nil;
				local_target <- nil;
				my_tactical_behavior <- nil;
				
			} else { // from high-density region to low-density region
//				my_operational_behavior <- first(avoiding) = nil ? first(walking_directly) : first(avoiding);
				my_operational_behavior <- first(avoiding) = nil ? (first(walking_directly) = nil ? first(avoiding_target) : first(walking_directly)) : first(avoiding);
//				my_operational_behavior <- first(avoiding_target);
				color <- #blue;
				
				if first(best_neighbor_mesh) != nil {
					current_mesh <- first(high_density_zone).exit_meshes[group_id];
					my_tactical_behavior <- first(best_neighbor_mesh);
				} else if first(best_adjacient_node) != nil {
					my_tactical_behavior <- first(best_adjacient_node);
				}
				
			}
		}
	
	}
	
	reflex update_information_when_exit when: ((location.x < 13) or (location.y > 74)) and !already_passed_exit_line {
		if (location.x < 13) {
			nb_instant_passed_people_constantine <- nb_instant_passed_people_constantine + 1;
		}
		
		if (location.y > 74) {
			nb_instant_passed_people_chenavard <- nb_instant_passed_people_chenavard + 1;
		}
		
		already_passed_exit_line <- true;
	}
	
	aspect default {
		draw circle(AGENT_RADIUS) color: color;
//		draw polyline(trajectory) color: #red;
	}
}
