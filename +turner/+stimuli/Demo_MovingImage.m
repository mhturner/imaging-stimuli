presentation = stage.core.Presentation(5);
windowSize = [800, 600];
window = stage.core.Window(windowSize, false);
canvas = turner.stage.Canvas(window, 'disableDwm', false);

%Set projection matrix
projection = turner.stage.MatrixStack();
projection.flyPerspective(windowSize);
canvas.setProjection(projection); %set perspective

imagesDir = '~/Dropbox/ClandininLab/imaging-stimuli/resources/images/';
butterflyImage = imread(fullfile(imagesDir, 'butterfly.jpg'));

%Image stimulus:
Image = turner.stimuli.Image(butterflyImage);
    %Properties of sphere:
Image.radius = 1;
Image.height = 1;
Image.contrast = 1;
Image.position = [0 0 0];
% Image.color = [0 0 1];
Image.orientation = 0;
% Image.thetaLimits = [0, 2*pi];
% Image.phiLimits = [0, pi];

shiftController = stage.builtin.controllers.PropertyController(Image, 'shiftX', @(state)90*state.time);

% Frame tracker stimulus:
Tracker = turner.stimuli.FrameTracker();

presentation.addStimulus(Image);
presentation.addController(shiftController);
presentation.addStimulus(Tracker);


presentation.play(canvas);
 