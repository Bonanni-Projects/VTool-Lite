function Data = ResampleDataset(Data,varargin)

% RESAMPLEDATASET - Resample a dataset.
% Data = ResampleDataset(Data,TS,Trange)
% Data = ResampleDataset(Data,Trange)
% Data = ResampleDataset(Data,TS)
% Data = ResampleDataset(Data,t)
% Data = ResampleDataset(...,method,extrapval)
%
% Resamples all signal groups in 'Data' on a new time grid.  
% Input 'Trange' is an optional 1x2 vector specifying a desired 
% time range.  Values for 'Trange' are interpreted in the time 
% units of the supplied dataset (e.g., elapsed time, absolute 
% time in date numbers, or, if the Matlab version supports it, 
% absolute time in 'datetime' values).  However, if values in 
% 'Trange' are  real-valued and small (i.e., < 1e5), they are 
% always interpreted as elapsed seconds from start of the dataset.  
% If 'Trange' is empty, an "empty" version of the dataset is 
% returned, i.e., one with data length equal to 0. 
%
% Input 'TS' specifies an optional re-sampling time, implicitly 
% in sec, or explicity if given in 'duration' type.  If empty or 
% omitted, then no re-sampling is performed. 
%
% If Data.Time is in elapsed time units (i.e., not 'datenum' or 
% 'datetime' type), the returned time vector is always adjusted 
% to start again from zero.  To limit the time range of a dataset 
% without re-zeroing, see function "LimitTimeRange", or provide 
% time vector 't' as explained next. 
%
% An alternative to specifying 'TS' and 'Trange' is to provide 
% time vector 't'.  As with 'Trange', time values in 't' are 
% interpreted in the units employed for Data.Time or in elapsed 
% seconds from the start time.  The dataset is resampled directly 
% onto 't' or its converted equivalent.  Data.Time.Values is set 
% to the new time vector, and no further manipulation of the time 
% vector is performed. 
%
% The default interpolation method is 'linear', with no 
% extrapolation beyond the limits of the original time axis. 
% Optional inputs 'method' and 'extrapval' permit specification 
% of alternative method ('spline','nearest','previous',etc.) and 
% extrapolation behavior (e.g., 'extrap' or fixed value), per 
% the Matlab "interp1" function. 
%
% P.G. Bonanni
% 3/6/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


args = varargin;  % initialize
args1 = {};       % initialize
i = find(cellfun(@ischar,args));
if ~isempty(i)
  args1 = args(i:end);
  args  = args(1:i-1);
end
if isempty(args) || length(args)>2
  error('Invalid usage.')
elseif length(args)==1
  TS = args{1};
  if numel(TS)==1
    Trange = [];
  elseif numel(TS)==2 && size(TS,1)==1
    Trange = TS;
    TS = [];
  else
    t = TS(:);
    TS     = [];
    Trange = [];
  end
elseif length(args)==2
  TS     = args{1};
  Trange = args{2};
end

% Determine if Matlab version is from 2014 or later
if datenum(version('-date')) > datenum('1-Jun-2014')
  laterVersion = true;
else  % if version is older
  laterVersion = false;
end

% Check 'TS' and 'Trange' arguments
if ~isempty(TS) && ~isscalar(TS)
  error('Input ''TS'' must be scalar.')
elseif ~isempty(Trange) && ~(numel(Trange)==2 && size(Trange,1)==1) 
  error('Input ''Trange'' must be 1 x 2.')
end

% Check 'Data' argument
if numel(Data) > 1
  error('Works for scalar datasets only.')
end
[flag,valid] = IsDataset(Data);
if ~flag || ~valid
  error('Input ''Data'' is not a valid dataset.  See "IsDataset".')
end

% Identify signal-group fields
[~,fields] = GetSignalGroups(Data);

% Extract time structure
Time = Data.Time;

% Check for monotonicity
if any(diff(Time.Values) <= 0)
  error('Time vector is non-monotonic.  See "RemoveRepeatedPoints".')
end

