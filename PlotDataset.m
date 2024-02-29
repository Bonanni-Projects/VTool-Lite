function PlotDataset(varargin)

% PLOTDATASET - Plot and analyze signals from one or more datasets.
% PlotDataset(Data [,Trange] [,'psd'] [,'coh'] [,'single'] [,'ppt'], [,'fig'])
% PlotDataset(Data1,Data2,Data3,... [,Trange] [,'psd'] [,'coh'] [,'single'] [,'ppt'], [,'fig'])
% PlotDataset(DATA1,DATA2,DATA3,... )
% PlotDataset(..., Selections)
%
% Plots one or more sets of grouped signal data of the format produced 
% by "BuildDataset".  Datasets may be provided as comma-separated list 
% of individual dataset structures or structure arrays.  Plots are 
% displayed in a series of tabbed plot windows.  The following options 
% are available: 
%    Trange      -  1 x 2 vector specifying [Tmin,Tmax] time range. 
%    'psd'       -  option to include power-spectral-density plots. 
%    'psde'      -  option to include power-spectral-density error plots. 
%    'coh'       -  include coherence spectra (magnitude and phase) 
%                   of all results in comparison to 'results1'. 
%    'only'      -  option to suppress the default time series plot 
%                   (applies only if one or more of the optional 
%                   spectral plot types is specified). 
%    'single'    -  directs that all plots should be full-window 
%                   (i.e., no subplots). 
%    'nolabels'  -  option to suppress display of signal names 
%                   within plot axes. 
%    'ppt'       -  saves all plot windows to a PowerPoint file 
%                   using a name derived from extracted dataset 
%                   casename(s) (defaults to '(untitled).pptx' if 
%                   casenames are not available). 
%    'fig'       -  saves plot windows as individual .fig files 
%                   within a subfolder.  The name of the subfolder 
%                   is derived from the extracted casename, or 
%                   set to '(untitled)'. 
% Plot legend entries are defined by 'source' fields in the 
% input data structure(s), or default to {'Data1','Data2',...} 
% if 'source' fields are not present. 
%
% Optional final argument 'Selections' is a cell array that specifies 
% any combination of signals or "signal groups" to be plotted.  Individual 
% signals are specified by their names on any "name layer".  By default, 
% all signal groups are chosen for plotting if 'Selections' is not included 
% in the function call. 
%
% Time and frequency axes across all plots and generated figures are 
% separately linked, to enable synchronized zooming and panning. (Turn 
% this feature off after plotting using function "UnlinkAxes".) 
%
% P.G. Bonanni
% 2/15/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check calling syntax
args = varargin;  % initialize
mask = cellfun(@isstruct,args);  if all(~mask), error('Invalid usage.'); end
i = find(mask,1,'first');        if i~=1, error('Invalid usage.'); end
j = find(mask,1,'last');
mask1 = cellfun(@isstruct,args(i:j));
if ~all(mask1), error('Invalid usage.'); end

% Number of 'struct' inputs
nstruct = j-i+1;

% Build a master list of signal groups, per argument (struct or struct array)
GROUPS = cell(nstruct,1);  % initialize
for k = i:j  % ... taking into account "structure array" inputs
  [~,GROUPS1] = arrayfun(@GetSignalGroups,args{k},'Uniform',false);
  if any(cellfun(@isempty,GROUPS1))
    error('One or more input structure(s) is missing signal-group fields.')
  elseif length(GROUPS1)>1 && ~isequal(GROUPS1{:})
    error('One or more input structure array(s) is inconsistent. Groups do not match.')
  end
  Groups1 = GROUPS1{1};  % (all entries equal)
  if any(ismember('casename',Groups1))
    error('Signal group name ''casename'' is not permitted.')
  elseif any(ismember('source',Groups1))
    error('Signal group name ''source'' is not permitted.')
  end
  GROUPS{k} = Groups1;
end

% Remove the non-group fields, except 'casename' and 'source'
CfieldsX = cell(nstruct,1);  % initialize
for k = i:j  % ... taking into account "structure array" inputs
  fieldsX = setdiff(fieldnames(args{k}),[GROUPS{k};{'casename';'source'}]);
  args{k} = rmfield(args{k},fieldsX);
  CfieldsX{k} = sort(fieldsX);
end

% Warn if non-group fields do not match
if length(CfieldsX) > 1 && ~isequal(CfieldsX{:})
  fprintf('Warning: The provided datasets/arrays do not have the same field names.\n')
