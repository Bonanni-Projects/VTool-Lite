function [Signals,ismatched,index] = SelectFromDataset(selections,Data)

% SELECTFROMDATASET - Reduce a dataset to a set of selected signals.
% Signals = SelectFromDataset(names,Data)
% Signals = SelectFromDataset(ivec,Data)
% [Signals,ismatched,index] = SelectFromDataset(names,Data)
% [Signals,ismatched,index] = SelectFromDataset(ivec,Data)
%
% Returns signal group 'Signals' obtained by selecting the subset of 
% signals specified by 'names' from dataset 'Data'.  Input 'names' is 
% a list of zero or more signal names, each entry drawn from any name 
% layer contained in 'Data'.  However, the empty string name ('') is 
% considered a match only if it appears on all name layers.  In the 
% event of a duplicated name, only the first instance is considered. 
% As an alternative to specifying 'names', an integer index list 
% 'ivec' may be supplied instead.  Index values refer to positions 
% of signals in the overall dataset (i.e., after processing with 
% "CollectSignals"). 
%
% A warning message is written to the screen if any element of 
% the 'names' (or 'ivec') list is not found in the input dataset.  
% Optionally, a second output argument 'ismatched' can be supplied to 
% suppress the warning and return a binary mask to indicate which names 
% are matched.  A third output 'index' gives the index values of the 
% matched signals, or 0 where there is no match. 
%
% P.G. Bonanni
% 12/20/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'Data' input
[flag,valid,errmsg] = IsDataset(Data);
if ~flag
  error('Input #2 is not a dataset: %s',errmsg)
elseif ~valid
  error('Input #2 is not a valid dataset: %s  See "IsDataset".',errmsg)
end

% Collect signals into a master group
Master = CollectSignals(Data);

% Select from the group
if nargout < 2
  Signals = SelectFromGroup(selections,Master);
else  % same, but suppress warning
  [Signals,ismatched,index] = SelectFromGroup(selections,Master);
end
