classdef FullFieldFlash < clandininlab.protocols.ClandininLabStageProtocol
    
    properties
        preTime = 1000                  % Leading duration (ms)
        stimTime = 2000                 % Duration (ms)
        tailTime = 1000                 % Trailing duration (ms)
        intensity = 1.0                 % Flash intensity (0-1)
        backgroundIntensity = 0.5       % Background light intensity (0-1)
        numberOfAverages = uint16(5)    % Number of epochs
    end
    
    properties (Hidden)

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
        end
        
        function p = createPresentation(obj)
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            
            % Set background intensity for presentation
            p.setBackgroundColor(obj.backgroundIntensity);
            
            % Uniform semisphere stimulus:
            Sphere = clandininlab.stimuli.PerspectiveSphere;
            Sphere.color = obj.intensity;
            p.addStimulus(Sphere);

            sphereVisible = stage.builtin.controllers.PropertyController(Sphere, 'visible', @(state)state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3);
            p.addController(sphereVisible);
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@clandininlab.protocols.ClandininLabStageProtocol(obj, epoch);
        end

        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages;
        end
        
    end
    
end

