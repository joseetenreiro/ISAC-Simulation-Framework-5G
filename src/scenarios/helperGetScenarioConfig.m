function scenarioConfig = helperGetScenarioConfig(scenarioName, topology)
% helperGetScenarioConfig
% Defines scenario-dependent geometry, scatterer source and array orientation.

scenarioConfig = struct();
scenarioConfig.name = scenarioName;
scenarioConfig.topology = topology;

switch scenarioName

    case "baseline"

        scenarioConfig.description = "Controlled baseline scenario with randomly generated scatterers";
        scenarioConfig.useOSMScatterers = false;
        scenarioConfig.scattererMatFile = "";

        scenarioConfig.roi = [0 120;
                             -80 80];

        txPosition = [0; 0; 0];

        % Keep original baseline orientations.
        txOrientationAxes = eye(3);

        switch topology
            case "monostatic"
                rxPosition = txPosition;
                rxOrientationAxes = txOrientationAxes;

            case "bistatic"
                rxPosition = [50; 60; 0];
                rxOrientationAxes = rotz(-90);

            otherwise
                error('topology must be "monostatic" or "bistatic".');
        end

    case "openArea"

        scenarioConfig.description = "OSM-based UMi open-area scenario";
        scenarioConfig.useOSMScatterers = true;
        scenarioConfig.scattererMatFile = "open_area_osm_scatterers.mat";

        scenarioConfig.roi = [-120 -20;
                               -70  30];

        txPosition = [-100; -60; 0];

        % Look roughly towards the centre of the target/ROI area.
        lookPoint = [-70; -20; 0];

        txOrientationAxes = helperLookAt2D(txPosition, lookPoint);

        switch topology
            case "monostatic"
                rxPosition = txPosition;
                rxOrientationAxes = txOrientationAxes;

            case "bistatic"
                rxPosition = [-30; 0; 0];
                rxOrientationAxes = helperLookAt2D(rxPosition, lookPoint);

            otherwise
                error('topology must be "monostatic" or "bistatic".');
        end

    case "piotrkowskaStreetCanyon"

        scenarioConfig.description = "OSM-based UMi street-canyon scenario";
        scenarioConfig.useOSMScatterers = true;
        scenarioConfig.scattererMatFile = "piotrkowska_osm_scatterers.mat";

        scenarioConfig.roi = [-50 50;
                              -50 50];

        txPosition = [-10; -40; 0];

        % Street canyon along y direction.
        txLookPoint = [-10; 0; 0];
        txOrientationAxes = helperLookAt2D(txPosition, txLookPoint);

        switch topology
            case "monostatic"
                rxPosition = txPosition;
                rxOrientationAxes = txOrientationAxes;

            case "bistatic"
               %Case original
                rxPosition = [-20; 40; 0];
                rxLookPoint = [-10; 0; 0];
                %Caso RX-C: Rx desplazado hacia Target 2    
                %rxPosition = [20; 40; 0];
                %rxLookPoint = [15; 0; 0];
                %Caso RX-B: Rx centrado, mirando al centro
                %rxPosition = [0; 40; 0];
                %rxLookPoint = [0; 0; 0];
                %Caso RX-A: misma posición, mirando a Target 2
                %rxLookPoint = [15; 0; 0];
                %rxPosition = [-20; 40; 0];
                %original
                %rxLookPoint = [-10; 0; 0];
                %rxPosition = [-20; 40; 0];
                rxOrientationAxes = helperLookAt2D(rxPosition, rxLookPoint);

            otherwise
                error('topology must be "monostatic" or "bistatic".');
        end

    otherwise
        error("Unknown scenarioName: %s", scenarioName);
end

scenarioConfig.txPosition = txPosition;
scenarioConfig.rxPosition = rxPosition;
scenarioConfig.txOrientationAxes = txOrientationAxes;
scenarioConfig.rxOrientationAxes = rxOrientationAxes;

end
%% 
function orientationAxes = helperLookAt2D(position, lookPoint)
% helperLookAt2D
% Returns a yaw-only orientation matrix whose local x-axis points
% approximately from position to lookPoint in the x-y plane.

direction = lookPoint - position;
yawDeg = atan2d(direction(2), direction(1));
orientationAxes = rotz(yawDeg);

end
