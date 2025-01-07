/**
* Name: generatemedialaxisfunction
* Based on the internal empty template. 
* Author: hdang
* Tags: 
*/


model generatemedialaxisfunction

/* Insert your model definition here */
global {	
	list<point> add_points(geometry geom, float dis_geom) {
		/* function to generate set of points on the boundary of geometry
		 * input:
		 * 		geom: geometry
		 * 		dis_geom: length of each segments to split edge to segments
		 * output: list of points
		 */
		list<point> points;
		if (dis_geom = 0) {
			points <- geom.points;
		} else {
			loop i from: 0 to: length(geom.points) - 2 {
				point p1 <- geom.points[i];
				point p2 <- geom.points[i + 1];
				points <- points + 	p1;
				// number of segments in one edge
				int n <- int(distance_to(p1, p2) / dis_geom);
				if (n >= 2) {
					loop j from: 1 to: n - 1 {
						points <- points + (p1 * j / n + p2 * (n - j) / n);
					}
				}
			}
			// add last point if needed
			if last(geom.points) != first(points) {
				points <- points + last(geom.points); 
			}
		}
		
		return points;
	}
	
	list<list<geometry>> generate_medial_axis (geometry bound, list<geometry> obstacles, float dis_bound, float dis_obstacle) {
		/* function to generate medial axis, nav mesh of the enviroment based on voronoi diagram
		 * input:
		 * 		bound: boundary of the environment
		 * 		obstacles: list of obstacles geometry
		 * 		dis_bound: length of each segment on boundary
		 * 		dis_obstacle: length of each segment on obstacles
		 * output: medial axis, nav mesh
		 */
		
		list<point> points;
		// add points on boundary to vonoroi seeds
		points <- points + add_points(bound, dis_bound);
		
		// add points on obstacle boundary to voronoi seeds
		loop ob over: obstacles {
			points <- points + add_points(ob, dis_obstacle);
		}
		
		list<geometry> boundaries <- voronoi(points, bound + 1);
		
		// get voronoi edges
		list<geometry> medial_axis;
		geometry obstacles_union <- union(obstacles);
		loop cell over: boundaries {
			list<geometry> segments <- to_segments(cell);
			loop seg over: segments {
				if ((seg in medial_axis = false) and (polyline(reverse(seg.points)) in medial_axis = false)) {  // remove duplicate edges
					// keep only interior edges, which do not intersect obstacles
					if (seg.points[0] overlaps bound) and (seg.points[1] overlaps bound) and (seg intersects obstacles_union = false) {
						medial_axis <- medial_axis + seg;
					}
				}
			}
		}

		list<geometry> nav_meshes;
		loop voro_cell over: boundaries {
			geometry my_mesh <- intersection(polygon(voro_cell.points), bound) - union(obstacles);
			nav_meshes <- nav_meshes + my_mesh;
		}

		return [medial_axis, nav_meshes];
		
	}
}