end

% Check that input structures/arrays have the same (remaining) fields
Fields = cellfun(@fieldnames,args(i:j),'Uniform',false);
Fields = cellfun(@sort,Fields,'Uniform',false);
if length(Fields)>1 && ~all(isequal(Fields{:}))
  error('The provided datasets are not compatible. Check the presence of group, ''casename'' and ''source'' fields.')
end

% Build complete 'DATA' structure array by stacking all inputs, including arrays
args(i:j) = cellfun(@(x)x(:),args(i:j),'Uniform',false);  % ensure all arrays are columns
DATA = cat(1,args{i:j});

% Check that input structures are valid and compatible
Fields = arrayfun(@(x)fieldnames(x.Time),DATA,'Uniform',false);
Fields = cellfun(@sort,Fields,'Uniform',false);
if length(Fields)>1 && ~all(isequal(Fields{:}))
  error('Input structures have missing/incompatible name layers.  Try "AddMissingLayers" or "CopyNamesFromModel".')
end
TimeUnits = arrayfun(@(x)x.Time.Units,DATA,'Uniform',false);
if length(TimeUnits)>1 && ~all(isequal(TimeUnits{:}))
  error('Input structures have incompatible time vectors. Possibly mixing absolute/elapsed time.')
end

% Identify the signal groups
[~,Groups] = GetSignalGroups(DATA(1));
if isempty(Groups)
  error('Input structure(s) have no signal-group fields.')
end

% Check for 'Selections' argument
args(i:j) = [];
if ~isempty(args) && iscell(args{end})
  Selections = args{end};
  args(end) = [];
else
  Selections = setdiff(Groups,'Time','stable');  % defaults to all groups but 'Time'
end
if ~all(cellfun(@ischar,Selections))
  error('Invalid ''Selections'' argument.')
end
if any(ismember(Selections,Groups)) && ~isempty(setdiff(Selections,Groups))
  fprintf('NOTE: Signal groups are plotted BEFORE additional selected signals.\n');
end

% Check for 'Trange' argument
Trange = [];  % initialize
if ~isempty(args)  % look for a 1x2 vector or []
  mask = cellfun(@(x)(isnumeric(x)||isdatetime(x))&&(numel(x)==2||isempty(x)),args);
  if any(mask)
    i = find(mask,1,'first');
    Trange = args{i};
    args(i) = [];
  end
end

% Collect remaining options arguments
if ~isempty(args)
  if ~all(cellfun(@ischar,args)) || ...
     ~all(ismember(args,{'psd','psde','coh','only','single','nolabels','ppt','fig'}))
    error('Invalid syntax or unrecognized option(s).  Note: Signal/group selections should be in { } brackets.')
  end
  if any(strcmp('psd',     args)), OptionPSD='on';     else OptionPSD='off';    end
  if any(strcmp('psde',    args)), OptionPSDE='on';    else OptionPSDE='off';   end
  if any(strcmp('coh',     args)), OptionCOH='on';     else OptionCOH='off';    end
  if any(strcmp('only',    args)), OptionOnly='on';    else OptionOnly='off';   end
  if any(strcmp('single',  args)), OptionSingle='on';  else OptionSingle='off'; end
  if any(strcmp('nolabels',args)), OptionLabels='off'; else OptionLabels='on';  end
  if any(strcmp('ppt',     args)), OptionPPT='on';     else OptionPPT='off';    end
  if any(strcmp('fig',     args)), OptionFig='on';     else OptionFig='off';    end
else
  OptionPSD='off';
  OptionPSDE='off';
  OptionCOH='off';
  OptionOnly='off';
  OptionSingle='off';
  OptionLabels='on';
  OptionPPT='off';
  OptionFig='off';
end

% Determine whether to suppress timeseries plots
if any(strcmp({OptionPSD,OptionPSDE,OptionCOH},'on')) && strcmp(OptionOnly,'on')
  OptionTime = 'off';
else  % if no other plot specified, or 'only' not specified
  OptionTime = 'on';
end

% Limit time range as specified
DATA = arrayfun(@(x)LimitTimeRange(x,Trange),DATA);

% Derive casename (single or combination)
if isfield(DATA,'casename')
  if numel(DATA)==1 || isequal(DATA.casename)
    casename = DATA(1).casename;
  else  % if different, combine the names
    C = strcat('~',{DATA(2:end).casename})';
    C = [DATA(1).casename; C(:)];
    casename = strcat(C{:});
  end
