function detections = helperFormatDetectionsForTrackerByTopology( ...
    topology, clusteredDetections, currentTime, ...
    rangeResolution, aoaResolution)
%HELPERFORMATDETECTIONSFORTRACKERBYTOPOLOGY Format tracker measurements.

topology = string(topology);
numDetections = size(clusteredDetections, 2);

switch topology

    case "bistatic"

        detections = struct;

        detections.ReceiverLookTime = currentTime;
        detections.ReceiverLookAzimuth = 0;
        detections.ReceiverLookElevation = 0;

        detections.EmitterLookAzimuth = 0;
        detections.EmitterLookElevation = 0;

        detections.DetectionTime = ...
            ones(1, numDetections) * currentTime;

        detections.Azimuth = ...
            clusteredDetections(2, :);

        detections.Range = ...
            clusteredDetections(1, :);

        detections.AzimuthAccuracy = ...
            ones(1, numDetections) * aoaResolution / 12;

        detections.RangeAccuracy = ...
            ones(1, numDetections) * rangeResolution / 8;

    case "monostatic"

        detections = struct;

        detections.LookTime = currentTime;
        detections.LookAzimuth = 0;
        detections.LookElevation = 0;

        detections.DetectionTime = ...
            ones(1, numDetections) * currentTime;

        detections.SensorIndex = ...
            ones(1, numDetections);

        detections.Range = ...
            clusteredDetections(1, :);

        detections.Azimuth = ...
            clusteredDetections(2, :);

        detections.Elevation = ...
            zeros(1, numDetections);

        detections.RangeRate = ...
            zeros(1, numDetections);

        detections.RangeAccuracy = ...
            ones(1, numDetections) * rangeResolution / 8;

        detections.AzimuthAccuracy = ...
            ones(1, numDetections) * aoaResolution / 12;

        detections.ElevationAccuracy = ...
            ones(1, numDetections) * aoaResolution / 12;

        detections.RangeRateAccuracy = ...
            ones(1, numDetections);

        detections.Measurements = [
            detections.Range
            detections.Azimuth
            detections.Elevation
            ];

        detections.MeasurementParameters = ...
            repmat(struct(), 1, numDetections);

    otherwise

        error("Unsupported topology: %s", topology);
end
end