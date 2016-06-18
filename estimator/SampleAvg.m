classdef SampleAvg < Avg
    properties
        mean
    end

    methods
        function obj = SampleAvg(mean)
            if ~exist('mean','var')
                obj.mean = [];
            else
                obj.mean = mean;
            end
        end
        
        function name = get_name(obj)
          name = 'Avg';
        end

        function mu_h = avg(obj, samples, y, N)
          % averaging using vanilla sample averages.
          % input:
          %     samples:   a 1-D cell array, each cell is a list of samples. 
          %     sigma2 :  noise variable.
            if (isempty(obj.mean))
                mu_h = cellfun(@mean, samples);
            else
                mu_h = obj.mean;
            end
            if (exist('y','var'))
                mu_h = y;
            end
        end
    end
end
