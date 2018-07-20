classdef DriftingGrating < clandininlab.protocols.ClandininLabStageProtocol
    
    properties
        preTime = 2000                  % Leading duration (ms)
        stimTime = 10000                 % Duration (ms)
        tailTime = 2000                 % Trailing duration (ms)
        gratingProfile = 'square'       % square, sine, or sawtooth grating in space
        spatialFrequency = 0.1          % (c.p.d.)
        speed = 30                      % Degrees per second
        contrast = 0.9                  % Grating contrast
        backgroundIntensity = 0.5       % Background light intensity (0-1)
        orientation = 0:45:315          % Degrees. + is clockwise
        randomizeOrder = false
        numberOfAverages = uint16(40)    % Number of epochs
    end
    
    properties (Hidden)
        gratingProfileType = symphonyui.core.PropertyType('char', 'row', {'square', 'sine', 'sawtooth'})
        orientationSequence
        currentOrientation
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
            
            % Create orientation sequence.
            obj.orientationSequence = obj.orientation;
        end
        
        function p = createPresentation(obj)
            % Presentation duration
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            % Set background intensity for presentation
            p.setBackgroundColor(obj.backgroundIntensity);
            
            % Grating stimulus:
            Grate = clandininlab.stimuli.Grating(obj.gratingProfile);
            Grate.contrast = obj.contrast;
            Grate.color = 2 * obj.backgroundIntensity;
            Grate.orientation = obj.currentOrientation;
            Grate.spatialFreq = obj.spatialFrequency;
            p.addStimulus(Grate);

            % Use a phase controller to make the grating drift
            thetaRange = rad2deg(Grate.thetaLimits(2) - Grate.thetaLimits(1));
            nCycles = Grate.spatialFreq * thetaRange; % how many times is the texture repeated across the surface
            speed_cps = nCycles * obj.speed/thetaRange; %cycles of texture per second
            phaseController = stage.builtin.controllers.PropertyController(Grate, 'phase', @(state)360*state.time*speed_cps);
            p.addController(phaseController);
            
            % Use a visible controller to make the grating appear only
            % during the stim time
            grateVisible = stage.builtin.controllers.PropertyController(Grate, 'visible', @(state)state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3);
            p.addController(grateVisible);
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@clandininlab.protocols.ClandininLabStageProtocol(obj, epoch);
            
            index = mod(obj.numEpochsCompleted, length(obj.orientationSequence)) + 1;
            % Randomize the orientation sequence order at the beginning of each sequence.
            if index == 1 && obj.randomizeOrder
                randInds = randperm(length(obj.orientationSequence));
                obj.orientationSequence = obj.orientationSequence(randInds);
            end
            obj.currentOrientation = obj.orientationSequence(index);
            epoch.addParameter('currentOrientation', obj.currentOrientation);
        end

        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages;
        end
        
    end
    
end

