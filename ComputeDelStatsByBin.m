function [DelStats,Cdel] = ComputeDelStatsByBin(SIGNALS,iclass,slope,Nref)

% COMPUTEDELSTATSBYBIN - Compute DEL signal-group array statistics by bin.
% DelStats = ComputeDelStatsByBin(SIGNALS,iclass,slope)
% DelStats = ComputeDelStatsByBin(SIGNALS,iclass,slope,Nref)
% [DelStats,Cdel] = ComputeDelStatsByBin(...)
%
% Computes damage equivalent load statistics from a signal-group 
% array according to a binning scheme.  Input 'slope' specifies the 
% S-N fatigue curve slope, and optional argument 'Nref' specifies 
% the number of reference cycles, if the default value based on 
% actual cycles is not desired (see function "DamageEquivLoad").   
%
% Input 'SIGNALS' is a length-N array of homogeneous signal groups 
% of M signals each.  Input 'iclass' is a length-N vector of bin 
% index values ranging from 0 to P, with 0 indicating array elements 
% to be excluded from the analysis. 
%
% Output 'DelStats' is a structure giving DEL statistics of all 
% signal channels, segregated by bin.  The structure has the 
% following fields, each a P x M matrix corresponding to the 
% P bins and M signals: 
%   'min'   -  minimum values by bin
%   'max'   -  maximum values by bin
%   'mean'  -  mean values by bin
%   'p05'   -  5th-percentile values by bin
%   'p50'   -  50th-percentile (median) values by bin
%   'p95'   -  95th-percentile values by bin
%
% To support computation of additional statistics not listed here, 
% cell array 'Cdel' is available as an optional output.  Each cell 
% of 'Cdel' contains an M-column matrix representing the raw DEL 
% data from the M signals segregated by bin.  As an example, a 
% standard deviation ('std') field can be added as follows: 
%   C = cellfun(@std, Cdel,'Uniform',false);
%   DelStats.std = cat(1,C{:});
%
% Note these special cases: 
%     iclass                          result
%    --------                        --------
%  1:length(SIGNALS)          -  Returns a complete set of DEL values 
%                                for the array, considering all cases 
%                                individually.  All fields are N X M, 
%                                and all fields are equal. 
%  ones(size(SIGNALS)))       -  Returns DEL statistics, considering 
%                                all cases pooled together. All fields 
%                                are 1 X M. 
%
% See also "ComputeLtStatsByBin", "ComputeStStatsByBin". 
%
% P.G. Bonanni
% 7/19/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 4
  Nref = [];
end

% Check 'SIGNALS' input
[flag,valid,errmsg] = IsSignalGroupArray(SIGNALS);
if ~flag
  error('Input ''SIGNALS'' is not a signal group array: %s',errmsg)
elseif ~valid
  error('Input ''SIGNALS'' is not a valid signal group array: %s  See "IsSignalGroupArray".',errmsg)
elseif ~isvector(SIGNALS)
  error('Multidimensional ''SIGNALS'' array not permitted.')
end

% Check for data-length uniformity
Lengths = arrayfun(@(x)size(x.Values,1),SIGNALS,'Uniform',false);
if ~isscalar(Lengths) && ~isequal(Lengths{:})
  error('Input array must be data-length uniform.')
end

% Check 'iclass' input
if ~isnumeric(iclass) || ~isvector(iclass) || ~all(rem(iclass,1)==0) || ...
    any(iclass < 0) || length(iclass)~=length(SIGNALS)
  error('Invalid ''iclass'' input.')
end

% Check other inputs
if ~isnumeric(slope) || ~isscalar(slope)
  error('Input ''slope'' must be numeric and scalar.')
elseif ~isempty(Nref) && (~isnumeric(Nref) || ~isscalar(Nref))
  error('Input ''Nref'' must be numeric and scalar.')
end

% Number of bins
P = max(iclass);

% Convert to 3d array
SIGNALS = cat(3,SIGNALS.Values);

% Percentile functions
fun05 = @(x)prctile(x, 5,1);
fun50 = @(x)prctile(x,50,1);
fun95 = @(x)prctile(x,95,1);

% Compute raw DEL values (N x M matrix)
Xdel = permute(calcDEL1(SIGNALS,slope,Nref), [3,2,1]);

% Classify into bins
Cdel = cell(P,1);  % initialize
for k = 1:P
  mask = iclass==k;
  Cdel{k}  = Xdel(mask,:);
end

% Compute statistics by bin
C = cellfun(@(x)min1(x),  Cdel, 'Uniform',false);  DelStats.min  = cat(1,C{:});
C = cellfun(@(x)max1(x),  Cdel, 'Uniform',false);  DelStats.max  = cat(1,C{:});
C = cellfun(@(x)mean1(x), Cdel, 'Uniform',false);  DelStats.mean = cat(1,C{:});
C = cellfun(@(x)fun05(x), Cdel, 'Uniform',false);  DelStats.p05  = cat(1,C{:});
C = cellfun(@(x)fun50(x), Cdel, 'Uniform',false);  DelStats.p50  = cat(1,C{:});
C = cellfun(@(x)fun95(x), Cdel, 'Uniform',false);  DelStats.p95  = cat(1,C{:});



% ---------------------------------------------------------
% calcDEL1 - Return columnwise DELs, and NaNs if empty
function x = calcDEL1(X,slope,Nref)

[m,n] = size(X);  % where X can be 3-d
if m == 0
  x = nan(1,n);
elseif m == 1
  x = zeros(size(X));
else
  [~,n2,n3] = size(X);
  x = zeros(1,n2,n3);  % initialize
  for j=1:n2
    for k=1:n3
      x(1,j,k) = DamageEquivLoad(X(:,j,k),[],slope,Nref);
    end
  end
end


% ---------------------------------------------------------
% MIN1 - Return columnwise minima, and NaNs if empty.
function x = min1(X)

v = size(X);  % where X can be 3-d
if v(1) == 0
  v(1) = 1;
  x = nan(v);
elseif v(1) == 1
  x = X;
else
  x = min(X,[],1);
end


% --------------------------------------------------------------------------
% MAX1 - Return columnwise maxima, and NaNs if empty.
function x = max1(X)

v = size(X);  % where X can be 3-d
if v(1) == 0
  v(1) = 1;
  x = nan(v);
elseif v(1) == 1
  x = X;
else
  x = max(X,[],1);
end


% --------------------------------------------------------------------------
% MEAN1 - Return columnwise means, and NaNs if empty.
function x = mean1(X)

v = size(X);  % where X can be 3-d
if v(1) == 0
  v(1) = 1;
  x = nan(v);
elseif v(1) == 1
  x = X;
else
  x = mean(X,1,'omitnan');
end
