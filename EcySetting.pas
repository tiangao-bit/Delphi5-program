unit EcySetting;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, iComponent, iVCLComponent, iEditCustom, iAnalogOutput, 
  LbSpeedButton, LbButton, iLed, iLedRectangle, EController;

type
  TFrmEcySetting = class(TForm)
    GroupBox7: TGroupBox;
    Label36: TLabel;
    Output_FGain: TiAnalogOutput;
    Output_FOff: TiAnalogOutput;
    GroupBox1: TGroupBox;
    Label3: TLabel;
    Label4: TLabel;
    Label6: TLabel;
    iAnalogOutput3: TiAnalogOutput;
    Output_Kp: TiAnalogOutput;
    iAnalogOutput6: TiAnalogOutput;
    GroupBox2: TGroupBox;
    Label5: TLabel;
    Label7: TLabel;
    Output_MaxSpeed: TiAnalogOutput;
    Btn_Update: TLbSpeedButton;
    Btn_Close: TLbSpeedButton;
    LbButton1: TLbButton;
    CB_Lead: TComboBox;
    Label1: TLabel;
    Btn_Reset: TLbSpeedButton;
    LbSpeedButton1: TLbSpeedButton;
    Led_SelfCheck: TiLedRectangle;
    LbSpeedButton2: TLbSpeedButton;
    Label2: TLabel;
    Output_FMax: TiAnalogOutput;
    Label8: TLabel;
    Output_FMin: TiAnalogOutput;
    Label9: TLabel;
    Output_SMax: TiAnalogOutput;
    Label10: TLabel;
    Output_SMin: TiAnalogOutput;
    procedure Btn_UpdateClick(Sender: TObject);
    procedure Btn_CloseClick(Sender: TObject);
    procedure LbButton1Click(Sender: TObject);
    procedure Btn_ResetClick(Sender: TObject);
    procedure CB_LeadChange(Sender: TObject);
    procedure LbSpeedButton1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LbSpeedButton2Click(Sender: TObject);
  private
    { Private declarations }
    EP:TECyPara;
  public
    { Public declarations }
    ECy: TECylinder;
  end;

var
  FrmEcySetting: TFrmEcySetting;

implementation

{$R *.DFM}

procedure TFrmEcySetting.Btn_UpdateClick(Sender: TObject);
var EP:TECyPara;
begin
  EP.ch:=ECy.CH;
  EP.control_kp:=Output_Kp.Value;
  EP.screw_lead:=StrToFloat(CB_Lead.Text);
  EP.screw_max:=Output_SMax.Value;
  EP.screw_min:=Output_SMin.Value;
  EP.force_gain:=Output_FGain.Value;
  EP.force_off:=Output_FOff.Value;
  EP.force_max:=Output_FMax.Value;
  EP.force_min:=Output_FMin.Value;
  ECy.SetEcyPara(EP);
end;

procedure TFrmEcySetting.Btn_CloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmEcySetting.LbButton1Click(Sender: TObject);
begin
  Output_FOff.Value:=ECy.TD.actforce/EP.force_gain+EP.force_off;
end;

procedure TFrmEcySetting.Btn_ResetClick(Sender: TObject);
begin
  ECy.ECtr.Reset;
end;

procedure TFrmEcySetting.CB_LeadChange(Sender: TObject);
begin
  Output_MaxSpeed.Value:=StrToFloat(CB_Lead.Text)*50;
end;

procedure TFrmEcySetting.LbSpeedButton1Click(Sender: TObject);
begin
  Led_SelfCheck.Active:=ECy.SelfCheck;
end;

procedure TFrmEcySetting.FormShow(Sender: TObject);
var i:integer;
begin
  ECy.GetEcyPara(EP);

  Output_Kp.Value:=EP.control_kp;
  if Abs(EP.screw_lead-2.5)<0.001 then CB_Lead.ItemIndex:=0
  else CB_Lead.ItemIndex:=CB_Lead.items.IndexOf(IntToStr(Round(EP.screw_lead)));
  Output_FGain.Value:=EP.force_gain;
  Output_FOff.Value:=EP.force_off;

  Output_SMax.Value:=EP.screw_max;
  Output_SMin.Value:=EP.screw_min;
  Output_FMax.Value:=EP.force_max;
  Output_FMin.Value:=EP.force_min;
end;

procedure TFrmEcySetting.LbSpeedButton2Click(Sender: TObject);
begin
  ECy.ShowSingleCyTest;
end;

end.
