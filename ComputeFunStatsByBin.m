function [Stats,Cval] = ComputeFunStatsByBin(SIGNALS,fun,iclass)

% COMPUTEFUNSTATSBYBIN - Compute generalized signal-group array statistics by bin.
% Stats = ComputeFunStatsByBin(SIGNALS,fun,iclass)
% [Stats,Cval] = ComputeFunStatsByBin(...)
%
% Compute user-function-based statistics from a signal-group array 
% according to a binning scheme.  Input 'fun' is any function of a 
% single (vector) input to be applied to all time series in the signal 
% group array before computing the statistics.  The function may 
% return a scalar (as, for example, @min, @max, or @rms, etc.) 
% or a vector of any length, provided that the length is consistent 
% for consistent-length inputs.  The function should also be tolerant 
% of nan inputs. (Setting 'fun' to @min, @max, and @mean replicates 
% the results of "ComputeLtStatsByBin", and setting fun to @(x)x 
% replicates the results of "ComputeStStatsByBin".) 
%
% Input 'SIGNALS' is a length-N array of homogeneous signal groups 
% of M signals each.  Input 'iclass' is a length-N vector of bin 
% index values ranging from 0 to P, with 0 indicating array elements 
% to be excluded from the analysis. 
%
% Output 'Stats' is a structure giving statistics of all signal 
% channels, segregated by bin.  The structure has the following 
% fields, each a P x M matrix corresponding to the P bins and M 
% signals: 
%   'min'   -  minimum values by bin
%   'max'   -  maximum values by bin
%   'mean'  -  mean values by bin
%   'p05'   -  5th-percentile values by bin
%   'p50'   -  50th-percentile (median) values by bin
%   'p95'   -  95th-percentile values by bin
%
% To support computation of additional statistics not listed here, 
% cell array 'Cval' is available as an optional output.  Each cell 
% of 'Cval' contains an M-column matrix representing the raw 'fun' 
% output for the M signals segregated by bin.  As an example, a 
% standard deviation ('std') field can be added as follows: 
%   C = cellfun(@std, Cval,'Uniform',false);
%   Stats.std = cat(1,C{:});
%
% Note these special cases: 
%     iclass                          result
%    --------                        --------
%  1:length(SIGNALS)          -  Returns a complete set of statistics 
%                                (min, max, mean, etc.) describing the 
%                                function outputs for the array, 
%                                considering all cases individually. 
%                                All fields are N X M. (Note, if 'fun' 
%                                returns a scalar, all fields will 
%                                also be equal.) 
%  ones(size(SIGNALS)))       -  Returns global min, max, mean, etc. 
%                                of the function output, by signal.  
%                                All fields are 1 X M. 
%
% See also "ComputeLtStatsByBin", "ComputeStStatsByBin". 
%
% P.G. Bonanni
% 6/20/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


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

% Check 'fun' input
if ~isa(fun,'function_handle')
  error('Invalid ''fun'' input.')
end

% Check 'iclass' input
if ~isnumeric(iclass) || ~isvector(iclass) || ~all(rem(iclass,1)==0) || ...
    any(iclass < 0) || length(iclass)~=length(SIGNALS)
  error('Invalid ''iclass'' input.')
end

% Number of bins
P = max(iclass);

% Convert to 3d array
XX = cat(3,SIGNALS.Values);

% Apply the function
C = num2cell(XX,1);  % separate columns
C1 = cellfun(fun,C,'Uniform',false);
[m,n] = cellfun(@size,C1);
if ~all(n==1)
  error('Function ''fun'' should return a scalar or a column vector.')
elseif ~all(m==m(1))
  error('Function ''fun'' outputs are not of consistent length.')
end
YY = cell2mat(C1);

% Percentile functions
fun05 = @(x)prctile(x, 5,1);
fun50 = @(x)prctile(x,50,1);
fun95 = @(x)prctile(x,95,1);

% Classify into bins
Cval = cell(P,1);  % initialize
for k = 1:P
  mask = iclass==k;
  X = YY(:,:,mask);
  X = permute(X,[1,3,2]);
  Cval{k} = reshape(X,[],size(X,3));
end

% Compute statistics by bin
C = cellfun(@(x)min1(x),  Cval, 'Uniform',false);  Stats.min  = cat(1,C{:});
C = cellfun(@(x)max1(x),  Cval, 'Uniform',false);  Stats.max  = cat(1,C{:});
C = cellfun(@(x)mean1(x), Cval, 'Uniform',false);  Stats.mean = cat(1,C{:});
C = cellfun(@(x)fun05(x), Cval, 'Uniform',false);  Stats.p05  = cat(1,C{:});
C = cellfun(@(x)fun50(x), Cval, 'Uniform',false);  Stats.p50  = cat(1,C{:});
C = cellfun(@(x)fun95(x), Cval, 'Uniform',false);  Stats.p95  = cat(1,C{:});



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
