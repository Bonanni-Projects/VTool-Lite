function varargout = ReconcileUnits(varargin)

% RECONCILEUNITS - Reconcile units across datasets or signal groups.
% [DATA,success] = ReconcileUnits(DATA)
% [Data1,Data2,...,success] = ReconcileUnits(Data1,Data2,...)
% [Data1,DATA2,...,success] = ReconcileUnits(Data1,DATA2,...)
% [SIGNALS,success] = ReconcileUnits(SIGNALS)
% [Signals1,Signals2,...,success] = ReconcileUnits(Signals1,Signals2,...)
% [Signals1,SIGNALS2,...,success] = ReconcileUnits(Signals1,SIGNALS2,...)
%
% Attempts to assign signal units (and descriptions) for "placeholder" 
% (i.e., all-NaN) signsls within datasets or signal groups to yield 
% datasets or signal groups with matching units.  In "dataset mode", 
% input can be a single dataset array or a sequence of datasets and/or 
% dataset arrays.  Similarly, in "signal group mode", input can be a 
% signal group array or a sequence of signal groups and/or signal-
% group arrays.  The corresponding objects are returned along with 
% a 'success' flag indicating whether reconciliation of units was 
% achieved. 
%
% In processing the input objects, the units, and if available, the 
% descriptions, are taken from array elements where the signal data 
% (and thus units and description attributes) are present.  The input 
% object(s) are updated and the 'success' flag is set to true if this 
% process succeeds.  If a conflict is detected, i.e., differing units 
% representing the same channel, the 'success' flag is set to false 
% and the input objects are returned unchanged.  
%
% P.G. Bonanni
% 8/8/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Get input arguments
args = varargin;

% Check usage
if isempty(args)
  error('Invalid usage.')
elseif ~IsDatasetArray(args{1}) && ~IsSignalGroupArray(args{1})
  error('Inputs must be datasets, signal groups, or arrays of same.')
end

% Initialize
success = true;

% If "dataset mode"
if IsDatasetArray(args{1})

  % Check that all inputs are datasets or dataset arrays
  if ~all(cellfun(@IsDatasetArray,args))
    error('Inputs must be all datasets or dataset arrays.')
  end

  % Collect inputs into a dataset array
  C = cellfun(@(x)x(:),args,'Uniform',false);
  DATA = cat(1,C{:});

  % Check compatibility of inputs by converting to signal-group array 
  % and checking homogeneity with units temporarily set to all blanks
  SIGNALSx = arrayfun(@CollectSignals,DATA);
  for k=1:length(SIGNALSx), SIGNALSx(k).Units=repmat({''},size(SIGNALSx(k).Units)); end
  [~,valid] = IsSignalGroupArray(SIGNALSx);
  if ~valid
    error('The provided inputs are not compatible.')
  end

  % List of signal groups, excluding 'Time'
  [~,groups] = GetSignalGroups(DATA(1));
  groups = setdiff(groups,'Time','stable');

  % Loop over groups
  for k = 1:length(groups)
    group = groups{k};

    % Collect signal groups into an array
    SIGNALS = arrayfun(@(x)x.(group),DATA);

    % Collect 'Units' and 'Descriptions' lists
    UNITS = arrayfun(@(x)x.Units,       SIGNALS,'Uniform',false);
    DESCR = arrayfun(@(x)x.Descriptions,SIGNALS,'Uniform',false);

    % Replace any [] entries with ''
    for j = 1:length(UNITS)
      mask=cellfun(@(x)isnumeric(x)&&isempty(x),UNITS{j}); [UNITS{j}{mask}]=deal('');
      mask=cellfun(@(x)isnumeric(x)&&isempty(x),DESCR{j}); [DESCR{j}{mask}]=deal('');
    end

    % Form 2-d arrays, then separate into rows
    UNITS = cat(2,UNITS{:});    % 2-d array
    DESCR = cat(2,DESCR{:});    % 2-d array
    UNITS = num2cell(UNITS,2);  % separate into rows
    DESCR = num2cell(DESCR,2);  % separate into rows

    % Find and replace '' in UNITS, provided units are consistent.
    % Combine all description strings in the affected channels. 
    for j = 1:length(UNITS)
      row = UNITS{j};  % all units for a single channel
      if length(unique(row))==2 && ismember('',row)
        i = find(~cellfun(@isempty,row),1,'first');
        units = UNITS{j}{i};
        C = setdiff(DESCR{j},'','stable');  % all description strings except ''
        if isempty(C), C = {''}; end        % if no descriptions found
        descr = sprintf('%s : ',C{:}); descr(end-2:end)=[];
        UNITS{j} = repmat({units},1,length(row));
        DESCR{j} = repmat({descr},1,length(row));
      elseif length(unique(row)) > 1
        success = false;
        varargout = [args, success];
        return
      end
    end

    % Form 2-d arrays, then separate into columns
    UNITS = cat(1,UNITS{:});    % 2-d array
    DESCR = cat(1,DESCR{:});    % 2-d array
    UNITS = num2cell(UNITS,1);  % separate into columns
    DESCR = num2cell(DESCR,1);  % separate into columns

    % Re-assign units and descriptions to signal group array
    [SIGNALS.Units]        = deal(UNITS{:});
    [SIGNALS.Descriptions] = deal(DESCR{:});

    % Re-assign signal groups onto dataset array
    C=num2cell(SIGNALS);  [DATA.(group)] = deal(C{:});
  end

  % Distribute units to the input objects
  for k = 1:length(args)
    for j = 1:numel(args{k})
      for i = 1:length(groups)
        group = groups{i};
          args{k}(j).(group).Units = DATA(1).(group).Units;
      end
    end
  end

