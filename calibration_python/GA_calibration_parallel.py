# -*- coding: utf-8 -*-
"""
Created on Sun Jan 14 19:32:43 2024

@author: 33765
"""

from multiprocessing import Pool
import random
import os
from bs4 import BeautifulSoup
import numpy as np
import pandas as pd
import random
import argparse
from pathlib import Path

gama_headless_folder = '/Applications/Gama.app/Contents/headless/'
step = 0

# Hyperparameters
min_threshold_MAX_DELAY = 0
max_threshold_MAX_DELAY = 10

min_threshold_PROB_CONSTANTINE = 0.0
max_threshold_PROB_CONSTANTINE = 1.0

min_threshold_PROB_CHENAVARD = 0.0
max_threshold_PROB_CHENAVARD = 1.0

# CC model
min_threshold_MAXIMUM_SPEED = 0.8
max_threshold_MAXIMUM_SPEED = 1.6

min_threshold_MINIMUM_SPEED = 0.05
max_threshold_MINIMUM_SPEED = 0.25

min_threshold_MAXIMUM_DENSITY = 6.0
max_threshold_MAXIMUM_DENSITY = 8.0

min_threshold_MINIMUM_DENSITY = 0.05
max_threshold_MINIMUM_DENSITY = 0.5

# SFM model
min_threshold_A = 0.5
max_threshold_A = 5.0

min_threshold_B = 0.1
max_threshold_B = 0.5

min_threshold_preferred_speed = 0.8
max_threshold_preferred_speed = 1.5

min_threshold_reaction_time = 0.4
max_threshold_reaction_time = 0.6

def update_xml_file(xml_file_path, input_parameters):
    '''
    Parameters
    ----------
    input_parameters : dict
        includes sim and x.

    Returns
    -------
    write xml file.

    '''
    
    # read xml file
    with open(xml_file_path, 'r') as f:
        data = f.read()
        
    xml_object = BeautifulSoup(data, "xml")
    
    # change xml configuration
    for tag in xml_object.find_all('Parameter', {'name':'MAX_DELAY'}):
        tag['value'] = input_parameters['MAX_DELAY']
        
    for tag in xml_object.find_all('Parameter', {'name':'PROB_CONSTANTINE'}):
        tag['value'] = input_parameters['PROB_CONSTANTINE']
        
    for tag in xml_object.find_all('Parameter', {'name':'PROB_CHENAVARD'}):
        tag['value'] = input_parameters['PROB_CHENAVARD']
   
    for tag in xml_object.find_all('Parameter', {'name':'MAXIMUM_SPEED'}):
        tag['value'] = input_parameters['MAXIMUM_SPEED']
        
    for tag in xml_object.find_all('Parameter', {'name':'MINIMUM_SPEED'}):
        tag['value'] = input_parameters['MINIMUM_SPEED']
        
    for tag in xml_object.find_all('Parameter', {'name':'MAXIMUM_DENSITY'}):
        tag['value'] = input_parameters['MAXIMUM_DENSITY']
        
    for tag in xml_object.find_all('Parameter', {'name':'MINIMUM_DENSITY'}):
        tag['value'] = input_parameters['MINIMUM_DENSITY']
    
    for tag in xml_object.find_all('Parameter', {'name':'A'}):
        tag['value'] = input_parameters['A']
        
    for tag in xml_object.find_all('Parameter', {'name':'B'}):
        tag['value'] = input_parameters['B']
        
    for tag in xml_object.find_all('Parameter', {'name':'preferred_speed'}):
        tag['value'] = input_parameters['preferred_speed']
        
    for tag in xml_object.find_all('Parameter', {'name':'reaction_time'}):
        tag['value'] = input_parameters['reaction_time']
        
    for tag in xml_object.find_all('Parameter', {'name':'sim_idx'}):
        tag['value'] = input_parameters['sim_idx']
    
    f = open(xml_file_path, "w")
    f.write(BeautifulSoup.prettify(xml_object))
    f.close()
    
def read_simulation_result(sim_result_file):
    try: 
        df = pd.read_csv(sim_result_file)
        fitness = df.similarity_score
        return float(fitness)
    except: 
        return 10

def run_simulation(key):
    os.chdir(gama_headless_folder)
    command = "sh ./gama-headless.sh ./samples/calibration_parallel_xml/calibration_" + str(key) + ".xml ./test"
    os.system(command)

