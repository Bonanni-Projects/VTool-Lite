function out = where(v,t)

% WHERE - Find range(s) of nonzero elements in a vector.
% irange = where(v)
% trange = where(v,t)
%
% Return Nx2 matrix 'irange', each row giving the [start,end] 
% indices of contiguous nonzero elements in vector 'v'. 
%
% If an equal sized and monotonically increasing vector 't' 
% is provided as a second argument, the [start,end] indices 
% are mapped to the 't' vector and returned as Nx2 'trange'.   
%
% See also "maketrue".
%
% P.G. Bonanni
% 1/31/06

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  t = 1:numel(v);
end

% Check inputs
if ~isvector(v) || ~isvector(t)
  error('Accepts vector inputs only.')
elseif length(t) ~= length(v)
  error('Second input must match size of first input.')
elseif min(diff(t)) <= 0
  error('Second input must be monotonically increasing.')
end

% Make columns
v = v(:);
t = t(:);

% Shift by one sample
vr = [0; v(1:end-1)]; % right
vl = [v(2:end); 0];   % left

% Find start and end indices
istart = find(v~=0 & vr==0);
iend   = find(v~=0 & vl==0);

% Output Nx2 matrix
out = [t(istart),t(iend)];
