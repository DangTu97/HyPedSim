/**
* Name: MovingStrategy
* Based on the internal empty template. 
* Author: hdang
* Tags: 
*/


model operationallevel
import 'individual.gaml'

/* Insert your model definition here */

species operational_behavior {
	point move(individual i) virtual: true;
}

species waiting parent: operational_behavior {
	point move(individual i) {
		return {0.0, 0.0};
	}
}

species walking_directly parent: operational_behavior {
	point move(individual i) {
//		// now it goes directly to the goal
		if (i.local_target != nil) {
			return (i.local_target - i.location) * 3.5 / norm(i.local_target - i.location);
		}
		return (i.target - i.location) / norm(i.target - i.location);
	}
}

species avoiding_target parent: operational_behavior {
	
	point move(individual i) {
		//compute target force
		point e <-  (i.target - i.location) / distance_to (i.target, i.location);
		point target_force <- (e * preferred_speed - i.velocity) / reaction_time;
		
//		 compute repulsion force with other pedestrians
		point pedestrian_forces;		
		if (i.current_mesh != nil) {
			loop ped over: i.neighbors {
				if dead(ped) = false {
					float d <- distance_to(i.location, ped.location);
					point nij <- (i.location - ped.location) / d;
					point force <- nij * A * exp((AGENT_RADIUS + AGENT_RADIUS - d) / B);
					pedestrian_forces <- pedestrian_forces + force;
				}
			}
		}
		
		// compute repulsion force with obstacles
		point obstacle_forces;
		loop ob over: i.obstacles {
			point closest_point_from_ob <- first(ob closest_points_with i.location);
			float d <- distance_to(i.location, closest_point_from_ob);
			if (d > 0) {
				point nij <- (i.location - closest_point_from_ob) / d;
				point force <- nij * A_ob * exp((AGENT_RADIUS - d) / B_ob);
				obstacle_forces <- obstacle_forces + force;
			}
		}
		
		point total_force <- target_force + pedestrian_forces + obstacle_forces;
		
		return i.velocity + total_force * STEP;
	}
}

species avoiding parent: operational_behavior {

	point move(individual i) {
		//compute target force
		point e <-  (i.local_target - i.location) / distance_to (i.local_target, i.location);
//		point e <-  (i.target - i.location) / distance_to (i.target, i.location);
		point target_force <- (e * preferred_speed - i.velocity) / reaction_time;
		
		// compute repulsion force with other pedestrians
		point pedestrian_forces;		
		if (i.current_mesh != nil) {
			loop ped over: i.neighbors {
				if dead(ped) = false {
					float d <- distance_to(i.location, ped.location);
					point nij <- (i.location - ped.location) / d;
					point force <- nij * A * exp((AGENT_RADIUS + AGENT_RADIUS - d) / B);
					pedestrian_forces <- pedestrian_forces + force;
				}
			}
		}
		point total_force <- target_force + pedestrian_forces ;

		return i.velocity + total_force * STEP;
		
	}
}

species avoiding_SFM parent: operational_behavior {
	
	point move(individual i) {
		//compute target force
		point e <-  (i.local_target - i.location) / distance_to (i.local_target, i.location);
		point target_force <- (e * preferred_speed - i.velocity) / reaction_time;
		
//		 compute repulsion force with other pedestrians
		point pedestrian_forces;		
		if (i.current_mesh != nil) {
			loop ped over: i.neighbors {
				if dead(ped) = false {
					float d <- distance_to(i.location, ped.location);
					point nij <- (i.location - ped.location) / d;
					point force <- nij * A * exp((AGENT_RADIUS + AGENT_RADIUS - d) / B);
					pedestrian_forces <- pedestrian_forces + force;
				}
			}
		}
		
		// compute repulsion force with obstacles
		point obstacle_forces;
		loop ob over: i.obstacles {
//			point closest_point_from_ob <- first(i.location closest_points_with ob);
			point closest_point_from_ob <- first(ob closest_points_with i.location);
			float d <- distance_to(i.location, closest_point_from_ob);
			if (d > 0) {
				point nij <- (i.location - closest_point_from_ob) / d;
				point force <- nij * A_ob * exp((AGENT_RADIUS - d) / B_ob);
				obstacle_forces <- obstacle_forces + force;
			}
		}
		
		point total_force <- target_force + pedestrian_forces + obstacle_forces;
//		point total_force <- target_force + obstacle_forces;
			
//		return  total_force * 1.4 / norm(total_force); 	// normalized value is not good for fundamental diagram
		return i.velocity + total_force * STEP;
	}
}

