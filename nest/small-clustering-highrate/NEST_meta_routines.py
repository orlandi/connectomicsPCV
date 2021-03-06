# Copyright 2012, Olav Stetter
# Copyright 2014, Javier G. Orlandi

# A collection of meta routines for the NEST simulator.

import sys
import numpy
import random
import nest


DEFAULT_NEURON_PARAMETERS = {
  "C_m"       : 1.0,
  "tau_m"     : 20.0,
  "t_ref"     : 2.0,
  "E_L"       : -70.0,
  "V_th"      : -50.0,
  "V_reset"   : -70.0
}
DEFAULT_TSODYKS_SYNAPSE_PARAMETERS = {
  "delay"     : 1.5,
  #"tau_rec"   : 5000.0,
  "tau_rec"   : 500.0,
  "tau_fac"   : 0.0,
  "tau_psc"   : 3.0,
  "U"         : 0.3
}



def uniq(sequence): # Not order preserving!
  return list(set(sequence))

# The following code was directly translated from te-datainit.cpp in TE-Causality
def determine_burst_rate(xindex, xtimes, total_timeMS, size, tauMS=50, burst_treshold=0.4):
  assert(len(xindex)==len(xtimes))
  if len(xindex)<1:
    print "-> no spikes recorded!"
    return 0.
  # print "DEBUG: spike times ranging from "+str(xtimes[0])+" to "+str(xtimes[-1])
  print "-> "+str(len(xtimes))+" spikes from "+str(len(uniq(xindex)))+" of "+str(size)+" possible cells recorded."
  print "-> single cell spike rate: "+str(1000.*float(len(xtimes))/(float(total_timeMS)*float(size)))+" Hz"
  samples = int(xtimes[-1]/float(tauMS))
  # 1.) generate HowManyAreActive-signal (code directly translated from te-datainit.cpp)
  startindex = -1
  endindex = 0
  tinybit_spikenumber = -1
  HowManyAreActive = []
  for s in range(samples):
    ttExactMS = s*tauMS
    HowManyAreActiveNow = 0
    while (endindex+1<len(xtimes) and xtimes[endindex+1]<=ttExactMS+tauMS):
      endindex += 1
    HowManyAreActiveNow = len(uniq(xindex[max(0,startindex):endindex+1]))
    # print "DEBUG: startindex "+str(startindex)+", endindex "+str(endindex)+": HowManyAreActiveNow = "+str(HowManyAreActiveNow)
    
    if startindex <= endindex:
      startindex = 1 + endindex
    
    if float(HowManyAreActiveNow)/size > burst_treshold:
      HowManyAreActive.append(1)
    else:
      HowManyAreActive.append(0)
  
  # 2.) calculate inter-burst-intervals
  oldvalue = 0
  IBI = 0
  IBIsList = []
  for s in HowManyAreActive:
    switch = [oldvalue,s]
    if switch == [0,0]:
      IBI += 1
    elif switch == [0,1]:
      IBIsList.append(IBI)
      IBI = 0 # so we want to measure burst rate, not actually the IBIs
    oldvalue = s
  if IBI>0 and len(IBIsList)>0:
    IBIsList.append(IBI)
  print "-> "+str(len(IBIsList))+" bursts detected."
  # 3.) calculate burst rate in Hz
  if len(IBIsList)<=1:
    return 0.
  else:
    return 1./(float(tauMS)/1000.*float(sum(IBIsList))/float(len(IBIsList)))


