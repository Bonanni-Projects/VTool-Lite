function [Names,SourceType,Layers,ALLNAMES] = ReadMasterLookup(pathname)

% READMASTERLOOKUP - Read MASTER lookup table.
% [Names,SourceType,Layers,ALLNAMES] = ReadMasterLookup
% [Names,SourceType,Layers,ALLNAMES] = ReadMasterLookup(pathname)
%
% Reads the "MASTER" tab of "NameTables.xlsx" and returns two output 
% structures, 'Names' and 'SourceType', plus cell arrays 'Layers' and 
% 'ALLNAMES'.  Fields of 'Names' correspond to groups listed in the 
% spreadsheet, which are themselves structures.  Fields of these 
% group structures correspond to columns of the spreadsheet (a.k.a. 
% "name layers"), and the contents of these fields are matching sets 
% of ordered name lists for the group.  The list of name layers is 
% returned as cell array 'Layers', and the complete matrix of names, 
% having the name layers as columns, is returned as cell array 
% 'ALLNAMES'. 
%
% The fields of 'SourceType' are layer names that correspond to columns 
% of the MASTER tab spreadsheet (e.g., 'Layer1Names', 'Layer2Names' ...). 
% The 'Names' ending is appended if not already present.  The value 
% assigned to each field indicates the "source type for each layer, 
% which is information contained on the second row of the MASTER tab 
% spreadsheet.  Sources are uniquely tied to name layers (via functions 
% "Source2Layer" and "Layer2Source"), but may share "source types" with 
% other name layers (e.g., compare rows 1 and 2 of MASTER tab in 
% "NameTables (sample).xlsx"). 
%
% Source types are associated with additional tabs in he "NameTables.xls" 
% workbook.  The tabs contain the lists of names coming from each source 
% type, with corresponding conversion factors and units.  See function 
% "ReadSourceTab", which reads the information in these tabs. 
%
% If the optional 'pathname' argument is supplied, the function reads 
% the specified file in place of the default "NameTables.xlsx" file. 
%
% P.G. Bonanni
% 2/15/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin == 0
  pathname = 'NameTables.xlsx';
end

% Read raw data from Excel file
[~,~,C] = xlsread(pathname,'MASTER');
C(:,end) = [];  % remove last column, containing "<---- ..." and comments

% Replace NaNs by ''
mask = cellfun(@(x)isnumeric(x)&&isnan(x),C(:));
[C{mask}] = deal('');

% Read then remove first line ("Source / Name Layers" line)
Columns = C(1,:);  C(1,:)=[];
Layers = Columns(2:end)';
if any(cellfun(@isempty,Layers))
  error('One or more name columns is not labeled.')
end
% Convert any "source" strings to name layers
Layers = cellfun(@Source2Layer,Layers,'Uniform',false);

% Read then remove next line ("Source Types" line)
Columns = C(1,:);  C(1,:)=[];
SourceTypes = Columns(2:end)';

% Remove lines with no "Group" indicated in first column
mask = cellfun(@isempty,C(:,1));
C(mask,:) = [];  ALLNAMES=C;

% Collect group names
Groups = unique(ALLNAMES(:,1),'stable');

% Build 'Names' structure
for k = 1:length(Groups)
  group = Groups{k};
  mask = strcmp(group,ALLNAMES(:,1));
  for j = 1:length(Layers)
    layer = Layers{j};
    Names.(group).(layer) = ALLNAMES(mask,1+j);
  end
end

% Build 'SourceType' structure
C1 = [Layers'; SourceTypes'];
SourceType = struct(C1{:});

% Remove first column of 'ALLNAMES'
ALLNAMES(:,1) = [];
