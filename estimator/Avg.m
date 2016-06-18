classdef Avg < handle
    methods(Abstract=true)
        mu_h = avg(obj, samples);
        name = get_name(obj);
    end
end
