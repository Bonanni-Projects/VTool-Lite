function TIMES = SequenceTime(Time,offset,N)

% SEQUENCETIME - Generate a sequenced time array.
% TIMES = SequenceTime(Time,offset,N)
% TIMES = SequenceTime(Time,'join',N)
% TIMES = SequenceTime(Time,'catenate',N)
%
% Extends time group 'Time' into a time array of length 'N', 
% with the scalar parameter 'offset' specifying the spacing 
% between the start times of successive elements.  If keyword 
% 'join' is specified in place of 'offset', the start time 
% of the kth element is set to the end time of the (k-1)th 
% element.  If 'catenate' is specified, successive elements 
% are spaced with one sample time of separation*. 
%
% Signal group 'Time' may be of any type.  If 'Time' is in 
% 'datetime' type, parameter 'offset' may be specified either 
% in 'duration' type or in real-valued seconds. 
%
% *Sample time is determined from "GetSampleTime" using the 
% 'simple' method option. 
%
% P.G. Bonanni
% 11/15/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'Time' input
if numel(Time) > 1
  error('Requires a scalar Time signal group.')
end
[flag,valid] = IsSignalGroup(Time,'Time');
if (~flag || ~valid)
  error('Input must be a valid Time signal group.  See "IsSignalGroup".')
end

% Check other inputs
if ~isnumeric(offset) && ~isduration(offset) && ~ischar(offset)
  error('Invalid ''offset'' input.')
elseif isnumeric(offset) && ~isscalar(offset)
  error('Input ''offset'' must be scalar.')
elseif isduration(offset) && ~isscalar(offset)
  error('Input ''offset'' must be scalar.')
elseif ischar(offset) && ~any(strcmp(offset,{'join','catenate'}))
  error('Invalid ''offset'' keyword.')
elseif ~isnumeric(N) || ~isscalar(N) || rem(N,1)~=0 || N<1
  error('Invalid ''N'' parameter.')
end

% Check 'offset' compatibility
if isduration(offset) && ~isdatetime(Time.Values)
  error('Input ''offset'' is not compatible with ''Time'' data type.')
end

% Interpret 'offset' as duration (in sec) if ''Time'' is 'datetime' type
if isdatetime(Time.Values) && isnumeric(offset)
  offset = seconds(offset);
end

% Get sample time and set type as necessary
Ts = GetSampleTime(Time);
if isdatetime(Time.Values)
  Ts = seconds(Ts);
end

% If an offset 'keyword' was supplied
if     ischar(offset) && strcmp(offset,'join'),     offset = Time.Values(end)-Time.Values(1);
elseif ischar(offset) && strcmp(offset,'catenate'), offset = Time.Values(end)-Time.Values(1)+Ts;
end

% Build 'TIMES' array
TIMES = repmat(Time,N,1);
for k = 2:length(TIMES)
  TIMES(k).Values = TIMES(k-1).Values + offset;
end
