function [Min,Max,Mean,Cmin,Cmax,Cmean] = ComputeLtStatsByBin(SIGNALS,iclass)

% COMPUTELTSTATSBYBIN - Compute LT signal-group array statistics by bin.
% [Min,Max,Mean] = ComputeLtStatsByBin(SIGNALS,iclass)
% [Min,Max,Mean,Cmin,Cmax,Cmean] = ComputeLtStatsByBin(...)
%
% Computes "long-time" statistics from a signal-group array 
% according to a binning scheme.  LT or "long-time" statistics 
% refer to the statistics of summary quantities (specifically, 
% min, max, and mean) taken over the the full dataset length. 
%
% Input 'SIGNALS' is a length-N array of homogeneous signal groups 
% of M signals each.  Input 'iclass' is a length-N vector of bin 
% index values ranging from 0 to P, with 0 indicating array elements 
% to be excluded from the analysis. 
%
% Outputs 'Min', 'Max', and 'Mean' are structures giving statistics 
% for the minima, maxima, and mean values of the individual signal 
% channels, segregated by bin.  The structures have the following 
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
% cell arrays (Cmin,Cmax,Cmean) are available as optional outputs. 
% Each cell contains an M-column matrix representing the raw LT 
% min, max, and mean data from the M signals segregated by bin. As 
% an example, a standard deviation ('std') field can be added to 
% the 'Min' structure as follows: 
%   C = cellfun(@std, Cmin,'Uniform',false);
%   Min.std = cat(1,C{:});
%
% Note these special cases: 
%     iclass                          result
%    --------                        --------
%  1:length(SIGNALS)          -  Returns a complete set of LT Min, 
%                                Max, and Mean values for the array, 
%                                considering all cases individually.  
%                                Within each output structure, all 
%                                fields are N X M, and all fields 
%                                are equal. 
%  ones(size(SIGNALS)))       -  Returns statistics for LT Min, Max, 
%                                and Mean, considering all cases pooled 
%                                together. All fields are 1 X M. 
%
% See also "ComputeStStatsByBin", "ComputeDelStatsByBin". 
%
% P.G. Bonanni
% 8/12/18

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

% Check 'iclass' input
if ~isnumeric(iclass) || ~isvector(iclass) || ~all(rem(iclass,1)==0) || ...
    any(iclass < 0) || length(iclass)~=length(SIGNALS)
  error('Invalid ''iclass'' input.')
end

% Number of bins
P = max(iclass);

% Convert to 3d array
SIGNALS = cat(3,SIGNALS.Values);

% Percentile functions
fun05 = @(x)prctile(x, 5,1);
fun50 = @(x)prctile(x,50,1);
fun95 = @(x)prctile(x,95,1);

% Compute raw minima, maxima and mean values (N x M matrices)
Xmin  = permute(min(SIGNALS,[],'omitnan'),[3,2,1]);
Xmax  = permute(max(SIGNALS,[],'omitnan'),[3,2,1]);
Xmean = permute(mean(SIGNALS,  'omitnan'),[3,2,1]);

% Classify into bins
Cmin  = cell(P,1);  % initialize
Cmax  = cell(P,1);  % initialize
Cmean = cell(P,1);  % initialize
for k = 1:P
  mask = iclass==k;
  Cmin{k}  = Xmin(mask,:);
  Cmax{k}  = Xmax(mask,:);
  Cmean{k} = Xmean(mask,:);
end

% Compute statistics by bin
C = cellfun(@(x)min1(x),  Cmin, 'Uniform',false);  Min.min  = cat(1,C{:});
C = cellfun(@(x)max1(x),  Cmin, 'Uniform',false);  Min.max  = cat(1,C{:});
C = cellfun(@(x)mean1(x), Cmin, 'Uniform',false);  Min.mean = cat(1,C{:});
C = cellfun(@(x)fun05(x), Cmin, 'Uniform',false);  Min.p05  = cat(1,C{:});
C = cellfun(@(x)fun50(x), Cmin, 'Uniform',false);  Min.p50  = cat(1,C{:});
C = cellfun(@(x)fun95(x), Cmin, 'Uniform',false);  Min.p95  = cat(1,C{:});
% ---
C = cellfun(@(x)min1(x),  Cmax, 'Uniform',false);  Max.min  = cat(1,C{:});
C = cellfun(@(x)max1(x),  Cmax, 'Uniform',false);  Max.max  = cat(1,C{:});
C = cellfun(@(x)mean1(x), Cmax, 'Uniform',false);  Max.mean = cat(1,C{:});
C = cellfun(@(x)fun05(x), Cmax, 'Uniform',false);  Max.p05  = cat(1,C{:});
C = cellfun(@(x)fun50(x), Cmax, 'Uniform',false);  Max.p50  = cat(1,C{:});
C = cellfun(@(x)fun95(x), Cmax, 'Uniform',false);  Max.p95  = cat(1,C{:});
% ---
C = cellfun(@(x)min1(x),  Cmean,'Uniform',false);  Mean.min  = cat(1,C{:});
C = cellfun(@(x)max1(x),  Cmean,'Uniform',false);  Mean.max  = cat(1,C{:});
C = cellfun(@(x)mean1(x), Cmean,'Uniform',false);  Mean.mean = cat(1,C{:});
C = cellfun(@(x)fun05(x), Cmean,'Uniform',false);  Mean.p05  = cat(1,C{:});
C = cellfun(@(x)fun50(x), Cmean,'Uniform',false);  Mean.p50  = cat(1,C{:});
C = cellfun(@(x)fun95(x), Cmean,'Uniform',false);  Mean.p95  = cat(1,C{:});



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
