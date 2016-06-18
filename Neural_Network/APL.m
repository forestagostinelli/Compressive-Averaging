classdef APL < Layer
        
    methods
        function Initialization(obj,bottomShape,topShape)
            obj.params = struct;

            inputNum = sum(bottomShape);
            outputNum = sum(topShape);

            obj.hyperParams.sums = 5;
            obj.hyperParams.hasInit = false;
            
            obj.params.slopes = zeros(inputNum,1,obj.hyperParams.sums);
            slopeRange = 1/obj.hyperParams.sums;
            obj.params.slopes = 0*unifrnd(-slopeRange,slopeRange,size(obj.params.slopes));
            obj.params.offsets = zeros(inputNum,1,obj.hyperParams.sums);
            
            obj.paramsGrad.slopes = zeros(size(obj.params.slopes));
            obj.paramsGrad.offsets = zeros(size(obj.params.offsets));
            
            obj.paramsPrevUpdate.slopes = zeros(size(obj.params.slopes));
            obj.paramsPrevUpdate.offsets = zeros(size(obj.params.offsets));
            
            obj.hyperParams.maxsData = [];
        end
        
        function output = ForwardProp(obj,input)
            obj.input = input;
            
            if obj.hyperParams.hasInit == false
                inputMean = mean(input,2);
                inputVar = var(input,0,2);
                
                for s=1:obj.hyperParams.sums
                    obj.params.offsets(:,s) = normrnd(inputMean,inputVar);
                end
                
                obj.hyperParams.hasInit = true;
            end
            
            output = max(input,0);
            obj.hyperParams.maxsData = max(bsxfun(@plus,-input,obj.params.offsets),0);
            output = output + ...
                    sum(bsxfun(@times,obj.params.slopes,obj.hyperParams.maxsData),3);
            
            obj.output = output;
        end
        
        function grad = BackProp(obj,grad)
            maxGTZero = obj.hyperParams.maxsData > 0;
            prevGrad = grad;
            %% Gradient to slopes
            obj.paramsGrad.slopes = sum(bsxfun(@times,prevGrad,obj.hyperParams.maxsData),2);
            
            %% Gradient to offsets and prop down
            grad = prevGrad.*(obj.input > 0);
            offsetDiff = bsxfun(@times,obj.params.slopes,maxGTZero);
            offsetDiff = bsxfun(@times,prevGrad,offsetDiff);
            obj.paramsGrad.offsets = sum(offsetDiff,2);
            
            grad = grad + sum(-offsetDiff,3);
        end
    end
    
end