function TIMES = BuildTimeArray(SIGNALS,name,Ts,offset,units,description)

% BUILDTIMEARRAY - Build a time signal group array.
% TIMES = BuildTimeArray(SIGNALS,name,Ts,offset,units,description)
% TIMES = BuildTimeArray(SIGNALS,name,Ts,'join',units,description)
% TIMES = BuildTimeArray(SIGNALS,name,Ts,'catenate',units,description)
% TIMES = BuildTimeArray(SIGNALS,name,[t0,Ts],offset,units,description)
% TIMES = BuildTimeArray(SIGNALS,name,t,offset,units,description)
% TIMES = BuildTimeArray(SIGNALS,name,Time,offset,units,description)
%
% Builds time signal group array 'TIMES' corresponding in size 
% to signal group array 'SIGNALS'.  Input string 'name' specifies 
% the time signal name, scalar 'Ts' the sample time, string 'units' 
% the time units, and 'description' the description string to 
% apply to all elements in the array.  For example, the command 
% "TIMES = BuildTimeArray(SIGNALS,'Time',0.5,0,'sec','Time vector')" 
% results in time signals named 'Time' with 0.5-sec sampling and 
% description string 'Time vector' assigned for all elements of 
% 'SIGNALS'.  All name layers in 'SIGNALS' are represented in the 
% result. 
%
% The 'offset' parameter permits "sequencing" of the time groups, 
% by specifies the spacing* between the start times of successive 
% elements.  If keyword 'join' is specified in place of 'offset', 
% the start time of the kth element is set to the end time of the 
% (k-1)th element.  If 'catenate' is specified, successive elements 
% are spaced with one sample time of separation**. 
%
% As an alternative to specifying a scalar sample time value, a 
% 2-vector [t0,Ts] defining start time 't0' and sample time 'Ts', 
% or an appropriately sized time vector ('t' signifying elapsed 
% time or 'Time' designating absolute time), may be specified in 
% place of 'Ts'.  If a full time vector is supplied, data lengths 
% must be compatible and uniform across the 'SIGNALS' array. 
%
% (*) Offset may be specified as a 'duration' value when 
%     time values are of 'datetime' type.  Seconds are 
%     assumed if a real value is supplied. 
% (**) Sample time is determined from "GetSampleTime" using 
%     the 'simple' method option. 
%
% P.G. Bonanni
% 8/28/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'SIGNALS' input
[flag,valid,errmsg] = IsSignalGroupArray(SIGNALS);
if ~flag
  error('Input #1 is not a signal group array: %s',errmsg)
elseif ~valid
  error('Input #1 is not a valid signal group array: %s  See "IsSignalGroupArray".',errmsg)
elseif isempty(SIGNALS)
  error('Input #1 is empty.')
end

% Check 'offset' input
if ~isnumeric(offset) && ~isduration(offset) && ~ischar(offset)
  error('Invalid ''offset'' input.')
elseif isnumeric(offset) && ~isscalar(offset)
  error('Input ''offset'' must be scalar.')
elseif isduration(offset) && ~isscalar(offset)
  error('Input ''offset'' must be scalar.')
elseif ischar(offset) && ~any(strcmp(offset,{'join','catenate'}))
  error('Invalid ''offset'' keyword.')
end

% Check other inputs
if ~ischar(name)
  error('Invalid ''name'' input.')
elseif isscalar(Ts) && ~isnumeric(Ts)
  error('Invalid ''Ts'' input.')
elseif ~isscalar(Ts) && ~(isrow(Ts) && length(Ts)==2) && (length(Ts) ~= size(SIGNALS(1).Values,1))
  error('Invalid ''Ts'', ''[t0,Ts]'', ''t'', or ''Time'' input.')
elseif ~ischar(units)
  error('Invalid ''units'' input.')
elseif ~ischar(description)
  error('Invalid ''description'' input.')
end

% Check compatibility of 'units' with 'Ts'
if isdatetime(Ts) && ~strcmp(units,'datetime')
  error('Units string is incompatible with supplied ''datetime'' vector.')
elseif ~isdatetime(Ts) && strcmp(units,'datetime')
  error('Units string is incompatible with supplied ''Ts'', ''t'', or ''Time'' input.')
end

% Check that data lengths are uniform if vector 't' or 'Time' supplied
nvec = arrayfun(@(x)size(x.Values,1),SIGNALS);
if ~isscalar(Ts) && ~(isrow(Ts) && length(Ts)==2) && ~all(nvec(:) == length(Ts))
  error('Supplied ''t'' or ''Time'' is not compatible with all array elements.')
end

% Initialize the 'TIMES' array with uniform time vectors
fun = @(x)BuildTimeGroup(x,name,Ts,units,description);
TIMES = arrayfun(fun,SIGNALS);

% Check 'offset' compatibility
if isduration(offset) && ~isdatetime(TIMES(1).Values)
  error('Input ''offset'' is not compatible with time data type.')
end

% Interpret 'offset' as duration (in sec) if ''Time'' is 'datetime' type
if isdatetime(TIMES(1).Values) && isnumeric(offset)
  offset = seconds(offset);
end

% Get sample time and set type as necessary
Ts = GetSampleTime(TIMES(1));
if isdatetime(TIMES(1).Values)
  Ts = seconds(Ts);
end

% Compute durations by element, then cumulative offsets
C = arrayfun(@(x)x.Values(end)-x.Values(1),TIMES,'Uniform',false);
Durations = cat(1,C{:});  % because non-Uniform output occurs with 'datetime' type
if ischar(offset) && strcmp(offset,'join')
  Offsets = [0; cumsum(Durations(:))];  Offsets(end)=[];
elseif ischar(offset) && strcmp(offset,'catenate')
  Offsets = [0; cumsum(Durations(:)+Ts)];  Offsets(end)=[];
else  % if isnumeric(offset)
  Offsets = offset*(0:numel(Durations)-1)';
end

% Revise the 'TIMES' array
for k = 2:numel(TIMES)
  TIMES(k).Values = TIMES(k).Values + Offsets(k);
end
