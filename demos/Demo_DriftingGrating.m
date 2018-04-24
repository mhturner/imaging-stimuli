presentation = stage.core.Presentation(2);
windowSize = [912, 1140]./2;
window = stage.core.Window(windowSize, false);
canvas = stage.core.Canvas(window);

%Set projection matrix
projection = stage.core.gl.MatrixStack();
projection.flyPerspective(windowSize);
canvas.setProjection(projection); %set perspective 

%Grating stimulus:
Grate = clandininlab.stimuli.Grating('square');

Grate.contrast = 0.5;
Grate.position = [0 0 -2];
Grate.orientation = 0;
Grate.spatialFreq = 1/45; %cpd

speed_degPerSecond = 90;
thetaRange = rad2deg(Grate.thetaLimits(2) - Grate.thetaLimits(1));
nCycles = Grate.spatialFreq * thetaRange;
speed_texturesPerSecond = nCycles * speed_degPerSecond/thetaRange;

phaseController = stage.builtin.controllers.PropertyController(Grate, 'phase', @(state)speed_texturesPerSecond*360*state.time);

% Frame tracker stimulus:
Tracker = clandininlab.stimuli.FrameTracker();

presentation.addStimulus(Grate);
presentation.addController(phaseController);
presentation.addStimulus(Tracker);


presentation.play(canvas);
 