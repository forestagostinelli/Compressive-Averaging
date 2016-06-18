% Massage pop data
clear
%% Load pop data
fid = fopen('../survey-data-bcs-data-store/XboxPollDemo/pop_data.csv');
pop_data = textscan(fid, '%s %s %s %s %s %s %s %s %s %s %s', 'Delimiter',',', 'HeaderLines',1, ... 
    'MultipleDelimsAsOne',true, 'CollectOutput',false);
fclose(fid);


%% Change to 2D cell
nRows = length(pop_data{1});
nCols = length(pop_data);
new_pop_data = cell(nRows,nCols);

for c=1:nCols
    for r=1:nRows
        new_pop_data{r,c} = pop_data{c}{r};
    end
end

pop_data = new_pop_data;
clear new_pop_data;
%% Get rid of rows with NA
goodRowIdxs = [];
for r=1:nRows
    pop_data{r,1} = str2double(pop_data{r,1});
    if (~ismember('NA',pop_data(r,[2:8 10])))
        goodRowIdxs = [goodRowIdxs r];
    end
end
pop_data = pop_data(goodRowIdxs,:);

%% Plot distribution
headerPos = [3 4 5 6 7 8 10];
categories = {{'male','female'},{'white','black','hispanic','other'},{'18-29','30-44','45-64','65+'}...
        {'didn''t graduate from HS','high school graduate','some college','college graduate'},...
        {'democrat','republican','other'},{'liberal','moderate','conservative'},...
        {'barack obama', 'john mccain', 'other', 'did not vote in 2008'}};
weightCol = 1;
for p=1:length(headerPos)
    pos = headerPos(p);
    catNames = categories{p};
    numCats = length(catNames);
    sumVals = sum([pop_data{:,weightCol}]);
    proportions = zeros(numCats,1);
    for c=1:length(catNames)
        idxs = strcmpi(pop_data(:,pos),catNames{c});
        proportions(c) = 100*sum([pop_data{idxs,weightCol}])/sumVals;
    end
    subplot(1,length(headerPos),p)
    xaxis = 1:length(catNames);
    plot(xaxis,proportions);
    ylim([0 100])
    set(gca, 'XTick',1:length(catNames), 'XTickLabel', catNames)
end

%% Save Data
save('../survey-data-bcs-data-store/XboxPollDemo/pop_data.mat','pop_data');