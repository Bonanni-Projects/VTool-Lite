function [Data,start] = ConvertToElapsedTime(Data,option)

% CONVERTTOELAPSEDTIME - Convert to elapsed time.
% Data = ConvertToElapsedTime(Data)
% Data = ConvertToElapsedTime(Data,'real')
% Data = ConvertToElapsedTime(Data,'continuous')
% [Data,start] = ConvertToElapsedTime(...)
%
% Converts the time signal in 'Data' to elapsed time, 
% in seconds.  The 'Time' signal in the supplied dataset 
% may have any units (e.g., elapsed time, absolute time 
% in date numbers, or, if the Matlab version supports it, 
% absolute time in 'datetime' values). 
%
% Two options are available: 
%   'real'        -  computes time as an offset in seconds 
%                    from start of the dataset, preserving 
%                    any real gaps in the existing absolute 
%                    time vector.  This is the default if 
%                    no option is specified. 
%   'continuous'  -  computes sample time based on the first 
%                    two time samples, and builds a continuous 
%                    time vector starting from zero assuming 
%                    uniform sampling throughout. 
%
% Also returns the original start time as output variable 
% 'start'. 
%
% P.G. Bonanni
% 3/6/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  option = '';
end

% Check 'Data' argument
if numel(Data) > 1
  error('Works for scalar datasets only.')
end
[flag,valid] = IsDataset(Data);
if ~flag || ~valid
  error('Input ''Data'' is not a valid dataset.  See "IsDataset".')
end

% Default option
if isempty(option)
  option = 'real';
end

% Extract time signal
Time = Data.Time;

% Record start time
start = Time.Values(1);

% If 'datetime' or 'datenum', convert to sec
% (also, if units = '', do nothing)
if strcmp(Time.Units{1},'datetime')
  Time.Values = seconds(Time.Values-Time.Values(1));
  Time.Units = {'sec'};
elseif strcmp(Time.Units{1},'datenum')
  Time.Values = 86400*(Time.Values-Time.Values(1));
  Time.Units = {'sec'};
end

% If 'continuous' option selected ...
if strcmp(option,'continuous')
  Ts = Time.Values(2) - Time.Values(1);
  n = length(Time.Values);
  Time.Values = Ts * (0:n-1)';
end

% Apply the new 'Time'
Data.Time = Time;
