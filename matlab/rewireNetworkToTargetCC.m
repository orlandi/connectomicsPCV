function network = rewireNetworkToTargetCC(network, targetClustering, varargin)
% REWIRENETWORKTOTARGETCC rewires the nodes to achieve the desired
% undirected clustering coefficient (CC)
%
% USAGE:
%    network = rewireNetworkToTargetCC(network, targetCC)
%
% INPUT arguments:
%    network - Network structure (see README for more info)
%    targetClustering - Desired clustering coefficient
%
% INPUT optional arguments ('key' followed by its value): 
%    'maxIterations' - maximum iterations allowed for the rewiring
%    procedure (you can set it to inf) (default 150000)
%
%    'tolerance' - range of valid values around the desired CC (default
%    0.01)
%
%    'verbose' - (true/false) Plot detailed information (default true)
%
% OUTPUT arguments:
%    network - Network structure (see README for more info)
%
% EXAMPLE:
%     network = rewireNetworkToTargetCC(network, 0.1);
%
% REFERENCES:
% Bansal, S., Khandelwal, S. & Meyers, L. A. Exploring biological 
% network structure with clustered random networks. BMC Bioinformatics 10,
% 405 (2009).
%
% Copyright (C) 2014, Javier G. Orlandi <javierorlandi@javierorlandi.com>

%%% Assign defuault values
params.maxIterations = 150000;
params.tolerance = 0.01;
params.verbose = true;
params = parse_pv_pairs(params,varargin); 

maxIterations = params.maxIterations;
tolerance = params.tolerance;
verbose = params.verbose;

%%% Start the rewiring procedure
iteration = 1;
outputIteration = 100;
outputCounter = 0;
done = false;

RS = network.RS;
fullC = getFullUndirectedClustering(RS);
meanC = mean(fullC);
if(targetClustering > meanC)
    clusteringModifier = 1; % We have to increase clustering
else
    clusteringModifier = 0; % We have to reduce clustering
end
if(verbose)
    fprintf('Starting the rewiring...\n');
    fprintf('Initial CC: %f\n', meanC);
end
while(iteration <= maxIterations && ~done)    
    % This basically changes connections A->B and C->D into A->D and C->B    
    permRS = RS;
    [r, c] = find(permRS);
    selection = randperm(length(r),2);
    c1 = selection(1); % Connection that goes from A to B
    A = r(c1);B = c(c1);
    c2 = selection(2); % Connection that goes from C to D
    C = r(c2);D = c(c2);
    if(~permRS(A, D) && ~permRS(C, B) ...
            && A ~= C && A ~= D && B ~= C) % if A->D and C->B doesn't exist
        permRS(A, B) = 0;
        permRS(C, D) = 0;
        permRS(A, D) = 1;
        permRS(C, B) = 1;

        % Now calculate the new clustering
        newC = getFullUndirectedClustering(permRS);
        %newClustering = mean(newC([A, B, C, D])) > mean(fullC([A, B, C, D]));
        newClustering = mean(newC) > mean(fullC);
        if(newClustering == clusteringModifier)
            RS = permRS;
            fullC = newC;
            meanC = mean(fullC);
            outputCounter = outputCounter+1;
            if(verbose && outputCounter == outputIteration)
                outputCounter = 1;
                fprintf('CC after %d iterations: %f\n', iteration, meanC);
            end
        end
    end
    iteration = iteration + 1;

    if(targetClustering-tolerance > meanC)
        clusteringModifier = 1;
    elseif(targetClustering+tolerance < meanC)
        clusteringModifier = 0;
    end
    if((meanC >= targetClustering-tolerance) && (meanC <= targetClustering+tolerance))
        done = true;
    end
end

if((targetClustering-tolerance > meanC) || (targetClustering+tolerance < meanC))
    fprintf('Warning: Could not reach the target CC after %d iterations\n Final CC: %f\n', maxIterations, meanC);
else
    if(verbose)
        fprintf('Target CC reached after %d iterations.\nFinal CC: %f\n', iteration, meanC);
    end
end
network.RS = RS;
network.CC = meanC;