else
  % If 'casename' field not present
  casename = '(untitled)';
end

% Collect Time signal groups
TIMES = cat(1,DATA.Time);

% Collect legend strings
if isfield(DATA,'source')
  Legend = {DATA.source};
else  % if no 'source' strings are available
  Legend = strcat({'Data'},arrayfun(@int2str,1:numel(DATA),'Uniform',false));
end

% Collect signals into master groups
C = arrayfun(@CollectSignals,DATA,'Uniform',false);
SIGNALS = cat(1,C{:});

% Set a tag string with a timestamp
tag = sprintf('PlotResults: %s', datestr(now));


% -----------------------------------------------------
%  Plot selected groups
% -----------------------------------------------------
Selections1 = intersect(Selections,Groups,'stable');
for k = 1:length(Selections1)

  % Get signal group name
  GroupName = Selections1{k};

  % Stack the groups with that name into an array
  SIGNALS1 = cat(1,DATA.(GroupName));

  % Plot the selected signals from the master group array
  PlotSignalGroup(TIMES,SIGNALS1,'groupname',GroupName, ...
                  'titlestr',sprintf('Casename: %s',casename),'Legend',Legend, ...
                  'OptionSingle',OptionSingle,'OptionTime',OptionTime,'OptionPSD',OptionPSD, ...
                  'OptionPSDE',OptionPSDE,'OptionCOH',OptionCOH,'OptionLabels',OptionLabels,'tag',tag);
end


% -----------------------------------------------------
%  Plot additional signal selections
% -----------------------------------------------------
names = setdiff(Selections,Groups,'stable');
if ~isempty(names)

  % Define a generic signal group name
  GroupName = 'additional selected signals';

  % Plot the selected signals from the master group array
  PlotSignalGroup(TIMES,SIGNALS,'names',names,'groupname',GroupName, ...
                  'titlestr',sprintf('Casename: %s',casename),'Legend',Legend, ...
                  'OptionSingle',OptionSingle,'OptionTime',OptionTime,'OptionPSD',OptionPSD, ...
                  'OptionPSDE',OptionPSDE,'OptionCOH',OptionCOH,'OptionLabels',OptionLabels,'tag',tag);
end


% -----------------------------------------------------
%  Finalizing / Saving
% -----------------------------------------------------
drawnow

% If saving to PowerPoint ...
if strcmp(OptionPPT,'on')
  fprintf('Saving to PowerPoint ...\n');
  handles = findobj('Tag',tag);
  handles = flipud(handles);

  fname = [casename,'.pptx'];
  if exist(fname,'file')
    prompt = sprintf('File "%s" exists and will be overwritten.  Append instead (y/n)? ',fname);
    resp = input(prompt,'s');
    if strcmp(resp,'y')
      exportToPPTX('open',fname);
    else
      exportToPPTX('new','Dimensions',[10,7.5]);
    end
  else
    exportToPPTX('new','Dimensions',[10,7.5]);
  end

  for h = handles'
    c = get(h,'Color');
    set(h,'Color','w')
    exportToPPTX('addslide');
    exportToPPTX('addpicture',h,'Scale','maxfixed');
    set(h,'Color',c)
    figure(h)
  end

  exportToPPTX('save',fname);
  exportToPPTX('close');
  fprintf('Done.\n');
end

% If saving .fig files ...
if strcmp(OptionFig,'on')
  fprintf('Saving figure files ...\n');
  handles = findobj('Tag',tag);
  handles = flipud(handles);

  % Ensure folder name is valid, and make the folder
  folder = casename;  % use single/combination casename
  if exist(folder,'file') && ~exist(folder,'dir')
    error('Extracted/derived casename points to an existing file.')
  elseif exist(folder,'dir')
    prompt = sprintf('Folder "%s" exists.  Overwrite files if names conflict (y/n)? ',casename);
    resp = input(prompt,'s');  if ~strcmp(resp,'y'), return, end
  else
    % Make new folder
    fprintf('Saving figures to folder "%s" ...\n',casename);
    try mkdir(folder), catch error('The folder name is invalid.'); end
  end

  % Save the figures
  for h = handles'
    fname = [get(h,'Name'),'.fig'];
    fprintf('  %s\n', fname);
    pathname = fullfile('.',folder,fname);
    hgsave(h,pathname);
  end
  fprintf('Done.\n');
end
