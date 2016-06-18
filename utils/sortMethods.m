function [methodNamesSorted] = sortMethods(methodNames)
    methodNamesSorted = {};
    methodOrder = {'Avg','JS','MTAvg','OMP','DNN','csavgShared',...
        'OMP (L=4)','OMP (L=8)','OMP (L=16)','OMP (L=32)'};

    methodPos = 1;
    for i=1:length(methodOrder)
        if ismember(methodOrder{i},methodNames)
            methodNamesSorted{methodPos} = methodOrder{i};
            methodPos = methodPos + 1;
        end
    end

    for i=1:length(methodNames)
        if ~ismember(methodNames{i},methodNamesSorted)
            methodNamesSorted{methodPos} = methodNames{i};
            methodPos = methodPos + 1;
        end
    end
end

