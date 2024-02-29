function RunBatchFunction(fun,varargin)

% RUNBATCHFUNCTION - Run a batch function on one or more data files.
% RunBatchFunction(fun,pathname)
% RunBatchFunction(fun,pathnames)
% RunBatchFunction(fun,dname,filetype)
% RunBatchFunction(..., 'parfor')
%
% Files used: "include.txt"
%             "exclude.txt"
%
% Runs the batch function specified by function handle 'fun' on either 
% searched or directly specified input files, depending on the calling 
% syntax employed, with option to use a parallel worker pool. 
%
% The batch function is any function of a single pathname variable, 
% but may accept additional arguments via Matlab's "anonymous function" 
% construct.  The function is assumed to store any required results to 
% a .mat file, with the naming convention "results_*.mat" recommended. 
%
% In the simplest form, if one or more 'pathnames' to files(s) are 
% provided, the function is run on all named files.  If directory 
% 'dname' and file type specification 'filetype' are provided, the 
% function is run on all files in 'dname' matching the specified type. 
% For a description of file formats and defining characteristics,  
% type "help formats" and see function "IsFileType". 
%
% As an alternative to operation on all files found, specific filenames 
% to be included may be listed in a file "include.txt" placed either 
% in the current working directory or the 'dname' folder.  That file 
% may list either simple filenames or full pathnames.  Similarly, if 
% some files are to be excluded, those filenames or pathnames should 
% be listed in a file called "exclude.txt" and the file placed in the 
% working directory or 'dname' folder.  The "include.txt" file, if 
% found, is read before any "exclude.txt" file.  If these files are 
% found in both locations, the current working directory takes 
% precedence. 
%
% The restriction that input files be resident under a single 'dname' 
% folder can be overcome by direct specification of pathnames via input 
% cell array 'pathnames'. This overrides both the filename search and 
% the filtering for inclusions/exclusions. (See function "FindFilesOfType" 
% and related functions for additional search options.)
%
% If the keyword 'parfor' is provided as a final argument, the Matlab 
% "parfor" command is invoked, and the job is executed employing worker 
% processes in a parallel pool. 
%
% If any cases fail to run successfully, the names are listed in a 
% file "failed.txt" and saved to the current working directory. 
%
% P.G. Bonanni
% 11/9/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


args = varargin;
if isempty(args)
  error('Invalid usage.')
end
if strcmp(args{end},'parfor')
  ParForOption = true;
  args(end) = [];
else
  ParForOption = false;
end
if isempty(args)
  error('Invalid usage.')
end
if length(args) == 1
  inp      = args{1};
  filetype = [];
elseif length(args) == 2
  inp      = args{1};
  filetype = args{2};
else
  error('Invalid usage.')
end

% Report start time
fprintf('Start Time: %s\n',datestr(now));
fprintf('\n');

% Check function-handle input
if ~isa(fun,'function_handle')
  error('Input ''fun'' is not a valid function handle.')
end

% If a single file pathname given ...
if ischar(inp) && ~isdir(inp)
  inp = cellstr(inp);
end

% Check for 'filetype' argument
if ischar(inp) && isempty(filetype)
  error('Input ''filetype'' is missing or invalid.')
end

% Derive input pathnames (and filenames)
if ischar(inp)  % if folder specified ...

  % Find files of the specified type, conditioned by any inclusions/exclusions
  [pathnames,fnames] = FindFilesOfType(inp,filetype,0);

elseif iscell(inp)  % if cell-array specified ...

  % Pathnames specified directly
  pathnames = inp;

  % Check for non-empty 'filetype'
  if ~isempty(filetype)
    error('Incorrect usage: ''filetype'' not applicable if pathname(s) specified directly.')
  end

  % Extract filenames
  [~,rootnames,exts] = cellfun(@fileparts,pathnames,'Uniform',false);
  fnames = strcat(rootnames,exts);

else
  error('Invalid input.')
end

