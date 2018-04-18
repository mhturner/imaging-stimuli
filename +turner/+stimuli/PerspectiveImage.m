presentation = stage.core.Presentation(5);
window = stage.core.Window([600, 600], false);
canvas = turner.stage.Canvas(window, 'disableDwm', false);

%Set projection matrix
projection = turner.stage.MatrixStack();
projection.flyPerspective();
canvas.setProjection(projection); %set perspective 

%Grating stimulus:
Grate = turner.stimuli.Grating('square');
    %Properties of sphere:
Grate.radius = 1;
Grate.height = 1;
Grate.position = [0 0 -1];
Grate.opacity = 1;
% Grate.color = [0 0 1];
Grate.orientation = 0;

    %Properties of texture (grating):
Grate.size = [5000,5000];

sphereAngularController = stage.builtin.controllers.PropertyController(Grate, 'phase', @(state)360*state.time/8);

% Frame tracker stimulus:
Tracker = turner.stimuli.FrameTracker();

presentation.addStimulus(Grate);
presentation.addController(sphereAngularController);
presentation.addStimulus(Tracker);


presentation.play(canvas);
 