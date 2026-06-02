function scenarioConfig = helperGetOSMScenarioConfig(osmScenarioName, topology)
% helperGetOSMScenarioConfig
% Returns Tx/Rx positions, ROI and scatterer file for each OSM scenario.
%
% Inputs:
%   osmScenarioName - "openArea" or "piotrkowskaStreetCanyon"
%   topology        - "monostatic" or "bistatic"
%
% Output:
%   scenarioConfig  - structure with scenario information

arguments
    osmScenarioName (1,1) string
    topology (1,1) string
end

scenarioConfig = struct();
scenarioConfig.name = osmScenarioName;
scenarioConfig.topology = topology;

switch osmScenarioName

    case "openArea"

        scenarioConfig.description = "OSM-based UMi open-area scenario";
        scenarioConfig.roi = [-120 -20;
            -70  30];

        scenarioConfig.scattererMatFile = "open_area_osm_scatterers.mat";

        % Common transmitter position
        txPosition = [-100; -60; 0];

        switch topology
            case "monostatic"
                rxPosition = txPosition;

            case "bistatic"
                rxPosition = [-30; 0; 0];

            otherwise
                error("Unknown topology: %s", topology);
        end

    case "piotrkowskaStreetCanyon"

        scenarioConfig.description = "OSM-based UMi street-canyon scenario";
        scenarioConfig.roi = [-50 50;
            -50 50];

        scenarioConfig.scattererMatFile = "piotrkowska_osm_scatterers.mat";

        % Common transmitter position
        txPosition = [-10; -40; 0];

        switch topology
            case "monostatic"
                rxPosition = txPosition;

            case "bistatic"
                rxPosition = [-10; 40; 0];

            otherwise
                error("Unknown topology: %s", topology);
        end

    otherwise
        error("Unknown OSM scenario name: %s", osmScenarioName);
end

scenarioConfig.txPosition = txPosition;
scenarioConfig.rxPosition = rxPosition;

end

%[appendix]{"version":"1.0"}
%---