def fitness(individual_with_key):
    global step
    individual, key = individual_with_key
    MAX_DELAY, PROB_CONSTANTINE, PROB_CHENAVARD, MAXIMUM_SPEED, MINIMUM_SPEED, MAXIMUM_DENSITY, MINIMUM_DENSITY, A, B, preferred_speed, reaction_time = individual
    inputs = {'MAX_DELAY': MAX_DELAY, 
              'PROB_CONSTANTINE': PROB_CONSTANTINE, 
              'PROB_CHENAVARD': PROB_CHENAVARD, 
              'MAXIMUM_SPEED': MAXIMUM_SPEED,
              'MINIMUM_SPEED': MINIMUM_SPEED,
              'MAXIMUM_DENSITY': MAXIMUM_DENSITY,
              'MINIMUM_DENSITY': MINIMUM_DENSITY,
              'A': A,
              'B': B,
              'preferred_speed': preferred_speed,
              'reaction_time': reaction_time,
              'sim_idx': str(key)}
    
    xml_file_path =  gama_headless_folder + '/samples/calibration_parallel_xml/calibration_' + str(key) + '.xml'
    sim_result_file = gama_headless_folder + '/samples/HyPedSim_framework/models/Experiments/Lyon_exit/calibration/output/results_' + str(key) + '.csv'
    
    update_xml_file(xml_file_path, inputs)
    run_simulation(key)
    fit = read_simulation_result(sim_result_file)
    
    # save to track files
    file = 'calibration_sim_results/result_tracks_' + str(key) + '.csv'
    if os.path.isfile(file):
        df = pd.read_csv(file)
    else:
        df = pd.DataFrame(columns=['step', 'MAX_DELAY', 'PROB_CONSTANTINE', 'PROB_CHENAVARD', "MAXIMUM_SPEED", "MINIMUM_SPEED", "MAXIMUM_DENSITY", "MINIMUM_DENSITY", "A", "B", "preferred_speed", "reaction_time", 'fitness'])
    new_row = pd.Series({
              'step': step,
              'MAX_DELAY': MAX_DELAY, 
              'PROB_CONSTANTINE': PROB_CONSTANTINE, 
              'PROB_CHENAVARD': PROB_CHENAVARD, 
              'MAXIMUM_SPEED': MAXIMUM_SPEED,
              'MINIMUM_SPEED': MINIMUM_SPEED,
              'MAXIMUM_DENSITY': MAXIMUM_DENSITY,
              'MINIMUM_DENSITY': MINIMUM_DENSITY,
              'A': A,
              'B': B,
              'preferred_speed': preferred_speed,
              'reaction_time': reaction_time,
              'fitness': fit}) 
    # df = df.append(new_row, ignore_index=True)
    df = pd.concat([df, pd.DataFrame([new_row])], ignore_index=True)
    df.to_csv(file, index=False)
        
    return [MAX_DELAY, PROB_CONSTANTINE, PROB_CHENAVARD, MAXIMUM_SPEED, MINIMUM_SPEED, MAXIMUM_DENSITY, MINIMUM_DENSITY, A, B, preferred_speed, reaction_time, fit]

def mutate(individual, mutation_rate=0.01):
    MAX_DELAY, PROB_CONSTANTINE, PROB_CHENAVARD, MAXIMUM_SPEED, MINIMUM_SPEED, MAXIMUM_DENSITY, MINIMUM_DENSITY, A, B, preferred_speed, reaction_time = individual
    
    if random.random() < mutation_rate:
        MAX_DELAY = random.randint(min_threshold_MAX_DELAY, max_threshold_MAX_DELAY)
        
    if random.random() < mutation_rate:  
        PROB_CONSTANTINE = round(random.uniform(min_threshold_PROB_CONSTANTINE, max_threshold_PROB_CONSTANTINE), 2)
        
    if random.random() < mutation_rate:
        PROB_CHENAVARD = round(random.uniform(min_threshold_PROB_CHENAVARD, max_threshold_PROB_CHENAVARD), 2)
        
    if random.random() < mutation_rate:
        MAXIMUM_SPEED = round(random.uniform(min_threshold_MAXIMUM_SPEED, max_threshold_MAXIMUM_SPEED), 2)
    
    if random.random() < mutation_rate:
        MINIMUM_SPEED = round(random.uniform(min_threshold_MINIMUM_SPEED, max_threshold_MINIMUM_SPEED), 2)
        
    if random.random() < mutation_rate:
        MAXIMUM_DENSITY = round(random.uniform(min_threshold_MAXIMUM_DENSITY, max_threshold_MAXIMUM_DENSITY), 2)
        
    if random.random() < mutation_rate:
        MINIMUM_DENSITY = round(random.uniform(min_threshold_MINIMUM_DENSITY, max_threshold_MINIMUM_DENSITY), 2)
        
    if random.random() < mutation_rate:
        A = round(random.uniform(min_threshold_A, max_threshold_A), 2)
        
    if random.random() < mutation_rate:
        B = round(random.uniform(min_threshold_B, max_threshold_B), 2)
        
    if random.random() < mutation_rate:
        preferred_speed = round(random.uniform(min_threshold_preferred_speed, max_threshold_preferred_speed), 2)
    
    if random.random() < mutation_rate:
        reaction_time = round(random.uniform(min_threshold_reaction_time, max_threshold_reaction_time), 2)
        
    return [MAX_DELAY, PROB_CONSTANTINE, PROB_CHENAVARD, MAXIMUM_SPEED, MINIMUM_SPEED, MAXIMUM_DENSITY, MINIMUM_DENSITY, A, B, preferred_speed, reaction_time]

