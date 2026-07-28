function videoPath = exportISACVideo(results, config)
%EXPORTISACVIDEO Export stored ISAC frames to an AVI video.
%
%   videoPath = exportISACVideo(results, config)
%
%   The function uses the frames already stored in results.frames, so the
%   channel simulation is not executed again.

    %% Validate inputs

    if nargin < 1 || isempty(results)
        error("A results structure must be provided.");
    end

    if ~isfield(results, "frames") || isempty(results.frames)
        error( ...
            ["No playback frames are available. Run the simulation with " ...
             "config.storePlaybackFrames = true."]);
    end

    if nargin < 2 || isempty(config)

        if isfield(results, "config")
            config = results.config;
        else
            config = defaultConfig();
        end
    end

    %% Output directory

    outputDirectory = string(config.outputDirectory);

    if ~isfolder(outputDirectory)
        mkdir(outputDirectory);
    end

    videoFileName = string(config.videoFileName);

    [~, baseName, extension] = fileparts(videoFileName);

    if extension == ""

        videoFileName = videoFileName + ".avi";

    elseif ~strcmpi(extension, ".avi")

        warning( ...
            "The video will be exported as Motion JPEG AVI.");

        videoFileName = string(baseName) + ".avi";
    end

    videoPath = fullfile( ...
        outputDirectory, ...
        videoFileName);

    %% Configure video writer

    writer = VideoWriter( ...
        char(videoPath), ...
        "Motion JPEG AVI");

    writer.FrameRate = config.videoFrameRate;
    writer.Quality = 95;

    %% Create rendering figure

    videoFigure = figure( ...
        "Name", "ISAC Video Export", ...
        "NumberTitle", "off", ...
        "Color", "w", ...
        "Position", [100 100 1280 720], ...
        "Visible", "on");

    videoLayout = tiledlayout( ...
        videoFigure, ...
        1, ...
        2, ...
        "Padding", "compact", ...
        "TileSpacing", "compact");

    scenarioAxes = nexttile(videoLayout);
    rangeAoAAxes = nexttile(videoLayout);

    %% Export frames

    writerOpened = false;

    try

        open(writer);
        writerOpened = true;

        numFrames = numel(results.frames);

        for frameIndex = 1:numFrames

            statusText = renderISACFrame( ...
                scenarioAxes, ...
                rangeAoAAxes, ...
                results, ...
                frameIndex);

            title(videoLayout, ...
                statusText, ...
                "Interpreter", "none");

            drawnow;

            capturedFrame = getframe(videoFigure);

            writeVideo(writer, capturedFrame);

            fprintf( ...
                "Exporting video frame %d of %d\n", ...
                frameIndex, ...
                numFrames);
        end

        close(writer);
        writerOpened = false;

        if isgraphics(videoFigure)
            close(videoFigure);
        end

    catch exception

        if writerOpened
            close(writer);
        end

        if isgraphics(videoFigure)
            close(videoFigure);
        end

        rethrow(exception);
    end

    fprintf( ...
        "ISAC video exported successfully:\n%s\n", ...
        videoPath);
end