species following parent: operational_behavior {
	
	point move(individual i) {
		float x_min <- i.my_zone.boundary[0];
		float y_min <- i.my_zone.boundary[2];
		
		int x <- int ( (i.location.x - x_min) / i.my_zone.CELL_SIZE_X );
		int y <- int ( (i.location.y - y_min) / i.my_zone.CELL_SIZE_Y );
		
		if (x >= 0 and x <= i.my_zone.GRID_WIDTH - 1) and (y >= 0 and y <= i.my_zone.GRID_HEIGHT - 1) {
			float gradient_norm <- sqrt(i.my_zone.group_gradient_field_WE_SN[i.group_id][x][y][0] ^ 2 + i.my_zone.group_gradient_field_WE_SN[i.group_id][x][y][1] ^ 2);
			point target_direction;
			
			if (gradient_norm = 0) { // gradient_norm = 0 at obstacle or boundary cells
				// walked into obstacle cell -> keep moving
				// use old velocity
				target_direction <- i.velocity / norm(i.velocity); 
			} else {
				target_direction <- - {i.my_zone.group_gradient_field_WE_SN[i.group_id][x][y][0], i.my_zone.group_gradient_field_WE_SN[i.group_id][x][y][1]} / gradient_norm;
			}
	
			if !is_number(target_direction.x) or !is_number(target_direction.y) {
				target_direction <- i.velocity / norm(i.velocity); 
			}
			
			float x_component_factor <- target_direction.x * target_direction.x;
	        float y_component_factor <- target_direction.y * target_direction.y;
			
			float speed <- 0.0;
			list<float> anisotropic_speeds <- i.my_zone.speed_field_NESW[x][y];
			
			// North
			speed <- target_direction.y > 0 ? speed + y_component_factor * anisotropic_speeds[0] : speed;
			
			//East
			speed <- target_direction.x > 0 ? speed + x_component_factor * anisotropic_speeds[1] : speed;
			
			// South
			speed <- target_direction.y < 0 ? speed + y_component_factor * anisotropic_speeds[2] : speed;
			
			// West
			speed <- target_direction.x < 0 ? speed + x_component_factor * anisotropic_speeds[3] : speed;
			
			speed <- min(speed, MAXIMUM_SPEED);
				
			// add collision resolver
			point velocity <- target_direction * speed;
			point delta;
			
			// ------------ improvement --------------------
//			point flow_velocity <- target_direction * speed;
////			point desired_velocity <- (i.target - location) * 1.34 / norm(i.target - location);
//			point desired_velocity <- (first(high_density_zone).exit_meshes[1].centroid - location) * 1.34 / norm(first(high_density_zone).exit_meshes[1].centroid - location);
//			
//			float Rho_max <- 8.0;
//			velocity <- desired_velocity + (flow_velocity - desired_velocity) * (density_field[x][y] / Rho_max);
			
			if (MODEL_NAME = 'one_CC' or MODEL_NAME = 'all_CC') {
				velocity <- velocity + {i.my_zone.wall_repulsion_velocity[x][y][0], i.my_zone.wall_repulsion_velocity[x][y][1]};
			}
			
			return velocity + delta;
//			return velocity + delta * (1 / STEP);
		
		}
	}
	
}
