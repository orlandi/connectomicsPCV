function networkToPlainText(network, adjacencyFile, positionsFile, varargin)
% NETWORKTOPLAINTEXT saves a Network structure in plain text format
%
% USAGE:
%    networkToYAML(network, fileName)
%
% INPUT arguments:
%    network - Network structure (see the README for more info)
%
%    adjacencyFile - file to use for the adjacency matrix
%
%    positionsFile - file to use for the neuron positions
%
% INPUT optional arguments ('key' followed by its value): 
%    'verbose' - (true/false) Print detailed information (default true)
%
% EXAMPLE:
%     networkToYAML(network, 'test.yaml', 'notes', '"test network"')
%
% Copyright (C) 2014, Javier G. Orlandi <javierorlandi@javierorlandi.com>

%%% Assign default values
params.verbose = true;
params = parse_pv_pairs(params,varargin); 

verbose = params.verbose;

%%% Generate the file
if(verbose)
    fprintf('Saving the network as plain text...\n');
end

%%% Store the network (each row of the form [i,j,w] denoting a connection from i
%%% to j with wegiht w). This format allows a direct load of the network
%%% through the sparse function
[i,j,w] = find(network.RS);
networkData = [i, j, w];
dlmwrite(adjacencyFile, networkData, ',');

%%% Store the neurons positions
positionsData = [network.X, network.Y];
dlmwrite(positionsFile, positionsData, ',');

%%% Close
if(verbose)
    fprintf('Network saved successfully.\n');
end
