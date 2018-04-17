presentation = stage.core.Presentation(5);
window = stage.core.Window([600, 600], false);
canvas = stage.core.Canvas(window, 'disableDwm', false);

projection = turner.stage.MatrixStack();
% projection.perspective(90, canvas.width/canvas.height);
projection.flyPerspective();
canvas.setProjection(projection); %set perspective 


Grate = turner.stimuli.Grating('square');
Grate.radius = 1;
Grate.height = 1;
Grate.position = [0 0 0];
Grate.opacity = 1;
% Grate.color = [0 0 1];
Grate.orientation = 0;
% Grate.size = [5000,5000];
% 
% cylinder.setMinFunction(GL.NEAREST); %don't interpolate to scale up board
% cylinder.setMagFunction(GL.NEAREST);

imagesDir = '~/Dropbox/ClandininLab/imaging-stimuli/resources/Images/';
[flowersImage, ~, flowersAlpha] = imread(fullfile(imagesDir, 'wildflowersBW.jpg'));
checks = repmat([0 1; 1 0],40,40);
% cylinder.setImageMatrix(255*uint8(checks));



cylinderAngularController = stage.builtin.controllers.PropertyController(Grate, 'angularPosition', @(state)360*state.time/8);


presentation.addStimulus(Grate);
presentation.addController(cylinderAngularController);

rectangle = stage.builtin.stimuli.Rectangle();
% presentation.addStimulus(rectangle);

presentation.play(canvas);
 