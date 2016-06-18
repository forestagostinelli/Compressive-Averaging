classdef EuclideanLoss < LossLayer
        
    methods
        function output = ForwardProp(obj,input,target)
            obj.input = input;
            obj.target = target;
            
            output = mean((input(:)-target(:)).^2)/2;
            
            obj.output = output;
        end
        
        function grad = BackProp(obj)
            %% Propdown Gradient
            num = length(obj.output);
            grad = (obj.input-obj.target)/num;
        end
    end
    
end