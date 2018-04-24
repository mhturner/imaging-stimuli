presentation = stage.core.Presentation(5);
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
Image.height = 1;
Image.position = [0 0 -1];
Image.orientation = 0;
shiftController = stage.builtin.controllers.PropertyController(Image, 'shiftX', @(state)90*state.time);

% Frame tracker stimulus:
Tracker = clandininlab.stimuli.FrameTracker();

presentation.addStimulus(Image);
presentation.addController(shiftController);
presentation.addStimulus(Tracker);


presentation.play(canvas);
 