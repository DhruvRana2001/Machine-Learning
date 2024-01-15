function [sys,x0,str,ts,simStateCompliance] = IP_Anim(t,x,u,flag,RefBlock)

    %IP_Anim S-function for making pendulum animation.
    
    % Plots every major integration step, but has no states of its own
    switch flag,
    
      %%%%%%%%%%%%%%%%%%
      % Initialization %
      %%%%%%%%%%%%%%%%%%
      case 0,
        [sys,x0,str,ts,simStateCompliance]=mdlInitializeSizes(RefBlock,t);
    
      %%%%%%%%%%
      % Update %
      %%%%%%%%%%
      case 2,
        sys=mdlUpdate(t,x,u);
    
      %%%%%%%%%%%%%
      % Terminate %
      %%%%%%%%%%%%%
      case 9,
        sys=mdlTerminate();
        
      %%%%%%%%%%%%%%%%
      % Unused flags %
      %%%%%%%%%%%%%%%%
      case { 1, 3, 4},
        sys = [];
       
      %%%%%%%%%%%%%%%%%%%%
      % Unexpected flags %
      %%%%%%%%%%%%%%%%%%%%
      otherwise
        error(message('simdemos:general:UnhandledFlag', num2str( flag )));
    end
end

%
%=============================================================================
% mdlInitializeSizes
% Return the sizes, initial conditions, and sample times for the S-function.
%=============================================================================
%
function [sys,x0,str,ts,simStateCompliance]=mdlInitializeSizes(RefBlock,t)

    %
    % call simsizes for a sizes structure, fill it in and convert it to a
    % sizes array.
    %
    sizes = simsizes;
    
    sizes.NumContStates  = 0;
    sizes.NumDiscStates  = 0;
    sizes.NumOutputs     = 0;
    sizes.NumInputs      = 5;
    sizes.DirFeedthrough = 1;
    sizes.NumSampleTimes = 1;
    
    sys = simsizes(sizes);
    
    %
    % initialize the initial conditions
    %
    x0  = [];
    
    %
    % str is always an empty matrix
    %
    str = [];
    
    %
    % initialize the array of sample times, for the pendulum example,
    % the animation is updated every x seconds
    %
    ts  = [-1 0];
    
    %
    % create the figure, if necessary
    %
    LocalPendInit(RefBlock,t);
    
    % specify that the simState for this s-function is same as the default
    simStateCompliance = 'DefaultSimState';

end % end mdlInitializeSizes

%
%=============================================================================
% mdlUpdate
% Update the pendulum animation.
%=============================================================================
%
function sys=mdlUpdate(t,~,u)

    fig = get_param(gcbh,'UserData');
    if ishghandle(fig, 'figure')
      if strcmp(get(fig,'Visible'),'on')
        ud = get(fig,'UserData');
        LocalPendSets(t,ud,u);
      end
    end

    sys = [];

end % end mdlUpdate

%
%=============================================================================
% mdlTerminate
%=============================================================================
%
function sys=mdlTerminate()
    
    fig = get_param(gcbh,'UserData');
    if ishghandle(fig, 'figure')
      delete(fig);
    end
    
    sys = [];

end % end mdlTerminate

