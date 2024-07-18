function [Signals,IDs] = GroupSignalFromArray(name,obj)

% GROUPSIGNALFROMARRAY - Group a signal pulled from array elements.
% Signals = GroupSignalFromArray(name,DATA)
% Signals = GroupSignalFromArray(name,SIGNALS)
% [Signals,IDs] = GroupSignalFromArray(...)
%
% Form a signal group consisting of versions of the named signal extracted 
% from successive elements of input dataset array 'DATA' or signal group 
% array 'SIGNALS'. The result is scalar signal group 'Signals' with number 
% of signals equal to the number of array elements. If 'DATA' or 'SIGNALS' 
% is multidimensional, the ordering of the member signals corresponds to 
% a columnwise ordering of the array. 
%
% The additional output 'IDs' is a suggested list of string identifiers 
% for the grouped signals. The list is formed from "source" strings in 
% 'DATA' (if available) or generated as a number sequence (e.g., '001', 
% '002', '003', ...) of appropriate width and length. (An example use 
% is for signal name modification or plot labeling.)  
%
% P.G. Bonanni
% 7/16/24

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check array input
[flag1,valid1,errmsg1] = IsDatasetArray(obj);
[flag2,valid2,errmsg2] = IsSignalGroupArray(obj);
if ~flag1 && ~flag2
  error('Input ''DATA'' or ''SIGNALS'' is not valid.')
elseif flag1 && ~valid1
  error('Input ''DATA'' is not a valid dataset array: %s  See "IsDatasetArray".',errmsg1)
elseif flag2 && ~valid2
  error('Input ''SIGNALS'' is not a valid signal group array: %s  See "IsSignalGroupArray".',errmsg2)
end

% Check 'name' input
if ~ischar(name)
  error('Input ''name'' is not valid.')
end

% Perform collection operation
if IsDatasetArray(obj)
  DATA = obj;
  SIGNALS = arrayfun(@(x)SelectFromDataset(name,x),DATA);
  C = num2cell(SIGNALS);
  Signals = MergeSignalGroups(C{:});
else  % if IsSignalGroupArray(obj)
  SIGNALS = obj;
  SIGNALS = arrayfun(@(x)SelectFromGroup(name,x),SIGNALS);
  C = num2cell(SIGNALS);
  Signals = MergeSignalGroups(C{:});
end

% Generate 'IDs'
if GetNumSignals(Signals) == 0
  IDs = {};  % no signals retrieved
elseif IsDatasetArray(obj) && isfield(obj,'source')
  IDs = {obj.source}';
else
  % Generate numerical sequence
  n = numel(obj);
  ndigits = 1 + floor(log10(n));
  formatstr = sprintf('%%0%dd',ndigits);
  IDs = arrayfun(@(x)sprintf(formatstr,x),(1:n)','Uniform',false);
end
