unit SingleCyTest;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  iPlotComponent, iPlot, LbStaticText, iLed, iLedRectangle, ExtCtrls,
  LbSpeedButton, StdCtrls, iComponent, iVCLComponent, iSevenSegmentDisplay,
  iSevenSegmentAnalog, EController;

type
  TFrmSingleCyTest = class(TForm)
    Panel2: TPanel;
    Label4: TLabel;
    Disp_GivPos1: TiSevenSegmentAnalog;
    Disp_ActPos1: TiSevenSegmentAnalog;
    Disp_Force1: TiSevenSegmentAnalog;
    Disp_Speed1: TiSevenSegmentAnalog;
    Disp_RunCount1: TiSevenSegmentAnalog;
    CK_GivPos: TCheckBox;
    CK_ActPos: TCheckBox;
    CK_Force: TCheckBox;
    CK_Speed: TCheckBox;
    Panel8: TPanel;
    Btn_Run1: TLbSpeedButton;
    Btn_Stop1: TLbSpeedButton;
    Btn_In1: TLbSpeedButton;
    Btn_Out1: TLbSpeedButton;
    Bevel1: TBevel;
    Label28: TLabel;
    Label29: TLabel;
    Label30: TLabel;
    Btn_SetZero: TLbSpeedButton;
    Disp_CommCount1: TiSevenSegmentAnalog;
    Led_ChState: TiLedRectangle;
    Lb_CtrMode: TLbStaticText;
    LbSpeedButton1: TLbSpeedButton;
    iPlot1: TiPlot;
    Btn_ShowPlot: TLbSpeedButton;
    Timer1: TTimer;
    procedure Timer1Timer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Btn_In1Click(Sender: TObject);
    procedure Btn_Run1Click(Sender: TObject);
    procedure Btn_Stop1Click(Sender: TObject);
    procedure Btn_SetZeroClick(Sender: TObject);
    procedure LbSpeedButton1Click(Sender: TObject);
    procedure Btn_ShowPlotClick(Sender: TObject);
    procedure CK_GivPosClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Ecy: TECylinder;
    MyTimer1:TMyTimer;
  end;

var
  FrmSingleCyTest: TFrmSingleCyTest;

implementation

{$R *.DFM}

procedure TFrmSingleCyTest.Timer1Timer(Sender: TObject);
begin
  if Btn_ShowPlot.Color=clYellow then
  begin
    with iPlot1.Channel[0] do if Visible then AddXY(MyTimer1.GetTime(0),ECy.TD.givpos);
    with iPlot1.Channel[1] do if Visible then AddXY(MyTimer1.GetTime(0),ECy.TD.actpos);
    with iPlot1.Channel[2] do if Visible then AddXY(MyTimer1.GetTime(0),ECy.TD.actforce);
    with iPlot1.Channel[3] do if Visible then AddXY(MyTimer1.GetTime(0),ECy.TD.speed);

    if MyTimer1.GetTime(0)>iPlot1.XAxis[0].Max then iPlot1.XAxis[0].Min:=iPlot1.XAxis[0].Min+iPlot1.XAxis[0].Span/4;
    if MyTimer1.GetTime(0)>3600 then
    begin
      MyTimer1.Clear(0);
      iPlot1.ClearAllData;
      iPlot1.XAxis[0].Min:=0;
    end;
  end;

  with ECy do
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
  Disp_CommCount1.Value:=ECy.ECtr.UDPComm_Rate;

  Btn_Run1.Enabled:=Led_ChState.Active;
  //Btn_Stop1.Enabled:=Btn_Run1.Enabled;
  Btn_In1.Enabled:=Btn_Run1.Enabled;
  Btn_Out1.Enabled:=Btn_Run1.Enabled;
end;

procedure TFrmSingleCyTest.FormShow(Sender: TObject);
var EP:TECyPara;
begin
  MyTimer1:=TMyTimer.Create;
  Caption:=ECy.ECtr.Caption+'--'+ECy.Caption;

  ECy.GetEcyPara(EP);
  iPlot1.YAxis[0].Min:=EP.screw_min;
  iPlot1.YAxis[0].Span:=Abs(EP.screw_max-EP.screw_min);
  iPlot1.YAxis[1].Min:=EP.force_min;
  iPlot1.YAxis[1].Span:=Abs(EP.force_max-EP.force_min);
end;

procedure TFrmSingleCyTest.Btn_In1Click(Sender: TObject);
begin
  if (Sender as TLbSpeedbutton)=Btn_In1 then ECy.RunFix(SPEED_CONTROL,1)
  else ECy.RunFix(SPEED_CONTROL,-1);
end;

procedure TFrmSingleCyTest.Btn_Run1Click(Sender: TObject);
begin
  ECy.AutoRun;
end;

procedure TFrmSingleCyTest.Btn_Stop1Click(Sender: TObject);
begin
  ECy.Stop;
end;

procedure TFrmSingleCyTest.Btn_SetZeroClick(Sender: TObject);
begin
  ECy.SetZero;
end;

procedure TFrmSingleCyTest.LbSpeedButton1Click(Sender: TObject);
begin
  ECy.ShowRunSigSetting;
end;

procedure TFrmSingleCyTest.Btn_ShowPlotClick(Sender: TObject);
begin
  if Btn_ShowPlot.Color=clYellow then
  begin
    Btn_ShowPlot.Color:=clSilver;
  end
  else
  begin
    Btn_ShowPlot.Color:=clYellow;
    iPlot1.ClearAllData;
    iPlot1.XAxis[0].Min:=0;
    MyTimer1.Clear(0);
  end;
end;

procedure TFrmSingleCyTest.CK_GivPosClick(Sender: TObject);
var CK:TCheckBox;
begin
  CK:=Sender as TCheckBox;
  if CK=CK_GivPos then iPlot1.Channel[0].Visible:=CK.Checked
  else if CK=CK_ActPos then iPlot1.Channel[1].Visible:=CK.Checked
  else if CK=CK_Speed then iPlot1.Channel[3].Visible:=CK.Checked
  else if CK=CK_Force then iPlot1.Channel[2].Visible:=CK.Checked
end;

end.
