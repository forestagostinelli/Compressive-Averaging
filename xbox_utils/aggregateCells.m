function [cellsByTime] = aggregateCells(cellsByTime,aggregatePrev,cellMeans,numAtTimepoint)
    if ~isempty(cellsByTime)
        % TODO update totalMean
        if aggregatePrev > 0
            %% Aggregate cell value and number in cell
            numCells = length(cellsByTime{1}.cellCategories);
            numsInCellByTime = zeros(numCells,length(cellsByTime));
            cellValuesByTime = zeros(numCells,length(cellsByTime));
            for t=1:length(cellsByTime)
                numsInCellByTime(:,t) = cellsByTime{t}.numInCell;
                cellValuesByTime(:,t) = cellsByTime{t}.cellValues.*cellsByTime{t}.numInCell; 
                for prevT=(t-1):-1:max(1,t-aggregatePrev)
                    numsInCellByTime(:,t) = numsInCellByTime(:,t) + cellsByTime{prevT}.numInCell;
                    cellValuesByTime(:,t) = cellValuesByTime(:,t) + ...
                        cellsByTime{prevT}.cellValues.*cellsByTime{prevT}.numInCell;
                end
            end
            %% Average cell values
            for t=1:length(cellsByTime)
                cellsByTime{t}.numInCell = numsInCellByTime(:,t);
                cellsByTime{t}.cellValues = cellValuesByTime(:,t);
                cellsByTime{t}.populatedCells = cellsByTime{t}.numInCell > 0;

                cellsByTime{t}.cellValues(cellsByTime{t}.populatedCells) = ...
                        cellsByTime{t}.cellValues(cellsByTime{t}.populatedCells)./cellsByTime{t}.numInCell(cellsByTime{t}.populatedCells);

                cellsByTime{t}.normalizeCellWeights();
            end
        end
    else
        if aggregatePrev > 0
            %% Aggregate cell value and number in cell
            numsInCellByTime = zeros(length(cellMeans),1);
            cellValuesByTime = zeros(length(cellMeans),1);
            for t=1:length(cellMeans)
                numsInCellByTime(t) = numAtTimepoint(t);
                cellValuesByTime(t) = cellMeans(t)*numAtTimepoint(t);
                for prevT=(t-1):-1:max(1,t-aggregatePrev)
                    numsInCellByTime(t) = numsInCellByTime(t) + numAtTimepoint(prevT);
                    cellValuesByTime(t) = cellValuesByTime(t) + cellMeans(prevT)*numAtTimepoint(prevT);
                end
            end
            %% Average cell values
            populatedTimePoints = numsInCellByTime > 0;
            cellValuesByTime(populatedTimePoints) = ...
                cellValuesByTime(populatedTimePoints)./numsInCellByTime(populatedTimePoints);
            
            cellsByTime = cellValuesByTime;
        else
            cellsByTime = cellMeans;
        end
    end
end

