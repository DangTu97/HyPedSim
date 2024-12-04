/**
* Name: detectdenseregion
* Based on the internal empty template. 
* Author: hdang
* Tags: 
*/


model detection

/* Insert your model definition here */

global {

	float rect_distance (float x1, float y1, float x1b, float y1b, float x2, float y2, float x2b, float y2b) {
		// compute the distance between two rectangles
		// a rectangle is denoted as two points: {x_min, y_min}, {x_max, y_max}
		bool left <- x2b < x1;
		bool right <- x1b < x2;
		bool bottom <- y2b < y1;
		bool top <- y1b < y2;
		
		if top and left {
			return ((x1 - x2b) ^ 2 + (y1b - y2) ^ 2) ^ 0.5;
		} else if left and bottom {
			return ((x1 - x2b) ^ 2 + (y1 - y2b) ^ 2) ^ 0.5;
		} else if  bottom and right {
			return ((x1b - x2) ^ 2 + (y1 - y2b) ^ 2) ^ 0.5;
		} else if right and top {
			return ((x1b - x2) ^ 2 + (y1b - y2) ^ 2) ^ 0.5;
		} else if left {
			return abs(x1 - x2b);
		} else if right {
			return abs(x2 - x1b);
		} else if bottom {
			return abs(y1 - y2b);
		} else if top {
			return abs(y2 - y1b);
		} else {
			return 0.0;
		}
	}
	
	list<float> merge_rect(float x_min, float y_min, float x_max, float y_max, float xc_min, float yc_min, float xc_max, float yc_max) {
		// merge two rectangle {x_min, y_min}, {x_max, y_max} and {xc_min, yc_min}, {xc_max, yc_max}
		return [min(x_min, xc_min), max(x_max, xc_max), min(y_min, yc_min), max(y_max, yc_max)];
	}
	
	list<float> get_boundary (list<list<float>> cluster) {
		// get rectangular boundary [x_min, x_max, y_min, y_max]
		// of all points in the cluster
		list<float> max_cluster_x_coordinates;
		list<float> max_cluster_y_coordinates;

		loop p over: cluster {
			max_cluster_x_coordinates <- max_cluster_x_coordinates + [p[0]];
			max_cluster_y_coordinates <- max_cluster_y_coordinates + [p[1]];
		}
		
		float x_min <- min(max_cluster_x_coordinates);
		float x_max <- max(max_cluster_x_coordinates);
		float y_min <- min(max_cluster_y_coordinates);
		float y_max <- max(max_cluster_y_coordinates);
		
		return [x_min, x_max, y_min, y_max];
	}
    
	list<float> detect_dense_region (list<list<float>> points, float eps, int min_sample, int min_group_members, float merging_distance) {
		
		// each cluster contains indices of members in points
		list<list<int>> output <- dbscan(points, eps, min_sample);
		// remove noise
		list<list<int>> valid_clusters_indices <- output where (length(each) > min_group_members);

		int nb_clusters <- length(valid_clusters_indices);
		list<list<list<float>>> clusters;
		
		// get nb of members for each cluster
		// add coordinates to their clusters
		list<int> nb_members_in_clusters;
		loop cluster_idx over: valid_clusters_indices {
			nb_members_in_clusters <- nb_members_in_clusters + length(cluster_idx);
			list<list<float>> points_in_each_cluster;
			loop id over: cluster_idx {
				points_in_each_cluster <- points_in_each_cluster + [points[id]];
			}
			clusters <- clusters + [points_in_each_cluster];
		}
		
		if length(nb_members_in_clusters) = 0 {
			list<float> nothing;
			return nothing;
		}
		
		// find the maximum cluster
		int max_idx <- nb_members_in_clusters index_of max(nb_members_in_clusters);
		list<list<float>> max_cluster <- clusters[max_idx];
		
		// get boundary of the max cluster
		list<float> max_cluster_boundary <- get_boundary (max_cluster);

		float x_min <- max_cluster_boundary[0];
		float x_max <- max_cluster_boundary[1];
		float y_min <- max_cluster_boundary[2];
		float y_max <- max_cluster_boundary[3];
		
	    // compute distance from other clusters to the maximum cluster
		list<float> cluster_distance;
		list<int> cluster_indices;
		loop i from: 0 to: nb_clusters - 1 {
			list<float> boundary <- get_boundary(clusters[i]);
			float xc_min <- boundary[0];
			float xc_max <- boundary[1];
			float yc_min <- boundary[2];
			float yc_max <- boundary[3];
		    float d <- rect_distance(x_min, y_min, x_max, y_max, xc_min, yc_min, xc_max, yc_max);
		    if (i != max_idx) {
		    	cluster_distance <- cluster_distance + [d];
		    	cluster_indices <- cluster_indices + [i];
		    } 
		}
		
		// sort distance
		list<float> sorted_cluster_distance <- cluster_distance sort_by (each);

	    // merge neighboring cluster if its valid
	    
//		loop distance over: sorted_cluster_distance {
//			// update distance to new region
//			int idx <- cluster_distance index_of distance;
//			int id <- cluster_indices[idx];
//		    list<float> boundary <- get_boundary(clusters[id]);
//			float xc_min <- boundary[0];
//			float xc_max <- boundary[1];
//			float yc_min <- boundary[2];
//			float yc_max <- boundary[3];
//			float d_new <- rect_distance(x_min, y_min, x_max, y_max, xc_min, yc_min, xc_max, yc_max);
//
//			if (d_new < merging_distance) {
//				list<float> new_boundary <- merge_rect(x_min, y_min, x_max, y_max, xc_min, yc_min, xc_max, yc_max);
//				x_min <- new_boundary[0];
//				x_max <- new_boundary[1];
//				y_min <- new_boundary[2];
//				y_max <- new_boundary[3];
//			}
//      			  
//		}
		
		return [x_min, x_max, y_min, y_max];
	}
	
	
}