def go_create_network(yamlobj, weight, JENoise, noise_rate, print_output=False, fraction_of_connections=1.0, subnetwork_index_in_YAML=-1, block_inh=False, block_exc=False):
  weights_are_given_as_array_for_each_subnet = hasattr(weight, "insert")
  size = yamlobj.get('size')
  cons = yamlobj.get('cons')
  print "-> We have a network of "+str(size)+" nodes and "+str(cons)+" connections overall."
  if block_inh:
    print "-> Inhibitory synapses blocked."
  if block_exc:
    print "-> Excitatory synapses blocked."
  # Create a re-mapping dictionary in the form map_between_indices[YAML_ID] = SERIAL_COUNTER_STARTING_FROM_ZERO
  map_between_indices = {}
  
  if subnetwork_index_in_YAML >= 0:
    # Collect list of cell indices that belong to the right subnetwork
    subnetwork_indices = []
    for i in range(size): # i starts counting at 0
      thisnode = yamlobj.get('nodes')[i]
      if thisnode.has_key('subset') and (thisnode.get('subset') == subnetwork_index_in_YAML):
        map_between_indices[thisnode.get('id')] = len(subnetwork_indices)
        subnetwork_indices.append(i)
      # print "DEBUG: node with ID {id} has subset key {s}".format(id=thisnode.get('id'), s=thisnode.get('subset'))
    assert len(subnetwork_indices) > 0
    # Override size variable to reflect the size of the actual network that is to be built
    size = len(subnetwork_indices)
    print "-> Limiting construction to subnetwork #"+str(subnetwork_index_in_YAML)+", "+str(size)+" neuron(s)."
  else:
    # Construct index map as the identity
    for i in range(size+1):
      map_between_indices[i] = i-1
  
  print "Resetting and creating network..."
  nest.ResetKernel()
  nest.SetKernelStatus({"resolution": 0.1, "print_time": False, "overwrite_files":True})

  msd = random.randint(0, sys.maxint)
  N_vp = nest.GetKernelStatus(['total_num_virtual_procs'])[0]
  print "Seeding the RNG..."
  print "  Main seed: " + str(msd)
  print "  Processes: " + str(N_vp)
  pyrngs = [numpy.random.RandomState(s) for s in range(msd, msd+N_vp)] 
  nest.SetKernelStatus({'grng_seed' : msd+N_vp})
  nest.SetKernelStatus({'rng_seeds' : range(msd+N_vp+1, msd+2*N_vp+1)})

  nest.SetDefaults("iaf_neuron", DEFAULT_NEURON_PARAMETERS)
  neurons = nest.Create("iaf_neuron", size)
  # Save GID offset of first neuron - this has the advantage that the output later will be
  # independent of the point at which the neurons were created
  GIDoffset = neurons[0]
  espikes = nest.Create("spike_detector")
  noise = nest.Create("poisson_generator", 1, {"rate":noise_rate})
  #nest.ConvergentConnect(neurons, espikes)
  nest.Connect(neurons, espikes, 'all_to_all')
  # Warning: delay is overwritten later if weights are given in the YAML file!
  nest.SetDefaults("tsodyks_synapse", DEFAULT_TSODYKS_SYNAPSE_PARAMETERS)
  if weights_are_given_as_array_for_each_subnet:
    nest.CopyModel("tsodyks_synapse", "exc", {"weight": weight[0]}) # will anyway be reset later
    nest.CopyModel("tsodyks_synapse", "inh", {"weight": 2*weight[0], "delay": 4.5, "tau_rec": 10.0, "tau_psc": 6.0}) # will anyway be reset later
  else:
    nest.CopyModel("tsodyks_synapse", "exc", {"weight": weight})
    nest.CopyModel("tsodyks_synapse", "inh", {"weight": 2*weight, "delay": 4.5, "tau_rec": 10.0, "tau_psc": 6.0})
  nest.CopyModel("static_synapse","poisson",{"weight":JENoise})
  #nest.DivergentConnect(noise,neurons,model="poisson")
  nest.Connect(noise,neurons,'all_to_all',syn_spec = {'model':'poisson'})
  # print "Loading connections from YAML file..."
  added_connections = 0
  # Print additional information if present in YAML file
  if print_output:
    if yamlobj.has_key('notes'):
      print "-> notes of YAML file: "+yamlobj.get('notes')
    if yamlobj.has_key('createdAt'):
      print "-> created: "+yamlobj.get('createdAt')
  
  for thisnode in yamlobj.get('nodes'):
    if subnetwork_index_in_YAML < 0 or thisnode.get('subset') == subnetwork_index_in_YAML:
      yaml_id = int(thisnode.get('id'))
      # Source neuron needs to be in the subnet we are modelling
      if map_between_indices.has_key(yaml_id):
        cfrom = neurons[map_between_indices[yaml_id]]
        if thisnode.has_key('connectedTo'):
          cto_list = thisnode.get('connectedTo')
          for j in range(len(cto_list)):
            # Target neuron needs to be in the subnet we are modelling as well
            yaml_id = int(cto_list[j])
            if map_between_indices.has_key(yaml_id):
              cto = neurons[map_between_indices[yaml_id]]
              # Choose only a subset of connections
              if random.random() <= fraction_of_connections:
                weight_here = 0.0
                # Set up case flags for later (just for readability)
                weights_are_given_in_YAML = thisnode.has_key('weights')
                subnet_index_is_given_in_YAML = thisnode.has_key('subset')
                # Initialize weight with value supplied as argument to fn. call
                if weights_are_given_as_array_for_each_subnet:
                  assert subnet_index_is_given_in_YAML
                  weight_here = weight[thisnode.get('subset')-1]
                else:
                  weight_here = weight
                # Factor in weight given in the YAML file, if any
                if weights_are_given_in_YAML:
                  assert len(thisnode.get('weights')) == len(cto_list)
                  weight_here *= thisnode.get('weights')[j]
                if (weight_here > 0.0 and not(block_exc)) or (weight_here < 0.0 and not(block_inh)):
                  if (weight_here > 0.0):
                    nest.Connect([cfrom], [cto], syn_spec={'weight': weight_here, 'delay': 1.5, 'model': 'exc'})
                  else:
                    nest.Connect([cfrom], [cto], syn_spec={'weight': 2*weight_here, 'delay': 4.5, 'model': 'inh'})
                  if print_output:
                    print "-> added connection: from #"+str(cfrom)+" to #"+str(cto)+" with weight (before multipliers) "+str(weight_here)
                    conn = nest.GetConnections([cfrom], [cto])
                    print nest.GetStatus(conn)
                  added_connections += 1
  
  print "-> "+str(added_connections)+" out of "+str(cons)+" connections (in YAML source) created."
  return [size, added_connections, neurons, espikes, noise, GIDoffset]

def save_spikes_to_disk(NEST_spike_object, index_file_name, times_file_name, GID_offset=0):
  inputFile = open(times_file_name,"w")
  # output spike times, in ms
  print >>inputFile, "\n".join([str(x) for x in nest.GetStatus(NEST_spike_object, "events")[0]["times"] ])
  inputFile.close()
  inputFile = open(index_file_name,"w")
  # remove offset, such that the output array starts with 0
  print >>inputFile, "\n".join([str(x-GID_offset) for x in nest.GetStatus(NEST_spike_object, "events")[0]["senders"] ])
  inputFile.close()

