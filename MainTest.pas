unit MainTest;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  NMUDP, ExtCtrls, Psock, NMMSG, StdCtrls, iEditCustom, iAnalogOutput,
  iComponent, iVCLComponent, iPlotComponent, iPlot, ComCtrls, LbButton,
  iLed, iLedRectangle, iSevenSegmentDisplay, iSevenSegmentAnalog,Jpeg,ShellAPI,
  LbSpeedButton, iLedRound, iAnalogDisplay, LbStaticText, IniFiles, EController;


type
  TMyThread = class(TThread)
    procedure Execute; override;
  end;

  TFrmEcyTest = class(TForm)
    Timer1: TTimer;
    SaveDialog1: TSaveDialog;
    PC1: TPageControl;
    TabSheet4: TTabSheet;
    iPlot1: TiPlot;
    Panel8: TPanel;
    Btn_Run1: TLbSpeedButton;
    Btn_Stop1: TLbSpeedButton;
    Panel2: TPanel;
    Disp_GivPos1: TiSevenSegmentAnalog;
    Disp_ActPos1: TiSevenSegmentAnalog;
    Disp_Force1: TiSevenSegmentAnalog;
    Disp_Speed1: TiSevenSegmentAnalog;
    TabSheet11: TTabSheet;
    Control_Led: TiLedRound;
    Btn_In1: TLbSpeedButton;
    Btn_Out1: TLbSpeedButton;
    Label4: TLabel;
    Disp_RunCount1: TiSevenSegmentAnalog;
    Bevel1: TBevel;
    Panel13: TPanel;
    Disp_CH0_S: TiSevenSegmentAnalog;
    iPlot0: TiPlot;
    Panel14: TPanel;
    Btn_Run0: TLbSpeedButton;
    Btn_Stop0: TLbSpeedButton;
    CK_CH0: TCheckBox;
    Disp_CH1_S: TiSevenSegmentAnalog;
    Disp_CH2_S: TiSevenSegmentAnalog;
    Disp_CH3_S: TiSevenSegmentAnalog;
    Disp_CH0_F: TiSevenSegmentAnalog;
    Disp_CH1_F: TiSevenSegmentAnalog;
    Disp_CH2_F: TiSevenSegmentAnalog;
    Disp_CH3_F: TiSevenSegmentAnalog;
    Panel9: TPanel;
    Btn_CH1: TLbSpeedButton;
    Btn_CH2: TLbSpeedButton;
    Btn_CH3: TLbSpeedButton;
    Btn_CH4: TLbSpeedButton;
    Btn_Save: TLbSpeedButton;
    Btn_CH0: TLbSpeedButton;
    Btn_RunPara: TLbSpeedButton;
    Btn_SetEP: TLbSpeedButton;
    Btn_Close: TLbSpeedButton;
    Btn_ShowPlot: TLbSpeedButton;
    Label28: TLabel;
    Disp_CommCount1: TiSevenSegmentAnalog;
    Label29: TLabel;
    Led_ChState: TiLedRectangle;
    Label30: TLabel;
    Lb_CtrMode: TLbStaticText;
    CK_GivPos: TCheckBox;
    CK_ActPos: TCheckBox;
    CK_Force: TCheckBox;
    CK_Speed: TCheckBox;
    CK_S0: TCheckBox;
    CK_F0: TCheckBox;
    CK_F1: TCheckBox;
    CK_S1: TCheckBox;
    CK_S2: TCheckBox;
    CK_F2: TCheckBox;
    CK_F3: TCheckBox;
    CK_S3: TCheckBox;
    CK_CH1: TCheckBox;
    CK_CH2: TCheckBox;
    CK_CH3: TCheckBox;
    Led_CH0: TiLedRectangle;
    Led_CH1: TiLedRectangle;
    Led_CH2: TiLedRectangle;
    Led_CH3: TiLedRectangle;
    Btn_SetZero: TLbSpeedButton;
    LbSpeedButton1: TLbSpeedButton;
    LbSpeedButton2: TLbSpeedButton;
    BtnAllIn: TLbSpeedButton;
    BtnAllOut: TLbSpeedButton;
    Btn_Help: TLbSpeedButton;
    procedure Timer1Timer(Sender: TObject);
    procedure Btn_Stop1Click(Sender: TObject);
    procedure Btn_Run1Click(Sender: TObject);
    procedure BtnSave1Click(Sender: TObject);
    procedure Btn_In1Click(Sender: TObject);
    procedure Btn_Run0Click(Sender: TObject);
    procedure Btn_Stop0Click(Sender: TObject);
    procedure Btn_CH1Click(Sender: TObject);
    procedure Btn_CloseClick(Sender: TObject);
    procedure Btn_ShowPlotClick(Sender: TObject);
    procedure Btn_SetEPClick(Sender: TObject);
    procedure CK_GivPosClick(Sender: TObject);
    procedure Btn_RunParaClick(Sender: TObject);
    procedure Btn_SetZeroClick(Sender: TObject);
    procedure LbSpeedButton1Click(Sender: TObject);
    procedure LbSpeedButton2Click(Sender: TObject);
    procedure BtnAllInClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Btn_HelpClick(Sender: TObject);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmEcyTest: TFrmEcyTest;
  MyThread:TMyThread;
  ThreadRun:Boolean;
  ActiveCH: Integer;
  ActiveEC: TEController;
  ECys: array[0..3]of TECylinder;
  MyTimer1:TMyTimer;

