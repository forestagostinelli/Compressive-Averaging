function [lineStyle,extra] = getLineStyle(methodName)
    extra = 0;
    switch methodName
        case 'Avg'
            lineStyle = 'r--x';
        case 'JS'
            lineStyle = 'b--x';
        case 'MTAvg'
            lineStyle = 'k--x';
        case 'OMP'
            lineStyle = 'g-o';
        case 'csavgShared'
            lineStyle = 'g-s';
        case 'csavg-boost'
            lineStyle = 'r-s';
        case 'DNN'
            lineStyle = 'm-*';
        otherwise
            lineStyle = '-o';
            extra = 1;
    end

end