%
%=============================================================================
% LocalPendInit
% Local function to initialize the pendulum animation.  If the animation
% window already exists, it is brought to the front.  Otherwise, a new
% figure window is created.
%=============================================================================
%
function LocalPendInit(RefBlock,time)
    
    %
    % The name of the reference is derived from the name of the
    % subsystem block that owns the pendulum animation S-function block.
    % This subsystem is the current system and is assumed to be the same
    % layer at which the reference block resides.
    %
    sys = get_param(gcs,'Parent');

    TimeClock = time;
    RefSignal = str2double(get_param([sys '/' RefBlock],'Value'));
    XCart     = 0;
    Theta     = 0;
    
    XDelta    = 0.5;
    PDelta    = 0.05;
    JDelta    = 0.09;
    RDelta    = 0.09;
    PLength   = 3;
    GroundLine = -0.5;
    XPendTop  = XCart + PLength*sin(Theta);
    YPendTop  = PLength*cos(Theta);
    PDcosT    = PDelta*cos(Theta);
    PDsinT    = -PDelta*sin(Theta);
    
    if abs(RefSignal - XCart) > 5
        set_param(bdroot,'SimulationCommand','stop'); %Stop Sim
        disp("Refrence Signal is FAR from the cart. Please amek sure it is atleast within in 5m.");
    end

    %
    % The animation figure handle is stored in the pendulum block's UserData.
    % If it exists, initialize the reference mark, time, cart, and pendulum
    % positions/strings/etc.
    %
    Fig = get_param(gcbh,'UserData');
    if ishghandle(Fig ,'figure')
        FigUD = get(Fig,'UserData');
      
        set(FigUD.TimeField,...
          Text = num2str(TimeClock));
    
        set(FigUD.RefrencePositionField,...
          Text = num2str(RefSignal));
    
        set(FigUD.CartPositionField,...
          Text = num2str(XCart));
      
        set(FigUD.Cart,...
          XData = ones(2,1)*[XCart-XDelta XCart+XDelta]);
    
        set(FigUD.Joint,...
          XData = ones(2,1)*[XCart-JDelta XCart+JDelta]);
      
        set(FigUD.Pend,...
          XData = [XPendTop-PDcosT XPendTop+PDcosT; XCart-PDcosT XCart+PDcosT],...
          YData = [YPendTop-PDsinT YPendTop+PDsinT; -PDsinT PDsinT]);
      
        set(FigUD.RefMark,...
          XData = RefSignal+[-RDelta 0 RDelta]);

        if (abs(XCart - RefSignal) > 5)
            set(FigUD.SlideControl, ...
            Min = RefSignal - 5, ...
            Max = RefSignal + 5, ...
            Value = RefSignal);
        else
            set(FigUD.SlideControl, ...
            Min = XCart - 5, ...
            Max = XCart + 5, ...
            Value = RefSignal);
        end
            
        %
        % bring it to the front
        %
        figure(Fig);
        return;
    end

    %
    % the animation figure doesn't exist, create a new one and store its
    % handle in the animation block's UserData
    %
    FigureName = 'Inverted Pendulum Visualization';
    
    %Create UIFigure
    Fig = uifigure( ...
        Name = FigureName,  ...
        Units = "pixels", ...
        Position = [100 100 800 700], ...
        NumberTitle = 'off', ...
        Scrollable = 'off', ...
        IntegerHandle = 'off', ...
        HandleVisibility = 'callback', ...
        Resize = 'off', ...
        CloseRequestFcn = @(src,event)LocalClose(src));
    
    %Create UIAxes
    AxesH = uiaxes(Parent=Fig, ...
        XGrid = "on", ...
        YGrid = "off", ...
        YTick = [], ...,
        Xlim = XCart + [-5 5], ...
        YLim = [(GroundLine-PLength-0.5) ((11-GroundLine-PLength-0.5)+0.1)], ...
        Position = [1 150 800 550], ...
        Box = 'on', ...
        GridLineStyle = ':');
    xlabel(AxesH,"Distance (m)");
    AxesH.Toolbar.Visible = 'off';
    AxesH.Interactions = [];
    yline(AxesH,GroundLine,LineWidth=5,Color=[0 0 0]);
    
    % Create CloseButton
    uicontrol(...
        Parent = Fig, ...
        Style = 'pushbutton', ...
        Position = [673 12 110 23], ...
        String = 'Close', ...
        Callback = @(src,event)LocalClose(Fig));
    
    % Create DisturbPendulumButton
    uicontrol( ...
        Parent = Fig, ...
        Style = 'pushbutton', ...
        Position = [18 12 110 23], ...
        String = 'Disturb Pendulum', ...
        Visible='off');
    
    % Create RefrencePositionSlider
    SlideControl = uicontrol(...
      Parent = Fig,...
      Style = 'slider',...
      Position = [11 115 783 23],...
      Min = XCart - 5, ...
      Max = XCart + 5, ...
      Value = RefSignal, ...
      Callback = @(src,event)LocalSlider(src,event,Fig));
    
    % Create RefrencePositionLabel
    uilabel( ...
        Parent = Fig, ...
        HorizontalAlignment = 'center', ...
        Position = [116 70 144 23], ...
        Text = 'Refrence Position :');
    
    % Create RefrencePositionFeild
    RefrencePositionField = uilabel( ...
        Parent = Fig, ...
        HorizontalAlignment = 'center', ...
        Position = [242 70 94 23], ...
        Text = num2str(RefSignal));
    
     % Create CartPositionLabel
    uilabel( ...
        Parent = Fig, ...
        HorizontalAlignment = 'center', ...
        Position = [496 70 84 23], ...
        Text = 'Cart Position :');
    
    % Create CartPositionFeild
    CartPositionField = uilabel( ...
        Parent = Fig, ...
        HorizontalAlignment = 'center', ...
        Position = [579 70 94 23], ...
        Text = num2str(XCart));
    
    % Create TimeLabel
    uilabel( ...
        Parent = Fig, ...
        Text = 'Time : ', ...
        HorizontalAlignment = 'center', ...
        Position = [345.5 12 41 23]);
    
    % Create TimeFeild
    TimeField = uilabel( ...
        Parent = Fig, ...
        HorizontalAlignment = 'center', ...
        Position = [385.5 12 94 23], ...
        Text = num2str(TimeClock));
    
    Cart = surface(...
      Parent = AxesH,...
      XData = ones(2,1)*[XCart-XDelta XCart+XDelta],...
      YData = [0.5 0.5; -0.5 -0.5],...
      ZData = zeros(2),...
      FaceColor = 'blue');
    
    Joint = surface(...
      Parent = AxesH,...
      XData = ones(2,1)*[XCart-JDelta XCart+JDelta],...
      YData = [0.15 0.15; -0.15 -0.15],...
      ZData = zeros(2),...
      FaceColor = 'black');
    
    Pend = surface( ...
      Parent = AxesH,...
      XData = [XPendTop-PDcosT XPendTop+PDcosT; XCart-PDcosT XCart+PDcosT],...
      YData = [YPendTop-PDsinT YPendTop+PDsinT; -PDsinT PDsinT],...
      ZData = zeros(2),...
      FaceColor = 'red');

    RefMark = patch(...
      Parent = AxesH,...
      XData = RefSignal+[-RDelta 0 RDelta],...
      YData = [-0.5 0 -0.5],...
      FaceColor = 'cyan');

    %
    % all the HG objects are created, store them into the Figure's UserData
    %
    FigUD.AxesH                 = AxesH;
    FigUD.Cart                  = Cart;
    FigUD.Pend                  = Pend;
    FigUD.Joint                 = Joint;
    FigUD.RefrencePositionField = RefrencePositionField;
    FigUD.CartPositionField     = CartPositionField;
    FigUD.TimeField             = TimeField;
    FigUD.SlideControl          = SlideControl;
    FigUD.RefMark               = RefMark;
    FigUD.Block                 = get_param(gcbh,'Handle');
    FigUD.RefBlock              = get_param([sys '/' RefBlock],'Handle');
    set(Fig,'UserData',FigUD);

    drawnow
    
    %
    % store the figure handle in the animation block's UserData
    %
    set_param(gcbh,'UserData',Fig);

