function playISACResults(results)
%PLAYISACRESULTS Interactive playback of stored ISAC simulation frames.
%
%   PLAYISACRESULTS(RESULTS) opens an interactive viewer with:
%       - Cartesian scenario
%       - Range-AoA map
%       - Play and pause
%       - Previous and next frame
%       - Frame slider
%       - Playback speed selector

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
    isPlaying = false;
    playbackSpeed = 1;

    %% Create interface

    fig = uifigure( ...
        'Name', 'ISAC Simulation Playback', ...
        'Position', [100 100 1250 720]);

    mainLayout = uigridlayout(fig, [3 2]);

    mainLayout.RowHeight = {'1x', 55, 30};
    mainLayout.ColumnWidth = {'1x', '1x'};

    %% Scenario axes

    scenarioAxes = uiaxes(mainLayout);

    scenarioAxes.Layout.Row = 1;
    scenarioAxes.Layout.Column = 1;

    title(scenarioAxes, 'Cartesian scenario');
    xlabel(scenarioAxes, 'x (m)');
    ylabel(scenarioAxes, 'y (m)');

    grid(scenarioAxes, 'on');
    box(scenarioAxes, 'on');

    %% Range-AoA axes

    rangeAoAAxes = uiaxes(mainLayout);

    rangeAoAAxes.Layout.Row = 1;
    rangeAoAAxes.Layout.Column = 2;

    title(rangeAoAAxes, 'Range-AoA map');
    xlabel(rangeAoAAxes, 'AoA (degrees)');
    ylabel(rangeAoAAxes, 'Range (m)');

    colormap(rangeAoAAxes, 'gray');

    %% Controls

    controlsLayout = uigridlayout(mainLayout, [1 8]);

    controlsLayout.Layout.Row = 2;
    controlsLayout.Layout.Column = [1 2];

    controlsLayout.ColumnWidth = ...
        {80, 80, 80, 70, 90, 50, '1x', 80};

    previousButton = uibutton( ...
        controlsLayout, ...
        'push', ...
        'Text', 'Previous', ...
        'ButtonPushedFcn', @previousFrame);

    playButton = uibutton( ...
        controlsLayout, ...
        'push', ...
        'Text', 'Play', ...
        'ButtonPushedFcn', @togglePlayback);

    nextButton = uibutton( ...
        controlsLayout, ...
        'push', ...
        'Text', 'Next', ...
        'ButtonPushedFcn', @nextFrame);

    speedLabel = uilabel( ...
        controlsLayout, ...
        'Text', 'Speed:');

    speedDropDown = uidropdown( ...
        controlsLayout, ...
        'Items', {'0.5x', '1x', '2x', '4x'}, ...
        'Value', '1x', ...
        'ValueChangedFcn', @changeSpeed);

    frameLabel = uilabel( ...
        controlsLayout, ...
        'Text', 'Frame:');

    frameSlider = uislider( ...
        controlsLayout, ...
        'Limits', [1 numFrames], ...
        'Value', 1, ...
        'MajorTicks', unique(round(linspace(1, numFrames, ...
            min(numFrames, 10)))), ...
        'ValueChangedFcn', @sliderChanged);

    restartButton = uibutton( ...
        controlsLayout, ...
        'push', ...
        'Text', 'Restart', ...
        'ButtonPushedFcn', @restartPlayback);

    %% Status label

    statusLabel = uilabel(mainLayout);

    statusLabel.Layout.Row = 3;
    statusLabel.Layout.Column = [1 2];

    statusLabel.HorizontalAlignment = 'center';

    %% Initial frame

    renderFrame(currentFrame);

    %% Nested callbacks

    function togglePlayback(~, ~)

        isPlaying = ~isPlaying;

        if isPlaying

            playButton.Text = 'Pause';

            while isPlaying && isvalid(fig)

                renderFrame(currentFrame);

                if currentFrame >= numFrames

                    isPlaying = false;
                    playButton.Text = 'Play';
                    break;
                end

                delaySeconds = max( ...
                    0.02, ...
                    results.dt / playbackSpeed);

                pause(delaySeconds);
                drawnow;

                if isPlaying

                    currentFrame = currentFrame + 1;
                    frameSlider.Value = currentFrame;
                end
            end

        else

            playButton.Text = 'Play';
        end
    end

    function previousFrame(~, ~)

        isPlaying = false;
        playButton.Text = 'Play';

        currentFrame = max(1, currentFrame - 1);

        frameSlider.Value = currentFrame;
        renderFrame(currentFrame);
    end

    function nextFrame(~, ~)

        isPlaying = false;
        playButton.Text = 'Play';

        currentFrame = min(numFrames, currentFrame + 1);

        frameSlider.Value = currentFrame;
        renderFrame(currentFrame);
    end

    function restartPlayback(~, ~)

        isPlaying = false;
        playButton.Text = 'Play';

        currentFrame = 1;

        frameSlider.Value = currentFrame;
        renderFrame(currentFrame);
    end

    function sliderChanged(source, ~)

        isPlaying = false;
        playButton.Text = 'Play';

        currentFrame = round(source.Value);
        source.Value = currentFrame;

        renderFrame(currentFrame);
    end

    function changeSpeed(source, ~)

        switch source.Value

            case '0.5x'
                playbackSpeed = 0.5;

            case '1x'
                playbackSpeed = 1;

            case '2x'
                playbackSpeed = 2;

            case '4x'
                playbackSpeed = 4;
        end
    end

    %% Frame renderer

    function renderFrame(frameIndex)

        frame = frames(frameIndex);

        renderScenario(frameIndex, frame);
        renderRangeAoA(frame);

        statusLabel.Text = sprintf( ...
            'Frame %d of %d | Simulation time: %.1f s | %s / %s', ...
            frameIndex, ...
            numFrames, ...
            frame.simulationTime, ...
            results.scenarioName, ...
            results.topology);

        drawnow;
    end

    %% Scenario renderer

    function renderScenario(frameIndex, frame)

        cla(scenarioAxes);
        hold(scenarioAxes, 'on');

        % Plot complete target trajectories using stored truth positions.
        if isfield(results, "targetPositionsHistory")

            numTargets = size( ...
                results.targetPositionsHistory, ...
                2);

            for targetIndex = 1:numTargets

                trajectoryX = squeeze( ...
                    results.targetPositionsHistory( ...
                        :, targetIndex, 1));

                trajectoryY = squeeze( ...
                    results.targetPositionsHistory( ...
                        :, targetIndex, 2));

                plot( ...
                    scenarioAxes, ...
                    trajectoryX, ...
                    trajectoryY, ...
                    '--', ...
                    'LineWidth', 1.2, ...
                    'HandleVisibility', 'off');
            end
        end
        % Static scatterers.
        if isfield(results, "scattererPositions") ...
                && ~isempty(results.scattererPositions)

            plot( ...
                scenarioAxes, ...
                results.scattererPositions(1, :), ...
                results.scattererPositions(2, :), ...
                '.', ...
                'MarkerSize', 6, ...
                'DisplayName', 'Scatterers');
        end
        % Tx and Rx.
        plot( ...
            scenarioAxes, ...
            results.txPosition(1), ...
            results.txPosition(2), ...
            'o', ...
            'MarkerSize', 9, ...
            'LineWidth', 1.5, ...
            'DisplayName', 'Tx');

        plot( ...
            scenarioAxes, ...
            results.rxPosition(1), ...
            results.rxPosition(2), ...
            'v', ...
            'MarkerSize', 9, ...
            'LineWidth', 1.5, ...
            'DisplayName', 'Rx');

        % Current target positions.
        targetPositions = frame.targetPositions;

        if ~isempty(targetPositions)

            plot( ...
                scenarioAxes, ...
                targetPositions(:, 1), ...
                targetPositions(:, 2), ...
                'x', ...
                'MarkerSize', 10, ...
                'LineWidth', 2, ...
                'DisplayName', 'Targets');
        end

        % Cartesian detections.
        measuredPositions = frame.measuredPositions;

        if ~isempty(measuredPositions)

            if size(measuredPositions, 1) == 3

                measuredX = measuredPositions(1, :);
                measuredY = measuredPositions(2, :);

            else

                measuredX = measuredPositions(:, 1);
                measuredY = measuredPositions(:, 2);
            end

            plot( ...
                scenarioAxes, ...
                measuredX, ...
                measuredY, ...
                'o', ...
                'MarkerSize', 6, ...
                'LineWidth', 1.2, ...
                'DisplayName', 'Detections');
        end

        % Current tracks.
        tracks = frame.tracks;

        for trackIndex = 1:numel(tracks)

            state = tracks(trackIndex).State;

            plot( ...
                scenarioAxes, ...
                state(1), ...
                state(3), ...
                's', ...
                'MarkerSize', 7, ...
                'LineWidth', 1.5, ...
                'DisplayName', sprintf( ...
                    'Track %d', ...
                    tracks(trackIndex).TrackID));
        end

        % Track history until current frame.
        trackIDsSeen = [];

        for previousFrameIndex = 1:frameIndex

            previousTracks = ...
                frames(previousFrameIndex).tracks;

            for trackIndex = 1:numel(previousTracks)

                trackID = previousTracks(trackIndex).TrackID;

                if ~ismember(trackID, trackIDsSeen)
                    trackIDsSeen(end + 1) = trackID; %#ok<AGROW>
                end
            end
        end

        for trackID = trackIDsSeen

            trackX = [];
            trackY = [];

            for previousFrameIndex = 1:frameIndex

                previousTracks = ...
                    frames(previousFrameIndex).tracks;

                for trackIndex = 1:numel(previousTracks)

                    if previousTracks(trackIndex).TrackID == trackID

                        state = previousTracks(trackIndex).State;

                        trackX(end + 1) = state(1); %#ok<AGROW>
                        trackY(end + 1) = state(3); %#ok<AGROW>
                    end
                end
            end

            plot( ...
                scenarioAxes, ...
                trackX, ...
                trackY, ...
                '-', ...
                'LineWidth', 1.4, ...
                'HandleVisibility', 'off');
        end

        xlim( ...
            scenarioAxes, ...
            results.scenarioPlotXLim(:).');

        ylim( ...
            scenarioAxes, ...
            results.scenarioPlotYLim(:).');

        axis(scenarioAxes, 'equal');

        grid(scenarioAxes, 'on');
        box(scenarioAxes, 'on');

        xlabel(scenarioAxes, 'x (m)');
        ylabel(scenarioAxes, 'y (m)');

        title( ...
            scenarioAxes, ...
            sprintf('Cartesian scenario — frame %d', frameIndex), ...
            'Interpreter', 'none');

        legend( ...
            scenarioAxes, ...
            'Location', 'best');

        hold(scenarioAxes, 'off');
    end

    %% Range-AoA renderer

    function renderRangeAoA(frame)

        cla(rangeAoAAxes);

        imagesc( ...
            rangeAoAAxes, ...
            results.aoaGrid, ...
            results.rangeGrid, ...
            frame.rangeAoAMap);

        rangeAoAAxes.YDir = 'normal';

        colormap(rangeAoAAxes, 'gray');

        hold(rangeAoAAxes, 'on');

        truth = frame.truthRangeAoA;

        if ~isempty(truth)

            plot( ...
                rangeAoAAxes, ...
                truth(2, :), ...
                truth(1, :), ...
                'x', ...
                'MarkerSize', 10, ...
                'LineWidth', 2, ...
                'DisplayName', 'Truth');
        end

        clusteredDetections = ...
            frame.clusteredDetections;

        if ~isempty(clusteredDetections)

            plot( ...
                rangeAoAAxes, ...
                clusteredDetections(2, :), ...
                clusteredDetections(1, :), ...
                'o', ...
                'MarkerSize', 7, ...
                'LineWidth', 1.5, ...
                'DisplayName', 'Clustered detections');
        end

        trackRangeAoA = frame.trackRangeAoA;

        if ~isempty(trackRangeAoA)

            plot( ...
                rangeAoAAxes, ...
                trackRangeAoA(2, :), ...
                trackRangeAoA(1, :), ...
                's', ...
                'MarkerSize', 7, ...
                'LineWidth', 1.5, ...
                'DisplayName', 'Tracks');
        end

        xlabel(rangeAoAAxes, 'AoA (degrees)');

        if results.topology == "bistatic"
            ylabel(rangeAoAAxes, 'Bistatic range (m)');
        else
            ylabel(rangeAoAAxes, 'Monostatic range (m)');
        end

        title(rangeAoAAxes, 'Range-AoA map');

        legend( ...
            rangeAoAAxes, ...
            'Location', 'best');

        hold(rangeAoAAxes, 'off');
    end

end