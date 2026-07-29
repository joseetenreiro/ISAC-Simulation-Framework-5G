function playISACResults(results)
%PLAYISACRESULTS Interactive playback of stored ISAC simulation frames.
%
%   PLAYISACRESULTS(RESULTS) opens an interactive viewer using a standard
%   MATLAB figure. Playback is controlled by a timer, so the interface
%   remains responsive while frames are being displayed.

    %% Validate input

    if nargin < 1 || isempty(results)
        error("A results structure must be provided.");
    end

    if ~isfield(results, "frames") || isempty(results.frames)
        error( ...
            ["No playback frames are available. Run the simulation with " ...
             "config.storePlaybackFrames = true."]);
    end

    frames = results.frames;
    numFrames = numel(frames);

    %% Playback state

    currentFrame = 1;
    playbackSpeed = 1;

    speedValues = [0.5, 1, 2, 4];

    if isfield(results, "dt") && ~isempty(results.dt)
        frameDuration = results.dt;
    else
        frameDuration = 0.4;
    end

    %% Create standard MATLAB figure

    fig = figure( ...
        'Name', 'ISAC Simulation Playback', ...
        'NumberTitle', 'off', ...
        'Color', 'w', ...
        'Position', [100 100 1250 720], ...
        'CloseRequestFcn', @closePlaybackWindow);

    %% Cartesian scenario axes

    scenarioAxes = axes( ...
        'Parent', fig, ...
        'Units', 'normalized', ...
        'Position', [0.055 0.20 0.41 0.73]);

    title(scenarioAxes, 'Cartesian scenario');
    xlabel(scenarioAxes, 'x [m]');
    ylabel(scenarioAxes, 'y [m]');

    grid(scenarioAxes, 'on');
    box(scenarioAxes, 'on');

    %% Range-AoA axes

    rangeAoAAxes = axes( ...
        'Parent', fig, ...
        'Units', 'normalized', ...
        'Position', [0.55 0.20 0.41 0.73]);

    title(rangeAoAAxes, 'Range-AoA map');
    xlabel(rangeAoAAxes, 'AoA [deg]');
    ylabel(rangeAoAAxes, 'Range [m]');

    colormap(rangeAoAAxes, gray(256));

    %% Playback controls

    previousButton = uicontrol( ...
        'Parent', fig, ...
        'Style', 'pushbutton', ...
        'Units', 'normalized', ...
        'Position', [0.02 0.095 0.07 0.05], ...
        'String', 'Previous', ...
        'Callback', @previousFrame);

    playButton = uicontrol( ...
        'Parent', fig, ...
        'Style', 'pushbutton', ...
        'Units', 'normalized', ...
        'Position', [0.10 0.095 0.07 0.05], ...
        'String', 'Play', ...
        'Callback', @togglePlayback);

    nextButton = uicontrol( ...
        'Parent', fig, ...
        'Style', 'pushbutton', ...
        'Units', 'normalized', ...
        'Position', [0.18 0.095 0.07 0.05], ...
        'String', 'Next', ...
        'Callback', @nextFrame);

    uicontrol( ...
        'Parent', fig, ...
        'Style', 'text', ...
        'Units', 'normalized', ...
        'Position', [0.265 0.098 0.055 0.035], ...
        'String', 'Speed:', ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', 'w');

    speedDropDown = uicontrol( ...
        'Parent', fig, ...
        'Style', 'popupmenu', ...
        'Units', 'normalized', ...
        'Position', [0.32 0.098 0.07 0.045], ...
        'String', {'0.5x', '1x', '2x', '4x'}, ...
        'Value', 2, ...
        'Callback', @changeSpeed);

    uicontrol( ...
        'Parent', fig, ...
        'Style', 'text', ...
        'Units', 'normalized', ...
        'Position', [0.405 0.098 0.05 0.035], ...
        'String', 'Frame:', ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', 'w');

    sliderStep = 1 / max(numFrames - 1, 1);

    frameSlider = uicontrol( ...
        'Parent', fig, ...
        'Style', 'slider', ...
        'Units', 'normalized', ...
        'Position', [0.455 0.105 0.43 0.035], ...
        'Min', 1, ...
        'Max', max(numFrames, 1), ...
        'Value', 1, ...
        'SliderStep', [sliderStep, min(5 * sliderStep, 1)], ...
        'Callback', @sliderChanged);

    restartButton = uicontrol( ...
        'Parent', fig, ...
        'Style', 'pushbutton', ...
        'Units', 'normalized', ...
        'Position', [0.90 0.095 0.075 0.05], ...
        'String', 'Restart', ...
        'Callback', @restartPlayback);

    statusLabel = uicontrol( ...
        'Parent', fig, ...
        'Style', 'text', ...
        'Units', 'normalized', ...
        'Position', [0.15 0.025 0.70 0.04], ...
        'String', '', ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', 'w', ...
        'FontWeight', 'bold');

    %% Timer-based playback

    playbackTimer = timer( ...
        'ExecutionMode', 'fixedSpacing', ...
        'Period', getTimerPeriod(), ...
        'BusyMode', 'drop', ...
        'TimerFcn', @timerTick, ...
        'ErrorFcn', @timerError);

    %% Initial frame

    renderFrame(currentFrame);

    %% Nested callbacks

    function togglePlayback(~, ~)

        if ~isvalid(playbackTimer)
            return;
        end

        if strcmp(playbackTimer.Running, 'on')

            stop(playbackTimer);
            playButton.String = 'Play';
            return;
        end

        % Restart from the beginning after reaching the final frame.
        if currentFrame >= numFrames

            currentFrame = 1;
            frameSlider.Value = currentFrame;

            renderFrame(currentFrame);
        end

        playbackTimer.Period = getTimerPeriod();

        playButton.String = 'Pause';

        start(playbackTimer);
    end

    function timerTick(~, ~)

        if ~isgraphics(fig)
            return;
        end

        if currentFrame >= numFrames

            stopPlayback();
            return;
        end

        currentFrame = currentFrame + 1;

        frameSlider.Value = currentFrame;

        renderFrame(currentFrame);

        if currentFrame >= numFrames
            stopPlayback();
        end
    end

    function previousFrame(~, ~)

        stopPlayback();

        currentFrame = max(1, currentFrame - 1);

        frameSlider.Value = currentFrame;

        renderFrame(currentFrame);
    end

    function nextFrame(~, ~)

        stopPlayback();

        currentFrame = min(numFrames, currentFrame + 1);

        frameSlider.Value = currentFrame;

        renderFrame(currentFrame);
    end

    function restartPlayback(~, ~)

        stopPlayback();

        currentFrame = 1;

        frameSlider.Value = currentFrame;

        renderFrame(currentFrame);
    end

    function sliderChanged(source, ~)

        stopPlayback();

        currentFrame = round(source.Value);

        source.Value = currentFrame;

        renderFrame(currentFrame);
    end

    function changeSpeed(source, ~)

        selectedIndex = source.Value;

        playbackSpeed = speedValues(selectedIndex);

        if isvalid(playbackTimer)

            wasRunning = strcmp( ...
                playbackTimer.Running, ...
                'on');

            if wasRunning
                stop(playbackTimer);
            end

            playbackTimer.Period = getTimerPeriod();

            if wasRunning
                start(playbackTimer);
            end
        end
    end

    function renderFrame(frameIndex)

        if ~isgraphics(fig) ...
                || ~isgraphics(scenarioAxes) ...
                || ~isgraphics(rangeAoAAxes) ...
                || ~isgraphics(statusLabel)

            return;
        end

        statusText = renderISACFrame( ...
            scenarioAxes, ...
            rangeAoAAxes, ...
            results, ...
            frameIndex);

        if isgraphics(statusLabel)
            statusLabel.String = statusText;
        end

        drawnow;
    end

    function stopPlayback()

        if isvalid(playbackTimer) ...
                && strcmp(playbackTimer.Running, 'on')

            stop(playbackTimer);
        end

        if isgraphics(playButton)
            playButton.String = 'Play';
        end
    end

    function period = getTimerPeriod()

        period = max( ...
            0.05, ...
            frameDuration / playbackSpeed);
    end

    function timerError(~, event)

        stopPlayback();

        warning( ...
            "ISAC playback timer error: %s", ...
            event.Data.Message);
    end

    function closePlaybackWindow(~, ~)

        if isvalid(playbackTimer)

            if strcmp(playbackTimer.Running, 'on')
                stop(playbackTimer);
            end

            delete(playbackTimer);
        end

        if isgraphics(fig)
            delete(fig);
        end
    end
end