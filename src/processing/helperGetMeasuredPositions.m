function measuredPositions = helperGetMeasuredPositions( ...
    topology, clusteredDetections, ...
    txPosition, rxPosition, rxOrientationAxes)
%HELPERGETMEASUREDPOSITIONS Convert range-angle detections to Cartesian.

topology = string(topology);

if isempty(clusteredDetections)
    measuredPositions = [];
    return;
end

switch topology

    case "bistatic"

        numDetections = size(clusteredDetections, 2);

        measurementSpherical = zeros(3, numDetections);

        measurementSpherical(1, :) = ...
            clusteredDetections(2, :);

        measurementSpherical(3, :) = ...
            clusteredDetections(1, :);

        measurementSpherical = local2globalcoord( ...
            measurementSpherical, ...
            "ss", ...
            [0; 0; 0], ...
            rxOrientationAxes);

        measuredPositions = bistaticposest( ...
            measurementSpherical(3, :), ...
            measurementSpherical(1:2, :), ...
            eps * ones(1, numDetections), ...
            repmat([eps; eps], 1, numDetections), ...
            txPosition, ...
            rxPosition, ...
            "RangeMeasurement", ...
            "BistaticRange");

    case "monostatic"

        range = clusteredDetections(1, :);
        azimuth = clusteredDetections(2, :);

        localPositions = [
            range .* cosd(azimuth)
            range .* sind(azimuth)
            zeros(size(range))
            ];

        measuredPositions = ...
            rxPosition + rxOrientationAxes * localPositions;

    otherwise

        error("Unsupported topology: %s", topology);
end
end