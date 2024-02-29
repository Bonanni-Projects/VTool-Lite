function Data = NanFillDataset(Data,Trange)

% NANFILLDATASET - Fill sampling holes in a dataset.
% Data1 = NanFillDataset(Data)
% Data1 = NanFillDataset(Data,Trange)
%
% Performs nan-filling operation on a dataset with missing time 
% samples. Determines the dominant sample time, then fills missing 
% samples with NaN values, resulting in a dataset with uniform time 
% sampling. Optional 'Trange' is a 1x2 vector specifying the desired 
% time range in compatible time units, defaulting to the original 
% dataset time range if not provided. 
%
% Note: For best results, all time values should be evenly divisible 
% by the dominant sample time. On datasets with absolute time units, 
% all time values should have whole-number seconds. 
%
% P.G. Bonanni
% 8/9/23

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  Trange = [];
end

% Check 'Data' argument
if numel(Data) > 1
  error('Works for scalar datasets only.')
end
[flag,valid] = IsDataset(Data);
if ~flag || ~valid
  error('Input ''Data'' is not a valid dataset.  See "IsDataset".')
end

% Default time range
if isempty(Trange)
  ti = Data.Time.Values(1);
  tf = Data.Time.Values(end);
  Trange = [ti,tf];
end

% Check 'Trange' argument
if ~strcmp(class(Data.Time.Values),class(Trange))
  error('Specified ''Trange'' is of incompatible type.')
elseif ~isrow(Trange) || numel(Trange)~=2
  error('Invalid ''Trange'' parameter.')
end

% Limit time range as necessary
Data = LimitTimeRange(Data,Trange);

% Determine dominant sampling time
if isdatetime(Data.Time.Values)
  Ts = round(GetSampleTime(Data,'mode'));
else  % if real-valued time vector
  Ts = GetSampleTime(Data,'mode');
end

% Compute sampling schedule
ti = Trange(1);
tf = Trange(2);
if isdatetime(Data.Time.Values)
  t = (ti:seconds(Ts):tf)';
else
  t = (ti:Ts:tf)';
end

% Get data length
N = GetDataLength(Data);

% Compute sampling mask
maskT = false(size(t));
[mask,i] = ismember(Data.Time.Values,t);
nbad = sum(~mask);  % number of unmatched samples
if nbad > 0  % report any sampling errors
  fprintf('Warning: %d of %d points deviate from the standard sampling schedule.\n',nbad,N);
  Data = ApplyIndex(Data,mask);
  i(~mask) = [];
end
maskT(i) = true;

% List of signal groups, excluding 'Time'
[~,groups] = GetSignalGroups(Data);
groups = setdiff(groups,'Time');

% Loop over groups
for k = 1:length(groups)
  group = groups{k};

  % Get number of signals
  nsignals = GetNumSignals(Data.(group));

  % Perform NaN-filling operation
  Values = Data.(group).Values;
  Data.(group).Values = nan(length(t),nsignals);
  Data.(group).Values(maskT,:) = Values;
end

% Assing new time vector
Data.Time.Values = t;
