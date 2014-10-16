%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CHALLENGEGENERATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% This script generates the data for the challenge (fluorescence and
%%% network structure). Note: The network and spike data have been created
%%% a priori.

clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DEFINE THE CHALLENGE FOLDER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(ismac || isunix)
    challengeFolder = '~/research/challengeKaggle/connectomicsPCV/';
elseif(ispc)
    challengeFolder = '';
end

% 'Pathify'
cd(challengeFolder);
addpath(genpath([pwd filesep 'matlab']));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MSG = 'Generating small-clustering-lowrate challenge datasets...';
disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DEFINE THE INPUT FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fileList = {'N100_CC0?_?'}; % 1-6, 1-500
clusteringList = 3:6;
networkList = 451:500;

networksBaseFolder = ['networks' filesep 'N100' filesep];
spikesFolder = ['~/ResearchData/challengeKaggle/connectomicsPCV/data' filesep 'small-clustering-lowrate' filesep 'N100' filesep 'spikes' filesep];
outputBaseFolder = ['~/ResearchData/challengeKaggle/connectomicsPCV/data' filesep 'small-clustering-lowrate' filesep 'N100' filesep];

for it1 = 1:length(fileList)
    for it2 = 1:length(clusteringList)
        for it3 = 1:length(networkList)

            baseFile = fileList{it1};
            baseFile = regexprep(baseFile,'?',num2str(clusteringList(it2)),'once');
            baseFile = regexprep(baseFile,'?',num2str(networkList(it3)),'once');
            
            networkFile = [networksBaseFolder 'network_' baseFile '.yaml'];
            outputNetworkFile = [outputBaseFolder 'network_' baseFile '.txt'];
            outputNetworkPositionskFile = [outputBaseFolder 'networkPositions_' baseFile '.txt'];

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            MSG = ['Processing network ' baseFile '...'];
            disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% LOAD THE NETWORK
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            network = YAMLToNetwork(networkFile,'weighted', true);

            timesFile = [spikesFolder baseFile '-times.txt'];
            indicesFile = [spikesFolder baseFile '-idx.txt'];
            outputFluorescenceFile = [outputBaseFolder 'fluorescence_' baseFile '.txt'];


            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% LOAD FIRINGS
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            firings = nestToFirings(indicesFile, timesFile);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% GENERATE FLUORESCENCE SIGNAL
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            sigmaScatter = 1/sqrt(100);  % STANDARD for N=100
            [F, T] = firingsToFluorescence(firings, network,'sigmaScatter',sigmaScatter);

            % Remove the first 10 seconds
            minT = find(T > 10, 1, 'first');
            T = T(minT:end);
            F = F(minT:end, :);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% SAVE FLUORESCENCE DATA
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Store the fluorescence signal (each row a sample, each column a neuron)
            fID = fopen(outputFluorescenceFile, 'w');
            for i = 1:size(F,1)
                %for j = 1:(size(F,2)-1)
                %    fprintf(fID, '%.3f, ', F(i,j));
                %end
                fprintf(fID, '%.3f, ', F(i,1:(end-1)));
                fprintf(fID, '%.3f\n', F(i, end));
            end
            fclose(fID);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% SAVE NETWORK
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Store the network (each row of the form [i,j,w] denoting a connection from i
            % to j with wegiht w). This format allows a direct load of the network
            % through the sparse function
            [i,j,w] = find(network.RS);
            networkData = [i, j, w];
            dlmwrite(outputNetworkFile, networkData, ',');
            % Store the neurons positions
            positionsData = [network.X, network.Y];
            dlmwrite(outputNetworkPositionskFile, positionsData, 'delimiter',',','precision','%.3f');
            if(ismac || isunix)
                cd(outputBaseFolder);
                system(['tar -czvf ' baseFile '.tgz *' baseFile '.txt']);
                %system(['gzip ' outputFluorescenceFile]);
                system(['rm *' baseFile '.txt']);
                cd(challengeFolder);
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MSG = 'Challenge generated.';
disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
