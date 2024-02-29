function WriteDataToCSV(outfile,Data,layer)

% WRITEDATATOCSV - Write dataset signals to a CSV file.
% WriteDataToCSV(outfile,Data,layer)
%
% Writes all signals in dataset 'Data' to the CSV file specified 
% by 'outfile'. Variable names are taken from the specified 'layer', 
% and signals with empty names are ignored.  If a file with the 
% specified name already exists, it is overwritten.  Conversion to 
% Excel date numbers is applied if the time vector is in absolute 
% units. 
%
% P.G. Bonanni
% 7/26/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'outfile' input
if ~ischar(outfile)
  error('Input ''outfile'' is invalid.')
end

% Check 'Data' input
[flag,valid,errmsg] = IsDataset(Data);
if ~flag
  error('Input #2 is not a dataset: %s',errmsg)
elseif ~valid
  error('Input #2 is not a valid dataset: %s  See "IsDataset".',errmsg)
end

% Collect all signals
Signals = CollectSignals(Data);

% In case 'layer' is a source string ...
layer = Source2Layer(layer);

% Check that 'layer' is valid
if ~isfield(Signals,layer)
  error('Specified ''layer'' is not a valid name layer.')
end

% Get variable names
names = Signals.(layer);

% Keep only signals with non-empty names
index = find(cellfun(@isempty,names));
Signals = RemoveFromGroup(index,Signals);

% Build and write header line
header = sprintf('%s,',Signals.(layer){:});
header = ['Time,',header(1:end-1)];
fid = fopen(outfile,'w');
fprintf(fid,'%s\n',header);
fclose(fid);

% Get time vector
t = GetTime(Data);

% If 't' is in absolute units
if ismember(Data.Time.Units{1},{'datetime','datenum'})

  % Excel offset time (NOTE: Subtraction of 2 days 
  % from the 1/1/1900 reference date disagrees with 
  % published articles, but is required for accurate 
  % time conversion. 
  ExcelOffset = datenum('1-Jan-1900') - 2;

  % Convert time values
  if strcmp(Data.Time.Units{1},'datetime')
    t = datenum(t) - ExcelOffset;
  elseif strcmp(Data.Time.Units{1},'datenum')
    t = t - ExcelOffset;
  end
end

% Write data lines, with time included
dlmwrite(outfile,[t,Signals.Values],'precision',10,'-append')