% If list is empty
if isempty(pathnames)
  fprintf('No files to process!\n');
  return
end

% Number of cases
ncases = length(pathnames);

% Report the final resulting number
fprintf('Number of files to be processed: %d\n',ncases);

% Initialize
FailedCases = {};

% Start timer clock
T0 = clock;

% Loop over pathnames
if ParForOption

  % Open parallel pool
  pool = parpool;

  % Loop over all cases
  parfor k = 1:ncases
    pathname = pathnames{k};

    fprintf('==========================================================================================\n');
    fprintf('Running case %d of %d\n',k,ncases);
    disp(pathname)

    try
      % Run batch function on the case
      fun(pathname);
    catch err
      FailedCases = [FailedCases; pathname];
      fprintf('  *** ERROR: Input file "%s" rejected by batch function.\n',fnames{k});
      fprintf('      The identifier was: %s\n', err.identifier);
      fprintf('      The message was: %s\n', err.message);
      fprintf('\n');
    end
  end

  % Close the pool
  delete(pool)

else

  % Loop over all cases
  for k = 1:ncases
    pathname = pathnames{k};

    fprintf('==========================================================================================\n');
    fprintf('Running case %d of %d\n',k,ncases);
    disp(pathname)

    try
      % Run batch function on the case
      fun(pathname);
    catch err
      FailedCases = [FailedCases; pathname];
      fprintf('  *** ERROR: Input file "%s" rejected by batch function.\n',fnames{k});
      fprintf('      The identifier was: %s\n', err.identifier);
      fprintf('      The message was: %s\n', err.message);
      fprintf('\n');
    end

    % Estimate completion time at reasonable intervals
    if ncases >= 10 && (k == 5 || ((k >= 20) && (fix(10*k/ncases) ~= fix(10*(k-1)/ncases))))
      elapsed   = etime(clock,T0);   % elapsed time (sec)
      duration1 = elapsed/k;         % time per case (sec)
      duration  = ncases*duration1;  % estimated total duration (sec)
      fprintf('##########################################################################################\n');
      fprintf('        Time per case: %.1f sec\n', duration1);
      fprintf('       Time remaining: %.1f hours\n', (duration-elapsed)/3600);
      fprintf(' Estimated completion: %s\n', datestr(datetime(T0) + seconds(duration)));
      fprintf('##########################################################################################\n');
      fprintf('\n');
    end
  end

end

% Report success/failures
failedfile = 'failed.txt';  failedfilepath=fullfile('.',failedfile);
if ncases > 0 && isempty(FailedCases) && ~exist(failedfilepath,'file')
  fprintf('All cases successful.\n');
  fprintf('\n');
elseif ncases > 0 && isempty(FailedCases) && exist(failedfilepath,'file')
  delete(failedfilepath)
  fprintf('All cases successful.  Old file "failed.txt" deleted.\n');
  fprintf('\n');
elseif ncases > 0
  % Report failures
  n = length(FailedCases);
  if n < 20
    fprintf('These cases failed:\n');
    disp(FailedCases)
  else
    fprintf('Failed cases: %d\n',n);
  end
  fprintf('Saving to file "%s".\n',failedfile)
  fid = fopen(failedfilepath,'w');
  fprintf(fid,'%s\r\n',FailedCases{:});
  fclose(fid);
  fprintf('\n');
elseif ncases == 0 && exist(failedfilepath,'file')
  fprintf('NOTE: Old file "failed.txt" detected but NOT deleted.\n');
  fprintf('\n');
else
  fprintf('\n');
end

% Report final time stats
duration = etime(clock,T0);
fprintf('End Time: %s\n',datestr(now));
if duration > 3600
  fprintf('Duration: %.1f hours.\n',duration/3600);
elseif duration >= 60
  fprintf('Duration: %.1f minutes.\n',duration/60);
else
  fprintf('Duration: %.1f seconds.\n',duration);
end
fprintf('\n');
