function [out1,out2] = RemoveFromGroup(selections,Signals,option)

% REMOVEFROMGROUP - Remove one or more signals from a signal group.
% Signals1 = RemoveFromGroup(names,Signals)
% Signals1 = RemoveFromGroup(ivec,Signals)
% [Signals1,ismatched] = RemoveFromGroup(names,Signals)
% [Signals1,ismatched] = RemoveFromGroup(ivec,Signals)
% [Signals1,ismatched] = RemoveFromGroup(..., 'nan')
%
% Returns signal group 'Signals1' obtained by removing signals specified 
% by 'names' from the input signal group 'Signals'.  Input 'names' is a 
% list of one or more signal names, each entry drawn from any name layer 
% contained in 'Signals'.  However, the empty string name ('') is 
% considered a match only if it appears on all name layers.  If a name 
% entry refers to more than one signal within the group, all matching 
% instances are removed.  As an alternative to specifying 'names', an 
% integer index list 'ivec' may be supplied instead. 
%
% Removal consists of deleting columns from the 'Values' field and 
% corresponding entries from all name layers.  However, if the 'nan' 
% option is invoked, the signals are NaN'd out instead.  This includes 
% replacing columns in 'Values' by NaNs and corresponding names, units, 
% and descriptions by ''. 
%
% A warning message is written to the screen if any element of the 
% 'names' (or 'ivec') list is not found in the 'Signals' signal group.  
% Optionally, a second output argument 'ismatched' can be supplied to 
% suppress the warning and return a binary mask to indicate which names 
% were matched and removed. 
%
% P.G. Bonanni
% 4/2/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 3
  option = '';
end

% Check 'Signals' input
[flag,valid,errmsg] = IsSignalGroup(Signals);
if ~flag
  error('Input #2 is not a signal group: %s',errmsg)
elseif ~valid
  error('Input #2 is not a valid signal group: %s  See "IsSignalGroup".',errmsg)
end

% Check 'option' input
if ~ischar(option)
  error('Input #3 is not a valid option.')
end

% If selections=[], interpret as empty list
if isnumeric(selections) && isempty(selections)
  selections = cell(0,1);
end

% Check 'selections' input
if ~(isnumeric(selections) && all(rem(selections(:),1)==0)) && ... 
   ~iscellstr(selections) && ~ischar(selections)
  error('Invalid ''selections'' input.')
end

% If 'names' input ...
if ~isnumeric(selections)
  names = selections;

  % Make cell array
  if ischar(names)
    names = cellstr(names);
  end

  % Find specified signals in the signal group, considering all name layers
  % (and, for each name, include duplicate instances, if any)
  Index = cellfun(@(x)FindName(x,Signals),names,'Uniform',false);
  ismatched = ~cellfun(@isempty,Index);
  unmatched = names(~ismatched);
  if ~isempty(unmatched) && nargout < 2
    fprintf('WARNING: The following names were not found:\n');
    disp(unmatched)
  end

  % Matched selections
  i = cat(1,Index{:});

else  % if ivec input ...
  ivec = selections;

  % Make column
  ivec = ivec(:);

  % Number of signals in the signal group
  nsignals = size(Signals.Values,2);

  % Ensure all selections are present
  ismatched = ismember(ivec,1:nsignals);
  unmatched = ivec(~ismatched);
  if ~isempty(unmatched)
    ivec(~ismatched) = [];
    if nargout < 2
      fprintf('WARNING: The following selections were not found:\n');
      disp(unmatched')
    end
  end

  % Matched selections
  i = ivec;
end

% Perform the removal
if isempty(option)
  % Remove the matched signals by keeping only the rest
  j = setdiff(1:size(Signals.Values,2), i');  % signals to keep
  Signals1 = Signals;  Signals1.Values=Signals1.Units;  % initialize
  Signals1 = structfun(@(x)x(j,1),Signals1,'Uniform',false);
  Signals1.Values = Signals.Values(:,j);
elseif strcmpi(option,'nan')
  % Remove the matched signals by a "clearing" operation
  Signals1 = Signals;  % initialize
  Signals1.Values(:,i) = nan;  % clear the signal data
  fields = setdiff(fieldnames(Signals1),'Values');
  for k = 1:length(fields)
    field = fields{k};
    [Signals1.(field){i}] = deal('');
  end
else
  error('Option ''%s'' is not recognized.',option)
end

% Outputs
out1 = Signals1;
if nargout==2, out2=ismatched; end
