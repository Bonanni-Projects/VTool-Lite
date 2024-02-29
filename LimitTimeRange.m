function Data = LimitTimeRange(Data,Trange)

% LIMITTIMERANGE - Limit time range of a dataset.
% Data = LimitTimeRange(Data,Trange)
%
% Returns input dataset 'Data' with the time range of signals 
% in all groups reduced according to Trange=[Tmin,Tmax], and 
% without re-zeroing.  Values for 'Trange' are interpreted in 
% the time units of the supplied dataset (e.g., elapsed time, 
% absolute time in date numbers, or, if the Matlab version 
% supports it, absolute time in 'datetime' values).  However, 
% if values in 'Trange' are  real-valued and small (i.e., < 1e5), 
% they are always interpreted as elapsed seconds from start of 
% the dataset.  If 'Trange' is empty or omitted, the full time 
% range is returned. 
%
% Note: To limit the time range with re-zeroing, and/or 
% use different sampling, see function "ResampleDataset". 
%
% P.G. Bonanni
% 3/6/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Determine if Matlab version is from 2014 or later
if datenum(version('-date')) > datenum('1-Jun-2014')
  laterVersion = true;
else  % if version is older
  laterVersion = false;
end

% Check 'Data' argument
if numel(Data) > 1
  error('Works for scalar datasets only.')
end
[flag,valid] = IsDataset(Data);
if ~flag || ~valid
  error('Input ''Data'' is not a valid dataset.  See "IsDataset".')
end

% Extract time signal
Time = Data.Time;

% Check 'Trange' argument
if (~isnumeric(Trange) && ~(laterVersion && isdatetime(Trange))) || ...
   ~(numel(Trange)==2 || isempty(Trange)) || ...
    (numel(Trange)==2 && Trange(2) < Trange(1))
  error('Invalid ''Trange'' argument.')
elseif isnumeric(Trange) && any(isinf(Trange)) && any(strcmp(Time.Units{1},{'datetime','datenum'}))
  error('''Trange'' cannot be real and infinite with ''datetime'' or ''datenum'' datasets.')
end

% Return immediately if Trange=[]
if isempty(Trange), return, end

% Express 'Trange' in units compatible with 'Time'
if isempty(Trange), Trange=[Time.Values(1),Time.Values(end)]; end  % default
if strcmp(Time.Units{1},'datetime')
  if isnumeric(Trange) && all(Trange > 1e5)  % interpret 'Trange' as date numbers
    Trange = datetime(Trange,'ConvertFrom','datenum');
  elseif isnumeric(Trange)  % interpret 'Trange' as elapsed seconds
    dTime = Time.Values - Time.Values(1);
    Trange = interp1(dTime, Time.Values, seconds(Trange));
  end
elseif strcmp(Time.Units{1},'datenum')
  if laterVersion && isdatetime(Trange)      % if 'Trange' is 'datetime' type
    Trange = datenum(Trange);  % convert
  elseif isnumeric(Trange) && all(Trange < 1e5)  % interpret 'Trange' as elapsed seconds
    dTime = 86400*(Time.Values - Time.Values(1));
    Trange = interp1(dTime, Time.Values, Trange);
  end
else  % if any(strcmp(Time.Units{1},{'','sec',...})) (real-valued time units)
  if (laterVersion && isdatetime(Trange)) || ...  % if 'Trange' is 'datetime' type
     (isnumeric(Trange) && all(Trange > 1e5))     % ... or large enough to be 'datenum' type
    error('Time vector has elapsed-time units.  Input ''Trange'' not compatible.') 
  end
end

% Identify signal-group fields
[~,fields] = GetSignalGroups(Data);

% Mask for desired time range
mask = Time.Values >= Trange(1) & Time.Values <= Trange(2);
for k = 1:length(fields)
  field = fields{k};
  Data.(field).Values = Data.(field).Values(mask,:);
end
