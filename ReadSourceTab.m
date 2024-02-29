function [Names,Factors,Units,Descriptions,TabInfo] = ReadSourceTab(sourcetype,pathname)

% READSOURCETAB - Read a "source tab" from "NameTables.xlsx".
% [Names,Factors,Units,Descriptions,TabInfo] = ReadSourceTab(sourcetype)
% [Names,Factors,Units,Descriptions,TabInfo] = ReadSourceTab(sourcetype,pathname)
%
% Reads the tab referred to by input string 'sourcetype' within 
% "NameTables.xlsx" and returns the information in structure array 
% outputs (Names,Factors,Units,Descriptions).  Each structure array 
% has fields corresponding to signal groups defined in the spreadsheet.  
% Values within 'Names', 'Factors', 'Units', and 'Descriptions' contain 
% the signal names, conversion factors, units designations, and signal 
% descriptions, respectively, as read from the spreadsheet. 
%
% Output 'TabInfo' is a structure array containing the same information 
% organized into a single structure array of length equal to the total 
% number of signal names read from the source tab worksheet.  Each 
% element TabInfo(i) has the following fields pertaining to the ith 
% signal name: 
%    'group'        -  group name
%    'name'         -  signal name
%    'factor'       -  conversion factor
%    'units'        -  units string
%    'description'  -  description string
%
% Note: The "MASTER" tab is not a "source tab", and is not a valid 
% value for 'sourcetype'. 
%
% If the optional 'pathname' argument is supplied, the function reads 
% the specified file in place of the default "NameTables.xlsx" file. 
%
% P.G. Bonanni
% 2/15/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  pathname = 'NameTables.xlsx';
end

% Read raw data from the designated tab
[~,~,C] = xlsread(pathname,sourcetype);

% Discard columns with no header
mask = cellfun(@(x)~ischar(x)||isempty(x), C(1,:));
C(:,mask) = [];

% Check headers
Headers0 = {'Group','Signal','Factor','Units','Comments','Descriptions'};
Headers = C(1,:);
if ~all(ismember(Headers0,Headers))
  error('Source tab has invalid or missing headers.')
end

% Retain only required columns
[~,i] = ismember(Headers0,Headers);
C = C(:,i);  % re-order
C = C(:,[1:4,6]);

% Remove first line
C(1,:) = [];

% Remove blank lines
mask = cellfun(@(x)isnumeric(x)&&isnan(x),C(:,1));
C(mask,:) = [];

% In 'Factor' column, replace NaNs by '' and '*' by NaN
mask = cellfun(@(x)isnumeric(x)&&isnan(x),  C(:,3));  [C{mask,3}]=deal('');
mask = cellfun(@(x)ischar(x)&&strcmp(x,'*'),C(:,3));  [C{mask,3}]=deal(NaN);

% Replace NaNs by '' in 'Units' and 'Descriptions' columns
mask = cellfun(@(x)isnumeric(x)&&isnan(x),C(:,4));  [C{mask,4}]=deal('');
mask = cellfun(@(x)isnumeric(x)&&isnan(x),C(:,5));  [C{mask,5}]=deal('');

% Loop over signal groups
for group = unique(C(:,1),'stable')'
  mask = strcmp(group{:},C(:,1));
  Names.(group{:})        = C(mask,2);  % cell array w/ signal names
  Factors.(group{:})      = C(mask,3);  % cell array w/ conversion factors
  Units.(group{:})        = C(mask,4);  % cell array w/ new units
  Descriptions.(group{:}) = C(mask,5);  % cell array w/ new descriptions
end

% Build 'TabInfo' structure
fields = {'group','name','factor','units','description'};
TabInfo = cell2struct(C,fields,2);
