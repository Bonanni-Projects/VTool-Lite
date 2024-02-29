function [out1,out2] = CombineStatsFiles(pathnames,outfolder)

% COMBINESTATSFILES - Combine multiple "computed_stats" files into one.
% CombineStatsFiles(pathnames,outfolder)
% [Stats,Info] = CombineStatsFiles(pathnames)
%
% Combines the content from two or more "computed_stats_*.mat" files 
% into one file, to be saved to the 'outfolder' as "compute_stats.mat".  
% If output arguments are provided, the results are returned as output 
% structure array 'Stats' and information structure 'Info' instead. 
%
% Input 'pathnames' is a cell array of pathnames to the files to be 
% combined.  To qualify for combining, the individual files must have 
% been produced by "ComputeStatsArray" using the same calling options.  
% In addition, although the 'edges1' and 'edges2' options used for 
% generating the original files should be the same, the data represented 
% in the different files must fall in non-overlapping classification 
% bins (although multiple bins per input file are permissible). 
%
% The order of pathnames in the provided list is important, and should 
% correspond to strictly increasing values of the classification (i.e., 
% 'nameC') variable. 
%
% The process comes with this caveat: 
%   1) The percentile statistics ('p05','p50','p95') within the 
%      'GlobalStats' and 'GlobalErr' structures, which span across 
%      classification bins, are returned as NaN values.  Unlike 
%      'max', 'min', and 'mean', percentile statistics cannot be 
%      computed recursively from the bin-specific statistics. 
%
% P.G. Bonanni
% 6/24/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  outfolder = [];
end

% If single string provided
if ischar(pathnames)
  pathnames = cellstr(pathnames);
end

% Check inputs
if ~iscellstr(pathnames)
  error('Input ''pathnames'' is invalid.')
elseif ~(isnumeric(outfolder) && isempty(outfolder)) && ~ischar(outfolder)
  error('Input ''outfolder'' is invalid.')
elseif ~(isnumeric(outfolder) && isempty(outfolder)) && ~isdir(outfolder)
  error('Specified ''outfolder'' not found.')
end

% Extract filenames from pathnames
[~,NAM,EXT] = cellfun(@fileparts,pathnames,'Uniform',false);
fnames = strcat(NAM,EXT);

% Check if "collected_stats.mat" filename is used
if ismember('computed_stats.mat',fnames)
  error('The name "computed_stats.mat" is not permitted as an input filename.')
end

% Check for the standard naming pattern
if any(cellfun(@(x)~isempty(regexp(x,'^computed_stats_.*.mat','match')),pathnames))
  error('Inputs should be "computed_stats_*.mat" files.')
end

% If output arguments are supplied, 'outfolder' should be []
if nargout && ~(isnumeric(outfolder) && isempty(outfolder))
  error('Invalid usage.  No ''outfolder'' permitted if output arguments are supplied.')
end

% Derive output pathname
outfile = fullfile(outfolder,'computed_stats.mat');

% Load data from all files
try    % assemble structure array
  S = cellfun(@load,pathnames);
catch  % if file do not have uniform content
  error('One or more input files is invalid.')
end

% Collect 'Info' structures
INFO = cat(1,S.Info);

% Number of input files
nfiles = numel(pathnames);

% Check data compatibility
% --- Stats.name fields (and 'Stats' lengths)
C = arrayfun(@(x){x.Stats.name},S,'Uniform',false);
if ~isequal(C{:})
  error('Compatibility error: Stats arrays have inconsistent names.')
end
% --- Stats fieldnames
C = arrayfun(@(x)fieldnames(x.Stats),S,'Uniform',false);
if ~isequal(C{:})
  error('Compatibility error: Stats arrays have inconsistent fields.')
end
% --- Info parameter fields
fieldsX = {'fnames','fnamesF','edges1','edges2','iclass1','iclass2', ...
           'BinResults1','BinResults2','xvec'};  % excluded
s = rmfield(INFO,intersect(fieldnames(INFO),fieldsX));  C=num2cell(s);
if ~isequaln(C{:})
  error('Compatibility error: Info structures have inconsistent fields.')
end
% --- Bin boundaries
x = cat(2,INFO.edges1);
if any(diff(x) < 0)
  error('Compatibility error: Classification bins (''edges1'') overlap or are not specified in increasing order.')
end
x = cat(2,INFO.edges2);
if any(diff(x) < 0)
  error('Compatibility error: Classification bins (''edges2'') overlap or are not specified in increasing order.')
end
% --- Filename lists
for i = 1 : nfiles-1
  for j = i+1 : nfiles
    if ~isempty(intersect(INFO(i).fnames,INFO(j).fnames))
      error('Compatibility error: Info structures show ''fnames'' overlap.')
    end
  end
end

% Check frequency vector consistency
if isfield(S(1).Stats,'f')
  C = arrayfun(@(x)x.Stats(1).f,S,'Uniform',false);
  if ~isequal(C{:})
    error('Compatibility error: Frequency vectors ''f'' differ.')
  end
end

% -----------------------------
% COMBINE 'INFO' STRUCTURES
% -----------------------------

