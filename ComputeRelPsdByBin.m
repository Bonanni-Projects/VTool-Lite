function [Stats,f,PSD,Cpsd] = ComputeRelPsdByBin(SIGNALS,SIGNALS0,iclass,Ts,option)

% COMPUTERELPSDBYBIN - Compute relative PSD spectra by bin.
% [Stats,f,PSD] = ComputeRelPsdByBin(SIGNALS,SIGNALS0,iclass,Ts)
% [Stats,f,PSD] = ComputeRelPsdByBin(SIGNALS,SIGNALS0,iclass,Ts,'dB')
% [Stats,f,PSD,Cpsd] = ComputeRelPsdByBin(...)
%
% Computes "relative PSD" spectra for signals in one signal-group 
% array ('SIGNALS') with respect to another ('SIGNALS0'), according 
% to a binning scheme.  Inputs 'SIGNALS' and 'SIGNALS0' are matching 
% length-N arrays.  Both are homogeneous signal groups of M signals 
% each.  Input 'iclass' is a length-N vector of bin index values 
% ranging from 0 to P, with 0 indicating array elements to be 
% excluded from the analysis.  Input 'Ts' is the sample time, in 
% sec. 
%
% THE "RELATIVE PSD" SPECTRUM OF SIGNAL X WITH RESPECT TO X0 IS 
% DEFINED AS THE QUOTIENT PSD(X)/PSD(X0). 
%
% Output 'Stats' is a structure giving the representative relative PSD 
% spectra of the individual signal channels, segregated by bin. Output 
% 'f' is the corresponding frequency vector.  Structure 'Stats' has 
% the following fields, each a length(f) x M x P numerical array: 
%   'min'   -  point-wise minimum relative-PSD by bin
%   'max'   -  point-wise maximum relative-PSD by bin
%   'mean'  -  point-wise mean relative-PSD by bin
%   'p05'   -  point-wise 5th-percentile relative-PSD by bin
%   'p50'   -  point-wise 50th-percentile (median) relative-PSD by bin
%   'p95'   -  point-wise 95th-percentile relative-PSD by bin
%
% Output 'PSD' gives the complete set of raw relative spectra, in 
% the form of a signal group array corresponding to 'SIGNALS0' and 
% 'SIGNALS'. 
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
% See also "ComputePsdByBin" and "ComputeErrPsdByBin". 
%
% P.G. Bonanni
% 8/12/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 5
  option = '';
end

% Check 'SIGNALS' and 'SIGNALS0' inputs
[flag1,valid1,errmsg1] = IsSignalGroupArray(SIGNALS);
[flag2,valid2,errmsg2] = IsSignalGroupArray(SIGNALS0);
if ~flag1
  error('Input ''SIGNALS'' is not a signal group array: %s',errmsg)
elseif ~valid1
  error('Input ''SIGNALS'' is not a valid signal group array: %s  See "IsSignalGroupArray".',errmsg1)
elseif ~flag2
  error('Input ''SIGNALS0'' is not a signal group array: %s',errmsg)
elseif ~valid2
  error('Input ''SIGNALS0'' is not a valid signal group array: %s  See "IsSignalGroupArray".',errmsg2)
elseif ~isvector(SIGNALS) || ~isvector(SIGNALS0)
  error('Multidimensional ''SIGNALS'' arrays not permitted.')
elseif length(SIGNALS) ~= length(SIGNALS0)
  error('Input arrays must have the same length.')
end

% Check for data-length uniformity
Len  = arrayfun(@(x)size(x.Values,1),SIGNALS,'Uniform',false);
Len0 = arrayfun(@(x)size(x.Values,1),SIGNALS0,'Uniform',false);
Lengths = [Len(:); Len0(:)];
if numel(SIGNALS) > 1 && (~isequal(Len{:}) || ~isequal(Len0{:}))
  error('Input arrays must be data-length uniform.')
elseif ~isequal(Lengths{:})
  error('Input array data lengths do not match.')
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
N = numel(SIGNALS);

% Number of bins
P = max(iclass);

% Compute raw relative-PSD spectra
[PSD, f] = SpectSignals(SIGNALS,Ts);
[PSD0,~] = SpectSignals(SIGNALS0,Ts);
for k = 1:N
  PSD(k).Values = PSD(k).Values ./ PSD0(k).Values;
end

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
