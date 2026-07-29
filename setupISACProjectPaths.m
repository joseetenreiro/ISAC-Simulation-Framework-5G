function projectRoot = setupISACProjectPaths()
%SETUPISACPROJECTPATHS Configure portable project paths.
%
%   PROJECTROOT = SETUPISACPROJECTPATHS() adds the project root,
%   source folders and data folder to the MATLAB path.
%
%   The function works regardless of where the repository is installed.

    projectRoot = fileparts(mfilename("fullpath"));

    sourceDirectory = fullfile(projectRoot, "src");
    dataDirectory = fullfile(projectRoot, "data");

    % Public entry points.
    addpath(projectRoot);

    % Internal framework source files.
    if isfolder(sourceDirectory)
        addpath(genpath(sourceDirectory));
    end

    % Scenario data.
    if isfolder(dataDirectory)
        addpath(dataDirectory);
    end

    rehash;

    if nargout == 0
        fprintf( ...
            "ISAC project configured from:\n%s\n", ...
            projectRoot);
    end
end