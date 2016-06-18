%% Load data
clear
load('../survey-data-bcs-data-store/XboxPoll/XboxData.mat');
load('../survey-data-bcs-data-store/XboxPollDemo/pop_data.mat')
for i = 1:length(samples)
  samples{i} = double(samples{i})';
end

%% Create cells for timepoints
cellsByTime = cell(length(samples),1);
unNormalizedCellWeights = [];
cellCategories = [];
demoNames = {'race','age','party','education','ideology','sex'};
weightName = 'weight';
%{
for t=1:length(samples)
    t
    cells = Cells(pop_data,demoNames,weightName,unNormalizedCellWeights,cellCategories);
    unNormalizedCellWeights = cells.unNormalizedCellWeights;
    cellCategories = cells.cellCategories;
    curr_samples = samples{t};
    curr_samples_demo = samplesDemo{t};
    for prevT=(t-1):-1:max(1,t-3)
        curr_samples = [curr_samples samples{prevT}];
        curr_samples_demo = [curr_samples_demo; samplesDemo{prevT}];
    end
    cells.makeValues(curr_samples,curr_samples_demo);
    cellsByTime{t} = cells;
end
%}
precomputedCells = load('../survey-data-bcs-data-store/XboxPoll/cellsByTime_3Prev.mat');
cellsByTime = precomputedCells.cellsByTime;
unNormalizedCellWeights = precomputedCells.unNormalizedCellWeights;
cellCategories = precomputedCells.cellCategories;

%% Plot raw and postrat estimates over time
figure
rawEst = Cells.getRawEstMult(cellsByTime);
rawEst = 100*(rawEst-1);
xaxis = 1:length(samples);
plot(rawEst,'-x');
hold on
postStratEst = Cells.getPostStratEstMult(cellsByTime);
postStratEst = 100*(postStratEst-1);
plot(postStratEst,'-+');
hold on
fiftyMark = 50*ones(length(xaxis),1);
fiftyTwoMark = 51.96*ones(length(xaxis),1);
plot(xaxis,fiftyMark,xaxis,fiftyTwoMark,'--');
hold off;

%% Plot raw and postrat estimates accuracies groups
figure
subplot(211)
groupAcc = plot_group_acc(cellsByTime{end},0,1);
title(sprintf('Difference for Raw Data. Med: %f, Mean: %f',median(abs(groupAcc)),mean(abs(groupAcc))))
subplot(212)
groupAcc = plot_group_acc(cellsByTime{end},1,1);
title(sprintf('Difference for Poststratified Data Med: %f, Mean: %f',median(abs(groupAcc)),mean(abs(groupAcc))))

%% Plot raw and postrat estimates accuracies categories
figure
categoryAcc = plot_category_acc(cellsByTime{end},0,1);
rawAccs = [median(abs(categoryAcc)) mean(abs(categoryAcc))]
figure
categoryAcc = plot_category_acc(cellsByTime{end},1,1);
postAccs = [median(abs(categoryAcc)) mean(abs(categoryAcc))]

%% Plot raw and postrat estimates for total country and states
figure
subplot(211)
twoPartyElectionError(cellsByTime{end},0,1);
subplot(212)
twoPartyElectionError(cellsByTime{end},1,1);
