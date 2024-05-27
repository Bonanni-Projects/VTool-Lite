function [Data1,DataC,DataX] = NanFillDataset(Data,varargin)

% NANFILLDATASET - Regularize time and fill sampling holes in a dataset.
% Data1 = NanFillDataset(Data)
% Data1 = NanFillDataset(Data,Ts,Trange)
% Data1 = NanFillDataset(Data,Trange)
% Data1 = NanFillDataset(Data,Ts)
% [Data1,DataC,DataX] = NanFillDataset(...)
%
% Performs time-grid regularization and nan-filling on a dataset to repair 
% irregularly placed and/or missing time samples. Determines the dominant 
% sample time, or explicit sample time 'Ts' if provided, to define a regular 
% time grid starting from the dataset's initial time value and spanning the 
% represented time range. It then removes samples deviating from the grid and 
% fills missing sample positions with NaN values. The result is dataset 'Data1' 
% with uniform time sampling. Input 'Trange' is a 1x2 vector specifying an 
% alternate time range in compatible time units, used to override the dataset's 
% original time range if desired. 
%
% Also returned are dataset 'DataC', representing a "cleaned-up" dataset after 
% removal of irregularly placed and out-of-range samples but before nan-filling, 
% and dataset 'DataX', containing only the errant samples. 
%
% The input dataset's time vector must be strictly monotonically increasing. 
% For best results, all time values should be evenly divisible by the dominant 
% or specified sample time after subtraction of the initial time offset. For 
% datasets with absolute time units, appropriate rounding is recommended: as 
% an example, time values in a vector 't' can be rounded to whole-number 
% seconds using "dateshift(t,'start','sec','nearest')", and rounding to 
% minutes, hours, or other units follows similarly. 
%
% P.G. Bonanni
% 8/9/23

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


args = varargin;  % initialize
if length(args)>2
  error('Invalid usage.')
elseif length(args)==2
  Ts     = args{1};
  Trange = args{2};
elseif length(args)==1
  Ts = args{1};
  if numel(Ts)<2
    Trange = [];
  elseif numel(Ts)==2 && size(Ts,1)==1
    Trange = Ts;
    Ts = [];
  end
elseif isempty(args)
  Ts     = [];
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

% Check time vector
if any(diff(Data.Time.Values) < 0)
  error('Time vector is invalid: reversals detected.')
elseif any(diff(Data.Time.Values) == 0)
  error('Time vector is invalid: repeated time points detected.')
end

% Default time range
if isnumeric(Trange) && isempty(Trange)
  ti = Data.Time.Values(1);
  tf = Data.Time.Values(end);
  Trange = [ti,tf];
end

% Check 'Ts'
if ~isnumeric(Ts) || numel(Ts)>1
  error('Specified ''Ts'' is invalid.')
end

% Check 'Trange' argument
if ~isrow(Trange) || numel(Trange)~=2 || Trange(2)<=Trange(1)
  error('Invalid ''Trange'' parameter.')
elseif ~strcmp(class(Data.Time.Values),class(Trange))
  error('Specified ''Trange'' is invalid or of incompatible type.')
end

% Limit time range as necessary
Data = LimitTimeRange(Data,Trange);

% If 'Ts' not provided
if isempty(Ts)
  % Determine dominant sampling time
  if isdatetime(Data.Time.Values)
    Ts = round(GetSampleTime(Data,'mode'));
  else  % if real-valued time vector
    Ts = GetSampleTime(Data,'mode');
  end
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

% Compute sampling mask and perform clean-up
maskT = false(size(t));
[mask,i] = ismember(Data.Time.Values,t);
nbad = sum(~mask);  % number of unmatched samples
if nbad > 0  % report any sampling errors
  fprintf('Clean-up found %d of %d points deviate from the defined sampling schedule.\n',nbad,N);
end
DataC = ApplyIndex(Data, mask);
DataX = ApplyIndex(Data,~mask);
maskT(i(mask)) = true;

% Initialize
Data1 = DataC;

% List of signal groups, excluding 'Time'
[~,groups] = GetSignalGroups(Data1);
groups = setdiff(groups,'Time');

% Loop over groups
for k = 1:length(groups)
  group = groups{k};

  % Get number of signals
  nsignals = GetNumSignals(Data1.(group));

  % Perform NaN-filling operation
  Values = Data1.(group).Values;
  Data1.(group).Values = nan(length(t),nsignals);
  Data1.(group).Values(maskT,:) = Values;
end

% Assign new time vector
Data1.Time.Values = t;