else  % if "signal-group mode"

  % Check that all inputs are signal groups or signal-group arrays
  if ~all(cellfun(@IsSignalGroupArray,args))
    error('Inputs must be all signal groups or signal-group arrays.')
  end

  % Collect inputs into a signal group array
  C = cellfun(@(x)x(:),args,'Uniform',false);
  SIGNALS = cat(1,C{:});

  % Check compatibility of inputs by performing a homogeneity check 
  % with units temporarily set to all blanks
  SIGNALSx = SIGNALS;  % initialize
  for k=1:length(SIGNALSx), SIGNALSx(k).Units=repmat({''},size(SIGNALSx(k).Units)); end
  [~,valid] = IsSignalGroupArray(SIGNALSx);
  if ~valid
    error('The provided inputs are not compatible.')
  end

  % Collect 'Units' and 'Descriptions' lists
  UNITS = arrayfun(@(x)x.Units,       SIGNALS,'Uniform',false);
  DESCR = arrayfun(@(x)x.Descriptions,SIGNALS,'Uniform',false);

  % Replace any [] entries with ''
  for j = 1:length(UNITS)
    mask=cellfun(@(x)isnumeric(x)&&isempty(x),UNITS{j}); [UNITS{j}{mask}]=deal('');
    mask=cellfun(@(x)isnumeric(x)&&isempty(x),DESCR{j}); [DESCR{j}{mask}]=deal('');
  end

  % Form 2-d arrays, then separate into rows
  UNITS = cat(2,UNITS{:});    % 2-d array
  DESCR = cat(2,DESCR{:});    % 2-d array
  UNITS = num2cell(UNITS,2);  % separate into rows
  DESCR = num2cell(DESCR,2);  % separate into rows

  % Find and replace '' in UNITS, provided units are consistent.
  % Combine all description strings in the affected channels. 
  for j = 1:length(UNITS)
    row = UNITS{j};  % all units for a single channel
    if length(unique(row))==2 && ismember('',row)
      i = find(~cellfun(@isempty,row),1,'first');
      units = UNITS{j}{i};
      C = setdiff(DESCR{j},'','stable');  % all description strings except ''
      if isempty(C), C = {''}; end        % if no descriptions found
      descr = sprintf('%s : ',C{:}); descr(end-2:end)=[];
      UNITS{j} = repmat({units},1,length(row));
      DESCR{j} = repmat({descr},1,length(row));
    elseif length(unique(row)) > 1
      success = false;
      varargout = [args, success];
      return
    end
  end

  % Form 2-d arrays, then separate into columns
  UNITS = cat(1,UNITS{:});    % 2-d array
  DESCR = cat(1,DESCR{:});    % 2-d array
  UNITS = num2cell(UNITS,1);  % separate into columns
  DESCR = num2cell(DESCR,1);  % separate into columns

  % Re-assign units and descriptions to signal group array
  [SIGNALS.Units]        = deal(UNITS{:});
  [SIGNALS.Descriptions] = deal(DESCR{:});

  % Distribute units to the input objects
  for k = 1:length(args)
    for j = 1:numel(args{k})
      args{k}(j).Units = SIGNALS(1).Units;
    end
  end
end

% Generate output arguments
varargout = [args, success];
