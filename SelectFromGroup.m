function [out1,out2,out3] = SelectFromGroup(selections,Signals)

% SELECTFROMGROUP - Reduce a signal group to a set of selected signals.
% Signals1 = SelectFromGroup(names,Signals)
% Signals1 = SelectFromGroup(ivec,Signals)
% [Signals1,ismatched,index] = SelectFromGroup(names,Signals)
% [Signals1,ismatched,index] = SelectFromGroup(ivec,Signals)
%
% Returns signal group 'Signals1' obtained by selecting the subset of 
% signals specified by 'names' from the larger signal group 'Signals'. 
% Input 'names' is a list of zero or more signal names, each entry drawn 
% from any name layer contained in 'Signals'.  However, the empty string 
% name ('') is considered a match only if it appears on all name layers. 
% In the event of a duplicated name, only the first instance is considered. 
% As an alternative to specifying 'names', an integer index list 'ivec' 
% may be supplied instead. 
%
% A warning message is written to the screen if any element of the 
% 'names' (or 'ivec') list is not found in the 'Signals' signal group.  
% Optionally, a second output argument 'ismatched' can be supplied to 
% suppress the warning and return a binary mask to indicate which names 
% are matched.  A third output 'index' gives the index values of the 
% matched signals, or 0 where there is no match. 
%
% P.G. Bonanni
% 2/18/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'Signals' input
[flag,valid,errmsg] = IsSignalGroup(Signals);
if ~flag
  error('Input #2 is not a signal group: %s',errmsg)
elseif ~valid
  error('Input #2 is not a valid signal group: %s  See "IsSignalGroup".',errmsg)
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

  % Make column
  names = names(:);

  % Get the names matrix for the signal group
  NAMES = GetNamesMatrix(Signals);

  % Define 'names1' and 'NAMES1' to handle empty names
  names1 = names;  % initialize
  NAMES1 = NAMES;  % initialize
  mask = cellfun(@isempty,names1);        [names1{mask}  ]=deal('(empty)');
  mask = all(cellfun(@isempty,NAMES1),2); [NAMES1{mask,:}]=deal('(empty)');

  % Ensure all selections are present
  ismatched = ismember(names1,NAMES1(:));
  unmatched = names(~ismatched);
  if ~isempty(unmatched)
    %names(~ismatched) = [];
    names1(~ismatched) = [];
    if nargout < 2
      fprintf('WARNING: The following names were not found:\n');
      disp(unmatched)
    end
  end

  % Locate the first instance of each match, considering all name layers
  i = zeros(size(names1));  % initialize
  for k = 1:length(names1)
    index1 = find(strcmp(names1{k},NAMES1(:)));  [j,~]=ind2sub(size(NAMES1),index1);
    i(k) = min(j);  % first row instance only (duplicates in 'i' correspond to same row, different layers)
  end

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

% Reduce the signal group array to the specified signal list
Signals1 = Signals;  Signals1.Values=Signals1.Units;  % initialize
Signals1 = structfun(@(x)x(i),Signals1,'Uniform',false);
Signals1.Values = Signals.Values(:,i);

% Build index vector referencing matched and unmatched names
index = zeros(size(ismatched));  % initialize
index(ismatched) = i;

% Outputs
out1 = Signals1;
out2 = ismatched;
out3 = index;