% If time vector 't' was provided directly ...
if exist('t','var')

  % Express 't' in units compatible with 'Time'
  if strcmp(Time.Units{1},'datetime')
    if ~isempty(t) && (isnumeric(t) && all(t > 1e5))  % interpret 't' as date numbers
      t = datetime(t,'ConvertFrom','datenum');
    elseif isnumeric(t)  % interpret 't' as elapsed seconds
      dTime = Time.Values - Time.Values(1);
      t = interp1(dTime, Time.Values, seconds(t));
    end
  elseif strcmp(Time.Units{1},'datenum')
    if laterVersion && isdatetime(t)      % if 't' is 'datetime' type
      t = datenum(t);  % convert
    elseif isnumeric(t) && all(t < 1e5)  % interpret 't' as elapsed seconds
      dTime = 86400*(Time.Values - Time.Values(1));
      t = interp1(dTime, Time.Values, t);
    end
  else  % if any(strcmp(Time.Units{1},{'','sec',...}))  (real-valued time units)
    if (laterVersion && isdatetime(t)) || ...         % if 't' is 'datetime' type
       ~isempty(t) && (isnumeric(t) && all(t > 1e5))  % ... or large enough to be 'datenum' type
      error('Time vector has elapsed-time units.  Input ''t'' not compatible.') 
    end
  end

  % Resample all groups
  for k = 1:length(fields)
    field = fields{k};
    if ~isempty(Data.(field).Values)
      Data.(field).Values = interp1(Time.Values, Data.(field).Values, t, args1{:});
    else  % special treatment for "empty" signal group
      n = length(t);  class0 = class(Data.(field).Values);
      Data.(field).Values = zeros(n,0,class0);
    end
  end

  % Overwrite time data (to ensure exact equality)
  Data.Time.Values = t;

else  % if 'TS' and 'Trange' provided

  % Check 'TS' argument
  if (~isnumeric(TS) && ~(laterVersion && isduration(TS))) || ...
     ~(isscalar(TS) || isempty(TS)) || ...
      (isscalar(TS) && (laterVersion && isduration(TS) && TS <= seconds(0))) || ...
      (isscalar(TS) && TS <= 0)
    error('Invalid ''TS'' argument.')
  end

  % Check 'Trange' argument
  if (~isnumeric(Trange) && ~(laterVersion && isdatetime(Trange))) || ...
     ~(numel(Trange)==2 || isempty(Trange)) || ...
      (numel(Trange)==2 && Trange(2) < Trange(1))
    error('Invalid ''Trange'' argument.')
  elseif isnumeric(Trange) && any(isinf(Trange)) && any(strcmp(Time.Units{1},{'datetime','datenum'}))
    error('''Trange'' cannot be real and infinite with ''datetime'' or ''datenum'' datasets.')
  end

  % Return immediately if no re-sampling or range modification specified
  if isempty(TS) && isempty(Trange), return, end

  % Express 'TS' in units compatible with 'Time'
  if ~isempty(TS)
    if strcmp(Time.Units{1},'datetime')
      if isnumeric(TS), TS=seconds(TS); end
    else  % if any(strcmp(Time.Units{1},{'','sec','datenum',...}))
      if laterVersion && isduration(TS), TS=seconds(TS); end
    end
  end

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

  % Mask for desired time range
  mask = Time.Values >= Trange(1) & Time.Values <= Trange(2);
  for k = 1:length(fields)
    field = fields{k};
    Data.(field).Values = Data.(field).Values(mask,:);
  end

  % Extract time signal
  Time = Data.Time;

  % Re-zero the time vector
  if ~any(strcmp(Time.Units{1},{'datenum','datetime'}))  % if not absolute time
    Time.Values = Time.Values - Time.Values(1);
    Data.Time = Time;
  end

  % If re-sampling specified ...
  if ~isempty(TS)
    if strcmp(Time.Units{1},'datenum')
      ti = (Time.Values(1):TS/86400:Time.Values(end))';
    else  % if real-valued or 'datetime' type
      ti = (Time.Values(1):TS:Time.Values(end))';
    end
    % Resample all groups
    for k = 1:length(fields)
      field = fields{k};
      if ~isempty(Data.(field).Values)
        Data.(field).Values = interp1(Time.Values, Data.(field).Values, ti, args1{:});
      else  % special treatment for "empty" signal group
        n = length(ti);  class0 = class(Data.(field).Values);
        Data.(field).Values = zeros(n,0,class0);
      end
    end
    % Overwrite time data (to ensure exact equality)
    Data.Time.Values = ti;
  end
end
