/**
* Name: test
* Based on the internal empty template. 
* Author: hdang
* Tags: 
*/


model test

/* Insert your model definition here */

global {
	int sim_idx <- 0;
	float x <- 0.0;
	float y <- 0.0;
	float z <- 0.0;
	float t <- 0.0;
	
	
	
	reflex compute_fitness when: cycle = 2 {
		float fitness <- x + y + z + t;
		save [sim_idx, x, y, z, t, fitness] type: csv to: 'test.csv' rewrite: false;
	}
}

experiment test {
	parameter "sim_idx" var: sim_idx;
	parameter "x" var: x;
	parameter "y" var: y;
	parameter "z" var: z;
	parameter "t" var: t;
	
	output {
		
	}

}
