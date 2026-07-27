function trajectories = helperGetTargetTrajectories(scenarioName, targetCase)
% helperGetTargetTrajectories
% Defines target trajectories depending on the selected scenario and target case.

    if nargin < 1
        scenarioName = "baseline";
    end

    if nargin < 2
        targetCase = "default";
    end

    switch scenarioName

        case "baseline"

            timeOfArrival = [0 4];

            waypoints1 = [25 -5 0;
                          40 30 0];

            waypoints2 = [70 30 0;
                          80 10 0];

            traj1 = waypointTrajectory(waypoints1, timeOfArrival);
            traj2 = waypointTrajectory(waypoints2, timeOfArrival);

            trajectories = {traj1, traj2};

        case "openArea"

            timeOfArrival = [0 4];

            waypoints1 = [-105 -50 0;
                           -45  10 0];

            waypoints2 = [-95  20 0;
                          -35 -45 0];

            traj1 = waypointTrajectory(waypoints1, timeOfArrival);
            traj2 = waypointTrajectory(waypoints2, timeOfArrival);

            trajectories = {traj1, traj2};

        case "piotrkowskaStreetCanyon"

            switch targetCase

                case "singleT1Fast"

                    timeOfArrival = [0 4];

                    waypoints1 = [-10 -25 0;
                                  -10  25 0];

                    traj1 = waypointTrajectory(waypoints1, timeOfArrival);
                    trajectories = {traj1};

                case "singleT1Slow"

                    timeOfArrival = [0 8];

                    waypoints1 = [-10 -25 0;
                                  -10  25 0];

                    traj1 = waypointTrajectory(waypoints1, timeOfArrival);
                    trajectories = {traj1};

                case "singleT2Slow"

                    timeOfArrival = [0 8];

                    waypoints1 = [15 -30 0;
                                  15  30 0];

                    traj1 = waypointTrajectory(waypoints1, timeOfArrival);
                    trajectories = {traj1};

                case "twoTargetsOriginalFast"

                    timeOfArrival = [0 4];

                    waypoints1 = [-10 -25 0;
                                  -10  25 0];

                    waypoints2 = [15 -30 0;
                                  15  30 0];

                    traj1 = waypointTrajectory(waypoints1, timeOfArrival);
                    traj2 = waypointTrajectory(waypoints2, timeOfArrival);

                    trajectories = {traj1, traj2};

                case "twoTargetsOriginalSlow"

                    timeOfArrival = [0 8];

                    waypoints1 = [-10 -25 0;
                                  -10  25 0];

                    waypoints2 = [15 -30 0;
                                  15  30 0];

                    traj1 = waypointTrajectory(waypoints1, timeOfArrival);
                    traj2 = waypointTrajectory(waypoints2, timeOfArrival);

                    trajectories = {traj1, traj2};

                case "twoTargetsSeparatedSlow"

                    timeOfArrival = [0 8];

                    % More laterally separated two-target case.
                    % This tests whether the degradation observed in the original
                    % two-target case is caused by insufficient range-AoA separability.
                    waypoints1 = [-20 -25 0;
                                  -20  25 0];

                    waypoints2 = [15 -30 0;
                                  15  30 0];

                    traj1 = waypointTrajectory(waypoints1, timeOfArrival);
                    traj2 = waypointTrajectory(waypoints2, timeOfArrival);

                    trajectories = {traj1, traj2};

                otherwise
                    error("Unknown targetCase for piotrkowskaStreetCanyon: %s", targetCase);
            end

        otherwise
            error("Unknown scenarioName: %s", scenarioName);
    end
end