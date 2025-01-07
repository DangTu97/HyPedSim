# HyPedSim
A hybrid framework for pedestrian simulation that allows pedestrians to dynamically switch models based on density-based zones in the environment.

Workflow:

![alt text](https://github.com/DangTu97/HyPedSim/blob/master/workflow.png?raw=true)

How to run calibration:

1. Prepare simulation in GAMA headless mode
2. In calibration_python folder, run: python GA_calibration_parallel.py --population_size 128 --num_generations 10000 --mutation_rate 0.01 


Cite this work: Dang H-T, Gaudou B, Verstaevel N. HyPedSim: A Multi-Level Crowd-Simulation Framework—Methodology, Calibration, and Validation. Sensors. 2024; 24(5):1639. https://doi.org/10.3390/s24051639
