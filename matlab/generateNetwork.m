function network = generateNetwork(N, p, varargin)
% GENERATENETWORK creates a random network with N nodes and connection
% probability p distributed randomly in a rectangle
%
% USAGE:
%    network = generateNetwork(N, p)
%
% INPUT arguments:
%    N - Number of nodes
%
%    p - Connection probability
%
% INPUT optional arguments ('key' followed by its value): 
%    'xrange' - 2-element vector containing the X dimension limits (default
%    [0,1])
%
%    'yrange' - 2-element vector containing the Y dimension limits (default
%    [0,1])
%
%    'minDist' - minimum distance allowed between any two nodes (default
%    0.01)
%
%    'maxIterations' - maximum iterations allowed to avoid node overlaps
%    (default 100)
%
%    'verbose' - (true/false) Plot detailed information (default true)
%
% OUTPUT arguments:
%    network - Network structure (see the README for more info)
%
% EXAMPLE:
%     network = generateNetwork(100, 0.12, 'minDist', 0.05);
%     spy(network.RS);
%     figure;
%     scatter(network.X, network.Y);
%
% Copyright (C) 2014, Javier G. Orlandi <javierorlandi@javierorlandi.com>

%%% Assign defuault values
params.xrange = [0, 1];
params.yrange = [0, 1];
params.minDist = 0.01;
params.maxIterations = 100;
params.verbose = true;
params = parse_pv_pairs(params,varargin); 

xrange = params.xrange;
yrange = params.yrange;
minDist = params.minDist;
maxIterations = params.maxIterations;
verbose = params.verbose;

%%% Position the neurons
X = rand(N,1)*diff(xrange)+xrange(1);
Y = rand(N,1)*diff(yrange)+yrange(1);

%%% Check for overlaps
done = false;
iteration = 0;
if(verbose)
    fprintf('Placing the neurons...\n');
end
while(~done && iteration < maxIterations)
    iteration = iteration + 1;
    dist = squareform(pdist([X, Y], 'euclidean'));
    % Fix the diagonal
    dist(logical(eye(size(dist)))) = inf;
    [r, c] = find(dist < minDist);
    if(isempty(r))
        done = true;
        continue;
    else
        reps = unique([r; c]);
        X(reps) = rand(length(reps), 1)*diff(xrange)+xrange(1);
        Y(reps) = rand(length(reps), 1)*diff(yrange)+yrange(1);
    end
end
if(iteration >= maxIterations)
    fprintf('Warning: Could not place the neurons satisfying a minimum separation of: %f\n', minDist);
else
    if(verbose)
        fprintf('Positions assigned.\n');
    end
end

%%% Create the connectivty matrix, RS
RS = rand(N) < p;
RS = RS - diag(diag(RS)); % Set the diagonal to 0

%%% Generate the network structure
network.RS = RS;
network.X = X;
network.Y = Y;
network.p = p;
network.minDist = minDist;
network.creationDate = datestr(now);