const  MAX_CHANNEL_NUM=4;

implementation

{$R *.DFM}


procedure TMyThread.Execute;
var i:integer;
    ActivePlot:TiPlot;
begin
  ThreadRun:=True;
  self.Priority:=tpHighest; 
  while not Application.Terminated do
  begin
    if ActiveEC.DataChanged and (FrmECyTest.Btn_ShowPlot.Color=clYellow) then
    begin
      if ActiveCH=0 then
      begin
        ActivePlot:=FrmECyTest.iPlot0;
        for i:=0 to ActivePlot.ChannelCount-1 do
          if ActivePlot.Channel[i].Visible then
          begin
            if i<4 then ActivePlot.Channel[i].AddXY(MyTimer1.GetTime(0),ECys[i].TD.actpos)
            else ActivePlot.Channel[i].AddXY(MyTimer1.GetTime(0),ECys[i-4].TD.actforce);
          end;
      end
      else
      begin
        ActivePlot:=FrmECyTest.iPlot1;
        with ActivePlot.Channel[0] do if Visible then AddXY(MyTimer1.GetTime(0),ECys[ActiveCH-1].TD.givpos);
        with ActivePlot.Channel[1] do if Visible then AddXY(MyTimer1.GetTime(0),ECys[ActiveCH-1].TD.actpos);
        with ActivePlot.Channel[2] do if Visible then AddXY(MyTimer1.GetTime(0),ECys[ActiveCH-1].TD.actforce);
        with ActivePlot.Channel[3] do if Visible then AddXY(MyTimer1.GetTime(0),ECys[ActiveCH-1].TD.speed);
      end;

      if MyTimer1.GetTime(0)>ActivePlot.XAxis[0].Max then ActivePlot.XAxis[0].Min:=ActivePlot.XAxis[0].Min+ActivePlot.XAxis[0].Span/4;
      if MyTimer1.GetTime(0)>3600 then
      begin
        MyTimer1.Clear(0);
        ActivePlot.ClearAllData;
        ActivePlot.XAxis[0].Min:=0;
      end;
    end;
    if ActiveEC.DataChanged then ActiveEC.DataChanged:=False;
  end;
  ThreadRun:=False;
end;

procedure TFrmEcyTest.Timer1Timer(Sender: TObject);
var Disp_GivPos,Disp_ActPos,Disp_Force,Disp_Speed,Disp_RunCount: TiSevenSegmentAnalog;
    Btn_Run,Btn_Stop,Btn_In,Btn_Out:TLbSpeedButton;
    i:Integer;
    runflag:Boolean;
    Led: TiLedRectangle;
    CK:TCheckBox;
