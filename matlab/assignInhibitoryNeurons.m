function network = assignInhibitoryNeurons(network, p)
% ASSIGNINHIBITORYNEURONS selects neurons at random with probability p and
% turns them into inhibitory (changes their output weights to -1)
%
% USAGE:
%    network = assignInhibitoryNeurons(network, p)
%
% INPUT arguments:
%    network - Network structure (see the README for more info)
%
%    p - Inhibitory probability
%
% OUTPUT arguments:
%    network - Network structure (see the README for more info)
%
% EXAMPLE:
%     network = assignInhibitoryNeurons(network, 0.2);
%     figure;
%     pcolor(newNetwork.RS);
%     shading flat
%
% Copyright (C) 2014, Javier G. Orlandi <javierorlandi@javierorlandi.com>

%%% Create the inhibitory fraction. Select from the binomial
N = size(network.RS,1);
Ninh = binornd(N, p);
inhNeurons = randperm(N, Ninh);

% Change the output weights to -1
network.RS(inhNeurons, :) = -1*network.RS(inhNeurons, :);
network.inhibitoryFraction = p;