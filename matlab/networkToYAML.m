function networkToYAML(network, filename, varargin)
% NETWORKTOYAML saves a Network structure in YAML format
%
% USAGE:
%    networkToYAML(network, fileName)
%
% INPUT arguments:
%    network - Network structure (see the README for more info)
%
%    fileName - fileName of the output file (with extension)
%
% INPUT optional arguments ('key' followed by its value): 
%    'notes' - String to add to the network structure (remember to use 
%    quotation marks) (default "")
%
%    'verbose' - (true/false) Plot detailed information (default true)
%
% EXAMPLE:
%     networkToYAML(network, 'test.yaml', 'notes', '"test network"')
%
% Copyright (C) 2014, Javier G. Orlandi <javierorlandi@javierorlandi.com>

%%% Assign defuault values
params.notes = '""';
params.verbose = true;
params = parse_pv_pairs(params,varargin); 

notes = params.notes;
verbose = params.verbose;

%%% Generate the file
if(verbose)
    fprintf('Saving the network to %s...\n', filename);
end

fid = fopen(filename, 'w');
if(fid == -1)
    fprintf('Could not open %s for writting. Aborting.\n', filename);
    return;
end
fprintf(fid, '--- # parameters for the simulator\n');
fprintf(fid, 'size: %d\n', length(network.X));
fprintf(fid, 'cons: %i\n', full(sum(~~network.RS(:))));
fprintf(fid, 'minDist: %.3f\n', network.minDist);
fprintf(fid, 'notes: %s\n', notes);
fprintf(fid, 'connectionProbability: %.3f\n', network.p);
if(isfield(network,'inhibitoryFraction'))
    fprintf(fid, 'inhibitoryFraction: %.3f\n', network.inhibitoryFraction);
else
    fprintf(fid, 'inhibitoryFraction: 0\n');
end
if(isfield(network,'CC'))
    fprintf(fid, 'clusteringCoefficient: %.3f\n', network.CC);
else
    fprintf(fid, 'clusteringCoefficient: %s\n', 'unknown');
end
fprintf(fid, 'createdAt: %s\n', network.creationDate);
fprintf(fid, 'nodes:\n');

for i = 1:length(network.X)
    fprintf(fid, '  - id: %d\n', i);
    fprintf(fid, '    pos: [%.3f, %.3f]\n', network.X(i), network.Y(i));
    fprintf(fid, '    connectedTo: [');
    cons = find(network.RS(i, :));
    for j = 1:length(cons)
        if(j < length(cons))
            fprintf(fid, '%d, ', cons(j));
        else
            fprintf(fid, '%d', cons(j));
        end
    end
    fprintf(fid, ']\n');
    
    fprintf(fid, '    weights: [');
    for j = 1:length(cons)
        if(j < length(cons))
            fprintf(fid, '%.3f, ', network.RS(i,cons(j)));
        else
            fprintf(fid, '%.3f', network.RS(i,cons(j)));
        end
    end
    fprintf(fid, ']\n');
end

%%% Close
fclose(fid);
if(verbose)
    fprintf('Network saved successfully.\n');
end
