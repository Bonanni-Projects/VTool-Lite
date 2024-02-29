function varargout = Compare(obj1,obj2,varargin)

% COMPARE - Compare two datasets or signal groups.
% Compare(Data1,Data2 [,'full'] [,'plot'])
% Compare(Signals1,Signals2 [,'full'] [,'plot'])
% [metrics,message1,message2] = Compare(...)
%
% Wrapper function for "CompareDatasets" and "CompareSignalGroups".  
% Compares two datasets ('Data1','Data2') or signal groups ('Signals1', 
% 'Signals2').  Reports differences by field and signal group, or plots 
% differences by signal.  Also detects name array differences.  Type 
% "help CompareSignalGroups" and "help CompareDatasets" for description 
% of 'full' and 'plot' options and additional information. 
%
% P.G. Bonanni
% 9/19/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Identify input type, and display
if IsDataset(obj1)
  [varargout{1:nargout}] = CompareDatasets(obj1,obj2,varargin{:});
elseif IsSignalGroup(obj1)
  [varargout{1:nargout}] = CompareSignalGroups(obj1,obj2,varargin{:});
else
  error('Works for datasets and signal groups only.')
end
