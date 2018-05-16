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
% Grate.position = [0 0 0];
Grate.orientation = 90;
Grate.spatialFreq = 1/10; %cpd
Grate.phiLimits = [0 pi];
Grate.thetaLimits = [0*pi 2*pi];
Grate.azimuth = 0;
Grate.elevation = 0;
Grate.opacity = 0.5;
speed_degPerSecond = 50;
thetaRange = rad2deg(Grate.thetaLimits(2) - Grate.thetaLimits(1));
nCycles = Grate.spatialFreq * thetaRange;
speed_texturesPerSecond = nCycles * speed_degPerSecond/thetaRange;
phaseController = stage.builtin.controllers.PropertyController(Grate, 'phase', @(state)speed_texturesPerSecond*360*state.time);
presentation.addStimulus(Grate);
presentation.addController(phaseController);

%aperture mask
% Rectangle = clandininlab.stimuli.Rectangle();
% % Rectangle.position = [0 0 -0];
% Rectangle.color = 0.5;
% Rectangle.width = 120;
% Rectangle.height = 120;
% mask = stage.core.Mask.createCircularAperture(0.7,1024);
% Rectangle.setMask(mask);
% presentation.addStimulus(Rectangle);

presentation.play(canvas);
 