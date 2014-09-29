%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CHALLENGEVALIDATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Example of a Challenge validation. Compares the provided scores matrix
%%% with the true topology using the ROC curve.

clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DEFINE THE CHALLENGE FOLDER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(ismac || isunix)
    challengeFolder = '~/drive/research/challengeKaggle/connectomicsPCV';
elseif(ispc)
    challengeFolder = 'C:\Users\Dherkova\Dropbox\Projects\GTE-Challenge\MATLAB';
end

% 'Pathify'
cd(challengeFolder);
addpath(genpath([pwd filesep 'matlab']));
addpath(genpath('~/drive/research/matlab'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DEFINE THE INPUT FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
truthFile = [pwd filesep 'originalData' filesep 'truth' filesep 'valid.csv'];
teFile = [pwd filesep 'originalData'  filesep 'te_solution.csv'];
top20folder = ['data' filesep 'top20'];

%%
[teScores,header,networkID]=readNetworkScoresFromCSV(teFile,'valid');
save('teScores','teScores');

%%
[valid,header,networkID]=readNetworkScoresFromCSV(truthFile,'valid');
save('valid','valid');


%%
scores610 = zeros(1000,1000,5);

k = 1;
for i = 6:10
    currDir = dir([pwd filesep top20folder filesep sprintf('%.4d',i) '*']);
    currResults = dir([pwd filesep top20folder filesep currDir.name filesep '*']);
    currFile = [pwd filesep top20folder filesep currDir.name filesep currResults(3).name];

    [scores610(:,:,k),~,~]=readNetworkScoresFromCSV(currFile,'valid');
    k = k+1;
end
save('scores610','scores610');

%%


i = 1;
currDir = dir([pwd filesep top20folder filesep sprintf('%.4d',i) '*']);
currResults = dir([pwd filesep top20folder filesep currDir.name filesep '*']);
currFile = [pwd filesep top20folder filesep currDir.name filesep currResults(3).name];

[truth,~,~]=readNetworkScoresFromCSV(currFile,'valid');

%%
[truth,header,networkID]=readNetworkScoresFromCSV(truthFile,'valid');

%[scoresTE, ~, ~]=readNetworkScoresFromCSV(teFile,'valid');




%%
scoresND = ND(scoresTE, 0.8);

%%
FPR = zeros(5, 500);
TPR = zeros(5, 500);
AUC = zeros(5, 1);
mark = zeros(5, 1);

[AUC(1), FPR(1,:), TPR(1,:), mark(1)] = computeROC(truth, scoresTE, 'plot', false, 'mark', 0.01);
[AUC(2), FPR(2,:), TPR(2,:), mark(2)] = computeROC(truth, scoresAAAGV, 'plot', false, 'mark', 0.01);
[AUC(3), FPR(3,:), TPR(3,:), mark(3)] = computeROC(truth, scoresMat, 'plot', false, 'mark', 0.01);
[AUC(4), FPR(4,:), TPR(4,:), mark(4)] = computeROC(truth, scoresIlde, 'plot', false, 'mark', 0.01);
[AUC(5), FPR(5,:), TPR(5,:), mark(5)] = computeROC(truth, scoresND, 'plot', false, 'mark', 0.01);

%%
N = 4;
cols = 'rmbkg';
figure; hold on;

for i = 1:N
    plot(FPR(i,:), TPR(i,:), 'Color', cols(i));
end
legend('GTE', '1st', '2nd', '3rd','Location','SE');
legend('boxoff');
xlabel('FPR');
ylabel('TPR');
box on;
title('ROC for GTE + ND');

%% Now with ND
scoresND= ND(scores);

%%
[AUCND, FPRND, TPRND] = computeROC(truth, scoresND, 'plot', true);

%%
N = 20;
eps = 1e-5;
FPR = zeros(N+1, 500);
TPR = zeros(N+1, 500);
AUC = zeros(N+1, 1);

betas = linspace(0+eps, 1-eps, N);
for i = 1:N
    scoresND= ND(scores, betas(i));
    [AUC(i), FPR(i,:), TPR(i,:)] = computeROC(truth, scoresND, 'plot', false);
end
[AUC(end), FPR(end,:), TPR(end,:)] = computeROC(truth, scores, 'plot', false);

%%
cols = jet(N);
figure; hold on;

for i = 1:N
    plot(FPR(i,:), TPR(i,:), 'Color', cols(i,:));
end
h = plot(FPR(end,:), TPR(end,:), 'Color', 'k','LineWidth',2);
legend(h, 'raw GTE','Location','SE');
legend('boxoff');
xlabel('FPR');
ylabel('TPR');
box on;
title('ROC for GTE + ND');

%%

figure;
plot(betas,AUC(1:end-1,1),'-','MarkerSize',18);
hold on;
xlabel('$\beta$');
ylabel('AUC');
title('AUC with Network Deconvolution algorithm (max 0.8931)');
xl = xlim;
plot(xl, [1, 1]*AUC(21),'k');
legend('GTE+ND', 'raw GTE');
legend('boxoff');
box on;

%% Load the network and the scores old format
networkData = load(networkFile);
N = max(max(networkData(:,1:2)));
network.RS = sparse(networkData(:,1), networkData(:,2), networkData(:,3), N, N);
network.RS(network.RS < 0) = 0;
network.RS = full(network.RS);
scores = load(scoresFile);


%% Load the network and the scores Kaggle format
networkData = load(networkFile);
N = max(max(networkData(:,1:2)));
network.RS = sparse(networkData(:,1), networkData(:,2), networkData(:,3), N, N);
network.RS(network.RS < 0) = 0;
network.RS = full(network.RS);
%scores = load(scoresFile);
scoresKaggle = dlmread(scoresFile,',',1,1);
% Scores should be a complete square matrix, so let's hack it back to
% matrix form
scores = zeros(sqrt(length(scoresKaggle)));
cidx = 1;
for j = 1:length(scores)
    for i = 1:length(scores)
        scores(i,j) = scoresKaggle(cidx);
        cidx = cidx+1;
    end
end

%% Calculate the ROC curve and plot it
figure;
[AUC, FPR, TPR, TPRatMark, raw] = calculateROC(network, scores, 'plot', true);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MSG = 'Challenge validated.';
disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



