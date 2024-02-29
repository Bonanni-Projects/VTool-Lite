function [out1,out2] = ReplaceSignalInDataset(varargin)

% REPLACESIGNALINDATASET - Replace a signal in a dataset.
% Data = ReplaceSignalInDataset(Data,name,x)
% Data = ReplaceSignalInDataset(Data,oldname,newname,x,units,description,layer)
% [Data,ismatched] = ReplaceSignalInDataset(...)
%
% Replaces all instances of a signal in dataset 'Data'.  For 
% each signal group contained in 'Data', replaces the data column 
% corresponding to the specified 'name', with vector 'x' providing 
% the new data, and all names on all layers left unmodified.  If 
% 'x' is scalar, it is extended to the appropriate length. 
%
% Alternatively, if the additional arguments are supplied, removes 
% signal 'oldname' and adds signal 'newname' with corresponding data 
% 'x' in its place.  Inputs 'units' and 'description' are strings 
% specifying the new signal units and description, and 'layer' 
% specifies the name layer on which the new name is to be recorded.  
% In this case, an empty string name is substituted on the remaining 
% name layers. 
%
% When looking for a match, input 'name' or 'oldname' may refer to 
% any name layer contained in 'Data'.  However, the empty string 
% name ('') is considered a match only if it appears on all name 
% layers. If 'name' or 'oldname' (or '') refers to more than one 
% signal within a group, the replacement is performed for all 
% matches. 
%
% An error occurs if the specified 'name' or 'oldname' (or '') is 
% not matched.  Optionally, a second output argument 'ismatched' 
% can be supplied to suppress the error and return a binary flag 
% to indicate whether a match was found. 
%
% P.G. Bonanni
% 4/14/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin ~= 3 && nargin ~= 7
  error('Invalid usage.')
end

args = varargin;
Data = args{1};
name = args{2};

% Check 'Data' input
[flag,valid,errmsg] = IsDataset(Data);
if ~flag
  error('Input ''Data'' is not a dataset: %s',errmsg)
elseif ~valid
  error('Input ''Data'' is not a valid dataset: %s  See "IsDataset".',errmsg)
end

% List the signal groups
[~,groups] = GetSignalGroups(Data);

% Initialize
ismatched = false(size(groups));

% Loop over groups
for k = 1:length(groups)
  group = groups{k};
  [Data.(group),ismatched(k)] = ReplaceSignalInGroup(Data.(group),varargin{2:end});
end

% Check if match occurred
ismatched = any(ismatched);
if ~ismatched && nargout < 2
  error('Signal ''%s'' was not found in the dataset.\n',name);
end

% Outputs
out1 = Data;
if nargout==2, out2=ismatched; end
