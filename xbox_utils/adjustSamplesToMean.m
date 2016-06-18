function [samples] = adjustSamplesToMean(old_mean,new_mean,samples)
    assert(length(old_mean) == length(new_mean));
    assert(length(old_mean) == length(samples));
    
    numMeans = length(old_mean);
    for n=1:numMeans
        diff = new_mean(n) - old_mean(n);
        samples{n} = samples{n} + diff;
        samples{n} = max(samples{n},1);
        samples{n} = min(samples{n},2);
    end
end

