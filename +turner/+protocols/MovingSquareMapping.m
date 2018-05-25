classdef MovingSquareMapping < clandininlab.protocols.ClandininLabStageProtocol
    
    properties
        preTime = 500                   % Leading duration (ms)
        stimTime = 5000                 % Duration (ms)
        tailTime = 500                  % Trailing duration (ms)
        intensity = 0                   % intensity of square (0-1)
        speed = 30                      % Deg/sec.
        backgroundIntensity = 0.5       % Background light intensity (0-1)
        numberOfAverages = uint16(100)  % Number of epochs
        squareSize = 10                 % Deg.
        azimuths = -40:10:40            % Deg.
        elevations = 5:10:55            % Deg.    
        randomizeOrder = false          % Randomize sequence of locations t/f
    end
    
    properties (Hidden)
        movementAxisSequence
        locationSequence
        currentLocation
        currentAxis
    end

    methods
        
        function didSetRig(obj)
            didSetRig@clandininlab.protocols.ClandininLabStageProtocol(obj);
        end
        
        function p = getPreview(obj, panel)
            if isempty(obj.rig.getDevices('Stage'))
                p = [];
                return;
            end
            p = io.github.stage_vss.previews.StagePreview(panel, @()obj.createPresentation(), ...
                'windowSize', obj.rig.getDevice('Stage').getTrueCanvasSize());
        end
        
        function prepareRun(obj)
            prepareRun@clandininlab.protocols.ClandininLabStageProtocol(obj);
            
            % Create sequences for location and axis search(1 = az, 2 = el)
            obj.locationSequence = [obj.azimuths obj.elevations];
            obj.movementAxisSequence = [ones(size(obj.azimuths)), 2*ones(size(obj.elevations))];
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@clandininlab.protocols.ClandininLabStageProtocol(obj, epoch);
            
            % Determine current azimuth & elevation
            index = mod(obj.numEpochsCompleted, size(obj.locationSequence,2)) + 1;
            % Randomize the bar width sequence order at the beginning of each sequence.
            if index == 1 && obj.randomizeOrder
                randInds = randperm(size(obj.locationSequence,2));
                obj.locationSequence = obj.locationSequence(randInds);
                obj.movementAxisSequence = obj.movementAxisSequence(randInds);
            end
            obj.currentLocation = obj.locationSequence(index);
            obj.currentAxis = obj.movementAxisSequence(index);
            
            epoch.addParameter('currentLocation', obj.currentLocation);
            epoch.addParameter('currentAxis', obj.currentAxis);
        end
        
        function p = createPresentation(obj)
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            
            % Set background intensity for presentation
            p.setBackgroundColor(obj.backgroundIntensity);
            
            % "Rectangle" stimulus:
            Rect = clandininlab.stimuli.Rectangle();
            Rect.width = obj.squareSize;
            Rect.height = obj.squareSize;
            Rect.color = obj.intensity;
            startPosition = -60;
            if obj.currentAxis == 1 %az search (move thru el)
                Rect.azimuth = obj.currentLocation;
                movementController = stage.builtin.controllers.PropertyController(Rect, 'elevation',@(state)startPosition + obj.speed*state.time);
            elseif obj.currentAxis == 2 %el search (move thru az)
                Rect.elevation = obj.currentLocation;
                movementController = stage.builtin.controllers.PropertyController(Rect, 'azimuth',@(state)startPosition + obj.speed*state.time);
            end
            p.addStimulus(Rect);
            p.addController(movementController); %add the movement controller

            % Visibility controller
            rectVisible = stage.builtin.controllers.PropertyController(Rect, 'visible', @(state)state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3);
            p.addController(rectVisible);
        end
  
        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages;
        end
        
    end
    
end

