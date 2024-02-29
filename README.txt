VTool - "Validation Toolbox"	by Pierino G. Bonanni, Ph.D.

    A toolbox for construction, comparison, and analysis of datasets 
    consisting of named signals and associated attributes.  Features 
    include time series, spectral, and statistical analysis, plotting, 
    flexible I/O, and full support for name "layering", i.e., aliasing. 

    The toolbox extends the reach of Matlab's signal processing 
    capabilities by enabling bulk processing of large numbers of data 
    files, wherein the user controls naming and organization of signals 
    into groups.

    VTool serves as a platform for generalized signal processing algorithm 
    development, and as a programming environment kernel on which to base 
    more domain-specific applications.  It has been vetted within an 
    industrial research environment since 2018. 


    INSTRUCTIONS

    Inside Matlab:

    1) cd to any working directory 
    2) On Windows, with MS Explorer window open to the VTool folder, drag 
       the VTool startup.m" file from the MS Explorer window into the Matlab 
       command window.  Alternatively, type "run <pathname>\startup", 
       where <pathname> is the pathname to the VTool folder, e.g., 
       >> run C:\...\GITHUB\VTool-Lite\startup

    Start by building datasets using "BuildDatasetFromData" (to assemble 
    data from the Matlab workspace), or "ExtractData" (to read data from a 
    file), or "BuildDataset" (to structure input data into groups, add 
    name layers, and employ unit conversions, per the specifications in 
    a "NameTables.xlsx" file). Then try out the options in "PlotDataset" 
    for plotting. 

    File "NameTables (sample).xlsx" is provided as an example.  It 
    should be renamed to "NameTables.xlsx", moved to a suitable working 
    directory, and edited as needed, before use. 

    Help is available on all functions.  Type "help vtool" or view the 
    "HELP.html" file found in the main folder.  Further documentation 
    in the form of a User's manual or tutorial document is planned. Visit 
    github.com/Bonanni-Projects/VTool-Lite for updates. 



    Copyright (C) 2024  Pierino G. Bonanni

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


    Training in the full set of features, and customization to permit 
    input of proprietary formats or further application building may 
    be available.  Contact the author at bonanni@alum.mit.edu. 
