function [catAcc] = plot_category_acc(cells,poststrat,plotData,exitPollData)
    %% Load data
    isCell = strcmpi(class(cells),'Cells');
    if isCell
        cellsHeader =  lower(cells.header);
    else
        cellsHeader =  keys(cells);
    end
    
    %% Set categories
    demoNames = {'sex','race','age','education','ideology','party'};
    demosKeepIdx = ismember(demoNames,cellsHeader);
    demoNames = demoNames(demosKeepIdx);
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
    
    catNum = 0;
    for d=1:length(demoNames)
        catNum = catNum + length(demoCategories(demoNames{d}));
    end
    catAcc = zeros(catNum,1);
        
    catPos = 1;
    %% Get vote estimate from exit poll data and cells
    for d=1:length(demoNames)
        demo = demoNames{d};
        catNames = demoCategories(lower(demo));

        %% Get estimated value from cells
        estVals = zeros(length(catNames),1);
        exitVals = zeros(length(catNames),1);
        for cat=1:length(catNames)
            [catAcc(catPos), estVals(cat), exitVals(cat)] = ...
                get_acc(cells,demoNames(d),catNames(cat),poststrat,exitPollData);
            catPos = catPos + 1;
        end
        
        %% Plot results
        if plotData
            exitVals = 100*(exitVals-1);
            estVals = 100*(estVals-1);
            subplot(1,length(demoNames),d);
            xaxis = 1:length(catNames);
            plot(xaxis,exitVals,'--o',xaxis,estVals,'-o');
            hold on;
            fiftyMark = 50*ones(length(xaxis),1);
            plot(xaxis,fiftyMark,'--');
            hold off;
            ylim([0 100]);
            xlim([min(xaxis) max(xaxis)]);
            set(gca, 'XTick',1:length(catNames), 'XTickLabel', catNames)
            title(sprintf('%s',demo))
        end
    end
end

