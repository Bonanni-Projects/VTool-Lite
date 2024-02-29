function PlotSignalsInDataset(Data,Names,varargin)

% PLOTSIGNALSINDATASET - Plot dataset signals with user-definable grouping.
% PlotSignalsInDataset(Data,Names)
% PlotSignalsInDataset(Data,Names,<Option1>,<Value>,<Option2>,{Value>,...)
%
% Plots selected signals from a dataset with user-definable grouping 
% of signals within subplots.  Input 'Data' is a scalar dataset, and 
% 'Names' is a 1d or 2d cell array of signal names.  If 'Names' is a 
% row array, a single plot is produced with the corresponding signals 
% plotted on a single set of axes.  If 'Names' has additional rows, 
% the number of rows defines a desired number of subplots, and each 
% row specifies the contents of the corresponding subplot.
%
% Additional control over the plotting, including number of rows 
% per figure window, specification of power spectral density or 
% coherence plots, etc., can be realized by providing any of the 
% option/value pairs defined in function "PlotSignalGroup".  Note 
% that if a 'Legend' option is specified, the specified legend strings 
% will be understood to apply to the columns of the 'Names' array. 
%
% Null signal names ('') are permitted in the 'Names' array, and 
% result in the corresponding signal being omitted from the plot. 
%
% P.G. Bonanni
% 12/5/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'Data' argument
if numel(Data) > 1
  error('Works for scalar datasets only.')
end
[flag,valid] = IsDataset(Data);
if ~flag || ~valid
  error('Input ''Data'' is not a valid dataset.  See "IsDataset".')
end

% Check 'Names' argument
if ~iscellstr(Names)
  error('Input ''Names'' must be a cell array of strings.')
end

% Array dimensions
[nrows,ncols] = size(Names);

% Get 'Time' group
Time = Data.Time;

% Check that all requested names are valid, except empties ('')
names = Names(:);  names(cellfun(@isempty,names))=[];
[~,ismatched] = SelectFromDataset(names,Data);
if any(~ismatched)
  error('One or more requested signals is not present in the dataset.')
end

% Ensure that a null signal is available if needed
Data = DefineSignalGroup(Data,'null',{''},'nowarn');

% Generate 'SIGNALS' array for plotting
NAMES = num2cell(Names,1);  % partition 'Names' into columns
SIGNALS = cellfun(@(x)SelectFromDataset(x,Data),NAMES);

% Collect and consolidate 'Units' strings
C = arrayfun(@(x)x.Units,SIGNALS,'Uniform',false);  C=cat(2,C{:});
Units = num2cell(C,2);  % initialize as a cell array of cells
for k = 1:length(Units)
  % --- Remove repeats, and string the remaining entries together
  Units{k} = unique(Units{k},'stable');
  if length(Units{k}) > 1
    C1 = strcat('~',Units{k}(2:end));
    C2 = [Units{k}{1}; C1(:)];
    Units{k} = {strcat(C2{:})};
  end
  % --- Extract result from cell
  Units{k} = Units{k}{1};
end

% Define generic name layers
layers = arrayfun(@(x)sprintf('Col%dNames',x),1:ncols,'Uniform',false);

% Replace name layers in 'SIGNALS'
SIGNALS = rmfield(SIGNALS,GetLayers(Data));
for k = 1:length(layers)
  layer = layers{k};
  [SIGNALS.(layer)] = deal(Names(:,k));
end
fields = [layers,'Values','Units','Descriptions'];
SIGNALS = orderfields(SIGNALS,fields);

% Assign 'Units' and 'Descriptions'
[SIGNALS.Units]        = deal(Units);
[SIGNALS.Descriptions] = deal(repmat({''},nrows,1));

% Set a tag string with a timestamp
tag = sprintf('PlotSignalsInDataset: %s', datestr(now));

% Plot the signal group array, passing all options
PlotSignalGroup(Time,SIGNALS,varargin{:},'tag',tag)
