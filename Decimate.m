function DataOut = Decimate(DataIn,factor,varargin)

% DECIMATE - Decimate signals or groups in a dataset.
% DataIn = Decimate(DataIn,factor,{'group1','group2',...} [,options, ...]])
% DataIn = Decimate(DataIn,factor,{'signal1','signal2',...} [,options, ...])
% DataIn = Decimate(DataIn,factor,Selections [,options, ...])
% DataIn = Decimate(DataIn,factor [,options, ...])
%
% Applies Matlab's "decimate" function to dataset 'DataIn', using 
% the specified decimation 'factor', and with "options, ..." 
% referring to additional filter specification options offered 
% by the "decimate" function (e.g., 'N', 'FIR', etc.).  Output 
% dataset 'DataOut' has the correspondingly shorter data length. 
%
% The 'Selections' input is a cell array specifying a list of signal 
% and/or group names to which the function should be applied.  Any 
% signals or groups not listed are simply downsampled by the 'factor' 
% (i.e., minus any filtering) to produce data of matching length. If 
% the 'Selections' input is omitted, the decimation operation is 
% applied to all signals in the dataset. 
%
% P.G. Bonanni
% 2/6/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


args = varargin;
if isempty(args)
  Selections = {};
  options = {};
elseif iscell(args{1})
  Selections = args{1};
  args(1) = [];
  options = args;
else
  Selections = {};
  options = args;
end

% Check 'DataIn' argument
if numel(DataIn) > 1
  error('Works for scalar datasets only.')
end
[flag,valid] = IsDataset(DataIn);
if ~flag || ~valid
  error('Input ''DataIn'' is not a valid dataset.  See "IsDataset".')
end

% Check other inputs
if ~isnumeric(factor) || ~isscalar(factor) || ~(rem(factor,1)==0)
  error('Input ''factor'' is not valid.')
elseif ~iscell(Selections) || ~all(cellfun(@ischar,Selections))
  error('Invalid ''Selections'' input.')
end

% Get signal group names
[~,Groups] = GetSignalGroups(DataIn);

% Default 'Selections' to all groups except 'Time'
if isempty(Selections), Selections=setdiff(Groups,'Time'); end

% Initialize output dataset
DataOut = DownsampleDataset(DataIn,factor);

% Loop over selections
for k = 1:length(Selections)
  selection = Selections{k};

  % If selection is a group ...
  if ismember(selection,Groups)

    % Perform decimation on the group
    for j = 1:size(DataIn.(selection).Values,2)
      x = DataIn.(selection).Values(:,j);
      y = decimate(x,factor,options{:});
      DataOut.(selection).Values(:,j) = y;
    end

  else  % assume selection is a signal name

    % Get input data and perform decimation
    x = GetSignal(selection,DataIn);
    y = decimate(x,factor,options{:});
    DataOut = ReplaceSignalInDataset(DataOut,selection,y);
  end
end
