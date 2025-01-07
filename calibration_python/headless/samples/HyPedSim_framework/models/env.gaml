/**
* Name: env
* Based on the internal empty template. 
* Author: hdang
* Tags: 
*/


model env
import 'Individual/individual.gaml'
/* Insert your model definition here */

species building {
	float d <-  name = 'building9' ? 0.7 : rnd(3.5, 5.0);
	aspect default {
//		draw shape color: #yellow border: #black depth: rnd(1.5, 2.0);
		//draw shape color: rgb(209, 209, 209) border: #black depth: d;
		draw shape color: #grey border: #black depth: d;
	}
}

species road {
	aspect default {
		draw shape color: #grey;
	}
}

species nav_mesh {
	rgb my_color;
	point centroid;
	bool is_corner_mesh;
	list<nav_mesh> neighbors;
	list<individual> pedestrians;
	
	aspect default {
		draw shape color: my_color border: #green;
//		draw circle(0.1) color: #red at: centroid;
	}
}

//species high_density_zone {
//	map<int, nav_mesh> exit_meshes; // group vs mesh
//	list<float> boundary; // rectangular boundary [x_min, x_max, y_min, y_max]
//	
//	aspect default {
//		draw shape color: #black;
//	}
//}