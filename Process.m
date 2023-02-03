function Process(input_Folder_name,...
    Output_Folder_name,...
    Slice_pic_num,...
    Pic_begin,...
    Pic_end,...
    Macrofile_name,...
    CreateVideo,...
    AnalyzeData,...
    dt,Rate)
%% Results name input
    Videoname = 'ResultVideo'; % Name of video results
    Area_Analyze_name = 'Area_Analyze'; % name of Pic after Area analyzing 
    Area_Analyze_P_name = 'Area_Analyze_P'; % name of Pic after Area analyzing (Positive)
    Area_Analyze_trend_name = 'Area_Analyze_trend';% name of Pic showing trend 
    Area_Coeff_name ='Area_Coeff'; % Matlab file name for Area
    Velocity_Analyze_name = 'Velocity_Analyze'; % name of Pic after Velocity analyzing 
    Velocity_Coeff_name = 'Velocity_Coeff'; % Matlab file name for Velocity
    %% Address
    fol = [pwd,'\'];
    fol_Input=[fol,'Input\',input_Folder_name,'\'];
    fol_IJ=[fol,'IJ_lib\'];
    fol_Macro=[fol,'Macro\'];
    fol_Output=[fol,'Output\'];
    if ~exist(fol_Output); mkdir(fol_Output);end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Add Jave Library
    javaaddpath([fol_IJ,'mij.jar'])
    javaaddpath([fol_IJ,'ij.jar'])
    %% Soft Name of Picture File
    Folder = dir(fol_Input);
    Folder(1:2,:)=[];
    for i=1:size(Folder,1)
        File{i,1}=Folder(i).name;
    end
    File = natsortfiles(File);
    %% Create or Check the Output Folder
    if isfolder([fol_Output,Output_Folder_name,'\']) ==0
        mkdir([fol_Output,Output_Folder_name,'\']);
        mkdir([fol_Output,Output_Folder_name,'\OutPut_Pic']);
        mkdir([fol_Output,Output_Folder_name,'\OutPut_Video']);
        mkdir([fol_Output,Output_Folder_name,'\OutPut_Data']);
        mkdir([fol_Output,Output_Folder_name,'\Area_Analysis']);
        mkdir([fol_Output,Output_Folder_name,'\Velocity_Analysis']);
    end
    %% Method
    MIJ.start;IJ=ij.IJ();
    u=1;
    for p=Pic_begin:Pic_end
        for i = (p-1)*Slice_pic_num+1:p*Slice_pic_num
            path=['path=[',fol_Input,File{i},']'];
            MIJ.run('Open...', path);
        end
        % Run Macro code
        IJ.runMacroFile([fol_Macro,Macrofile_name,'.ijm']);
        % Save Data in CSV file and Picture
        IJ.saveAs('Results', [fol_Output,Output_Folder_name,'\OutPut_Data\Results_pic_',num2str(p),'.csv']);
        IJ.saveAs('PNG', [fol_Output,Output_Folder_name,'\OutPut_Pic\Results_pic_',num2str(p),'.png']);
        % Import Data from ImageJ to Matlab
        RawData{u}=MIJ.getResultsTable;
        RawData{u}(:,2:end)=[];
        u=u+1;
        % Close all windows in ImageJ
        MIJ.closeAllWindows
    end
    % Exit ImageJ
    MIJ.exit;
    clc
    %% Make Video
    switch upper(CreateVideo)
        case 'Y'
            PicFolder=dir([fol_Output,Output_Folder_name,'\OutPut_Pic']);
            PicFolder(1:2,:)=[];
            for i=1:size(PicFolder,1)
                PicFile{i,1}=PicFolder(i).name;
            end
            PicFile = natsortfiles(PicFile);
            writerObj = VideoWriter([fol_Output,Output_Folder_name,'\OutPut_Video\',Videoname,'.avi']);
            writerObj.FrameRate = Rate;
            open(writerObj);
            for u=1:length(PicFile)
                frame = imread([fol_Output,Output_Folder_name,'\OutPut_Pic\',PicFile{u}]);
                writeVideo(writerObj, frame);
            end
            close(writerObj);
        case 'N'
            warning('Not create video');
        otherwise
            warning('Not create video & Next time just (Y/N)');
    end
    %% Calculation
    switch upper(AnalyzeData)
        case 'Y'
            %% Calculation: Area analysis
            time=(dt*(1:length(RawData))-dt)';
            for i=1:length(RawData)
                Area_Data(i,1)=sum(RawData{i});
            end
            Average_Area_Increasing=Area_Data(end)-Area_Data(1);
            % Positive Area
            [Pos_Area,t]=Positive_Area(Area_Data,time);
            % Trend of increasing Area
            trend=Area_Data-detrend(Area_Data,2);
            % Regression Coefficient for Areaz
            [Coeff,S] = polyfit(time,Area_Data,2);
            [Re_Area_Data,delta] = polyval(Coeff,time,S); 
            [Coeff_P,S_P] = polyfit(t,Pos_Area,2);
            [Re_Area_Data_P,delta_P] = polyval(Coeff_P,t,S_P); 
            %% Calculation: Veloity analysis 
            % Velocity Data
            V_Data=diff(Area_Data)/dt;
            % Average Velocity
            Average_Velocity=Average_Area_Increasing/time(end);
            % Velocity Data (Positive)
            V_Data_P=diff(Pos_Area)./diff(t);
            % Mean & Std
            M_v=mean(V_Data_P);
            St_v=std(V_Data_P);
            %% Plot
            % Plot 1
            fig1=figure('Position',[250 100 1080 606]);
            plot(time,Area_Data,'bo','MarkerSize',3,'MarkerFaceColo','b');hold on
            plot(time,Re_Area_Data,'r','LineWidth',2);
            plot(time,Re_Area_Data+2*delta,'m--','LineWidth',1);
            plot(time,Re_Area_Data-2*delta,'m--','LineWidth',1);
            legend('Original Data', 'Curve fitting Data','95% Prediction Interval','Location','southeast')
            xlabel('Time (min)','FontWeight','bold');
            ylabel('Area (\mum^{2})','FontWeight','bold');
            title('Regression for Area Data','FontWeight','bold','FontSize',12)
            NW = [min(xlim) max(ylim)]+[diff(xlim) -diff(ylim)]*0.03;
            text(NW(1),NW(2),['Average Area Increasing: ',...
                num2str(Average_Area_Increasing/1000),'x10^{4}\mum^{2}'],'FontWeight','bold','FontSize',12)
            grid on
            % Plot 2
            fig2=figure('Position',[250 100 1080 606]);
            plot(t,Pos_Area,'bo','MarkerSize',3,'MarkerFaceColo','b');hold on
            plot(t,Re_Area_Data_P,'r','LineWidth',2);
            plot(t,Re_Area_Data_P+2*delta_P,'m--','LineWidth',1);
            plot(t,Re_Area_Data_P-2*delta_P,'m--','LineWidth',1);
            legend('Original Data', 'Curve fitting Data','95% Prediction Interval','Location','southeast')
            xlabel('Time (min)','FontWeight','bold');
            ylabel('Area (\mum^{2})','FontWeight','bold');
            title('Regression for Area Data','FontWeight','bold','FontSize',12)
            NW = [min(xlim) max(ylim)]+[diff(xlim) -diff(ylim)]*0.03;
            text(NW(1),NW(2),['Average Area Increasing: ',...
                num2str(Average_Area_Increasing/1000),'x10^{4}\mum^{2}'],'FontWeight','bold','FontSize',12)
            grid on
            % Plot 3
            fig3=figure('Position',[250 100 1080 606]);
            plot(time,trend,'r','LineWidth',2);
            xlabel('Time (min)','FontWeight','bold');
            ylabel('Trend','FontWeight','bold');
            title('The Graph Shows the Trend of Area Data','FontWeight','bold','FontSize',12)
            grid on
            axis tight
            % Plot 4
            fig4=figure('Position',[250 100 1080 606]);
            subplot(211)
            plot(V_Data,'LineWidth',2);
            xlabel('n (times)','FontWeight','bold');
            ylabel('Velocity (\mum^{2}/min)','FontWeight','bold');
            title('Representation of Velocity Over Time','FontWeight','bold','FontSize',12)
            SW = [min(xlim) min(ylim)]+[diff(xlim) diff(ylim)]*0.08;
            text(SW(1),SW(2),['Average Velocity: ',num2str(Average_Velocity),...
                '\mum^{2}/min'],'FontWeight','bold','FontSize',12);
            grid on
            subplot(212)
            plot(V_Data_P,'LineWidth',2);
            xlabel('n (times)','FontWeight','bold');
            ylabel('Velocity (\mum^{2}/min)','FontWeight','bold');
            title('Representation of Velocity Over Time (Absolute)','FontWeight','bold','FontSize',12)
            NW = [min(xlim) max(ylim)]+[diff(xlim) -diff(ylim)]*0.08;
            text(NW(1),NW(2),['Mean & STD in Velocity Data'],'FontWeight','bold','FontSize',12);
            text(NW(1),NW(2)+[-diff(ylim)]*0.1,[num2str(M_v),'\pm',num2str(St_v),'\mum^{2}/min'],...
                'FontWeight','bold','FontSize',12);
            grid on
            %% Save Picture and Coeff 
            saveas(fig1,[fol_Output,Output_Folder_name,'\Area_Analysis\',Area_Analyze_name,'.png'])
            saveas(fig2,[fol_Output,Output_Folder_name,'\Area_Analysis\',Area_Analyze_P_name,'.png'])
            saveas(fig3,[fol_Output,Output_Folder_name,'\Area_Analysis\',Area_Analyze_trend_name,'.png'])
            saveas(fig4,[fol_Output,Output_Folder_name,'\Velocity_Analysis\',Velocity_Analyze_name,'.png'])
            save([fol_Output,Output_Folder_name,'\Velocity_Analysis\',Velocity_Coeff_name],...
                'V_Data','V_Data_P','Average_Velocity','M_v','St_v','dt','time','t');
            save([fol_Output,Output_Folder_name,'\Area_Analysis\',Area_Coeff_name],...
                'Average_Area_Increasing','trend',...
                'Area_Data','dt','time','Coeff','delta',...
                'Pos_Area','t','Coeff_P','delta_P');
        case 'N'
            warning('Process stop');
        otherwise
            warning('Process stop & Next time just (Y/N)');
    end
end