end

%
%=============================================================================
% LocalPendSets
% Local function to set the position of the graphics objects in the
% inverted pendulum animation window.
%=============================================================================
%
function LocalPendSets(time,ud,u)

    TimeClock = time;
    XCart     = u(2);
    Theta     = u(4);
    RefSignal = u(1);
    
    XDelta    = 0.5;
    PDelta    = 0.05;
    JDelta    = 0.09;
    RDelta    = 0.09;
    PLength   = 3;

    XPendTop  = XCart + PLength*sin(Theta);
    YPendTop  = PLength*cos(Theta);
    PDcosT    = PDelta*cos(Theta);
    PDsinT    = -PDelta*sin(Theta);

    set(ud.RefrencePositionField, ...
        Text = num2str(RefSignal));

    set(ud.CartPositionField, ...
        Text = num2str(XCart));

    set(ud.TimeField, ...
        Text = num2str(TimeClock));

    set(ud.Cart, ...
        XData = ones(2,1)*[XCart-XDelta XCart+XDelta]);

    set(ud.Joint, ...
        XData = ones(2,1)*[XCart-JDelta XCart+JDelta]);

    set(ud.Pend, ...
        XData = [XPendTop-PDcosT XPendTop+PDcosT; XCart-PDcosT XCart+PDcosT], ...
        YData = [YPendTop-PDsinT YPendTop+PDsinT; -PDsinT PDsinT]);

    set(ud.RefMark, ...
        XData = RefSignal+[-RDelta 0 RDelta]);

    set(ud.AxesH, ...
        Xlim = XCart + [-5 5]);
    
    if (abs(XCart - RefSignal) > 5)
        set(ud.SlideControl, ...
        Min = RefSignal - 5, ...
        Max = RefSignal + 5, ...
        Value = RefSignal);
    else
        set(ud.SlideControl, ...
        Min = XCart - 5, ...
        Max = XCart + 5, ...
        Value = RefSignal);
    end
    

end

%
%=============================================================================
% LocalClose
% The callback function for the animation window close button.  Delete
% the animation figure window.
%=============================================================================
%
function LocalClose(fig)
    ud = get(fig,'UserData');

    set_param(bdroot,'SimulationCommand','pause'); %Pause Sim
    selection = uiconfirm(fig, ...
        ['Closing the figure window will stop the simulation\' newline  'Do you want to close? '],...
        'Confirmation', ...
        Interpreter = 'latex');
        
        switch selection
            case 'OK'
                set_param(ud.RefBlock,'Value',num2str(0));
                delete(fig);
                set_param(bdroot,'SimulationCommand','stop'); %Stop Sim
            case 'Cancel'
                set_param(bdroot,'SimulationCommand','continue'); %Cont. Sim
                return
        end

end %endLocalClose

%
%=============================================================================
% LocalSlider
% The callback function for the animation window slider uicontrol.  Change
% the reference block's value.
%=============================================================================
%
function LocalSlider(src,~,fig)
    
    RefSignal = get(src,'Value');
    RDelta    = 0.09;

    ud = get(fig,'UserData');
    set_param(ud.RefBlock,'Value',num2str(get(src,'Value')));
    set(ud.RefMark,XData = RefSignal+[-RDelta 0 RDelta]);
    set(ud.RefrencePositionField, Text = num2str(RefSignal));

end % end LocalSlider