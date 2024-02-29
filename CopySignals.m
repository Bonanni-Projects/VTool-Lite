function obj2 = CopySignals(obj1,obj2,Selections)

% COPYSIGNALS - Copy signals between datasets or signal groups.
% Data2 = CopySignals(Data1,Data2,Selections)
% Data2 = CopySignals(Signals1,Data2,Selections)
% Signals2 = CopySignals(Data1,Signals2,Selections)
% Signals2 = CopySignals(Signals1,Signals2,Selections)
%
% Copies signal data, along with units and description strings, 
% between datasets and/or signal groups.  Input 'Selections' is 
% a cell array specifying signals to copy.  Name layers for the 
% source and destination objects need not be the same, and name 
% entries within the 'Selections' array may be drawn from any 
% available name layer within the source object.  All matching 
% occurrences within the destination object are affected. 
%
% P.G. Bonanni
% 2/27/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check inputs for validity
if length(obj1) > 1 || length(obj2) > 1
  error('Works for scalar objects only.')
elseif ~IsDataset(obj1) && ~IsSignalGroup(obj1)
  error('Input #1 is not a valid VTool object.')
elseif ~IsDataset(obj2) && ~IsSignalGroup(obj2)
  error('Input #2 is not a valid VTool object.')
elseif ~iscell(Selections) || ~all(cellfun(@ischar,Selections))
  error('Input ''Selections'' is not valid.')
elseif any(cellfun(@isempty,Selections))
  error('Input ''Selections'' cannot contain empty entries.')
end

% Extract signal information from 'obj1'
if IsDataset(obj1)
  [Signals,ismatched] = SelectFromDataset(Selections,obj1);
else  % if IsSignalGroup(obj)
  [Signals,ismatched] = SelectFromGroup(Selections,obj1);
end

% Reduce 'Selections' if necessary
if any(~ismatched)
  fprintf('WARNING: These names are not found in the source object.\n');
  disp(Selections(~ismatched))
  Selections(~ismatched) = [];
end

% Copy extracted information to 'obj2'
if IsDataset(obj2)

  % Transfer to all occurrences within all groups
  for k = 1:length(Selections)
    name = Selections{k};
    [Index,groups] = FindName(name,obj2);
    for j = 1:length(groups)
      group = groups{j};
      index = Index{j};
      obj2.(group).Values(:,index) = repmat(Signals.Values(:,k),1,length(index));
      [obj2.(group).Units{index}]        = deal(Signals.Units{k});
      [obj2.(group).Descriptions{index}] = deal(Signals.Descriptions{k});
    end
  end

else  % if IsSignalGroup(obj2)

  % Transfer to all occurrences within the group
  for k = 1:length(Selections)
    name = Selections{k};
    index = FindName(name,obj2);
    obj2.Values(:,index) = repmat(Signals.Values(:,k),1,length(index));
    [obj2.Units{index}]        = deal(Signals.Units{k});
    [obj2.Descriptions{index}] = deal(Signals.Descriptions{k});
  end

end
