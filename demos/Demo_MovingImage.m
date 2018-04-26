presentation = stage.core.Presentation(4);
windowSize = [912, 1140]./2;
window = stage.core.Window(windowSize, false);
canvas = stage.core.Canvas(window);

%Set projection matrix
projection = stage.core.gl.MatrixStack();
projection.flyPerspective(windowSize);
canvas.setProjection(projection); %set perspective

imagesDir = '~/Dropbox/ClandininLab/imaging-stimuli/resources/images/';
butterflyImage = imread(fullfile(imagesDir, 'butterfly.jpg'));

%Image stimulus:
Image = clandininlab.stimuli.Image(butterflyImage);
    %Properties of sphere:
Image.radius = 1;
Image.position = [0 0 0];
Image.azimuth = 0;
Image.elevation = 0;
Image.orientation = 0;
Image.opacity = 0.5;
Image.shiftY = 0;
Image.thetaLimits = [0 2*pi];
Image.phiLimits = [0 1*pi];
Speed_degPerSecond = 0;
shiftControllerY = stage.builtin.controllers.PropertyController(Image, 'shiftY', @(state)Speed_degPerSecond*state.time);
shiftControllerX = stage.builtin.controllers.PropertyController(Image, 'shiftX', @(state)Speed_degPerSecond*state.time);

presentation.addStimulus(Image);
presentation.addController(shiftControllerY);
presentation.addController(shiftControllerX);

presentation.play(canvas);
 