begin
  if ActiveCH>0 then
  begin
    with ECys[ActiveCH-1] do
    begin
      Disp_GivPos1.Value:=TD.givpos;
      Disp_ActPos1.Value:=TD.actpos;
      Disp_Force1.Value:=TD.actforce;
      Disp_Speed1.Value:=TD.speed;
      Disp_RunCount1.Value:=TD.runcount;

      if TD.ctrmode=POS_CONTROL then Lb_CtrMode.Caption:='位置控制'
      else if TD.ctrmode=FORCE_CONTROL then Lb_CtrMode.Caption:='力控制'
      else if TD.ctrmode=SPEED_CONTROL then Lb_CtrMode.Caption:='速度控制';

      Led_ChState.Active:=ActiveState;

      if TD.runstate=0 then Btn_Stop1.Color:=clRed
      else Btn_Stop1.Color:=$00ECCE94;
      if TD.runstate=1 then Btn_Run1.Color:=clLime
      else Btn_Run1.Color:=$00ECCE94;
      if TD.runstate=2 then Btn_In1.Color:=clLime
      else Btn_In1.Color:=$00ECCE94;
      if TD.runstate=3 then Btn_Out1.Color:=clLime
      else Btn_Out1.Color:=$00ECCE94;
    end;

    Btn_Run1.Enabled:=Led_ChState.Active;
    //Btn_Stop1.Enabled:=Btn_Run1.Enabled;
    Btn_In1.Enabled:=Btn_Run1.Enabled;
    Btn_Out1.Enabled:=Btn_Run1.Enabled;
  end
  else
  begin
    if (ECys[0].TD.runstate=0) and (ECys[1].TD.runstate=0) and (ECys[2].TD.runstate=0) and (ECys[3].TD.runstate=0) then
    begin
      Btn_Stop0.Color:=clRed;   Btn_Run0.Color:=$00ECCE94;
    end
    else
    begin
      Btn_Run0.Color:=clLime;   Btn_Stop0.Color:=$00ECCE94;
    end;

    for i:=0 to 3 do
    begin
      Led:=FindComponent('Led_CH'+IntToStr(i)) as TiLedRectangle;
      Led.Active:=ECys[i].ActiveState;
      CK:=FindComponent('CK_CH'+IntToStr(i)) as TCheckBox;
      CK.Enabled:=Led.Active;
      if not CK.Enabled then CK.Checked:=False;

      Disp_ActPos:=FindComponent('Disp_CH'+IntToStr(i)+'_S') as TiSevenSegmentAnalog;
      Disp_Force:=FindComponent('Disp_CH'+IntToStr(i)+'_F') as TiSevenSegmentAnalog;
      if Disp_ActPos<>nil then
      begin
        Disp_ActPos.PowerOff:=not Led.Active;
        Disp_ActPos.Value:=ECys[i].TD.actpos;
      end;
      if Disp_Force<>nil then
      begin
        Disp_Force.PowerOff:=not Led.Active;
        Disp_Force.Value:=ECys[i].TD.actforce;
      end;
    end;
  end;

  if ActiveCH>0 then Disp_CommCount1.Value:=ActiveEC.UDPComm_Rate;
end;

procedure TFrmEcyTest.Btn_Stop1Click(Sender: TObject);
begin
  if ActiveCH>0 then ECys[ActiveCH-1].Stop;
end;

procedure TFrmEcyTest.Btn_Run1Click(Sender: TObject);
begin
  ECys[ActiveCH-1].AutoRun;
end;

procedure TFrmEcyTest.BtnSave1Click(Sender: TObject);
begin
  SaveDialog1.InitialDir:=ExtractFilePath(Application.ExeName);
  if SaveDialog1.Execute then
  begin
    if PC1.ActivePageIndex=0 then iPlot1.SaveDataToFile(SaveDialog1.FileName)
    else iPlot0.SaveDataToFile(SaveDialog1.FileName)
  end;
end;

procedure TFrmEcyTest.Btn_In1Click(Sender: TObject);
begin
  if (Sender as TLbSpeedbutton)=Btn_In1 then ECys[ActiveCH-1].RunFix(SPEED_CONTROL,1)
  else ECys[ActiveCH-1].RunFix(SPEED_CONTROL,-1);
end;

procedure TFrmEcyTest.Btn_Run0Click(Sender: TObject);
var i:Integer;
    CK:TCheckBox;
begin
  for i:=0 to 3 do
  begin
    CK:=FindComponent('CK_CH'+IntToStr(i)) as TCheckBox;
    if (CK<>nil) and CK.Checked then ECys[i].AutoRun;
  end;
end;

procedure TFrmEcyTest.Btn_Stop0Click(Sender: TObject);
var i:Integer;
begin
  for i:=0 to 3 do ECys[i].Stop;
end;

procedure TFrmEcyTest.Btn_CH1Click(Sender: TObject);
var i:Integer;
    Btn: TLbSpeedButton;
begin
  if ActiveCH<>(Sender as TLbSpeedButton).Tag then
  begin
    ActiveCH:=(Sender as TLbSpeedButton).Tag;
    if ActiveCH=0 then
    begin
      PC1.ActivePageIndex:=1;
      if Btn_ShowPlot.Color=clYellow then
      begin
        iPlot0.ClearAllData;
        iPlot0.XAxis[0].Min:=0;
        MyTimer1.Clear(0);
      end;
    end
    else
    begin
      PC1.ActivePageIndex:=0;
      if Btn_ShowPlot.Color=clYellow then
      begin
        iPlot1.ClearAllData;
        iPlot1.XAxis[0].Min:=0;
        MyTimer1.Clear(0);
      end;
    end;
  end;

  for i:=0 to 4 do
  begin
    Btn:=FindComponent('Btn_CH'+inttostr(i)) as TLbSpeedButton;
    if (Sender as TLbSpeedButton)=Btn then Btn.Color:=clYellow
    else Btn.Color:=$00ECCE94;
  end;
end;

