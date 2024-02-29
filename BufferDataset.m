function [DATA,Dataf] = BufferDataset(Data,N)

% BUFFERDATASET - Buffer a dataset into a dataset array.
% DATA = BufferDataset(Data,N)
% [DATA,Dataf] = BufferDataset(...)
%
% Buffers the data from all signal groups within input dataset 
% 'Data' into non-overlapping segments of data length 'N'.  The 
% resulting data segments occupy one element of output dataset 
% array 'DATA'.  All non-signal group fields of 'Data' are 
% replicated to each element of the output array.  Optional 
% output 'Dataf' is a dataset containing the remaining data that 
% results if the data length of the original dataset is not an 
% integer multiple of N.  
%
% See also "ConcatDatasets", "BufferSignalGroup".  
%
% P.G. Bonanni
% 9/20/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'Data' input
[flag,valid,errmsg] = IsDataset(Data);
if ~flag
  error('Input #1 is not a dataset: %s',errmsg)
elseif ~valid
  error('Input #1 is not a valid dataset: %s  See "IsDataset".',errmsg)
end

% Get input data length
npoints = size(Data.Time.Values,1);

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

% List of signal groups
[~,groups] = GetSignalGroups(Data);

% Initialize outputs
DATA = Data;
for k = 1:length(groups)
  group = groups{k};
  DATA.(group) = [];
end
DATA = repmat(DATA,nsegs,1);
Dataf = DATA(1);

% Buffer the signal groups, and populate output array
for k = 1:length(groups)
  group = groups{k};
  [SIGNALS,Signalsf] = BufferSignalGroup(Data.(group),N);
  C = arrayfun(@(x)x,SIGNALS,'Uniform',false);
  [DATA.(group)] = deal(C{:});
  Dataf.(group) = Signalsf;
end
