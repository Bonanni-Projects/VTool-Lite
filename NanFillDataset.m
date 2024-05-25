function Data = NanFillDataset(Data,varargin)

% NANFILLDATASET - Fill sampling holes in a dataset.
% Data1 = NanFillDataset(Data)
% Data1 = NanFillDataset(Data,Ts,Trange)
% Data1 = NanFillDataset(Data,Trange)
% Data1 = NanFillDataset(Data,Ts)
%
% Performs time-grid regularization and nan-filling on a dataset to 
% repair irregularly placed and/or missing time samples. Determines 
% the dominant sample time, or explicit sample time 'Ts' if provided, 
% then removes samples deviating from the grid and fills missing samples 
% with NaN values. The result is a dataset with uniform time sampling. 
% Optional 'Trange' is a 1x2 vector specifying the desired time range 
% in compatible time units, defaulting to the original dataset time 
% range if not provided. 
%
% Note: For best results, all time values should be evenly divisible 
% by the dominant or specified sample time. On datasets with absolute 
% time units, time values in a vector 't' can be rounded to whole-number 
% seconds using "dateshift(t,'start','sec','nearest')", and rounding to 
% minutes, hours, etc. follows similarly. 
%
% P.G. Bonanni
% 8/9/23

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


args = varargin;  % initialize
if length(args)>2
  error('Invalid usage.')
elseif length(args)==1
  Ts = args{1};
  if numel(Ts)<2
    Trange = [];
  elseif numel(Ts)==2 && size(Ts,1)==1
    Trange = Ts;
    Ts = [];
  end
elseif length(args)==2
  Ts     = args{1};
  Trange = args{2};
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
