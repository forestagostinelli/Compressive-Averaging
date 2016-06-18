classdef ReLU < Layer
        
    methods
        function Initialization(obj,bottomShape,topShape)
            obj.params = struct;
            obj.hyperParams.negCoeff = 0.01;
        end
        
        function output = ForwardProp(obj,input)
            obj.input = input;
            
            output = max(input,0) + obj.hyperParams.negCoeff*min(input,0);
            
            obj.output = output;
        end
        
        function grad = BackProp(obj,grad)
            %% Propdown Gradient
            grad = grad.*((obj.input > 0) + obj.hyperParams.negCoeff*(obj.input <= 0));
        end
    end
    
end