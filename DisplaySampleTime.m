function DisplaySampleTime(obj)

% DISPLAYSAMPLETIME - Display sample time statistics.
% DisplaySampleTime(Data)
% DisplaySampleTime(Time)
% DisplaySampleTime(t)
%
% Computes sample time and time range statistics, and prints 
% results to the screen.  The sample time is taken to be the 
% most frequently occurring time-difference value.  Accepts a 
% dataset ('Data'), a 'Time' signal group, or a time vector 't' 
% as input.  Works for real-valued, date-number, and 'datetime' 
% time data. 
%
% See also "GetSampleTime". 
%
% P.G. Bonanni
% 4/11/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Determine if Matlab version is from 2014 or later
if datenum(version('-date')) > datenum('1-Jun-2014')
  laterVersion = true;
else  % if version is older
  laterVersion = false;
end

% Check input
if isnumeric(obj)
  t = obj;
  units = 'sec';
elseif laterVersion && isdatetime(obj)
  t = obj;
  units = 'datetime';
elseif IsDataset(obj)
  Data = obj;
  t = Data.Time.Values;
  units = Data.Time.Units{1};
elseif IsSignalGroup(obj)
  Time = obj;
  t = Time.Values;
  units = Time.Units{1};
else
  error('Invalid input type.')
end
if isempty(units)
  units = '(none)';
end

% Special case
if isscalar(t)
  fprintf('Data length:       '); disp(1)
  fprintf('Time range:        '); disp([t,t])
  fprintf('Units: %s\n',units);
  fprintf('(sampling not defined)\n');
  return
end

% Ensure that 't' is a vector
if isempty(t)
  fprintf('Time vector is empty.\n')
  return
elseif ~isvector(t)
  error('Time data ''t'' is not a vector.')
end

% Compute sample-time statistics
if laterVersion && isdatetime(t)     % if 'datetime' type
  dt = diff(t);  dt=duration(dt,'Format','s');
  Ts = mode(dt);
  N = length(t);
  Trange = [min(t),max(t)];
  TSrange = [min(dt),max(dt)];
  TSvariation = diff(TSrange)/mean(TSrange);
elseif isnumeric(t) && min(t) > 1e5  % assume 'datenum' type
  dt = diff(t)*86400;  % sec
  Ts = mode(dt);
  N = length(t);
  Trange = [min(t),max(t)];
  Trange = datestr(double(Trange));
  Trange = cellstr(Trange)';
  TSrange = [min(dt),max(dt)];
  TSvariation = diff(TSrange)/mean(TSrange);
  fprintf('Time in sec ...\n');
elseif isnumeric(t)                  % real type
  dt = diff(t);
  Ts = mode(dt);
  N = length(t);
  Trange = [min(t),max(t)];
  TSrange = [min(dt),max(dt)];
  TSvariation = diff(TSrange)/mean(TSrange);
else
  error('Time vector has invalid type.')
end

% Print statistics
if TSrange(2) == TSrange(1)
  fprintf('Data length:       '); disp(N)
  fprintf('Sample time:       '); disp(Ts)
  fprintf('Sample time range:   *** CONSTANT ***\n');
  fprintf('Time range:        '); disp(Trange)
  fprintf('Units: %s\n',units);
elseif TSvariation < 0.5e-4
  fprintf('Data length:       '); disp(N)
  fprintf('Sample time:       '); disp(Ts)
  fprintf('Percent variation:    +/- %.2e\n', 100*TSvariation/2);
  fprintf('Time range:        '); disp(Trange)
  fprintf('Units: %s\n',units);
else
  fprintf('Data length:       '); disp(N)
  fprintf('Sample time:       '); disp(Ts)
  fprintf('Sample time range: '); disp(TSrange)
  fprintf('Time range:        '); disp(Trange)
  fprintf('Units: %s\n',units);
end

% Warn if 't' is not monotonic
if ~all(diff(t) >= 0)
  fprintf('\n');
  fprintf('Warning: Time vector ''t'' is not monotically increasing.\n');
end
