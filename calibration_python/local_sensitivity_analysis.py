from multiprocessing import Pool
import random
import os
from bs4 import BeautifulSoup
import numpy as np
import pandas as pd
import random
from pathlib import Path

gama_headless_folder = '/Applications/Gama.app/Contents/headless/'

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

MAX_DELAY = 9
PROB_CONSTANTINE = 0.91
PROB_CHENAVARD = 0.76
MAXIMUM_SPEED = 1.35
MINIMUM_SPEED = 0.15
MAXIMUM_DENSITY = 6.36
MINIMUM_DENSITY = 0.11
A = 1.83
B = 0.45
preferred_speed = 1.25
reaction_time = 0.57

optimal_individual = [MAX_DELAY, PROB_CONSTANTINE, PROB_CHENAVARD, 
                      MAXIMUM_SPEED, MINIMUM_SPEED, MAXIMUM_DENSITY, MINIMUM_DENSITY, 
                      A, B, preferred_speed, reaction_time]


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
    #b_name = xml_object.find('Parameter', {'name':'x'})
    
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
    command = "sh ./gama-headless.sh ./samples/local_sensitivity_analysis_xml/parameter_" + str(key) + ".xml ./test"
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
    
    xml_file_path = gama_headless_folder + '/samples/local_sensitivity_analysis_xml/parameter_' + str(key) + '.xml'
    sim_result_file = gama_headless_folder + '/samples/HyPedSim/models/Experiments/Lyon_exit/calibration/output/results_' + str(key) + '.csv'
    
    update_xml_file(xml_file_path, inputs)
    run_simulation(key)
    fit = read_simulation_result(sim_result_file)
    
    # save to track files
    file = 'local_sensitivity_analysis_sim_results/result_' + str(key) + '.csv'
    if os.path.isfile(file):
        df = pd.read_csv(file)
    else:
        df = pd.DataFrame(columns=['MAX_DELAY', 'PROB_CONSTANTINE', 'PROB_CHENAVARD', "MAXIMUM_SPEED", "MINIMUM_SPEED", "MAXIMUM_DENSITY", "MINIMUM_DENSITY", "A", "B", "preferred_speed", "reaction_time", 'fitness'])
    new_row = pd.Series({
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
    df = pd.concat([df, pd.DataFrame([new_row])], ignore_index=True)
    df.to_csv(file, index=False)
        
    return [MAX_DELAY, PROB_CONSTANTINE, PROB_CHENAVARD, MAXIMUM_SPEED, MINIMUM_SPEED, MAXIMUM_DENSITY, MINIMUM_DENSITY, A, B, preferred_speed, reaction_time, fit]
    
if __name__ == '__main__':
    df = pd.DataFrame(columns=['MAX_DELAY', 'PROB_CONSTANTINE', 'PROB_CHENAVARD', 
                      'MAXIMUM_SPEED', 'MINIMUM_SPEED', 'MAXIMUM_DENSITY', 'MINIMUM_DENSITY', 
                      'A', 'B', 'preferred_speed', 'reaction_time', 'fitness'])
    pool = Pool(processes=8) 
     
    S = 16 # 10 samples for each parameter

    # generate candidates based on optimal_individual for sensitivity analysis
    candidates = []
    gaps = [-0.25, -0.2, -0.15, -0.1, -0.05, 0.05, 0.1, 0.15, 0.2, 0.25]

    for i in range(len(optimal_individual)):
        if i == 0: # max_delay => int type
            for j in range(5,11):
                canditdate = optimal_individual.copy()
                canditdate[i] =  j
                for k in range(S):
                    candidates.append(canditdate)
                
        if i == 1: # alpha
            for gap in gaps:
                canditdate = optimal_individual.copy()
                canditdate[i] =  round(canditdate[i] + gap * canditdate[i], 3)
                if canditdate[i] >= min_threshold_PROB_CONSTANTINE and canditdate[i] <= max_threshold_PROB_CONSTANTINE:
                    for k in range(S):
                        candidates.append(canditdate)
        
        if i == 2: # beta
            for gap in gaps:
                canditdate = optimal_individual.copy()
                canditdate[i] =  round(canditdate[i] + gap * canditdate[i], 3)
                if canditdate[i] >= min_threshold_PROB_CHENAVARD and canditdate[i] <= max_threshold_PROB_CHENAVARD:
                    for k in range(S):
                        candidates.append(canditdate)
        
        if i == 3: # maximum_speed
            for gap in gaps:
                canditdate = optimal_individual.copy()
                canditdate[i] =  round(canditdate[i] + gap * canditdate[i], 3)
                if canditdate[i] >= min_threshold_MAXIMUM_SPEED and canditdate[i] <= max_threshold_MAXIMUM_SPEED:
                    for k in range(S):
                        candidates.append(canditdate)

        if i == 4: # minimum_speed
            for gap in gaps:
                canditdate = optimal_individual.copy()
                canditdate[i] =  round(canditdate[i] + gap * canditdate[i], 3)
                if canditdate[i] >= min_threshold_MINIMUM_SPEED and canditdate[i] <= max_threshold_MINIMUM_SPEED:
                    for k in range(S):
                        candidates.append(canditdate)
        
        if i == 5: # maximum_density
            for gap in gaps:
                canditdate = optimal_individual.copy()
                canditdate[i] =  round(canditdate[i] + gap * canditdate[i], 3)
                if canditdate[i] >= min_threshold_MAXIMUM_DENSITY and canditdate[i] <= max_threshold_MAXIMUM_DENSITY:
                    for k in range(S):
                        candidates.append(canditdate)
        
        if i == 6: # minimum_density
            for gap in gaps:
                canditdate = optimal_individual.copy()
                canditdate[i] =  round(canditdate[i] + gap * canditdate[i], 3)
                if canditdate[i] >= min_threshold_MINIMUM_DENSITY and canditdate[i] <= max_threshold_MINIMUM_DENSITY:
                    for k in range(S):
                        candidates.append(canditdate)
        
        if i == 7: # A
            for gap in gaps:
                canditdate = optimal_individual.copy()
                canditdate[i] =  round(canditdate[i] + gap * canditdate[i], 3)
                if canditdate[i] >= min_threshold_A and canditdate[i] <= max_threshold_A:
                    for k in range(S):
                        candidates.append(canditdate)
        
        if i == 8: # B
            for gap in gaps:
                canditdate = optimal_individual.copy()
                canditdate[i] =  round(canditdate[i] + gap * canditdate[i], 3)
                if canditdate[i] >= min_threshold_B and canditdate[i] <= max_threshold_B:
                    for k in range(S):
                        candidates.append(canditdate)
        
        if i == 9: # preferred_speed
            for gap in gaps:
                canditdate = optimal_individual.copy()
                canditdate[i] =  round(canditdate[i] + gap * canditdate[i], 3)
                if canditdate[i] >= min_threshold_preferred_speed and canditdate[i] <= max_threshold_preferred_speed:
                    for k in range(S):
                        candidates.append(canditdate)
        
        if i == 10: # reaction_time
            for gap in gaps:
                canditdate = optimal_individual.copy()
                canditdate[i] =  round(canditdate[i] + gap * canditdate[i], 3)
                if canditdate[i] >= min_threshold_reaction_time and canditdate[i] <= max_threshold_reaction_time:
                    for k in range(S):
                        candidates.append(canditdate)

    # save candidates to text file
    file = 'individuals.txt'
    with open(file, 'w') as f:
        for item in candidates:
            f.write("%s\n" % item)
                    
    population_with_keys = [(individual, key) for key, individual in enumerate(candidates)]
    population_with_fitness = pool.map(fitness, population_with_keys)
    