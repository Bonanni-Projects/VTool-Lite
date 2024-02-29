function [Stats,f,PSD,Cpsd] = ComputeErrPsdByBin(SIGNALS1,SIGNALS2,iclass,Ts,option)

% COMPUTEERRPSDBYBIN - Compute Error-PSD spectra by bin.
% [Stats,f,PSD] = ComputeErrPsdByBin(SIGNALS1,SIGNALS2,iclass,Ts)
% [Stats,f,PSD] = ComputeErrPsdByBin(SIGNALS1,SIGNALS2,iclass,Ts,'dB')
% [Stats,f,PSD,Cpsd] = ComputeErrPsdByBin(...)
%
% Computes "Error-PSD" spectra for signals in two signal-group 
% arrays according to a binning scheme.  Inputs 'SIGNALS1' and 
% 'SIGNALS2' are matching length-N arrays to be compared.  Both 
% are homogeneous signal groups of M signals each.  Input 'iclass' 
% is a length-N vector of bin index values ranging from 0 to P, 
% with 0 indicating array elements to be excluded from the analysis.  
% Input 'Ts' is the sample time, in sec. 
%
% THE "ERROR-PSD" SPECTRUM OF SIGNALS X1 AND X2 IS DEFINED AS THE 
% PSD OF THE DIFFERENCE SIGNAL X2-X1.
%
% Output 'Stats' is a structure giving the representative Error-PSD 
% spectra of the individual signal channels, segregated by bin. Output 
% 'f' is the corresponding frequency vector.  Structure 'Stats' has 
% the following fields, each a length(f) x M x P numerical array: 
%   'min'   -  point-wise minimum Error-PSD by bin
%   'max'   -  point-wise maximum Error-PSD by bin
%   'mean'  -  point-wise mean Error-PSD by bin
%   'p05'   -  point-wise 5th-percentile Error-PSD by bin
%   'p50'   -  point-wise 50th-percentile (median) Error-PSD by bin
%   'p95'   -  point-wise 95th-percentile Error-PSD by bin
%
% Output 'PSD' gives the complete set of raw Error-PSD spectra, in 
% the form of a signal group array corresponding to 'SIGNALS1' and 
% 'SIGNALS2'. 
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
% See also "ComputePsdByBin" and "ComputeRelPsdByBin". 
%
% P.G. Bonanni
% 8/12/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 5
  option = '';
end

% Check 'SIGNALS1' and 'SIGNALS2' inputs
[flag1,valid1,errmsg1] = IsSignalGroupArray(SIGNALS1);
[flag2,valid2,errmsg2] = IsSignalGroupArray(SIGNALS2);
if ~flag1
  error('Input ''SIGNALS1'' is not a signal group array: %s',errmsg)
elseif ~valid1
  error('Input ''SIGNALS1'' is not a valid signal group array: %s  See "IsSignalGroupArray".',errmsg1)
elseif ~flag2
  error('Input ''SIGNALS2'' is not a signal group array: %s',errmsg)
elseif ~valid2
  error('Input ''SIGNALS2'' is not a valid signal group array: %s  See "IsSignalGroupArray".',errmsg2)
elseif ~isvector(SIGNALS1) || ~isvector(SIGNALS2)
  error('Multidimensional ''SIGNALS'' arrays not permitted.')
elseif length(SIGNALS1) ~= length(SIGNALS2)
  error('Input arrays must have the same length.')
end

% Check for data-length uniformity
Len1 = arrayfun(@(x)size(x.Values,1),SIGNALS1,'Uniform',false);
Len2 = arrayfun(@(x)size(x.Values,1),SIGNALS2,'Uniform',false);
Lengths = [Len1(:); Len2(:)];
if numel(SIGNALS1) > 1 && (~isequal(Len1{:}) || ~isequal(Len2{:}))
  error('Input arrays must be data-length uniform.')
elseif ~isequal(Lengths{:})
  error('Input array data lengths do not match.')
end

% Check 'iclass' input
if ~isnumeric(iclass) || ~isvector(iclass) || ~all(rem(iclass,1)==0) || ...
    any(iclass < 0) || length(iclass)~=length(SIGNALS1)
  error('Invalid ''iclass'' input.')
end

% Check 'Ts' input
if ~isnumeric(Ts) || ~isscalar(Ts) || Ts < 0
  error('Invalid ''Ts'' input.')
end

% Array length
N = numel(SIGNALS1);

% Number of bins
P = max(iclass);

% Compute error array
for k = 1:N  % replace 'SIGNALS1' to conserve memory
  SIGNALS1(k).Values = SIGNALS2(k).Values - SIGNALS1(k).Values;
end

% Compute raw Error-PSD spectra
[PSD,f] = SpectSignals(SIGNALS1,Ts);

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
