/**
* Name: generateevn
* Based on the internal empty template. 
* Author: hdang
* Tags: 
*/


model generateenv

/* Insert your model definition here */

global {
	float environment_size <- 120 #m;
	geometry shape <- envelope(square(environment_size));
	
	float room_width <- 50 #m;
	float room_length <- 50 #m;
	float bottleneck_width <- 5 #m;
	float bottleneck_length <- 40 #m;
	
	init {
		geometry room_area <- polyline([{0, 0}, {room_width, 0}, {room_width, room_length}, {0, room_length}, {0, 0}]);
		geometry bottleneck_area <- polyline([{0, 0}, {bottleneck_length, 0}, {bottleneck_length, bottleneck_width}, {0, bottleneck_width}, {0, 0}]) 
									at_location {room_width + bottleneck_length/2, room_length/2};
		geometry gate1 <- (room_area inter bottleneck_area);
		geometry gate2 <- gate1 at_location {room_width + bottleneck_length, room_length/2};	
					
		create wall {
			shape <- room_area + bottleneck_area - gate1 - gate2;
		}

//		list<geometry> network_edges <- [polyline([{room_width - 4, room_length/2}, {room_width + bottleneck_length, room_length/2}]),
//										polyline([{room_width + bottleneck_length, room_length/2}, {environment_size, room_length/4}]),
//										polyline([{room_width + bottleneck_length, room_length/2}, {environment_size, room_length * 3/4}])];

		list<geometry> network_edges <- [polyline([{room_width - 4, room_length/2}, {room_width + bottleneck_length/4, (room_length + 2)/2}, 
									     {room_width + bottleneck_length/2, (room_length - 2)/2}, {room_width + bottleneck_length * 3/4, (room_length + 3)/2}, {room_width + bottleneck_length, room_length/2}]),
										polyline([{room_width + bottleneck_length, room_length/2}, {environment_size, room_length/4}]),
										polyline([{room_width + bottleneck_length, room_length/2}, {environment_size, room_length * 3/4}])];
							
		loop edge over: network_edges {
			create graph_network {
				shape <- edge;
			}
		}
		
		save wall type: shp to: "../../includes/bottleneck/wall.shp";
		save graph_network type: shp to: "../../includes/bottleneck/network_segments.shp";
	}
}

species wall {
	aspect default {
		draw shape color: #grey;
	}
}


species graph_network {
	aspect default {
		draw shape color: #grey;
	}
}

experiment exp {
	output {
		display map  {
			species wall;
			species graph_network;
			
		}
	}
}