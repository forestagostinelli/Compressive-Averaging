classdef LossLayer < handle
    %LAYER Summary of this class goes here
    
    properties
        input
        output
        target
    end
    
    methods(Abstract=true)
        % Input of shape dim x num
        output = ForwardProp(obj,input,target)
        % grad of shape dim x num
        grad = BackProp(obj)
    end
    
end