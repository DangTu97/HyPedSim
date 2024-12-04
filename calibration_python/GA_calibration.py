import random
import os
from bs4 import BeautifulSoup
import numpy as np
import pandas as pd

population_size = 100
num_generations = 100
mutation_rate = 0.01 
sim = 0

min_threshold_MAX_DELAY = 0
max_threshold_MAX_DELAY = 10

min_threshold_PROB_CONSTANTINE = 0.0
max_threshold_PROB_CONSTANTINE = 1.0

min_threshold_PROB_CHENAVARD = 0.0
max_threshold_PROB_CHENAVARD = 1.0

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
   
        
    for tag in xml_object.find_all('Parameter', {'name':'sim_idx'}):
        tag['value'] = input_parameters['sim_idx']
    
    
    f = open(xml_file_path, "w")
    f.write(BeautifulSoup.prettify(xml_object))
    f.close()
    
def read_simulation_result(sim_result_file):
    df = pd.read_csv(sim_result_file)
    fitness = df[df.sim_idx == sim].similarity_score
    
    try: 
        return float(fitness)
    except: 
        return 10

def run_simulation():
    os.chdir("/Applications/Gama.app/Contents/headless")
    os.system("sh ./gama-headless.sh ./samples/calibration.xml ./test")


def fitness(individual):
    global sim
    MAX_DELAY, PROB_CONSTANTINE, PROB_CHENAVARD = individual
    sim = sim + 1
    inputs = {'MAX_DELAY': MAX_DELAY, 'PROB_CONSTANTINE': PROB_CONSTANTINE, 'PROB_CHENAVARD': PROB_CHENAVARD, 'sim_idx': str(sim)}
    
    xml_file_path = '/Applications/Gama.app/Contents/headless/samples/calibration.xml'
    sim_result_file = '/Applications/Gama.app/Contents/headless/samples/PAAMS23_EXTENSION/models/Experiments/Lyon_exit/calibration/' + 'results.csv'
    
    update_xml_file(xml_file_path, inputs)
    run_simulation()
    fitness = read_simulation_result(sim_result_file)
        
    return fitness
    

def mutate(individual):
    MAX_DELAY, PROB_CONSTANTINE, PROB_CHENAVARD = individual
    
    if random.random() < mutation_rate:
        MAX_DELAY = random.randint(min_threshold_MAX_DELAY, max_threshold_MAX_DELAY)
        
    if random.random() < mutation_rate:  
        PROB_CONSTANTINE = round(random.uniform(min_threshold_PROB_CONSTANTINE, max_threshold_PROB_CONSTANTINE), 2)
        
    if random.random() < mutation_rate:
        PROB_CHENAVARD = round(random.uniform(min_threshold_PROB_CHENAVARD, max_threshold_PROB_CHENAVARD), 2)
        
    return [MAX_DELAY, PROB_CONSTANTINE, PROB_CHENAVARD]

def crossover(parent1, parent2):
    child = []
    for i in range(len(parent1)):
        if random.random() < 0.5:
            child.append(parent1[i])
        else:
            child.append(parent2[i])
            
    return child

def run_GA():

    population = [[random.randint(min_threshold_MAX_DELAY, max_threshold_MAX_DELAY),
                   round(random.uniform(min_threshold_PROB_CONSTANTINE, max_threshold_PROB_CONSTANTINE), 2),
                   round(random.uniform(min_threshold_PROB_CHENAVARD, max_threshold_PROB_CHENAVARD), 2) ] 
                  for j in range(population_size)]
    
    for i in range(num_generations):
        # reverse = True => max, reverse = False => min
        population = sorted(population, key=fitness)
        
        print('========================================== Generation {0} ==========================================='.format(i))
        
        next_generation = population[:int(population_size/2)]
        
        while len(next_generation) < population_size:
            parent1 = random.choice(population[:int(population_size/2)])
            parent2 = random.choice(population[:int(population_size/2)])
            
            child = crossover(parent1, parent2)
            child = mutate(child)
            
            next_generation.append(child)
        
        population = next_generation
        
    return population[0]


sim = 100
df = pd.read_csv('/Applications/Gama.app/Contents/headless/samples/PAAMS23_EXTENSION/models/Experiments/Lyon_exit/calibration/results.csv')

# Ensure 'similarity_score' is in the list of columns obtained from the DataFrame.
# sort population by fitnes

columns_list = ['MAX_DELAY', 'PROB_CONSTANTINE', 'PROB_CHENAVARD', 'similarity_score']
list_of_lists = df[columns_list].values.tolist()

# Find the index of 'similarity_score' in the columns_list
similarity_score_index = columns_list.index('similarity_score')

# Sort the list_of_lists by the similarity_score
sorted_list_of_lists = sorted(list_of_lists, key=lambda x: x[similarity_score_index])

population = [[int(item[0]), item[1], item[2]] for item in sorted_list_of_lists]

for i in range(num_generations):
    # reverse = True => max, reverse = False => min
    if sim == 100:
        sim = sim + 1
    else:
        if sim == 101: 
            sim = 100
        population = sorted(population, key=fitness)
    
    print('========================================== Generation {0} ==========================================='.format(i))
    
    next_generation = population[:int(population_size/2)]
    
    while len(next_generation) < population_size:
        parent1 = random.choice(population[:int(population_size/2)])
        parent2 = random.choice(population[:int(population_size/2)])
        
        child = crossover(parent1, parent2)
        child = mutate(child)
        
        next_generation.append(child)
    
    population = next_generation
 
best = population[0]
print("Best Solution: ", best)
# Open a file in write mode
with open('best.txt', 'w') as file:
    # Write the first element of population to the file
    file.write(str(best))


if __name__ == '__main__':

    gama_headless_folder = '/Applications/Gama.app/Contents/headless'
    run_gama_headless_command = 'sh ./gama-headless.sh ./samples/calibration.xml ./test'
    xml_file_path = gama_headless_folder + '/samples/calibration.xml'
    sim_result_file = gama_headless_folder + '/samples/PAAMS23_EXTENSION/models/Experiments/Lyon_exit/calibration/results.csv'

    run_GA(gama_headless_folder, run_gama_headless_command, xml_file_path, sim_result_file)


    