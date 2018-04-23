presentation = stage.core.Presentation(5);
windowSize = [800, 600];
window = stage.core.Window(windowSize, false);
canvas = stage.core.Canvas(window);

%Set projection matrix
projection = stage.core.gl.MatrixStack();
projection.flyPerspective(windowSize);
canvas.setProjection(projection); %set perspective 

%Grating stimulus:
Grate = turner.stimuli.Grating('square');

Grate.contrast = 0.5;
Grate.position = [0 0 0];
% Grate.color = [0 0 1];
Grate.orientation = 0;
Grate.spatialFreq = 1/10; %cpd
% Grate.thetaLimits = [0, 2*pi];
% Grate.phiLimits = [0, pi];

speed_cyclesPerSecond = 2;
phaseController = stage.builtin.controllers.PropertyController(Grate, 'phase', @(state)520*state.time*speed_cyclesPerSecond);

% Frame tracker stimulus:
Tracker = turner.stimuli.FrameTracker();

presentation.addStimulus(Grate);
presentation.addController(phaseController);
presentation.addStimulus(Tracker);


presentation.play(canvas);
 