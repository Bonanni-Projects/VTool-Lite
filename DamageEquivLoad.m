function [del,Nref] = DamageEquivLoad(x,t,slope,Nref,Life)

% DAMAGEEQUIVLOAD - Damage equivalent load for a time series.
% [del,Nref] = DamageEquivLoad(x,[],slope)
% [del,Nref] = DamageEquivLoad(x,[],slope,Nref)
% [del,Nref] = DamageEquivLoad(x,t,slope,Nref,Life)
% [del,Nref] = DamageEquivLoad(x,T,slope,Nref,Life)
%
% Computes the damage equivalent load of time series vector 'x' 
% given S-N fatigue 'slope'.  Outputs damage equivalent load 
% value 'del' and the corresponding number of reference cycles, 
% taken to be the actual number of counted cycles in the time 
% series.  Alternatively, the user may directly specify the 
% number of reference cycles by providing a non-empty value 
% for 'Nref'. 
%
% Input 'Life' specifies a lifetime duration for extrapolating 
% the computed 'del' value.  It requires specification of time 
% vector 't' matching 'x' in length, or scalar 'T' representing 
% a sample time for 'x'.  Input 'Life' is interpreted in the units 
% provided for 't' or 'T'. 
%
% Calls "rainflow" counting function by Adam Nieslony, obtained 
% from the Mathworks File Exchange. 
%
% Borrows from code by A.S. Deshpande 2012 and L.C. Kammer 2017-18. 
%
% P.G. Bonanni
% 7/19/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 4
  Nref = [];
  Life = [];
elseif nargin < 5
  Life = [];
end

% Check data input
if ~isnumeric(x) || ~isvector(x)
  error('Input ''x'' must be a numeric vector.')
end

% Make column
x = x(:);

% Default 't' if not provided
if isempty(t), t=(0:length(x)-1)'; end

% Check time input
if ~isnumeric(t)
  error('Input ''t'' must be numeric.')
elseif ~isscalar(t) && ~(isvector(t) && length(t)==length(x))
  error('Input ''t'' must be numeric, and either scalar or match ''x'' in length.')
end

% Check other inputs
if ~isnumeric(slope) || ~isscalar(slope)
  error('Input ''slope'' must be numeric and scalar.')
elseif ~isempty(Nref) && (~isnumeric(Nref) || ~isscalar(Nref))
  error('Input ''Nref'' must be numeric and scalar.')
elseif ~isempty(Life) && (~isnumeric(Life) || ~isscalar(Life))
  error('Input ''Life'' must be numeric and scalar.')
end

% Convert single-precision inputs
if ~isa(x, 'double')
  x = double(x);
end
if ~isa(slope, 'double')
  slope = double(slope);
end

% Return NaN if 'x' is all-NaN
if all(isnan(x))
  del = NaN;
  return
end

% Find the extrema of the time series
extrema = sig2ext(x);

% Perform rainflow counting
rf = rainflow(extrema);
CycAmpl = rf(1,:);	% cycle amplitudes
NCycles = rf(3,:);	% number of cycles (0.5 or 1.0)

% Default reference cycles
if isempty(Nref)
  Nref = sum(NCycles);
end

% Damage equivalent load value
del = 2*sum( (NCycles/Nref) .* CycAmpl.^slope) ^ (1/slope);

% Extrapolate to lifetime value, if required
if ~isempty(Life)
  if isscalar(t)
    T = t;  % sample time
    t = T*(0:length(x)-1)';
  end
  duration = t(end)-t(1);
  scale = Life / duration;
  del = del * scale^(1/slope);  % new 'del' value
  Nref = Nref*scale;            % corresponding 'Nref'
end
