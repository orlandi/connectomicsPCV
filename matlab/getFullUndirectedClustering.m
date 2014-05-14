function C = getFullUndirectedClustering(RS)
% GETFULLUNDIRECTEDCLUSTERING returns the clustering coefficient of each
% node from a given adjacency matrix
%
% USAGE:
%    C = getFullUndirectedClustering(RS)
%
% INPUT arguments:
%    RS - Adjacency matrix (where RS(i,j) = 1 denotes a connection from
%    I to J)
%
% OUTPUT arguments:
%    C - List of nodes' undirected clustering cofficient
%
% EXAMPLE:
%     RS = double(rand(100) > 0.8);
%     RS = RS - diag(diag(RS));
%     C = getFullUndirectedClustering(RS);
%
% REFERENCES:
% Fagiolo, G. Clustering in complex directed networks. 
% Phys Rev E Stat Nonlin Soft Matter Phys 76, 26107 (2007).
%
% Copyright (C) 2014, Javier G. Orlandi <javierorlandi@javierorlandi.com>

A = RS';
T = diag(1/2*(A+A')^3);
dt = (A+A')*ones(length(A),1);
dbw = diag(A^2);
Tmax = dt.*(dt-1)-2*dbw;
C = T./Tmax;
