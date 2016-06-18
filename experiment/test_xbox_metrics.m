%% Load data
clear
close all
load('../survey-data-bcs-data-store/XboxPollDemo/pop_data.mat');
exitPollData = load('../survey-data-bcs-data-store/XboxPollDemo/exit_poll_2012.mat'); 

%% Load cells for specified demos
ratio = 1;
seed = 1;
aggregatePrev = 0;
unNormalizedCellWeights = [];
cellCategories = [];

demoNames = {'age','sex','race','education','party','ideology'};
demoNamesString = strjoin(sort(demoNames),'_');
weightName = 'weight';

currDataFileName = sprintf('../survey-data-bcs-data-store/XboxCells/ratio_%0.3f_seed_%i_aggPrev_%i_demo_%s.mat',ratio,seed,aggregatePrev,demoNamesString);
cellsByTime = load(currDataFileName,'curr_cells');
cellsByTime = cellsByTime.curr_cells;
numCells = cellsByTime{1}.numCells;

%% Adjust cells
adjust = 0;
adjustType = 2;
modelAggregatePrev = 0;
if adjust == 1
    if adjustType == 0 || adjustType == 2
        paramFileName = sprintf('xbox_utils/meanPredictionModels/no_means_ratio_%0.3f_seed_%i_aggPrev_%i_modelAggPrev%i_demo_%s.mat',ratio,seed,aggregatePrev,modelAggregatePrev,demoNamesString);
        adjustmentModel = load(paramFileName);
        assert(length(adjustmentModel.timeParams) == length(cellsByTime))
    elseif adjustType == 1
        paramFileName = sprintf('xbox_utils/meanPredictionModels/shared_no_inidividual_ratio_%0.3f_seed_%i_aggPrev_%i_demo_%s.mat',ratio,seed,aggregatePrev,demoNamesString);
        adjustmentModel = load(paramFileName);
        assert(length(adjustmentModel.params) == numCells)
    end
    
    cellsByTime = Cells.adjustCellsMult(cellsByTime,adjustmentModel,adjustType);
end

%% Aggregate Cells
aggregateCellsPrev = 0;
cellsByTime = aggregateCells(cellsByTime,aggregateCellsPrev);

%% Plot raw and postrat estimates over time
figure
rawEst = Cells.getRawEstMult(cellsByTime);
rawEst = 100*(rawEst-1);
xaxis = 1:length(cellsByTime);
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


%% Plot raw and postrat estimates accuracies categories
figure
categoryAcc = plot_category_acc(cellsByTime{end},0,1,exitPollData);
rawCategoryAccs = [median(abs(categoryAcc)) mean(abs(categoryAcc))];
figure
categoryAcc = plot_category_acc(cellsByTime{end},1,1,exitPollData);
postCategoryAccs = [median(abs(categoryAcc)) mean(abs(categoryAcc))];

fprintf('Raw median category accuracy: %f, Raw mean category accuracy: %f\n',rawCategoryAccs(1),rawCategoryAccs(2));
fprintf('Poststrat median category accuracy: %f, Poststrat mean category accuracy: %f\n',postCategoryAccs(1),postCategoryAccs(2));

%% Plot country and state accuracy
fprintf('\n');
[~,rawErrorCountry] = twoPartyElectionError(cellsByTime{end},0,0,1);
[~,postErrorCountry] = twoPartyElectionError(cellsByTime{end},1,0,1);

if ismember('state',lower(demoNames))
    figure
    [rawErrorPerState,rawErrorCountry] = twoPartyElectionError(cellsByTime{end},0,1);
    figure
    [postErrorPerState,postErrorCountry] = twoPartyElectionError(cellsByTime{end},1,1);

    fprintf('Raw median state accuracy: %f, Raw mean state accuracy: %f\n',median(abs(rawErrorPerState)),mean(abs(rawErrorPerState)));
    fprintf('Poststrat median state accuracy: %f, Poststrat mean state accuracy: %f\n',median(abs(postErrorPerState)),mean(abs(postErrorPerState)));
end

fprintf('Raw country absolute difference %f\n',rawErrorCountry);
fprintf('Poststrat country absolute difference %f\n',postErrorCountry);


%% Plot raw and postrat estimates accuracies groups
fprintf('\n')
figure
subplot(211)
rawGroupAcc = plot_group_acc(cellsByTime{end},0,1,exitPollData);
title(sprintf('Difference for Raw Data. Med: %f, Mean: %f',median(abs(rawGroupAcc)),mean(abs(rawGroupAcc))))
subplot(212)
poststratGroupAcc = plot_group_acc(cellsByTime{end},1,1,exitPollData);
title(sprintf('Difference for Poststratified Data Med: %f, Mean: %f',median(abs(poststratGroupAcc)),mean(abs(poststratGroupAcc))))

fprintf('Raw median group accuracy: %f, Raw mean group accuracy: %f\n',median(abs(rawGroupAcc)),mean(abs(rawGroupAcc)));
fprintf('Poststrat median group accuracy: %f, Poststrat mean group accuracy: %f\n',median(abs(poststratGroupAcc)),mean(abs(poststratGroupAcc)));

%% Plot each category for each demo
demoCategories = containers.Map();
demoCategories('sex') = {'male','female'};
demoCategories('race') = {'white','black','hispanic','other'};
demoCategories('age') = {'18-29','30-44','45-64','65+'};
demoCategories('education') = {'didn''t graduate from HS','high school graduate','some college','college graduate'};
demoCategories('party') = {'democrat','other','republican'};
demoCategories('ideology') = {'liberal','moderate','conservative'};
demoCategories('state') = {'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','ID','IL','IN',...
    'IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',...
    'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA'...
    'WA','WV','WI','WY'};

figure 
demo = 'age';
categories = demoCategories(demo);
startDate = datenum('09-22-2012');
endDate = datenum('11-5-2012');
xaxis = linspace(startDate,endDate,length(cellsByTime));
for c=1:length(categories)
    subplot(2,2,c)
    vals = zeros(length(cellsByTime),1);
    for t=1:length(cellsByTime)
        vals(t) = getCellGroupEst(cellsByTime{t},{demo},categories(c),1,0);
    end
    halfMark = 1.5*ones(length(xaxis),1);
    h = plot(xaxis,halfMark,'--'); hold on;
    set(h, 'LineWidth', 3);
    h = plot(xaxis,vals);
    set(h, 'LineWidth', 3);
    ylim([1 2]);
    title(sprintf('%s',categories{c}));
    %set(gca,'XtickLabel',xaxis(1:1:end))
    %ax = gca;
    %ax.XTick = xaxis;
    datetick('x','mmm/dd','keepticks')
    xlim([min(xaxis) max(xaxis)]);
    %ax.XTickLabelRotation=45;
end
