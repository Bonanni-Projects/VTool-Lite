function [SIGNALS,Signalsf] = BufferSignalGroup(Signals,N)

% BUFFERSIGNALGROUP - Buffer a signal group into a signal group array.
% SIGNALS = BufferSignalGroup(Signals,N)
% [SIGNALS,Signalsf] = BufferSignalGroup(...)
%
% Buffers the data from input signal group 'Signals' into 
% non-overlapping segments of data length 'N'.  Each data segment 
% occupies one element of output signal group array 'SIGNALS'.  
% Optional output 'Signalf' is a signal group containing the 
% remaining data that results if the data length of the original 
% signal group is not an integer multiple of N.  
%
% See also "ConcatSignalGroups", "BufferDataset". 
%
% P.G. Bonanni
% 9/19/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'Signals' input
[flag,valid,errmsg] = IsSignalGroup(Signals);
if ~flag
  error('Input #1 is not a signal group: %s',errmsg)
elseif ~valid
  error('Input #1 is not a valid signal group: %s  See "IsSignalGroup".',errmsg)
end

% Get input data dimensions
[npoints,nsignals] = size(Signals.Values);

% Check remaining input
if ~isnumeric(N) || ~isscalar(N)
  error('Input ''N'' must be numeric and scalar.')
elseif rem(N,1) ~= 0 || N < 1
  error('Input ''N'' must be a positive integer.')
elseif N > npoints
  error('Input ''N'' cannot exceed the input data length.')
end

% Number of segments
nsegs = floor(npoints/N);

% Initialize outputs
SIGNALS = Signals;
SIGNALS.Values = [];
SIGNALS = repmat(SIGNALS,nsegs,1);
Signalsf = SIGNALS(1);

% Get 'Values' array
Values = Signals.Values;

% Remove leftover data, and assign to 'Signalsf'
index = (nsegs*N+1):npoints;
Signalsf.Values = Values(index,:);
Values(index,:) = [];

% Separate 'Values' into segments, and populate output array
VALUES = reshape(Values,[N,nsegs,nsignals]);
VALUES = permute(VALUES,[1,3,2]);
C = num2cell(VALUES,[1,2]);
[SIGNALS.Values] = deal(C{:});
