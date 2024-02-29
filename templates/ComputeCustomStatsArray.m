function [out1,out2] = ComputeCustomStatsArray(pathname,outfolder)

% COMPUTECUSTOMSTATSARRAY - Compute custom statistics from a signal group array.
% ComputeCustomStatsArray(pathname [,outfolder])
% [Stats,Info] = ComputeCustomStatsArray(...)
%
% Computes a "Stats structure" from a saved signal group array. 
% Fields of 'Stats' represent user-defined statistics for the signal 
% group array found in a "collected_signals_*.mat" file (as produced, 
% for example, by functions "CollectSignalsFromFiles" or 
% "CollectSignalsFromResults"). Parameter 'pathname' specifies the 
% pathname to the input file.  The signal group array in the file 
% is assumed to be data-length uniform. 
%
% If output arguments are not provided, the 'Stats' structure is 
% saved in a mat-file either to the current working directory or to 
% an optionally specified 'outfolder', with filename derived from 
% the input filename by replacing the string 'collected_signals' 
% with 'computed_stats'. 
%
% As a supplement to 'Stats', a scalar 'Info' structure is also 
% stored in the output file, or returned.  This structure captures 
% additional information resulting from the statistical processing. 
%
% P.G. Bonanni
% 5/4/23

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% If output argument is supplied, 'outfolder' should be []
if nargout && nargin==2
  error('Invalid usage.  No ''outfolder'' permitted if output argument is supplied.')
end

% Default 'outfolder'
if nargin < 2
  outfolder = '.';
end

% Check 'pathname' argument and get rootname
if ~ischar(pathname)
  error('Invalid ''pathname'' input.')
end
[~,rootname,ext] = fileparts(pathname);  % rootname and extension
if ~strncmp(rootname,'collected_signals',length('collected_signals')) || ~strcmp(ext,'.mat')
  error('Input file name ''%s'' is not valid.',[rootname,ext])
elseif ~exist(pathname,'file')
  error('Input file ''%s'' not found.',pathname)
end

% Check 'outfolder'
if ~ischar(outfolder)
  error('Parameter ''outfolder'' is not valid.')
elseif ~isdir(outfolder)
  error('Destination folder ''%s'' does not exist.',outfolder)
end

% Derive output pathname
rootname1 = strrep(rootname,'collected_signals','computed_stats');
outfile = fullfile(outfolder,[rootname1,'.mat']);

tic

% Load input data
fprintf('Loading collected signals ... ');
load(pathname)
fprintf('done.\n');

% Number of cases
N = length(SIGNALS);

% Get the min and max sample time.
% Consider only the first element in the group array.
TsValues = [];
t = TIMES(1).Values;
if isa(t,'datetime')                 % if 'datetime' type
  dt = diff(t);  dt=seconds(dt);
elseif isnumeric(t) && min(t) > 1e5  % assume 'datenum' type
  dt = diff(t)*86400;  % sec
  dt = double(dt);
elseif isnumeric(t)                  % real type
  dt = diff(t);
  dt = double(dt);
else
  error('Time vector has invalid type.')
end
TsValues = [TsValues; min(dt); max(dt)];

% If 'Ts' info was extracted
if ~isempty(TsValues)

  % Sample time range
  TSrange = [min(TsValues),max(TsValues)];

  % Check results
  if any(TsValues <= 0)
    Ts = [];
    TsFlag = -2;  % sampling is not monotonic
  elseif diff(TSrange)/min(TsValues) > 0.002
    Ts = [];
    TsFlag = -1;  % sample time is not constant
  else
    Ts = TsValues(1);
    TsFlag = 1;   % sampling is uniform and valid
  end
else
  Ts = [];
  TsFlag = 0;     % sampling info not available
end

% Check sampling
if isempty(Ts)
  switch TsFlag
    case  0, fprintf('Warning: Sampling time information not available.\n')
    case -1, fprintf('Warning: Sample time is not constant.\n')
    case -2, fprintf('Warning: Sampling is not monotonic.\n')
  end
end

% Compute statistics
[Stats,Cval] = ComputeStStatsByBin(SIGNALS,1:N);
C = cellfun(@(x)std(x,0,1),Cval,'Uniform',false);
Stats.std = cat(1,C{:});
C = cellfun(@(x)x(1,:),Cval,'Uniform',false);
Stats.first = cat(1,C{:});
C = cellfun(@(x)x(end,:),Cval,'Uniform',false);
Stats.last = cat(1,C{:});

% Build 'Info' structure
Info.fnames     = fnames;
Info.ArrayName0 = 'SIGNALS';
Info.Selections = SIGNALS.Names;
Info.nameF      = [];
Info.rangesF    = [];
Info.valuesF    = [];
Info.fnamesF    = [];
Info.nameC      = [];
Info.spectral   = [];
Info.edges1     = [];
Info.edges2     = [];
Info.Ts         = Ts;

% Return or store results
if nargout
  out1 = Stats;
  out2 = Info;
else
  fprintf('Storing results to "%s" ... ',outfile);
  save(outfile,'Stats','Info')
  fprintf('done.\n');
  fprintf('\n');
end

toc