def crossover(parent1, parent2):
    child = []
    for i in range(len(parent1)):
        if random.random() < 0.5:
            child.append(parent1[i])
        else:
            child.append(parent2[i])
            
    return child

def run_GA():
    parser = argparse.ArgumentParser(description='Genetic Algorithm for calibration of HyPedSim framework')
    parser.add_argument('--population_size', type=int, default=128, help='Population size')
    parser.add_argument('--num_generations', type=int, default=10000, help='Number of generations')
    parser.add_argument('--mutation_rate', type=float, default=0.01, help='Mutation rate')
    args = parser.parse_args()

    population_size = args.population_size
    num_generations = args.num_generations
    mutation_rate = args.mutation_rate
    #  find_max=True => get max fitness, find_max=False => get min fitness
    find_max = True

    df = pd.DataFrame(columns=['step', 'individual', 'fitness'])

    population = [[random.randint(min_threshold_MAX_DELAY, max_threshold_MAX_DELAY),
                   round(random.uniform(min_threshold_PROB_CONSTANTINE, max_threshold_PROB_CONSTANTINE), 2),
                   round(random.uniform(min_threshold_PROB_CHENAVARD, max_threshold_PROB_CHENAVARD), 2),
                   round(random.uniform(min_threshold_MAXIMUM_SPEED, max_threshold_MAXIMUM_SPEED), 2),
                   round(random.uniform(min_threshold_MINIMUM_SPEED, max_threshold_MINIMUM_SPEED), 2),
                   round(random.uniform(min_threshold_MAXIMUM_DENSITY, max_threshold_MAXIMUM_DENSITY), 2),
                   round(random.uniform(min_threshold_MINIMUM_DENSITY, max_threshold_MINIMUM_DENSITY), 2),
                   round(random.uniform(min_threshold_A, max_threshold_A), 2),
                   round(random.uniform(min_threshold_B, max_threshold_B), 2),
                   round(random.uniform(min_threshold_preferred_speed, max_threshold_preferred_speed), 2),
                   round(random.uniform(min_threshold_reaction_time, max_threshold_reaction_time), 2) ] 
                  for j in range(population_size)]
    
    population_with_keys = [(individual, key) for key, individual in enumerate(population)]
    population_with_fitness = pool.map(fitness, population_with_keys)
    
    population = [individual[:-1] for individual in population_with_fitness]
    fitness_results = [individual[-1] for individual in population_with_fitness]
    sorted_pop = sorted(zip(fitness_results, population), 
                            key=lambda x: x[0], reverse=find_max)
    sorted_fitness_of_population = [x[0] for x in sorted_pop]
    sorted_population = [x[1] for x in sorted_pop]
    population = sorted_population

    for i in range(num_generations):
        step = step + 1
        next_generation = []
                
        while len(next_generation) < int(population_size/2):
            parent1 = random.choice(population[:int(population_size/2)])
            parent2 = random.choice(population[:int(population_size/2)])
            
            child = crossover(parent1, parent2)
            child = mutate(child, mutation_rate)
            
            next_generation.append(child)
        
        # Evaluate fitness only for children        
        next_population_with_keys = [(individual, key) for key, individual in enumerate(next_generation)]
        next_population_with_fitness = pool.map(fitness, next_population_with_keys)

        next_generation = [individual[:-1] for individual in next_population_with_fitness]
        next_generation_fitnesses = [individual[-1] for individual in next_population_with_fitness]
        
        # Combine parents and children
        combined_pop = population[:int(population_size/2)] + next_generation
        combined_fits = sorted_fitness_of_population[:int(population_size/2)] + next_generation_fitnesses
        sorted_pop_and_fits_combined = sorted(zip(combined_fits, combined_pop), 
                                key=lambda x: x[0], reverse=find_max)
        sorted_population_combined = [x[1] for x in sorted_pop_and_fits_combined]
        sorted_fitnesses_combined = [x[0] for x in sorted_pop_and_fits_combined]
        
        # Update to next generation
        population = sorted_population_combined
        sorted_fitness_of_population = sorted_fitnesses_combined
     
        best = population[0]
        best_fitness = sorted_fitnesses_combined[0]
        
        new_row = pd.Series({'step': step, 'individual': best, 'fitness': best_fitness}) 
        df = df.append(new_row, ignore_index=True)
        df = pd.concat([df, pd.DataFrame([new_row])], ignore_index=True)
        df.to_csv('result_step_calibration.csv', index=False)
        
        print(' ======================= STEP {0} BEST SOLUTION: {1} ==========================='.format(step, best))

    return best


if __name__ == '__main__':
    pool = Pool(processes=8) 
    run_GA()
    
    
