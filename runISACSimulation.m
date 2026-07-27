function results = runISACSimulation(config)
%RUNISACSIMULATION Run the configurable ISAC simulation.
%
%   RESULTS = RUNISACSIMULATION(CONFIG) prepares and executes the ISAC
%   simulation using the supplied configuration.
%
%   RESULTS = RUNISACSIMULATION() uses defaultConfig.

    %% Input configuration

    if nargin < 1 || isempty(config)
        config = defaultConfig();
    end

    validateattributes(config, {'struct'}, {'scalar'});

    config.scenarioName = string(config.scenarioName);
    config.topology = string(config.topology);
    config.targetCase = string(config.targetCase);

    validScenarios = [
        "baseline"
        "openArea"
        "piotrkowskaStreetCanyon"
    ];

    validTopologies = [
        "monostatic"
        "bistatic"
    ];

    if ~any(config.scenarioName == validScenarios)
        error("Unknown scenario: %s", config.scenarioName);
    end

    if ~any(config.topology == validTopologies)
        error("Unknown topology: %s", config.topology);
    end

    %% Reproducibility

    rng(config.randomSeed, "twister");

    %% Carrier configuration

    carrierFrequency = config.carrierFrequency;
    wavelength = freq2wavelen(carrierFrequency);

    %% Scenario-dependent geometry

    scenarioConfig = helperGetScenarioConfig( ...
        config.scenarioName, ...
        config.topology);

    % Use file paths defined in defaultConfig.
    switch config.scenarioName

        case "openArea"
            scenarioConfig.scattererMatFile = ...
                config.openAreaScattererFile;

        case "piotrkowskaStreetCanyon"
            scenarioConfig.scattererMatFile = ...
                config.piotrkowskaScattererFile;
    end

    txPosition = scenarioConfig.txPosition;
    rxPosition = scenarioConfig.rxPosition;

    txOrientationAxes = scenarioConfig.txOrientationAxes;
    rxOrientationAxes = scenarioConfig.rxOrientationAxes;

    regionOfInterest = scenarioConfig.roi;

    fprintf("\nISAC simulation setup\n");
    fprintf("Scenario: %s\n", config.scenarioName);
    fprintf("Topology: %s\n", config.topology);

    fprintf( ...
        "Tx position: [%.1f %.1f %.1f] m\n", ...
        txPosition(1), ...
        txPosition(2), ...
        txPosition(3));

    fprintf( ...
        "Rx position: [%.1f %.1f %.1f] m\n", ...
        rxPosition(1), ...
        rxPosition(2), ...
        rxPosition(3));

    %% Plot limits

    plotMargin = 10;

    scenarioPlotXLim = [
        regionOfInterest(1, 1) - plotMargin
        regionOfInterest(1, 2) + plotMargin
    ];

    scenarioPlotYLim = [
        regionOfInterest(2, 1) - plotMargin
        regionOfInterest(2, 2) + plotMargin
    ];

    %% Transmitter

    transmitter = phased.Transmitter( ...
        'PeakPower', db2pow(config.txPowerDBm - 30), ...
        'Gain', 0);

    numTxAntennas = config.numTxAntennas;

    element = phased.IsotropicAntennaElement( ...
        'BackBaffled', true);

    txArray = phased.ULA( ...
        numTxAntennas, ...
        wavelength / 2, ...
        'Element', element);

    %% Receiver

    receiver = phased.Receiver( ...
        'AddInputNoise', true, ...
        'Gain', 0, ...
        'NoiseMethod', 'Noise figure', ...
        'NoiseFigure', config.receiverNoiseFigureDB, ...
        'ReferenceTemperature', config.referenceTemperatureK);

    switch config.topology

        case "bistatic"

            numRxAntennas = config.numRxAntennas;

            rxArray = phased.ULA( ...
                numRxAntennas, ...
                wavelength / 2, ...
                'Element', element);

        case "monostatic"

            % Preserve the original monostatic implementation:
            % the same physical array is used for transmission and reception.
            numRxAntennas = numTxAntennas;
            rxArray = txArray;
    end

    %% Static scatterers

    if scenarioConfig.useOSMScatterers

        scattererFile = scenarioConfig.scattererMatFile;

        if ~isfile(scattererFile)
            error( ...
                "OSM scatterer file not found: %s", ...
                scattererFile);
        end

        scattererData = load( ...
            scattererFile, ...
            "scattererPositions", ...
            "reflectionCoefficients");

        requiredFields = [
            "scattererPositions"
            "reflectionCoefficients"
        ];

        for fieldIndex = 1:numel(requiredFields)

            fieldName = requiredFields(fieldIndex);

            if ~isfield(scattererData, fieldName)
                error( ...
                    "Variable %s not found in %s.", ...
                    fieldName, ...
                    scattererFile);
            end
        end

        scatterers.Positions = ...
            scattererData.scattererPositions;

        scatterers.ReflectionCoefficients = ...
            scattererData.reflectionCoefficients ...
            .* config.osmReflectionScale;

    else

        [scatterers.Positions, ...
            scatterers.ReflectionCoefficients] = ...
            helperGenerateStaticScatterers( ...
                config.numBaselineScatterers, ...
                regionOfInterest);
    end

    scatterers.Velocities = ...
        zeros(size(scatterers.Positions));

    numScatterers = size(scatterers.Positions, 2);

    fprintf( ...
        "Number of static scatterers: %d\n", ...
        numScatterers);

    %% Targets and trajectories

    targets.Trajectories = ...
        helperGetTargetTrajectories( ...
            config.scenarioName, ...
            config.targetCase);

    numTargets = numel(targets.Trajectories);

    targets.ReflectionCoefficients = ...
        exp(1i * 2 * pi * rand(1, numTargets));

    fprintf("Number of targets: %d\n", numTargets);

    %% Scattering channel

    simulateDirectPath = ...
        config.topology == "bistatic";

    channel = phased.ScatteringMIMOChannel( ...
        'CarrierFrequency', carrierFrequency, ...
        'TransmitArray', txArray, ...
        'TransmitArrayPosition', txPosition, ...
        'ReceiveArray', rxArray, ...
        'ReceiveArrayPosition', rxPosition, ...
        'TransmitArrayOrientationAxes', txOrientationAxes, ...
        'ReceiveArrayOrientationAxes', rxOrientationAxes, ...
        'SimulateDirectPath', simulateDirectPath, ...
        'ScattererSpecificationSource', 'Input Port', ...
        'ChannelResponseOutputPort', true, ...
        'Polarization', 'None');

    %% Initial scenario figure

    if config.showInitialScenario

        helperVisualizeScatteringMIMOChannel( ...
            channel, ...
            scatterers.Positions, ...
            targets.Trajectories);

        title(sprintf( ...
            'ISAC Scenario — %s / %s', ...
            config.scenarioName, ...
            config.topology));
    end

    %% 5G NR waveform

    waveformConfig = helperGet5GWaveformConfiguration( ...
        config.channelBandwidthMHz, ...
        config.bandwidthOccupancy, ...
        config.subcarrierSpacingKHz);

    waveformInfo = nrOFDMInfo(waveformConfig.Carrier);

    transmissionBandwidth = ...
        config.subcarrierSpacingKHz * 1e3 ...
        * waveformConfig.Carrier.NSizeGrid ...
        * 12;

    channel.SampleRate = waveformInfo.SampleRate;

    %% Optional PDSCH DM-RS resource grid

    if config.showResourceGrid

        resourceGrid = nrResourceGrid( ...
            waveformConfig.Carrier, ...
            waveformConfig.PDSCH.NumLayers);

        dmrsIndices = nrPDSCHDMRSIndices( ...
            waveformConfig.Carrier, ...
            waveformConfig.PDSCH);

        dmrsSymbols = nrPDSCHDMRS( ...
            waveformConfig.Carrier, ...
            waveformConfig.PDSCH);

        resourceGrid(dmrsIndices) = dmrsSymbols;

        helperVisualizeResourceGrid( ...
            abs(resourceGrid(1:12, 1:14, 1)));

        title({ ...
            'PDSCH DM-RS Resource Elements', ...
            '(single resource block)'});
    end

    %% Maximum Doppler and velocity

    [~, pdschInfo] = nrPDSCHIndices( ...
        waveformConfig.Carrier, ...
        waveformConfig.PDSCH);

    Mt = max(diff(pdschInfo.DMRSSymbolSet));

    ofdmSymbolDuration = ...
        max(waveformInfo.SymbolLengths) ...
        / waveformInfo.SampleRate;

    maxDoppler = ...
        1 / (2 * Mt * ofdmSymbolDuration);

    maxVelocity = dop2speed( ...
        maxDoppler, ...
        wavelength);

    if config.topology == "monostatic"
        maxVelocity = maxVelocity / 2;
    end

    %% Maximum delay

    Mf = min(diff( ...
        waveformConfig.PDSCH.DMRS ...
        .DMRSSubcarrierLocations));

    maxDelay = ...
        1 / ( ...
        2 ...
        * Mf ...
        * config.subcarrierSpacingKHz ...
        * 1e3);

    channel.MaximumDelaySource = 'Property';
    channel.MaximumDelay = maxDelay;

    %% Range limits

    propagationSpeed = physconst("LightSpeed");

    if config.topology == "bistatic"

        baseline = vecnorm( ...
            txPosition - rxPosition);

        maxRange = ...
            maxDelay * propagationSpeed ...
            - baseline;

    else

        baseline = 0;

        maxRange = ...
            maxDelay * propagationSpeed / 2;
    end

    rangeResolution = ...
        propagationSpeed / transmissionBandwidth;

    if config.printSensingLimits

        fprintf( ...
            "Transmission bandwidth: %.2f MHz\n", ...
            transmissionBandwidth * 1e-6);

        fprintf( ...
            "Maximum unambiguous Doppler shift: %.2f kHz\n", ...
            maxDoppler * 1e-3);

        fprintf( ...
            "Maximum unambiguous velocity: %.2f m/s\n", ...
            maxVelocity);

        fprintf( ...
            "Maximum time delay: %.2f microseconds\n", ...
            maxDelay * 1e6);

        fprintf( ...
            "Maximum unambiguous %s range: %.2f m\n", ...
            config.topology, ...
            maxRange);

        fprintf( ...
            "Range resolution: %.2f m\n", ...
            rangeResolution);
    end

    %% Simulation time

    dt = config.dt;
    numSensingFrames = config.numSensingFrames;

    if config.autoExtendSlowTargetCases ...
            && contains(config.targetCase, "Slow")

        numSensingFrames = ...
            config.slowTargetNumFrames;
    end

    simulationTime = ...
        (0:numSensingFrames - 1) * dt;

    %% Temporary setup results

    % During this first development stage, the function only returns the
    % prepared simulation configuration. The sensing loop is added next.

    results = struct();

    results.config = config;

    results.scenarioName = config.scenarioName;
    results.topology = config.topology;
    results.targetCase = config.targetCase;

    results.scenarioDescription = ...
        scenarioConfig.description;

    results.txPosition = txPosition;
    results.rxPosition = rxPosition;

    results.txOrientationAxes = txOrientationAxes;
    results.rxOrientationAxes = rxOrientationAxes;

    results.regionOfInterest = regionOfInterest;
    results.scenarioPlotXLim = scenarioPlotXLim;
    results.scenarioPlotYLim = scenarioPlotYLim;

    results.numTargets = numTargets;
    results.numScatterers = numScatterers;

    results.carrierFrequency = carrierFrequency;
    results.transmissionBandwidth = transmissionBandwidth;

    results.rangeResolution = rangeResolution;
    results.maxRange = maxRange;
    results.maxVelocity = maxVelocity;
    results.maxDelay = maxDelay;
    results.baseline = baseline;

    results.dt = dt;
    results.numSensingFrames = numSensingFrames;
    results.simulationTime = simulationTime;

    results.setupComplete = true;

end