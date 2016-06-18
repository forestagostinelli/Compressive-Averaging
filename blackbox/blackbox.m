classdef blackbox < handle
  properties
    mu % measurement.
    noise % noise
  end
  methods (Abstract)
    recover(new_mu, new_noise)
  end
  methods
    function M = estimate(obj, A)
      new_noise = obj.noise + A;
      M = obj.estimate(obj.mu, new_noise);
    end
  end
end