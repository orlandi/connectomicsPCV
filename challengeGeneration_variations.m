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
MSG = 'Generating original-variations challenge datasets';
disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DEFINE THE INPUT FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fileList = {'test', 'valid'};
networksBaseFolder = ['networks' filesep 'original' filesep];
spikesFolder = ['data' filesep 'original-variations' filesep 'spikes' filesep];
outputBaseFolder = ['data' filesep 'original-variations' filesep ];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DEFINE THE ITERATORS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
it_noiseList = [0, 0.03, 0.06]; % noise_str
it_lsList = [0, 1/sqrt(1000), 1/sqrt(100)]; % LS sigmaScatter
it_rateList = [50, 100, 200]; % FPS
%params.dt
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
    
    timesFile = [spikesFolder baseFile '-times.txt'];
    indicesFile = [spikesFolder baseFile '-idx.txt'];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% LOAD FIRINGS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    firings = nestToFirings(strcat(challengeFolder,indicesFile), strcat(challengeFolder,timesFile));
    
    % Iterators
    for it_noise = 1:length(it_noiseList)
        for it_rate = 1:length(it_rateList)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% GENERATE FLUORESCENCE SIGNAL WITHOUT LS AT THE GIVEN
            %%% NOISE LEVEL AND FPS
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [Forig, Torig] = firingsToFluorescence(firings, network,'lightScattering', false, 'noise_str', it_noiseList(it_noise), 'dt', 1/it_rateList(it_rate));
            
            % Remove the first 10 seconds
            minT = find(Torig > 10, 1, 'first');
            Torig = Torig(minT:end);
            Forig = Forig(minT:end, :);
            
            for it_ls = 1:length(it_lsList)
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%% DEFINE THE OUTPUT FLUORESCENCE FILE
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                outputFluorescenceFile = [outputBaseFolder 'fluorescence_' baseFile '_noise' num2str(it_noise) '_ls', num2str(it_ls) '_rate' num2str(it_rate) '.txt'];
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                MSG = ['Generating file fluorescence_' baseFile '_noise' num2str(it_noise) '_ls', num2str(it_ls) '_rate' num2str(it_rate) '.txt ' '...'];
                disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%% MANUALLY ADD THE LIGHT SCATTERING
                %%% (FOR EFFICIENCY REASONS)
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                sigmaScatter = it_lsList(it_ls);

                amplitudeScatter = 0.15;
                if(sigmaScatter > 0)
                    LSAmplitudes = zeros(size(network.RS));
                    F = Forig;
                    for i = 1:length(network.RS);
                        dist = sqrt((network.X-network.X(i)).^2+(network.Y-network.Y(i)).^2);
                        for j = (i+1):length(network.RS);
                            LSAmplitudes(i,j) = amplitudeScatter*exp(-(dist(j)/sigmaScatter)^2);
                            LSAmplitudes(j,i) = LSAmplitudes(i,j);
                        end
                    end
                    for i = 1:length(network.RS);
                        for j = 1:length(network.RS);
                           F(:, i) =  F(:, i)+Forig(:,j)*LSAmplitudes(i,j);
                        end
                    end
                else
                    F = Forig;
                end
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
        end
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
