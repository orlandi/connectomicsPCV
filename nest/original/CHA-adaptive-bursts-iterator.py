#! /usr/bin/env python

# Copyright 2012, Olav Stetter
# Copyright 2014, Javier G. Orlandi

# NEST simulator designed to iterate over a number of input topologies
# (YAML) and to adjst the internal synaptic weight to always achieve an
# equal bursting rate across networks.

import sys
import nest
import numpy
import time
import yaml
import NEST_meta_routines as nest_meta

from BoundedAdaptation import *

class extraLogger:
    def __init__(self, stdout, filename):
        self.stdout = stdout
        self.logfile = file(filename, 'a')

    def write(self, text):
        self.stdout.write(text)
        self.logfile.write(text)

    def close(self):
        self.stdout.close()
        self.logfile.close()




print "------ adaptive-multibursts, Olav Stetter, Fri 14 Oct 2011 ------"
# first, make sure command line parameters are fine
cmd_arguments = sys.argv
print str(cmd_arguments)
if len(cmd_arguments) != 3:
  print "usage: ./CHA-adaptive-bursts.py input_yaml_file iterator"
  print "the program will replace any ? in the file name by the iterator"
  sys.exit(0)
# else:
YAMLinputfilename = str(cmd_arguments[1])
iterator = str(cmd_arguments[4])
YAMLinputfilename = YAMLinputfilename.replace("?",iterator)

spiketimefilename = os.path.splitext(YAMLinputfilename)[0] + "_times.txt"
spikeindexfilename = os.path.splitext(YAMLinputfilename)[0] + "_indices.txt"
logfilename = os.path.splitext(YAMLinputfilename)[0] + ".log"
#sys.stdout = open(logfilename, 'w')
logger = extraLogger(sys.stdout, logfilename)
sys.stdout = logger

# ------------------------------ Simulation parameters ------------------------------ #
MAX_ADAPTATION_ITERATIONS = 100 # maximum number of iterations to find parameters for target bursting rate
ADAPTATION_SIMULATION_TIME = 2*200*1000. # in ms
FRACTION_OF_ACTIVE_NEURONS_FOR_BURST_DETECTION = 0.9
hours = 1.
SIMULATION_TIME = hours*60.*60.*1000. # in ms
TARGET_BURST_RATE = 0.1 # in Hz
TARGET_BURST_RATE_ACCURACY_GOAL = 0.005 # in Hz
INITIAL_WEIGHT_JE = 8. # internal synaptic weight, initial value, in pA
WEIGHT_NOISE = 2*0.28*20.0 #4. # external synaptic weight, in pA
NOISE_RATE = 0.2 # rate of external inputs, in Hz
FRACTION_OF_CONNECTIONS = 1.0



# ------------------------------ Main loop starts here ------------------------------ #
startbuild = time.time()

print "Loading topology from disk..."
filestream = file(YAMLinputfilename,"r")
yamlobj = yaml.load(filestream)
filestream.close()
assert filestream.closed

# --- adaptation phase ---
print "Starting adaptation phase..."
weight = INITIAL_WEIGHT_JE
burst_rate = -1
adaptation_iteration = 1
last_burst_rates = []
last_JEs = []
upper_bound_on_weight = 1000.0
lower_bound_on_weight = 0.0
upper_bound_on_burst_rate = 1000.0
lower_bound_on_burst_rate = 0.0

print "\n----------------------------- adaptation phase -----------------------------"
adaptation_runner = BoundedAdaptationRunner(0.0, 100.0, 0.0, 100.0, INITIAL_WEIGHT_JE, TARGET_BURST_RATE)
while abs(burst_rate-TARGET_BURST_RATE)>TARGET_BURST_RATE_ACCURACY_GOAL:
  weight = adaptation_runner.next(burst_rate)
  print "adaptation #"+str(adaptation_iteration)+": setting weight to "+str(weight)+" ..."
  # Start test simulation
  [size,cons,neuronsE,espikes,noise,GIDoffset] = nest_meta.go_create_network(yamlobj,weight,WEIGHT_NOISE,NOISE_RATE,True,1.,-1,True,False)
  nest.Simulate(ADAPTATION_SIMULATION_TIME)
  tauMS = 50
  #burst_rate = nest_meta.determine_burst_rate(nest.GetStatus(espikes, "events")[0]["senders"].flatten().tolist(), nest.GetStatus(espikes, "events")[0]["times"].flatten().tolist(), ADAPTATION_SIMULATION_TIME, size, tauMS, FRACTION_OF_ACTIVE_NEURONS_FOR_BURST_DETECTION)
  burst_rate = nest_meta.determine_burst_rate(nest.GetStatus(espikes, "events")[0]["senders"], nest.GetStatus(espikes, "events")[0]["times"], ADAPTATION_SIMULATION_TIME, size, tauMS, FRACTION_OF_ACTIVE_NEURONS_FOR_BURST_DETECTION)
  print "-> the burst rate is "+str(burst_rate)+" Hz"
  assert adaptation_iteration < MAX_ADAPTATION_ITERATIONS

print "\n----------------------------- actual simulation -----------------------------"
[size,cons,neuronsE,espikes,noise,GIDoffset] = nest_meta.go_create_network(yamlobj,weight,WEIGHT_NOISE,NOISE_RATE,True,1.,-1,True,False)
endbuild = time.time()


# --- simulate ---
print "Simulating..."
nest.Simulate(SIMULATION_TIME)
endsimulate = time.time()

build_time = endbuild - startbuild
sim_time = endsimulate - endbuild

totalspikes = nest.GetStatus(espikes, "n_events")[0]
print "Number of neurons : ", size
print "Number of spikes recorded: ", totalspikes
print "Avg. spike rate of neurons: %.2f Hz" % (totalspikes/(size*SIMULATION_TIME/1000.))
print "Building time: %.2f s" % build_time
print "Simulation time: %.2f s" % sim_time

print "Saving spike times to disk..."
inputFile = open(spiketimefilename,"w")
# output spike times, in ms
print >>inputFile, "\n".join([str(x) for x in nest.GetStatus(espikes, "events")[0]["times"] ])
inputFile.close()

inputFile = open(spikeindexfilename,"w")
# remove offset, such that the output array starts with 0
print >>inputFile, "\n".join([str(x-GIDoffset) for x in nest.GetStatus(espikes, "events")[0]["senders"] ])
inputFile.close()