procedure TFrmEcyTest.Btn_CloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmEcyTest.Btn_ShowPlotClick(Sender: TObject);
begin
  if Btn_ShowPlot.Color=clYellow then
  begin
    Btn_ShowPlot.Color:=clSilver;
  end
  else
  begin
    Btn_ShowPlot.Color:=clYellow;
    iPlot0.ClearAllData;
    iPlot0.XAxis[0].Min:=0;
    iPlot1.ClearAllData;
    iPlot1.XAxis[0].Min:=0;
    MyTimer1.Clear(0);
  end;
end;

procedure TFrmEcyTest.Btn_SetEPClick(Sender: TObject);
begin
  if ActiveCH>0 then ECys[ActiveCH-1].ShowEcyParaSetting;
end;

procedure TFrmEcyTest.CK_GivPosClick(Sender: TObject);
var CK:TCheckBox;
begin
  CK:=Sender as TCheckBox;
  if CK=CK_GivPos then iPlot1.Channel[0].Visible:=CK.Checked
  else if CK=CK_ActPos then iPlot1.Channel[1].Visible:=CK.Checked
  else if CK=CK_Speed then iPlot1.Channel[3].Visible:=CK.Checked
  else if CK=CK_Force then iPlot1.Channel[2].Visible:=CK.Checked
  else if CK=CK_S0 then iPlot0.Channel[0].Visible:=CK.Checked
  else if CK=CK_S1 then iPlot0.Channel[1].Visible:=CK.Checked
  else if CK=CK_S2 then iPlot0.Channel[2].Visible:=CK.Checked
  else if CK=CK_S3 then iPlot0.Channel[3].Visible:=CK.Checked
  else if CK=CK_F0 then iPlot0.Channel[4].Visible:=CK.Checked
  else if CK=CK_F1 then iPlot0.Channel[5].Visible:=CK.Checked
  else if CK=CK_f2 then iPlot0.Channel[6].Visible:=CK.Checked
  else if CK=CK_F3 then iPlot0.Channel[7].Visible:=CK.Checked
end;

procedure TFrmEcyTest.Btn_RunParaClick(Sender: TObject);
begin
  if ActiveCH>0 then ECys[ActiveCH-1].ShowRunSigSetting;
end;

procedure TFrmEcyTest.Btn_SetZeroClick(Sender: TObject);
begin
  ECys[ActiveCH-1].SetZero;
end;

procedure TFrmEcyTest.LbSpeedButton1Click(Sender: TObject);
var i:Integer;
    ec:TEController;
begin
  ec:=ShowControllerList;
  if ec<>nil then ActiveEC:=EC;
  for i:=0 to 3 do ECys[i]:=ActiveEC.ECys[i];
  Caption:='多通道电动缸综合测控软件-远程控制器'+ActiveEC.GetIPAddr;
end;

procedure TFrmEcyTest.LbSpeedButton2Click(Sender: TObject);
var FName:String;
begin
  FName:=ExtractFilePath(Application.ExeName)+'\TeamViewer\TeamViewer.exe';
  WinExec(pChar(FName), SW_SHOW);
end;

procedure TFrmEcyTest.BtnAllInClick(Sender: TObject);
var CK: TCheckBox;
    i:Integer;
begin
  for i:=0 to 3 do
  begin
    CK:=FindComponent('CK_CH'+IntToStr(i)) as TCheckBox;
    if (CK<>nil) and CK.Checked then
    begin
      if (Sender as TLbSpeedbutton)=BtnAllIn then ECys[i].RunFix(SPEED_CONTROL,1)
      else ECys[i].RunFix(SPEED_CONTROL,-1);
    end;
  end;
end;

procedure TFrmEcyTest.FormDestroy(Sender: TObject);
begin
  ThreadRun:=False;
  CloseECSystem;
end;

procedure TFrmEcyTest.FormShow(Sender: TObject);
var i:Integer;
begin
  InitECSystem;
  ActiveEC:=ShowControllerList;
  if ActiveEC=nil then ActiveEC:=ECs[0];
  for i:=0 to 3 do ECys[i]:=ActiveEC.ECys[i];

  Caption:='多通道电动缸综合测控软件--------'+ActiveEC.Caption+' IP:'+ActiveEC.GetIPAddr;

  MyTimer1:=TMyTimer.Create;
  TMyThread.Create(False);

  for i:=0 to PC1.PageCount-1 do PC1.Pages[i].TabVisible:=False;
  Btn_CH1.Click;
  Timer1.Enabled:=True;
end;

procedure TFrmEcyTest.Btn_HelpClick(Sender: TObject);
begin
  ECys[0].ClearSig;
  ECys[0].AddSigSpeed(POS_CONTROL,REALTIMEPOS,100,100,0,0);
  ECys[0].AddSigSin(POS_CONTROL,50,0.5,REALTIMEPOS,1);
  ECys[0].Run;
end;

end.



