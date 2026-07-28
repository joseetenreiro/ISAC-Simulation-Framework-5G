function tracker = helperConfigureTrackerByTopology( ...
    config, ...
    txPosition, ...
    rxPosition, ...
    txOrientation, ...
    rxOrientation, ...
    rangeResolution, ...
    aoaResolution)
%HELPERCONFIGURETRACKERBYTOPOLOGY Configure the ISAC JIPDA tracker.
%
%   TRACKER = HELPERCONFIGURETRACKERBYTOPOLOGY(CONFIG, ...)
%   creates either a monostatic or bistatic tracker specification.

    topology = string(config.topology);

    %% Sensor specification

    switch topology

        case "bistatic"

            sensorSpec = trackerSensorSpec( ...
                "aerospace", ...
                "radar", ...
                "bistatic");

            sensorSpec.MeasurementMode = "range-angle";

            sensorSpec.IsReceiverStationary = true;
            sensorSpec.IsEmitterStationary = true;

            sensorSpec.HasElevation = false;
            sensorSpec.HasRangeRate = false;

            sensorSpec.MaxNumLooksPerUpdate = 1;

            sensorSpec.MaxNumMeasurementsPerUpdate = ...
                config.trackerMaxMeasurementsPerUpdate;

            sensorSpec.EmitterPlatformPosition = ...
                txPosition;

            sensorSpec.EmitterPlatformOrientation = ...
                txOrientation.';

            sensorSpec.ReceiverPlatformPosition = ...
                rxPosition;

            sensorSpec.ReceiverPlatformOrientation = ...
                rxOrientation.';

            sensorSpec.RangeResolution = ...
                rangeResolution;

            sensorSpec.AzimuthResolution = ...
                aoaResolution;

            sensorSpec.ReceiverFieldOfView = [360 180];
            sensorSpec.EmitterFieldOfView = [360 180];

            sensorSpec.ReceiverRangeLimits = ...
                config.trackerRangeLimits;

            sensorSpec.EmitterRangeLimits = ...
                config.trackerRangeLimits;

            sensorSpec.DetectionProbability = ...
                config.trackerDetectionProbability;

        case "monostatic"

            sensorSpec = trackerSensorSpec( ...
                "aerospace", ...
                "radar", ...
                "monostatic");

            sensorSpec.PlatformPosition = ...
                rxPosition;

            sensorSpec.PlatformOrientation = ...
                rxOrientation.';

            sensorSpec.RangeResolution = ...
                rangeResolution;

            sensorSpec.AzimuthResolution = ...
                aoaResolution;

            sensorSpec.DetectionProbability = ...
                config.trackerDetectionProbability;

        otherwise

            error( ...
                "Unsupported tracker topology: %s", ...
                topology);
    end

    %% Target model

    targetSpec = trackerTargetSpec("custom");

    targetSpec.StateTransitionModel = ...
        targetStateTransitionModel("constant-velocity");

    targetSpec.StateTransitionModel.NumMotionDimensions = 2;

    targetSpec.StateTransitionModel.VelocityVariance = ...
        config.trackerVelocityVariance * eye(2);

    targetSpec.StateTransitionModel.AccelerationVariance = ...
        config.trackerAccelerationVariance * eye(2);

    %% JIPDA tracker

    tracker = multiSensorTargetTracker( ...
        targetSpec, ...
        sensorSpec, ...
        "jipda");

    tracker.ConfirmationExistenceProbability = ...
        config.trackerConfirmationExistenceProbability;

    tracker.MaxMahalanobisDistance = ...
        config.trackerMaxMahalanobisDistance;

end