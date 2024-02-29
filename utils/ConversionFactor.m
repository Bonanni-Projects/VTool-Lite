function factor = ConversionFactor(units1,units2)

% CONVERSIONFACTOR - Conversion factor between units.
% factor = ConversionFactor(units1,units2)
%
% Returns the multiplication factor for conversion 
% from units string 'units1' to 'units2'. 
%
% P.G. Bonanni
% 8/12/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


Table1 = { ...
  'G'  1e9
  'M'  1e6
  'k'  1e3
  'c'  1e-2
  'm'  1e-3
  'u'  1e-6
  'n'  1e-9
  };

Table2 = { ...
  'deg'      'rad'       pi/180
  'rpm'      'rad/s'     2*pi/60
  'rpm/s'    'rad/s^2'   2*pi/60
  'rpm'      'deg/s'     60
  'rpm/s'    'deg/s^2'   60
  'in'       'mm'        25.40
  'in'       'm'         0.0254
  'ft'       'm'         0.3048
  'mi'       'ft'        5280
  'mi'       'm'         1609.344
  'mi'       'km'        1.609344
  'mph'      'km/h'      1.609344
  'mph'      'ft/s'      1.466667
  'nmi'      'km'        1.8520045
  'mi'       'nmi'       0.8684
  'lb'       'kg'        0.4536
  'qt'       'lt'        0.9463
  'mbar'     'Pa'        100
  'hr'       'sec'       3600
  'hrs'      'sec'       3600
  'min'      'sec'       60
  'hr'       'min'       60
  'hrs'      'min'       60
  };

% Check inputs
if ~ischar(units1) || ~ischar(units2)
  error('Invalid input type.  Inputs must be character strings.')
elseif isempty(units1) || isempty(units2)
  error('Empty strings are not valid.')
end

% Trivial case
if strcmp(units1,units2)
  factor = 1;
  return
end

% Next, check if strings differ by a prefix listed in 'Table1'
if (length(units1) > length(units2)) && ...
   strcmp(units1(2:end),units2) && ...
   ismember(units1(1),Table1(:,1))
  mask = strcmp(units1(1),Table1(:,1));
  factor = Table1{mask,2};
  return
elseif (length(units2) > length(units1)) && ...
   strcmp(units2(2:end),units1) && ...
   ismember(units2(1),Table1(:,1))
  mask = strcmp(units2(1),Table1(:,1));
  factor = 1/Table1{mask,2};
  return
end

% Remove common trailing characters appearing in rate units
pat = '/[a-zA-Z0-9\-\^]+$';  % i.e., '/s', '/sec^2', etc.
if strcmp(regexp(units1,pat,'match','once'),regexp(units2,pat,'match','once'))
  units1 = regexprep(units1,pat,'');
  units2 = regexprep(units2,pat,'');
end

% Finally, check against combinations in 'Table2'
mask1 = strcmp(units1,Table2(:,1));
mask2 = strcmp(units2,Table2(:,2));
if any(mask1 & mask2)
  factor = Table2{mask1 & mask2, 3};
  return
end
mask1 = strcmp(units2,Table2(:,1));
mask2 = strcmp(units1,Table2(:,2));
if any(mask1 & mask2)
  factor = 1/Table2{mask1 & mask2, 3};
  return
end

% Otherwise return NaN
factor = NaN;
