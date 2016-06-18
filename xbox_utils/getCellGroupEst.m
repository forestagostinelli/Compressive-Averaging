function [estVal, cellIdxs, cellSamples, cellIdxsTotal] = getCellGroupEst(cells,demoNames,categoryNames,poststrat,adjustCells)
    %% Initialization
    if ~exist('adjustCells','var')
        adjustCells = 1;
        %fprintf('Warning: must say if cells are adjusted\n');
    end
    cellsHeader =  lower(cells.header);
    
    %% Find index that match that category
    numCells = cells.numCells;
    cellIdxs = true(numCells,1);
    for d=1:length(demoNames)
        cellDemoPos = strcmpi(cellsHeader,demoNames{d});
        
        assert(sum(cellDemoPos) > 0,'No header names found with name %s',demoNames{d});
        assert(sum(cellDemoPos) < 2,'More than one header names found with name %s',demoNames{d});
        
        matchIdxs = strcmpi(categoryNames{d},cells.cellCategories(cellDemoPos,:));
        assert(sum(matchIdxs) > 0,'No people found with demographic info in cells for category %s',categoryNames{d});

        cellIdxs(:) = cellIdxs(:) & matchIdxs(:);
    end
    
    cellIdxsTotal = cellIdxs;
    if ~poststrat || ~adjustCells
        cellIdxs(:) = cellIdxs(:) & cells.populatedCells(:);
        if max(cellIdxs) == 0
            cellIdxs(cells.populatedCells) = 1;
        end
    end
    
    %% Get estimate for category
    cellSamples = [cells.cellSamples{cellIdxs}];
    
    if poststrat
        cellWeights = cells.cellWeights(cellIdxs);
        if (max(cellWeights) == 0)
            cellWeights(:) = 1;
        end

        cellWeights = cellWeights/sum(cellWeights);
        cellValues = cells.cellValues(cellIdxs);
        
        estVal = sum(cellValues.*cellWeights);
    else
        estVal = mean(cellSamples);
    end
end