% Adjust the 'iclass1' and 'iclass2' index values
for k = 1:length(S)
  iclass1 = INFO(k).iclass1;
  iclass2 = INFO(k).iclass2;
  iclass1(iclass1 > 0) = iclass1(iclass1 > 0) + INFO(k).BinResults1(1).index - 1;
  iclass2(iclass2 > 0) = iclass2(iclass2 > 0) + INFO(k).BinResults2(1).index - 1;
  INFO(k).iclass1 = iclass1;
  INFO(k).iclass2 = iclass2;
end

% Build combined 'Info' structure
Info = INFO(1);  % initialize
Info.fnames      = cat(1,INFO.fnames);
Info.fnamesF     = unique(cat(1,INFO.fnamesF),'stable');
Info.edges1      = unique(cat(2,INFO.edges1), 'stable');
Info.edges2      = unique(cat(2,INFO.edges2), 'stable');
Info.xvec        = cat(1,INFO.xvec);
Info.iclass1     = cat(1,INFO.iclass1);
Info.iclass2     = cat(1,INFO.iclass2);
Info.BinResults1 = cat(1,INFO.BinResults1);
Info.BinResults2 = cat(1,INFO.BinResults2);

% -----------------------------
% COMBINE 'STATS' ARRAYS
% -----------------------------

% Initialize
Stats = S(1).Stats;

% Get fieldnames
fields = fieldnames(Stats);

% Loop over 'Stats' fields
for k = 1:length(fields)
  field = fields{k};

  % Perform concatenation for the field
  for j = 1:length(Stats)

    % Collect the field from all array elements into a cell array
    C = arrayfun(@(x)x.Stats(j).(field),S,'Uniform',false);

    % If field is 'PsdStats', 'ErrPsdStats', or 'RelPsdStats'
    if ~isempty(regexp(field,'PsdStats$','match'))
      Stats(j).(field) = CombineStats(3,C{:});

    % ... if field is any other structure with the standard statistical fields
    elseif isstruct(Stats(j).(field)) && ... 
           all(ismember(fieldnames(Stats(j).(field)),{'min','max','mean','p05','p50','p95'}))
      Stats(j).(field) = CombineStats(1,C{:});

    % ... if field is a signal group array, like 'PSD', 'ErrPSD', and 'RelPSD'
    elseif IsSignalGroupArray(Stats(j).(field))
      Stats(j).(field) = cat(1,C{:});

    end
  end
end

% -----------------------------
% CONSOLIDATE THE GLOBAL STATS
% -----------------------------

% Combine stats recursively
nvec = arrayfun(@(x)sum([x.Info.BinResults1.cases]),S);  % number of cases per file
nsignals = length(Info.Selections);
for k = 1:length(Stats)
  Stats(k).GlobalStats.min  = min(Stats(k).GlobalStats.min);
  Stats(k).GlobalStats.max  = max(Stats(k).GlobalStats.max);
  Stats(k).GlobalStats.mean = (nvec' * Stats(k).GlobalStats.mean) / sum(nvec);
  Stats(k).GlobalStats.p05  = nan(1,nsignals);  % cannot be computed
  Stats(k).GlobalStats.p50  = nan(1,nsignals);  % cannot be computed
  Stats(k).GlobalStats.p95  = nan(1,nsignals);  % cannot be computed
  % ---
  Stats(k).GlobalErr.min  = min(Stats(k).GlobalErr.min);
  Stats(k).GlobalErr.max  = max(Stats(k).GlobalErr.max);
  Stats(k).GlobalErr.mean = (nvec' * Stats(k).GlobalErr.mean) / sum(nvec);
  Stats(k).GlobalErr.p05  = nan(1,nsignals);  % cannot be computed
  Stats(k).GlobalErr.p50  = nan(1,nsignals);  % cannot be computed
  Stats(k).GlobalErr.p95  = nan(1,nsignals);  % cannot be computed
end


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



% -----------------------------------------------------------------------
function stat = CombineStats(dim,varargin)

% Combine multiple statistics structures into one. 
% Usage: stat = CombineStats(dim,stat1,stat2,stat3,...)
% Given a variable number of 'stat' structures, containing fields 
% 'min', 'max', 'mean', 'p05', 'p50', 'p95', return the combined 
% 'stat' with the same fields, but with data concatenated. Input 
% 'dim' specifies the dimension along which to concatenate. 

% Check that inputs are structures
if ~all(cellfun(@isstruct,varargin))
  error('One or more inputs is invalid.')
end

% Check that correct fields are present
C = cellfun(@fieldnames,varargin,'Uniform',false);
if ~isequal(C{:}) || ~isempty(setxor(C{1},{'min','max','mean','p05','p50','p95'}))
  error('One or more inputs is invalid.')
end

% Perform the concatenation
S = cat(1,varargin{:});  % make structure array
C=arrayfun(@(x)x.min, S,'Uniform',false); stat.min  = cat(dim,C{:});
C=arrayfun(@(x)x.max, S,'Uniform',false); stat.max  = cat(dim,C{:});
C=arrayfun(@(x)x.mean,S,'Uniform',false); stat.mean = cat(dim,C{:});
C=arrayfun(@(x)x.p05, S,'Uniform',false); stat.p05  = cat(dim,C{:});
C=arrayfun(@(x)x.p50, S,'Uniform',false); stat.p50  = cat(dim,C{:});
C=arrayfun(@(x)x.p95, S,'Uniform',false); stat.p95  = cat(dim,C{:});
