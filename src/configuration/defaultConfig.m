function config = defaultConfig()
%DEFAULTCONFIG Default configuration for the ISAC simulation framework.
%
%   CONFIG = DEFAULTCONFIG() returns the default parameters used by the
%   original validated baseline monostatic simulation.
%% Portable project paths

projectRoot = string(setupISACProjectPaths());
%% Configuration structure

config = struct();

config.projectRoot = projectRoot;
    %% Scenario and topology

    config.scenarioName = "baseline";
    config.topology = "monostatic";
    config.targetCase = "twoTargetsOriginalFast";

    %% Reproducibility

    config.randomSeed = 0;

    %% Radio parameters

    config.carrierFrequency = 30e9;
    config.txPowerDBm = 46;

    config.numTxAntennas = 8;
    config.numRxAntennas = 8;

    config.receiverNoiseFigureDB = 5;
    config.referenceTemperatureK = 290;

    %% 5G NR waveform

    config.channelBandwidthMHz = 50;
    config.bandwidthOccupancy = 0.9;
    config.subcarrierSpacingKHz = 60;

    %% Simulation timing

    config.dt = 0.4;
    config.numSensingFrames = 10;

    % Slow target cases will automatically use 20 sensing frames.
    config.autoExtendSlowTargetCases = true;
    config.slowTargetNumFrames = 20;

    %% Scatterers

    config.numBaselineScatterers = 40;
    config.osmReflectionScale = 1.0;

       config.openAreaScattererFile = fullfile( ...
        projectRoot, ...
        "data", ...
        "open_area_osm_scatterers.mat");

    config.piotrkowskaScattererFile = fullfile( ...
        projectRoot, ...
        "data", ...
        "piotrkowska_osm_scatterers.mat");

    %% Detection and clustering

    config.cfarPfa = 1e-5;
    config.cfarTrainingBandSize = [4 6];

    config.truthRangeTolerance = 8;
    config.truthAoATolerance = 10;

    %% Tracking

    config.trackDistanceTolerance = 8;

    config.trackerConfirmationExistenceProbability = 0.98;
    config.trackerMaxMahalanobisDistance = 10;
    config.trackerDetectionProbability = 0.9;
    config.trackerVelocityVariance = 15^2 / 3;
    config.trackerAccelerationVariance = 0.01^2 / 3;

    config.trackerMaxMeasurementsPerUpdate = 10;
    config.trackerRangeLimits = [0 500];

    %% Range-AoA processing

    config.rangeOversamplingFactor = 4;

    config.monostaticRangeLimits = [0 100];
    config.bistaticRangeLimits = [-20 100];

    %% Console output

    config.printSensingLimits = true;
    config.printMetricsSummary = true;
    config.debugGeometry = false;

    %% Visualisations

    % PDSCH DM-RS resource grid.
    config.showResourceGrid = false;

    % Initial static scenario with Tx, Rx, array orientations,
    % scatterers and complete target trajectories.
    config.showInitialScenario = true;

    % Main live animation:
    % left: scenario, targets, detections and tracks
    % right: range-AoA map, truth and clustered CFAR detections.
    config.showLiveAnimation = true;

    % Tracking position error per sensing frame.
    config.showTrackingErrorFigure = true;

    % Target and track speed/heading comparison.
    config.showSpeedHeadingFigure = true;

    %% Playback storage for the future app

    % Store frame-by-frame information so the app can reproduce,
    % pause and navigate through the simulation afterwards.
    config.storePlaybackFrames = true;

    %% Export

    % Disabled by default so running the simulation does not continuously
    % create PDFs, EPS files, PNGs or videos.
    config.exportFigures = false;
    config.exportVideo = false;

        config.outputDirectory = fullfile( ...
        projectRoot, ...
        "results");

   config.videoFileName = "isac_simulation.avi";
    config.videoFrameRate = 5;

end