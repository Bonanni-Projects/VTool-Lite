function [Stats,f,PSD,Cpsd] = ComputePsdByBin(SIGNALS,iclass,Ts,option)

% COMPUTEPSDBYBIN - Compute PSD spectra by bin.
% [Stats,f,PSD] = ComputePsdByBin(SIGNALS,iclass,Ts)
% [Stats,f,PSD] = ComputePsdByBin(SIGNALS,iclass,Ts,'dB')
% [Stats,f,PSD,Cpsd] = ComputePsdByBin(...)
%
% Computes statistical PSD spectra for signals in a signal-group 
% array according to a binning scheme.  Input 'SIGNALS' is a 
% length-N array of homogeneous signal groups of M signals each.  
% Input 'iclass' is a length-N vector of bin index values ranging 
% from 0 to P, with 0 indicating array elements to be excluded 
% from the analysis.  Input 'Ts' is the sample time, in sec. 
%
% Output 'Stats' is a structure giving statistically representative 
% PSD spectra of the individual signal channels, segregated by bin.  
% Output 'f' is the corresponding frequency vector.  Structure 'Stats' 
% has the following fields, each a length(f) x M x P numerical array: 
%   'min'   -  point-wise minimum PSD by bin
%   'max'   -  point-wise maximum PSD by bin
%   'mean'  -  point-wise mean PSD by bin
%   'p05'   -  point-wise 5th-percentile PSD by bin
%   'p50'   -  point-wise 50th-percentile (median) PSD by bin
%   'p95'   -  point-wise 95th-percentile PSD by bin
%
% Output 'PSD' gives the complete set of raw PSD spectra, in the 
% form of a signal group array corresponding to 'SIGNALS'. 
%
% To support computation of additional statistics not listed above, 
% cell array 'Cpsd' is available as an optional output.  Each cell 
% of 'Cpsd' contains a 3d array of length(f) rows and M columns, 
% with the sample PSDs distributed in the third dimension.  The 
% cells of 'Cpsd' represent the raw PSD spectra from the M signals 
% segregated by bin. Thus, for example, a standard deviation ('std') 
% field with default normalization can be added as follows: 
%   C = cellfun(@(x)std(x,0,3),Cpsd,'Uniform',false);
%   Stats.std = cat(3,C{:});
%
% The default units for all spectra, both in 'Stats' and 'PSD', 
% are in (.)^2/Hz.  However, if 'dB' is specified as a final 
% argument, 'Stats' and 'PSD' (but not the raw data in 'Cpsd') 
% are converted to dB before being returned. 
%
% See also "ComputeErrPsdByBin" and "ComputeRelPsdByBin". 
%
% P.G. Bonanni
% 8/12/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 4
  option = '';
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
if numel(SIGNALS) > 1 && ~isequal(Lengths{:})
  error('Input array must be data-length uniform.')
end

% Check 'iclass' input
if ~isnumeric(iclass) || ~isvector(iclass) || ~all(rem(iclass,1)==0) || ...
    any(iclass < 0) || length(iclass)~=length(SIGNALS)
  error('Invalid ''iclass'' input.')
end

% Check 'Ts' input
if ~isnumeric(Ts) || ~isscalar(Ts) || Ts < 0
  error('Invalid ''Ts'' input.')
end

% Array length
N = length(SIGNALS);

% Number of bins
P = max(iclass);

% Compute raw PSDs
[PSD,f] = SpectSignals(SIGNALS,Ts);

% Convert to 3d array
RAW = cat(3,PSD.Values);

% Percentile functions
fun05 = @(x)prctile(x, 5,3);
fun50 = @(x)prctile(x,50,3);
fun95 = @(x)prctile(x,95,3);

% Classify into bins
Cpsd = cell(P,1);  % initialize
for k = 1:P
  mask = iclass==k;
  Cpsd{k} = RAW(:,:,mask);
end

% Compute dimension-3 statistics by bin
C = cellfun(@(x)min3(x),  Cpsd, 'Uniform',false);  Stats.min  = cat(3,C{:});
C = cellfun(@(x)max3(x),  Cpsd, 'Uniform',false);  Stats.max  = cat(3,C{:});
C = cellfun(@(x)mean3(x), Cpsd, 'Uniform',false);  Stats.mean = cat(3,C{:});
C = cellfun(@(x)fun05(x), Cpsd, 'Uniform',false);  Stats.p05  = cat(3,C{:});
C = cellfun(@(x)fun50(x), Cpsd, 'Uniform',false);  Stats.p50  = cat(3,C{:});
C = cellfun(@(x)fun95(x), Cpsd, 'Uniform',false);  Stats.p95  = cat(3,C{:});

% Convert to dB, if specified
if strcmpi(option,'dB')
  Stats = structfun(@(x)10*log10(x),Stats,'Uniform',false);
  PSD = ConvertSignalsToDB(PSD,'power');
end



% ---------------------------------------------------------
% MIN3 - Return dimension-3 minima, and NaNs if empty.
function x = min3(X)

[m,n,p] = size(X);
if p == 0
  x = nan(m,n);
elseif p == 1
  x = X;
else
  x = min(X,[],3);
end


% ---------------------------------------------------------
% MAX3 - Return dimension-3 maxima, and NaNs if empty.
function x = max3(X)

[m,n,p] = size(X);
if p == 0
  x = nan(m,n);
elseif p == 1
  x = X;
else
  x = max(X,[],3);
end


% --------------------------------------------------------------------------
% MEAN3 - Return dimension-3 means, and NaNs if empty.
function x = mean3(X)

[m,n,p] = size(X);
if p == 0
  x = nan(m,n);
elseif p == 1
  x = X;
else
  x = mean(X,3,'omitnan');
end
