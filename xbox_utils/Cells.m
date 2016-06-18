classdef Cells < handle
    properties
        cellCategories % the categories in each cell
        cellWeights % How much each cell is weighted
        unNormalizedCellWeights % Cell weights before dividing by sum of populated cell weights
        cellValues % estimates for that cell
        numInCell % Number samples in each cell
        idxs % indecies of demographics
        populatedCells % indicies of populated cells
        cellSamples % samples in each cell
        header % header of population
        totalMean % Total mean samples
        numCells % How many cells there are
    end
    
    methods
        function obj = Cells(pop_data,demo_names,weight_name,unNormalizedCellWeights,cellCategories)
            %% Get category info for cells
            if ~exist('unNormalizedCellWeights','var')
                unNormalizedCellWeights = [];
            end
            header = {'weight','state','sex','race','age','education','party',...
                'ideology','vote.2004','vote.2008','state.contestedness'};
            obj.header = header;
            obj.idxs = find(ismember(obj.header,demo_names));
            weight_idx = find(ismember(obj.header,weight_name));
            obj.header = obj.header(obj.idxs);
            
            weights = pop_data(:,weight_idx);
            pop_data = pop_data(:,obj.idxs);
            numDemo = length(obj.idxs);
            
            %% Set cell categories
            obj.cellCategories = cell(0,0);
            
            if (isempty(cellCategories))
                numCategoriesPerDemo = zeros(numDemo,1);
                demoCategories = cell(numDemo,1);
                for d=1:numDemo
                    demoCategories{d,1} = unique(pop_data(:,d));
                    numCategoriesPerDemo(d) = length(demoCategories{d,1});
                end
                obj.numCells = prod(numCategoriesPerDemo);
                for l=1:numDemo
                    numCurrCells = length(obj.cellCategories);
                    numCategories = numCategoriesPerDemo(l);
                    numNewCell = length(obj.cellCategories)*numCategories;
                    newCells = cell(numNewCell,1);
                    newCellPos = 0;
                    if numCurrCells == 0
                        newCells = demoCategories{l};
                        for nc = 1:length(newCells)
                            newCells{nc} = newCells(nc);
                        end
                    end
                    for i=1:numCurrCells
                        for c=1:numCategories
                            newCellPos = newCellPos + 1;
                            newCell = obj.cellCategories{i};
                            newCell{end+1} = demoCategories{l}{c};
                            newCells{newCellPos} = newCell;
                        end
                    end
                    obj.cellCategories = newCells;
                end
                obj2DCellCategories = cell(length(obj.cellCategories{1}),length(obj.cellCategories));
                for c=1:obj.numCells
                    obj2DCellCategories(:,c) = obj.cellCategories{c};
                end
                obj.cellCategories = obj2DCellCategories;
                assert(size(obj.cellCategories,2) == obj.numCells);
            else
                obj.cellCategories = cellCategories;
            end
            numCategoriesPerCell = length(obj.cellCategories(:,1));
            
            obj.cellValues = zeros(obj.numCells,1);
            obj.unNormalizedCellWeights = zeros(obj.numCells,1);
            obj.numInCell = zeros(obj.numCells,1);
            obj.cellSamples = cell(obj.numCells,1);
            
            %% Create cell weights
            if (isempty(unNormalizedCellWeights))
                numSamples = length(pop_data(:,1));
                idxsRemaining = 1:numSamples;
                for n=1:obj.numCells
                    cCategories = obj.cellCategories(:,n);

                    cellRows = ismember(pop_data(idxsRemaining,1),cCategories{1});
                    for c=2:numCategoriesPerCell
                        cellRows = cellRows & ismember(pop_data(idxsRemaining,c),cCategories{c});
                    end
                    cellIdxs = idxsRemaining(cellRows);
                    idxsRemaining = idxsRemaining(~cellRows); % Remove pop data that has been used

                    obj.unNormalizedCellWeights(n) = sum([weights{cellIdxs}]);
                    if obj.unNormalizedCellWeights(n) == 0 && n>1
                      %  obj.unNormalizedCellWeights(n) = obj.unNormalizedCellWeights(n-1);
                    end
                end
            else
                obj.unNormalizedCellWeights = unNormalizedCellWeights;
            end
        end
        
        function makeValues(obj,vals,vals_pop_data)
            % TODO handle case of unknown category
            %% Initialize
            vals_pop_data = vals_pop_data(:,obj.idxs);
            obj.numCells = length(obj.unNormalizedCellWeights);
            responseNum = length(vals);
            
            assert(responseNum == size(vals_pop_data,1));
            
            obj.cellValues = zeros(obj.numCells,1);
            obj.cellWeights = zeros(obj.numCells,1);
            obj.numInCell = zeros(obj.numCells,1);
            
            %% Record mean
            obj.totalMean = mean(vals);
            
            %% For each response find cell that it belongs to
            cellMem = cell(obj.numCells,1);
            hasCellMem = zeros(responseNum,1);
            
            % Split on demographic with the most entries for fewer
            % comparisons
            numCategoriesInDemo = zeros(size(obj.cellCategories,1),1);
            for d=1:size(obj.cellCategories,1)
                numCategoriesInDemo(d) = length(unique(obj.cellCategories(d,:)));
            end
            [numMaxDemo, demoSplitPos] = max(numCategoriesInDemo);
            catMaxDemo = unique(obj.cellCategories(demoSplitPos,:));
            
            for cat=1:numMaxDemo
                catName = catMaxDemo(cat);
                cellCatPos = find(strcmpi(catName,obj.cellCategories(demoSplitPos,:)));
                pop_data_CatIdx = strcmpi(catName,vals_pop_data(:,demoSplitPos));
                catResponseNum = sum(pop_data_CatIdx);
                for c=1:length(cellCatPos)
                    cPos = cellCatPos(c);
                    cMemIdxs = min(strcmpi(vals_pop_data(pop_data_CatIdx,:),repmat(obj.cellCategories(:,cPos)',catResponseNum,1)),[],2);
                    cellMem{cPos} = false(responseNum,1);
                    cellMem{cPos}(pop_data_CatIdx) = cMemIdxs;
                    
                    hasCellMem(pop_data_CatIdx) = hasCellMem(pop_data_CatIdx) + cellMem{cPos}(pop_data_CatIdx);
                end
            end
                        
            %{
            for c=1:obj.numCells
                cellMem{c} = min(strcmpi(vals_pop_data,repmat(obj.cellCategories(:,c)',responseNum,1)),[],2);
                hasCellMem = hasCellMem + cellMem{c};
            end
            %}
            for c=1:obj.numCells
                memIdxs = cellMem{c};
                obj.numInCell(c) = sum(memIdxs); % memIdxs only 0 or 1
                obj.cellSamples{c} = vals(memIdxs);
                obj.cellValues(c) = sum(obj.cellSamples{c});
            end
            if min(hasCellMem) == 0
                %error('There are samples that dont belong to any cell')
            end
            fprintf('There are %i out of %i samples that don''t belong to any cell\n',...
                length(find(~hasCellMem)),length(hasCellMem))
            if max(hasCellMem) > 1
                error('There are samples that belong to more than one cell')
            end
            obj.populatedCells = obj.numInCell > 0;
            obj.cellValues(obj.populatedCells) = ...
                obj.cellValues(obj.populatedCells)./obj.numInCell(obj.populatedCells);
            
            %% Normalize cell weights
            obj.cellWeights(obj.populatedCells) = ...
                obj.unNormalizedCellWeights(obj.populatedCells)./sum(obj.unNormalizedCellWeights(obj.populatedCells));
        end
        
        function rawEst = getRawEst(obj)
            rawEst = sum(obj.cellValues(obj.populatedCells).*obj.numInCell(obj.populatedCells))./...
                sum(obj.numInCell(obj.populatedCells));
        end
        
        function postStratEst = getPostStratEst(obj)
            postStratEst = sum(obj.cellValues.*obj.cellWeights);
        end
        
        function normalizeCellWeights(obj)
            obj.cellWeights = ...
                obj.unNormalizedCellWeights./sum(obj.unNormalizedCellWeights);
        end
        
        function adjustCells(obj,params,predModel,adjustType,obamaFrac)
            if adjustType == 0
                assert(length(params) == obj.numCells)
                allParams = cell2mat(params);
                obj.cellValues(:) = predModel(allParams)+1;
            elseif adjustType == 1
                timeMean = obj.totalMean;
                allParams = cell2mat(params);
                obj.cellValues(:) = predModel(allParams,(timeMean-1))+1;
            elseif adjustType == 2
                assert(length(params) == obj.numCells)
                allParams = cell2mat(params);
                                
                obj.cellValues(:) = predModel(allParams,obamaFrac)+1;
            end
            obj.cellWeights = obj.unNormalizedCellWeights./sum(obj.unNormalizedCellWeights);
        end
    end
    
    methods(Static)
        function rawEst = getRawEstMult(allCells)
            rawEst = zeros(length(allCells),1);
            for i =1:length(allCells)
                rawEst(i) = allCells{i}.getRawEst();
            end
        end
        
        function postStratEst = getPostStratEstMult(allCells)
            postStratEst = zeros(length(allCells),1);
            for i =1:length(allCells)
                postStratEst(i) = allCells{i}.getPostStratEst();
            end
        end
        
        function obamaFrac = getObamaFrac(cells)
            obamaFrac = zeros(cells.numCells,1);
            statePos = ismember(cells.header,'state');
            uniqueStates = unique(cells.cellCategories(statePos,:));
            for s=1:length(uniqueStates)
                frac = obama2008(uniqueStates{s});
                stateIdxs = strcmpi(cells.cellCategories(statePos,:),uniqueStates{s});
                obamaFrac(stateIdxs) = frac;
            end
        end
        
        function allCells = adjustCellsMult(allCells,adjustmentModel,adjustType,obamaFrac)
            for i =1:length(allCells)
                if adjustType == 0
                    allCells{i}.adjustCells(adjustmentModel.timeParams{i},adjustmentModel.predModel,adjustType);
                elseif adjustType == 1
                    allCells{i}.adjustCells(adjustmentModel.params,adjustmentModel.predModel,adjustType);
                elseif adjustType == 2
                    if ~exist('obamaFrac','var')
                        obamaFrac = Cells.getObamaFrac(allCells{i});
                    end
                    allCells{i}.adjustCells(adjustmentModel.timeParams{i},adjustmentModel.predModel,adjustType,obamaFrac);
                end
            end
        end
    end
end

