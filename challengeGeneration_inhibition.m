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
MSG = 'Generating inhibition challenge datasets...';
disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DEFINE THE INPUT FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fileList = {'normal-1','normal-2','normal-3','normal-4','valid','test'};
networksBaseFolder = ['networks' filesep 'original' filesep];
spikesFolder = ['data' filesep 'inhibition' filesep 'spikes' filesep];
outputBaseFolder = ['data' filesep 'inhibition' filesep ];
%fileList = {'valid','test'};

for it1 = 1:length(fileList)
    baseFile = fileList{it1};
    networkFile = [networksBaseFolder baseFile '-withShufflingData.yaml'];
    outputNetworkFile = [outputBaseFolder 'network_' baseFile '.txt'];
    outputNetworkPositionskFile = [outputBaseFolder 'networkPositions_' baseFile '.txt'];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    MSG = ['Processing network ' baseFile '...'];
    disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% LOAD THE NETWORK
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    network = YAMLToNetwork(strcat(challengeFolder,networkFile),'weighted', true);

    % Inh on and off iterator
    for it2 = 1:2
        if(it2 == 1)
            timesFile = [spikesFolder baseFile '-inh-times.txt'];
            indicesFile = [spikesFolder baseFile '-inh-idx.txt'];
            outputFluorescenceFile = [outputBaseFolder 'fluorescence_' baseFile '-inh.txt'];
        else
            timesFile = [spikesFolder baseFile '-inh_off-times.txt'];
            indicesFile = [spikesFolder baseFile '-inh_off-idx.txt'];
            outputFluorescenceFile = [outputBaseFolder 'fluorescence_' baseFile '-inh_off.txt'];
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% LOAD FIRINGS
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        firings = nestToFirings(strcat(challengeFolder,indicesFile), strcat(challengeFolder,timesFile));

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% GENERATE FLUORESCENCE SIGNAL
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        sigmaScatter = 1/sqrt(1000);  % STANDARD for N=1000
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
    end
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
        system(['tar -czvf ' baseFile '_inhibition.tgz *' baseFile '*.txt']);
        system(['rm *' baseFile '*.txt']);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MSG = 'Challenge generated.';
disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
