function PlotBinnedSequences(SIGNALS,iclass,BinTitles,Names)

% PLOTBINNEDSEQUENCES - Plot raw sequences, segregated by bin.
% PlotBinnedSequences(SIGNALS)
% PlotBinnedSequences(SIGNALS,iclass,BinTitles)
% PlotBinnedSequences(SIGNALS,iclass,BinTitles,Names)
% PlotBinnedSequences(SIGNALS,[],[],Names)
%
% Plots raw signals in a signal-group array after segregating 
% into bins.  Input 'SIGNALS' is a length-N array of homogeneous 
% signal groups of M signals each.  Input 'iclass' is a length-N 
% vector of bin index values ranging from 0 to P, with 0 indicating 
% array elements to be ignored (see function "ComputeClassVector".) 
% If 'iclass' is empty or not provided, no segregation of the array 
% is performed. 
%
% Signals within the same bin are plotted as contiguous sequences 
% distinguished by color.  The different bins are represented in 
% separate subplots.  Up to 25 bins are supported*.  Input 'BinTitles' 
% is a length-P cell array of title strings corresponding to the bins. 
% If empty or not provided, 'BinTitles' defaults to the generic titles 
% {'Bin 1','Bin 2', ..., 'Bin P'}. 
%
% A separate figure window is generated for each named signal. 
% By default, all signals in the array are plotted.  Optionally, 
% a list of signal 'Names' can be provided as a final argument 
% to limit plotting to a specified subset of signals. 
%
% *Note: The function can be made to handle more than 25 bins using 
% multiple calls, with zero values in 'iclass' used to reject the 
% bins plotted in previous calls. 
%
% P.G. Bonanni
% 8/12/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin == 1
  iclass    = [];
  BinTitles = {};
  Names     = {};
elseif nargin == 2
  BinTitles = {};
  Names     = {};
elseif nargin == 3
  Names     = {};
end

% Check 'SIGNALS' input
[flag,valid,errmsg] = IsSignalGroupArray(SIGNALS);
if ~flag
  error('Input ''SIGNALS'' is not a signal group array: %s',errmsg)
elseif ~valid
  error('Input ''SIGNALS'' is not a valid signal group array: %s  See "IsSignalGroupArray".',errmsg)
elseif ~isvector(SIGNALS)
  error('Multidimensional ''SIGNALS'' array not permitted.')
end

% Return immediately if array length is zero
if isempty(SIGNALS)
  fprintf('Array length is zero.  Nothing to plot!\n');
  return
end

% Check for data-length uniformity
Lengths = arrayfun(@(x)size(x.Values,1),SIGNALS,'Uniform',false);
if length(SIGNALS) > 1 && ~isequal(Lengths{:})
  error('Input array must be data-length uniform.')
end

% Default 'iclass'
if isempty(iclass)
  iclass = ones(length(SIGNALS),1);
end

% Check 'iclass' input
if ~isnumeric(iclass) || ~isvector(iclass) || ~all(rem(iclass,1)==0) || any(iclass < 0)
  error('Invalid ''iclass'' input.')
elseif length(iclass) ~= length(SIGNALS)
  error('Inputs ''SIGNALS'' and ''iclass'' must have the same length.')
elseif max(iclass) > 25
  error('This function supports up to 25 bin classes.')
end

% Default 'BinTitles'
if isempty(BinTitles)
  BinTitles = arrayfun(@(x)sprintf('Bin %d',x),(1:max(iclass))','Uniform',false);
end

% Check 'BinTitles' input
if ~iscellstr(BinTitles)
  error('Invalid ''BinTitles'' input.')
elseif length(BinTitles) ~= max(iclass)
  error('Length of ''BinTitles'' should match the number of classes in ''iclass''.')
end

% Make cell array if necessary
if ischar(Names)
  Names = cellstr(Names);
end

% Check 'Names' input
if ~iscellstr(Names)
  error('Invalid ''Names'' input.')
end

% Make cell array
if ischar(Names)
  Names = cellstr(Names);
end

% Reduce signal array if required
if ~isempty(Names)
  % First check that all names are valid
  [~,ismatched] = SelectFromGroup(Names,SIGNALS(1));
  if ~all(ismatched)
    fprintf('These names were not found:\n');
    disp(Names(~ismatched));
    return
  end
  % Reduce the signal-group array to the specified set of signals
  SIGNALS = arrayfun(@(x)SelectFromGroup(Names,x),SIGNALS);
end

% Number of bins
P = max(iclass);

% Determine subplot layout
Rows = [3 3 3 3 3 3 3 3 3 4 4 4 4 4 4 4 5 5 5 5 5 5 5 5 5];
Cols = [1 1 1 2 2 2 3 3 3 3 3 3 4 4 4 4 4 4 4 4 5 5 5 5 5];
rows = Rows(P);
cols = Cols(P);

% Get default signal names
Names = GetDefaultNames(SIGNALS);

% Get signal units
Units = SIGNALS(1).Units;

% Convert to 3d array
SIGNALS = cat(3,SIGNALS.Values);

% Get data length
npoints = size(SIGNALS,1);

% Set figure-stacking mode
set(0,'DefaultFigureWindowStyle','docked')

% Number of signals
M = length(Names);

% Loop over signals
for m = 1:M

  figure
  set(gcf,'Name',Names{m},'NumberTitle','off')

  % Initialize
  imax = 0;

  % Loop over bins
  for k = 1:P
    subplot(rows,cols,k)

    % Get data for current bin
    mask = iclass==k;
    Z = squeeze(SIGNALS(:,m,mask));

    % Skip if no data
    if isempty(Z), continue, end

    % Compute "bounding" data
    Zmin = min(Z,[],1);  Zmin=repmat(Zmin,size(Z,1),1);
    Zmax = max(Z,[],1);  Zmax=repmat(Zmax,size(Z,1),1);

    % Generate index matrix
    I = reshape(1:numel(Z),size(Z));
    imax = max(imax,I(end));

    % Plot sequences
    plot(I,Z), hold on
    plot(I,Zmin,'k-')
    plot(I,Zmax,'k-')
    hold off
    if k>(rows-1)*cols, xlabel('Points'), end
    ylabel(Units{m})
    title(BinTitles{k})

    % Attach 'UserData' for access by data tips
    UserData.npoints = npoints;
    UserData.indexVals = find(mask);
    set(gca,'UserData',UserData)
  end
  linkaxes(get(gcf,'Children'),'xy')
  set(gca,'XLim',[0,imax])

  % Add title to figure window
  titlestr = sprintf('%s - Raw Sequences',strrep(Names{m},'_','\_'));
  suptitle(titlestr)

  % Set up data cursor feature
  handle = datacursormode(gcf);
  set(handle,'Enable','on')
  set(handle,'UpdateFcn',@callback_fcn2)
end

% Reset to no-stacking mode
set(0,'DefaultFigureWindowStyle','normal')
