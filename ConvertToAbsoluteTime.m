function Data = ConvertToAbsoluteTime(Data,start)

% CONVERTTOABSOLUTETIME - Convert to absolute time.
% Data = ConvertToAbsoluteTime(Data,start)
% Data = ConvertToAbsoluteTime(Data)
%
% Converts the time signal in 'Data' to absolute time, in 
% 'datetime' format.  Datasets with real-valued time units of 
% 'sec', 'min', 'hrs', or 'days' are recognized.  Input 'start' 
% specifies the absolute start time in 'datetime', 'datenum', 
% or any valid date string format.  The 'start' input may be 
% omitted if a 'start' field is present on the dataset. 
%
% P.G. Bonanni
% 2/28/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  start = '';
end

% Check 'Data' argument
if numel(Data) > 1
  error('Works for scalar datasets only.')
end
[flag,valid] = IsDataset(Data);
if ~flag || ~valid
  error('Input ''Data'' is not a valid dataset.  See "IsDataset".')
end

% Get 'start' time
if isempty(start) && isfield(Data,'start')
  start = Data.start;
elseif isempty(start)
  error('A ''start'' time must be specified.')
end

% Check 'start' for validity
if isnumeric(start) && start < 1e5
  error('Input ''start'' is not valid.');
end
try  % to convert any format to 'datetime'
  start = datetime(datestr(start));
catch
  error('Input ''start'' is not valid.')
end

% Extract time signal
Time = Data.Time;

% Perform conversion according to current time units
if strcmp(Time.Units{1},'datetime')
  error('Dataset already in absolute time units.')
elseif strcmp(Time.Units{1},'datenum')
  error('Dataset already in absolute time units.')
elseif strcmp(Time.Units{1},'')
  error('Dataset time vector is unitless.')
elseif strcmp(Time.Units{1},'sec')
  Time.Values = start + seconds(Time.Values);
  Time.Units = {'datetime'};
elseif strcmp(Time.Units{1},'min')
  Time.Values = start + minutes(Time.Values);
  Time.Units = {'datetime'};
elseif strcmp(Time.Units{1},'hrs')
  Time.Values = start + hours(Time.Values);
  Time.Units = {'datetime'};
elseif strcmp(Time.Units{1},'days')
  Time.Values = start + days(Time.Values);
  Time.Units = {'datetime'};
else
  error('Dataset has unrecognized time units.')
end

% Apply the new 'Time'
Data.Time = Time;
