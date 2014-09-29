function [scores,header,networkID]=readNetworkScoresFromCSV(filename,networkID,n)
%[scores,header,networkID]=readNetworkScoresFromCSV(filename,networkID,n)
% Will write the scores in kaggle format as a CSV file when given the network ID.  
% Scores should be an nxn matrix, whose (i,j)th entry indicates the strength of 
% connection between neuron i and j 
% n is the dimension of the scores matrix....if it is not specified it will
% be inferred from the CSV file

%==========================================================================
% Package: ChaLearn Connectomics Challenge Sample Code
% Source: http://connectomics.chalearn.org
% Authors: Mehreen Saeed
% Date: Jan 2014
% Last modified: NA
% Contact: causality@chalearn.org
% License: GPL v3 see http://www.gnu.org/licenses/
%==========================================================================

% IG: bug corrected May 2014

if nargin < 3, n=0; end
if nargin < 2, networkID=''; end
scores=[]; header=[];

fileExtension = filename(end-3:end);

if ~(strcmp(fileExtension, '.csv') || strcmp(fileExtension, '.txt')), 
    filename=[filename '.csv']; 
end

if ~exist(filename, 'file')
    fprintf([filename ' not found']);
    return; 
end

fp=fopen(filename,'r');

%read the entire file
text = textscan(fp,'%s%s','Delimiter',',');

%segregate the header
header{1} = text{1}{1};
header{2} = text{2}{1};

%segregate the rest of the data
[rows temp] = size(text{1});
text{1} = text{1}(2:rows);
text{2} = text{2}(2:rows);

if isempty(networkID), 
    networkID=text{1}{2};
    uns=strfind(networkID, '_');
    networkID = networkID(1:uns(end-1)-1);
end

%segregate all rows that contain networkID followed by '_'
%ind=regexp(text{1},[networkID '_']);
%ind = cell2mat(ind);
%ind = find(ind==1);
ind = strmatch([networkID '_'], text{1}); % Corrected IG May 2014

%find the strength of each connection
strength = str2num(char(text{2}(ind,:)));

%scan each string and separate the neuron i and neuron j
%i and j indices will be stored in indx and indy
str = text{1}(ind,:);
totalchar = length(networkID);
format = ['%' num2str(totalchar+1) 's%d%1c%d']; %format string for textscan
s = textscan(char(str)',format);
indx = s{2};
indy = s{4};

%find size of scores matrix if we don't know it
if(n==0)
    n=max(max([indx indy]));
end
%allocate scores matrix
scores = zeros(n,n);
%fill it up
scoreIndices = sub2ind([n n],indx,indy);
scores(scoreIndices) = strength;

fclose(fp);