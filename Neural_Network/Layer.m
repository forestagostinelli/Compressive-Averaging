classdef Layer < handle
    %LAYER Summary of this class goes here
    
    properties
        params
        paramsGrad
        paramsPrevUpdate
        hyperParams
        input
        output
    end
    
    methods(Abstract=true)
        Initialization(obj,bottomShape,topShape)
        % Input of shape dim x num
        output = ForwardProp(obj,input)
        % grad of shape dim x num
        grad = BackProp(obj,grad)
    end
    
end

