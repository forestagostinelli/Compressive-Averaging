classdef Sigmoid < Layer
        
    methods
        function Initialization(obj,bottomShape,topShape)
            obj.params = struct;
        end
        
        function output = ForwardProp(obj,input)
            obj.input = input;
            
            output = 1./(1+exp(-input));
            
            obj.output = output;
        end
        
        function grad = BackProp(obj,grad)
            %% Propdown Gradient
            grad = grad.*obj.output.*(1-obj.output);
        end
    end
    
end