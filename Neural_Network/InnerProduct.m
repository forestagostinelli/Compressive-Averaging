classdef InnerProduct < Layer
        
    methods
        %% Initialization
        function Initialization(obj,bottomShape,topShape)
            obj.params = struct;
            inputNum = sum(bottomShape);
            outputNum = sum(topShape);
            
            a = sqrt(3/((inputNum + outputNum)/2));
            
            obj.params.W = unifrnd(-a,a,outputNum,inputNum);
            obj.params.b = zeros(outputNum,1);
            
            obj.paramsGrad.W = zeros(size(obj.params.W));
            obj.paramsGrad.b = zeros(size(obj.params.b));
            
            obj.paramsPrevUpdate.W = zeros(size(obj.params.W));
            obj.paramsPrevUpdate.b = zeros(size(obj.params.b));
        end
        
        %% Forward prop
        function output = ForwardProp(obj,input)
            obj.input = input;
            
            output = bsxfun(@plus,obj.params.W*input,obj.params.b);
            
            obj.output = output;
        end
        
        %% Backprop
        function grad = BackProp(obj,grad)
            %% Gradient to parameters
            obj.paramsGrad.W = grad*obj.input';
            obj.paramsGrad.b = (sum(grad,2));
            
            %% Propdown Gradient
            grad = obj.params.W'*grad;
        end
    end
    
end

