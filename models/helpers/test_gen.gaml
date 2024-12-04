/**
* Name: testgen
* Based on the internal empty template. 
* Author: hdang
* Tags: 
*/


model testgen
import 'generate_medial_axis_function.gaml'
/* Insert your model definition here */

global {
	shape_file wall_shape_file <- shape_file('../../includes/place_des_Terreaux/ok.shp');
	shape_file bound_shape_file <- shape_file('../../includes/place_des_Terreaux/boundary.shp');
	geometry shape <- envelope(bound_shape_file);
	geometry bound <- shape;
	init {
		list<geometry> obstacles;
		create obstacle from: wall_shape_file;
		
		loop ob over: obstacle {
	    	obstacles <- obstacles + ob.shape;
	    }
		list<list> results <- generate_medial_axis(bound, obstacles, 10.0, 5.0);

		list<geometry> medial_axis <- results[0];
		loop ax over: medial_axis {
			create my_edge {
				shape <- ax;
			}
		}

		list<geometry> nav_meshes <- results[1];
		loop i from: 0 to: length(nav_meshes) - 1 {
			create my_nav_mesh {
				shape <- nav_meshes[i];
				list<point> points <- first(shape.points) = last(shape.points) ? shape.points - last(shape.points): shape.points;
				loop p over: points {
					centroid <- centroid + p;
				}
				centroid <- centroid / length(points);
			}
		}
		
		loop nav over: my_nav_mesh {
			create nav_centroid {
				center <- nav.centroid;
				shape <- center;
			}	
		}
		
		save my_nav_mesh type: shp to: "../../includes/gen_map/mesh.shp";
		save nav_centroid type: shp to: "../../includes/gen_map/node.shp";
		
	}
}

species obstacle {
	aspect default {
		draw shape color: #blue border: #grey;
	}
}

species my_edge {
	aspect default {
		draw shape color: #red;
	}
}

species nav_centroid {
	point center;
	aspect default {
		draw circle(0.1) color:#red at: center;
	}
}

species my_nav_mesh {
	point centroid;
	aspect default {
		draw shape color: #white border: #green;
//		draw circle(0.1) color:#red at: centroid;
	}
}

experiment exp {
	output {
		display my_display {
			species my_nav_mesh;
			species nav_centroid;
			species obstacle;
			species my_edge;
		}
	}
}