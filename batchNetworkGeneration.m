%% Batch network generation script
% Generates a full set of equivalent networks for the post challenge
% verification
%
% Copyright (C) 2014, Javier G. Orlandi <javierorlandi@javierorlandi.com>

%%% Init functions

clear all;
cd('~/drive/research/challengeKaggle/connectomicsPCV/');
addpath(genpath([pwd filesep 'matlab']));

baseOutputPath = [pwd filesep 'networks'];

% 1 question mark for each iterator (N, CC, repetition)
networkBaseFile = 'network_N?_CC?_?';
yamlTag = '.yaml';
adjacencyTag = '_adj.txt';
positionTag = '_pos.txt';
%networkSizes = [50, 100, 200, 500, 1000];
%networkCCs = 0.1:0.1:0.6;
%networkIterations = [1000, 500, 200, 100, 10];

networkSizes = [50, 100];
networkCCs = 0.1:0.2:0.5;
networkIterations = [2, 3];

%% Generate 1 network
N = 100;
p = 0.12;
targetCC = 0.25;
inhFraction = 0.2;

network = generateNetwork(N, p);
network = rewireNetworkToTargetCC(network, targetCC);
network = assignInhibitoryNeurons(network, inhFraction);
% Save it
networkToYAML(network, 'file.yaml');
networkToPlainText(network, 'adj.txt', 'pos.txt');

%% Batch iteration
inhFraction = 0.2;


fprintf('Generating networks...\n');
%%% Iterate sizes
for it1 = 1:length(networkSizes)
    currentNetworkFile_tmp1 = regexprep(networkBaseFile, '?',num2str(networkSizes(it1)),'once');
    N = networkSizes(it1);
    % We want fixed <k>, so p depends on N
    p = 12/N;
    %%% Iterate CCs
    for it2 = 1:length(networkCCs)
        currentNetworkFile_tmp2 = regexprep(currentNetworkFile_tmp1, '?',strrep(num2str(networkCCs(it2)),'.',''),'once');
        targetCC = networkCCs(it2);
        %%% Iterate repetitions
        for it3 = 1:networkIterations(it1)
            currentNetworkFile = regexprep(currentNetworkFile_tmp2, '?',num2str(it3),'once');
            fprintf('Working on %s...\n', currentNetworkFile);
            %%% Generate the network
            network = generateNetwork(N, p, 'verbose', false);
            network = rewireNetworkToTargetCC(network, targetCC, 'verbose', false);
            network = assignInhibitoryNeurons(network, inhFraction);
            
            %%% Save the network
            networkToYAML(network, [baseOutputPath filesep currentNetworkFile yamlTag], 'verbose', false);
            networkToPlainText(network, [baseOutputPath filesep currentNetworkFile adjacencyTag], [baseOutputPath filesep currentNetworkFile positionTag], 'verbose', false);
        end
    end
end

fprintf('Done!\n');
