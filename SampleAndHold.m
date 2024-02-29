function [out1,out2] = SampleAndHold(obj,names,trigger)

% SAMPLEANDHOLD - Sample and hold signals in a dataset or signal group.
% Data = SampleAndHold(Data,names,trigger)
% DATA = SampleAndHold(DATA,names,trigger)
% Signals = SampleAndHold(Signals,names,trigger)
% SIGNALS = SampleAndHold(SIGNALS,names,trigger)
% [Data,unmatched] = SampleAndHold(...)
%
% Performs a sample-and-hold operation on selected signals in 
% a dataset or signal group, in accordance with a trigger signal.  
% The function accepts a dataset 'Data' or a signal group 'Signals', 
% or arrays of either, for modification.  Input 'names' is a cell 
% array of selected signal names to modify;  if an entry in 'names' 
% matches more than one signal within a dataset or signal group, 
% the operation is performed for all matches. 
%
% Input 'trigger' is a binary vector matching the data length, 
% which is assumed uniform across the provided dataset(s) and 
% signal group(s).  Signal values occurring where trigger == 1 
% are retained, and values occurring where trigger == 0 are 
% held to the most recent triggered value.  The first value is 
% always treated as a trigger value. 
%
% An error is reported if one or more specified 'names' is not 
% matched.  Optionally, a second output argument 'unmatched' can 
% be supplied to suppress the error and return a list of unmatched 
% names. 
%
% P.G. Bonanni
% 10/18/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'names' and 'trigger' inputs
if ~ischar(names) && ~iscellstr(names)
  error('Input ''names'' is invalid.')
elseif ~all(ismember(unique(trigger(:)),[0,1]))
  error('Input ''trigger'' is invalid.')
end

% Make column
trigger = trigger(:);


if IsDataset(obj)

  % Check 'trigger' length against time vector
  if length(trigger) ~= length(obj.Time.Values)
    error('Trigger vector does not match data length.')
  end

  % Initialize
  unmatched = {};

  % Loop over names
  for k = 1:length(names)
    name = names{k};

    % Locate name within the dataset groups
    [Index,groups] = FindName(name,obj);

    % If name is matched
    if ~isempty(groups)

      % Loop over groups
      for k = 1:length(groups)
        group = groups{k};
        index = Index{k};
        for j = 1:length(index)  % loop over occurrences, performing sample-and-hold
          obj.(group).Values(:,index(j)) = sample_and_hold(obj.(group).Values(:,index(j)),trigger);
        end
      end

    else
      % Append unmatched name to list
      unmatched = [unmatched; name];
    end
  end

  % Check for any unmatched names
  if ~isempty(unmatched) && nargout < 2
    fprintf('These names were not found in the dataset:\n');
    disp(unmatched)
  end

elseif IsSignalGroup(obj)

  % Check 'trigger' length against data length
  if length(trigger) ~= size(obj.Values,1)
    error('Trigger vector does not match data length.')
  end

  % Initialize
  unmatched = {};

  % Loop over names
  for k = 1:length(names)
    name = names{k};

    % Locate name within the signal group
    index = FindName(name,obj);

    % If name is matched
    if ~isempty(index)

      % Loop over occurrences
      for j = 1:length(index)  % loop over occurrences, performing sample-and-hold
        obj.Values(:,index(j)) = sample_and_hold(obj.Values(:,index(j)),trigger);
      end

    else
      % Append unmatched name to list
      unmatched = [unmatched; name];
    end
  end

  % Check for any unmatched names
  if ~isempty(unmatched) && nargout < 2
    fprintf('These names were not found in the signal group:\n');
    disp(unmatched)
  end

elseif IsDatasetArray(obj) || IsSignalGroupArray(obj)

  % Loop over all elements in the array
  for k = 1:numel(obj)  % one 'unmatched' list only, since arrays are homogeneous
    [obj(k),unmatched] = SampleAndHold(obj(k),names,trigger);
  end

  % Check for any unmatched names
  if ~isempty(unmatched) && nargout < 2
    fprintf('These names were not found in the array:\n');
    disp(unmatched)
  end

else
  error('Works for datasets, signal groups, and their arrays only.')
end

% Outputs
out1 = obj;
if nargout==2, out2=unmatched; end



% ------------------------------------------------------------------------
function y = sample_and_hold(x,trigger)

% Performs the sample-and-hold operation on vector 'x', where 
% trigger is a binary vector of the same length. 

% Initialize
y = nan(size(x));

% Build index vector
i=x; i(:)=1:length(x);

% Compute mask; ensure first value is triggered
mask = trigger==1;  mask(1)=true;

% Perform sample and hold using previous-neighbor interpolation
y( mask) = x(mask);  % retain all trigger values
y(~mask) = interp1(i(mask),x(mask),i(~mask),'previous','extrap');

