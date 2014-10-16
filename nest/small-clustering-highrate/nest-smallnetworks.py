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



print "------ adaptive-multibursts, Sep 26 Sep 2014 ------"
# first, make sure command line parameters are fine
cmd_arguments = sys.argv

baseFile = 'N100_CC0?_?'

clusterList = range(1,7)
replicaList = range(1,501)

iterations = len(clusterList)*len(replicaList)

if len(cmd_arguments) != 2:
  print "usage: ./nest-smallnetworks.py #iteration (starts at 1)"
  print "usage: ./nest-smallnetworks.py iterations (to know the number of total iterations)"
  sys.exit(0)
elif cmd_arguments[1] == 'iterations':
  print "Total number of iterations: " + str(iterations)
  sys.exit(0)

currentIteration = numpy.unravel_index(int(cmd_arguments[1])-1, ((len(clusterList),len(replicaList))))
baseFile = baseFile.replace("?",str(clusterList[currentIteration[0]]),1)
baseFile = baseFile.replace("?",str(replicaList[currentIteration[1]]),1)

# ------------------------------ Define the input files ------------------------------ #
YAMLinputfilename = "../../networks/N100/network_" + baseFile + ".yaml"
spiketimefilename = "/home/users/orlandi/ResearchData/challengeKaggle/connectomicsPCV/data/small-clustering-highrate/N100/spikes/" + baseFile + "-times.txt"
spikeindexfilename = "/home/users/orlandi/ResearchData/challengeKaggle/connectomicsPCV/data/small-clustering-highrate/N100/spikes/" + baseFile + "-idx.txt"

print "Selected network " + str(YAMLinputfilename)
print "Data will be stored at " + str(spiketimefilename) + " and " + str(spikeindexfilename)

# ------------------------------ Simulation parameters ------------------------------ #
MAX_ADAPTATION_ITERATIONS = 100 # maximum number of iterations to find parameters for target bursting rate
MAX_PARTIAL_ADAPTATION_ITERATIONS = 15 # maximum number of iterations to find parameters for target bursting rate before doing a partial reset
ADAPTATION_SIMULATION_TIME = 500*1000. # in ms
FRACTION_OF_ACTIVE_NEURONS_FOR_BURST_DETECTION = 0.5
hours = 1.
SIMULATION_TIME = hours*60.*60.*1000. # in ms
TARGET_BURST_RATE = 0.2 # in Hz
TARGET_BURST_RATE_ACCURACY_GOAL = 0.005 # in Hz
INITIAL_WEIGHT_JE = 7.0 # internal synaptic weight, initial value, in pA
WEIGHT_NOISE = 2.*0.28*20. # external synaptic weight, in pA
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
last_burst_rates = []
last_JEs = []
upper_bound_on_weight = 100.0
lower_bound_on_weight = 0.0
upper_bound_on_burst_rate = 100.0
lower_bound_on_burst_rate = 0.0
subnet_weight_list = []
tauMS = 50
weight = INITIAL_WEIGHT_JE

print "\n----------------------------- adaptation phase for whole network -----------------------------"
burst_rate = -1
adaptation_iteration = 1
full_adaptation_iteration = 1
adaptation_runner = BoundedAdaptationRunner(0.1, 10.0, 0.0, 100.0, weight, TARGET_BURST_RATE)
while abs(burst_rate-TARGET_BURST_RATE)>TARGET_BURST_RATE_ACCURACY_GOAL:
  weight = adaptation_runner.next(burst_rate)
  print "adaptation #"+str(adaptation_iteration)+": setting weight to "+str(weight)+" ..."
  # Start test simulation
  [size,cons,neuronsE,espikes,noise,GIDoffset] = nest_meta.go_create_network(yamlobj, weight, WEIGHT_NOISE, NOISE_RATE, False, 1.0, -1, True)
  nest.Simulate(ADAPTATION_SIMULATION_TIME)
  burst_rate = nest_meta.determine_burst_rate(nest.GetStatus(espikes, "events")[0]["senders"], nest.GetStatus(espikes, "events")[0]["times"], ADAPTATION_SIMULATION_TIME, size, tauMS, FRACTION_OF_ACTIVE_NEURONS_FOR_BURST_DETECTION)
  print "-> the burst rate is "+str(burst_rate)+" Hz"
  
  assert full_adaptation_iteration < MAX_ADAPTATION_ITERATIONS
  if adaptation_iteration >= MAX_PARTIAL_ADAPTATION_ITERATIONS:
    print "-> max partial iterations reached. Resetting..."
    adaptation_runner = BoundedAdaptationRunner(0.1, 10.0, 0.0, 100.0, INITIAL_WEIGHT_JE, TARGET_BURST_RATE)
    burst_rate = -1
    adaptation_iteration = 1

  adaptation_iteration += 1
  full_adaptation_iteration += 1

print "\n----------------------------- actual simulation -----------------------------"
[size,cons,neuronsE,espikes,noise,GIDoffset] = nest_meta.go_create_network(yamlobj, weight, WEIGHT_NOISE, NOISE_RATE, False, 1.0, -1, True)
endbuild = time.time()
print "Simulating..."
nest.Simulate(SIMULATION_TIME)
endsimulate = time.time()

build_time = endbuild - startbuild
sim_time = endsimulate - endbuild

totalspikes = nest.GetStatus(espikes, "n_events")[0]
print "Number of neurons: ", size
print "Number of spikes recorded: ", totalspikes
print "Avg. spike rate of neurons: %.2f Hz" % (totalspikes/(size*SIMULATION_TIME/1000.))
burst_rate = nest_meta.determine_burst_rate(nest.GetStatus(espikes, "events")[0]["senders"], nest.GetStatus(espikes, "events")[0]["times"], ADAPTATION_SIMULATION_TIME, size, tauMS, FRACTION_OF_ACTIVE_NEURONS_FOR_BURST_DETECTION)
print "Burst rate: "+str(burst_rate)+" Hz"
print "Building time: %.2f s" % build_time
print "Simulation time: %.2f s" % sim_time

print "Saving spike times to disk..."
nest_meta.save_spikes_to_disk(espikes, spikeindexfilename, spiketimefilename, GIDoffset)

print "done."

