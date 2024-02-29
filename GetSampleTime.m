function [Ts,TSrange] = GetSampleTime(obj,option)

% GETSAMPLETIME - Get sample time from a dataset or a Time group.
% Ts = GetSampleTime(Data)
% Ts = GetSampleTime(Time)
% Ts = GetSampleTime(...,method)
% [Ts,TSrange] = GetSampleTime(...)
%
% Computes the sample time employed in dataset 'Data' or time 
% group 'Time', using one of the following methods: 
%  'simple'  -  time difference between first two samples (default), 
%  'mean'    -  mean time difference between samples, 
%  'median'  -  median time difference between samples, 
%  'mode'    -  most frequently occurring time difference. 
%
% Accepts datasets with any time type, i.e., 'datetime', 
% 'datenum', or real-valued.  Sample time 'Ts' is returned 
% in seconds, or in the units of the real-valued time vector.  
% If no method is specified, the 'simple' option is used. 
% Optional second output 'TSrange' is a 2-vector giving the 
% sample time [min,max] range. 
%
% See also "DisplaySampleTime". 
%
% P.G. Bonanni
% 8/28/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  option = 'simple';
end

% Check input
if numel(obj) > 1
  error('Works for scalar datasets or time groups only.')
end
[flag1,valid1] = IsDataset(obj);
[flag2,valid2] = IsSignalGroup(obj,'Time');
if (~flag1 || ~valid1) && (~flag2 || ~valid2)
  error('Input must be a valid dataset or Time signal group.  See "IsDataset" and "IsSignalGroup".')
end

% Determine if Matlab version is from 2014 or later
if datenum(version('-date')) > datenum('1-Jun-2014')
  laterVersion = true;
else  % if version is older
  laterVersion = false;
end

% Get time vector
if IsDataset(obj)
  Data = obj;
  t = Data.Time.Values;
else
  Time = obj;
  t = Time.Values;
end

% Special case
if length(t) < 2
  Ts      = NaN;
  TSrange = [NaN,NaN];
  return
end

% Compute time-difference vector
if laterVersion && isdatetime(t)     % if 'datetime' type
  dt = diff(t);  dt=seconds(dt);
elseif isnumeric(t) && min(t) > 1e5  % assume 'datenum' type
  dt = diff(t)*86400;  % sec
elseif isnumeric(t)                  % real type
  dt = diff(t);
else
  error('Time vector has invalid type.')
end

% Compute sample time
switch option
  case 'simple', Ts = dt(1);
  case 'mean',   Ts = mean(dt);
  case 'median', Ts = median(dt);
  case 'mode',   Ts = mode(dt);
  otherwise
    error('Invalid method specified.')
end

% Sample time range
TSrange = [min(dt),max(dt)];

% Warn if 'simple' method and sample time varies or is not monotonic ...
if nargout < 2  % ... but suppress message if 'TSrange' argument is supplied
  if strcmp(option,'simple') && diff(TSrange)/min(dt) > 1e-6
    maxTSvariation = max(abs([min(dt)-Ts,max(dt)-Ts]/Ts));  % worst-case fractional variation
    fprintf('Warning: Sample time not constant.  Max variation %.2g %%.\n', 100*maxTSvariation);
  end
  if strcmp(option,'simple') && any(dt <= 0)
    fprintf('Warning: Sampling is not monotonic.\n')
  end
end
