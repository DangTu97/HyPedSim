/**
* Name: tacticallevel
* Based on the internal empty template. 
* Author: hdang
* Tags: 
*/


model tacticallevel
import 'individual.gaml'

/* Insert your model definition here */

species tactical_behavior {
	point get_local_target(individual i) virtual: true;
}

species best_adjacient_node parent: tactical_behavior {
	float compute_cost (individual i, point node) {
		point current_location <- i.location;
		point final_target <- i.target;

		return distance_to(final_target, node);
	}
	
	point get_local_target(individual i) {
		list<float> costs;

		if (i.local_target = nil) {
			point shortest_node <- graph_network.vertices closest_to i.location;
			return shortest_node;
		} 
		
		// local_target is a node in the graph network
		list<point> adjacient_nodes <- graph_network neighbors_of i.local_target;

		loop adjacient_node over: adjacient_nodes {
			costs <- costs + [compute_cost(i, adjacient_node)];
		}
		int best_idx <- costs index_of min(costs);
		
		if length(adjacient_nodes) = 0 {write i;}
		
		point best_node <- adjacient_nodes[best_idx];
		
		if distance_to(i.local_target, i.target) < distance_to(best_node, i.target) {
			return i.target;
		}
		
		return best_node;
	}
}

species best_neighbor_mesh parent: tactical_behavior {
	float compute_cost (individual i, point node) {
		point current_location <- i.location;
		point final_target <- i.target;

		return distance_to(final_target, node);
	}
	
	point get_local_target(individual i) {
		list<float> costs;
		
		// local_target is a centroid of nav mesh
		list<point> adjacient_mesh_centroids;
		
		loop neighbor_mesh over: i.current_mesh.neighbors {
			adjacient_mesh_centroids <- adjacient_mesh_centroids + [neighbor_mesh.centroid];
			costs <- costs + [compute_cost(i, neighbor_mesh.centroid)];
		}

		int best_idx <- costs index_of min(costs);
		
		point best_neighbor_centroid <- adjacient_mesh_centroids[best_idx];
		if distance_to(i.current_mesh.centroid, i.target) < distance_to(best_neighbor_centroid, i.target) {
			return i.target;
		}
		
		//i.current_mesh.pedestrians <- i.current_mesh.pedestrians - i;
		i.old_mesh <- i.current_mesh;
		
		i.current_mesh <- i.current_mesh.neighbors[best_idx];
		//i.current_mesh.pedestrians <- i.current_mesh.pedestrians + i;
		
		return best_neighbor_centroid;
	}
}

species best_neighbor_mesh2 parent: tactical_behavior {
	float compute_cost (individual i, point node) {
		point current_location <- i.location;
		point final_target <- i.target;

		return distance_to(final_target, node);
	}
	
	point get_local_target(individual i) {
		list<float> costs;
		
		// local_target is a centroid of nav mesh
		list<point> adjacient_mesh_centroids;
		list<nav_mesh> validated_meshes;
		loop neighbor_mesh over: i.current_mesh.neighbors {
			if (neighbor_mesh.is_corner_mesh = false) and (neighbor_mesh != i.old_mesh) {	
//			if (neighbor_mesh.is_corner_mesh = false) {	
//				write neighbor_mesh;
				validated_meshes <- validated_meshes + [neighbor_mesh];
				adjacient_mesh_centroids <- adjacient_mesh_centroids + [neighbor_mesh.centroid];
				costs <- costs + [compute_cost(i, neighbor_mesh.centroid)];
			}
		}

		int best_idx <- costs index_of min(costs);
		
//		write adjacient_mesh_centroids;
//		write costs;
//		write best_idx;
		
//		if best_idx = -1 {
//			write "--";
//			write i;
//			write i.is_at_dense_region;
//			write cycle;
//			write best_idx;
//			write length(adjacient_mesh_centroids);
//			write i.old_mesh;
//		}
		
		point best_neighbor_centroid <- adjacient_mesh_centroids[best_idx];
//		if distance_to(i.current_mesh.centroid, i.target) < distance_to(best_neighbor_centroid, i.target) {
		if i.target overlaps i.current_mesh.shape {
			return i.target;
		}
		
		//i.current_mesh.pedestrians <- i.current_mesh.pedestrians - i;
		i.old_mesh <- i.current_mesh;
		
		i.current_mesh <- validated_meshes[best_idx];
		//i.current_mesh.pedestrians <- i.current_mesh.pedestrians + i;
		
		return best_neighbor_centroid;
	}
}

species tactical_all_SFM parent: tactical_behavior {
	
	point get_local_target(individual i) {
		// =============================
		// count outflow
//		if i.local_target != i.target {
		if i.local_target = {19.5, 66.8} {
			nb_exit_pedestrians <- nb_exit_pedestrians + 1;
		}
		// =============================
		
		//i.target <- location.x < 20.84 ? {5, rnd(65.5, 69.5)} : {rnd(16.5, 21), 88};
		return i.target;
	}
}