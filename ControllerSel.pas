unit ControllerSel;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  LbSpeedButton, StdCtrls, LbButton, Grids, BaseGrid, AdvGrid, EController,
  ExtCtrls, iComponent, iVCLComponent, iLed, iLedRectangle;

type
  TFrmControllerSel = class(TForm)
    Btn_OK: TLbButton;
    Btn_Cancel: TLbButton;
    Grid1: TAdvStringGrid;
    Label1: TLabel;
    Timer1: TTimer;
    Label7: TLabel;
    Btn_Check: TLbButton;
    Led_ChState: TiLedRectangle;
    LbButton1: TLbButton;
    procedure FormCreate(Sender: TObject);
    procedure Grid1GetAlignment(Sender: TObject; ARow, ACol: Integer;
      var HAlign: TAlignment; var VAlign: TVAlignment);
    procedure Btn_OKClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Btn_CancelClick(Sender: TObject);
    procedure Btn_CheckClick(Sender: TObject);
    procedure LbButton1Click(Sender: TObject);
  private
    { Private declarations }
    SelectID:Integer;
  public
    { Public declarations }
    ActiveEC: TEController;
  end;

var
  FrmControllerSel: TFrmControllerSel;

implementation

{$R *.DFM}

uses IPSetting;

procedure TFrmControllerSel.FormCreate(Sender: TObject);
var i:Integer;
begin
  Grid1.Cells[0,0]:='控制器名称';
  Grid1.Cells[1,0]:='控制器地址';
  for i:=2 to 5 do Grid1.Cells[i,0]:='CH'+inttostr(i-1);
  Grid1.Cells[6,0]:='通讯率';

  ActiveEC:=nil;
  SelectID:=1;
  Grid1.SelectRows(SelectID,1);
end;

procedure TFrmControllerSel.Grid1GetAlignment(Sender: TObject; ARow,
  ACol: Integer; var HAlign: TAlignment; var VAlign: TVAlignment);
begin
  HAlign := taCenter;
  VAlign := vtaCenter;
end;

procedure TFrmControllerSel.Btn_OKClick(Sender: TObject);
var i:Integer;
begin
  for i:=1 to Grid1.RowCount-1 do
    if Grid1.IsSelected(0,i) then SelectID:=i;

  if Grid1.Cells[0,SelectID]<>'' then
  begin
    ActiveEC:=GetEController(Grid1.Cells[1,SelectID]);
    Close;
  end;
end;

procedure TFrmControllerSel.Timer1Timer(Sender: TObject);
var i,j:Integer;
    IPList:TStringList;
    ec: TEController;
begin
  IPList:=GetActiveECIP;
  if IPList.Count>0 then
  begin
    Grid1.RowCount:=IPList.Count+1;
    for i:=0 to IPList.Count-1 do
    begin
      ec:=GetEController(IPList[i]);
      Grid1.Cells[0,i+1]:=ec.Caption;
      Grid1.Cells[1,i+1]:=ec.GetIPAddr;
      for j:=0 to 3 do
        if ec.ECys[j].ActiveState then Grid1.Cells[2+j,i+1]:='√';
      Grid1.Ints[6,i+1]:=ec.UDPComm_Rate;
    end;
  end
  else
  begin
    Grid1.RowCount:=2;
    Grid1.ClearRows(1,1);
  end;

  IPList.Free;
end;

procedure TFrmControllerSel.Btn_CancelClick(Sender: TObject);
begin
  if Grid1.Cells[0,1]<>'' then ActiveEC:=GetEController(Grid1.Cells[1,1]);
end;

procedure TFrmControllerSel.Btn_CheckClick(Sender: TObject);
var i:Integer;
begin
  for i:=1 to Grid1.RowCount-1 do
    if Grid1.IsSelected(0,i) and (Grid1.Cells[0,i]<>'')  then
    begin
      Led_ChState.Active:=GetEController(Grid1.Cells[1,i]).NetCheck;
      Break;
    end;
end;

procedure TFrmControllerSel.LbButton1Click(Sender: TObject);
var ec:TEController;
    i:Integer;
    FrmIPSetting:TFrmIPSetting;
begin
  for i:=1 to Grid1.RowCount-1 do
    if Grid1.IsSelected(0,i) and (Grid1.Cells[0,i]<>'')  then
    begin
      ec:=GetEController(Grid1.Cells[1,i]);

      FrmIPSetting:=TFrmIPSetting.Create(Application);
      if FrmIPSetting.ShowModal=mrOK then
      begin
        ec.SetIPAddr('192.168.1.'+FrmIPSetting.ComboBox1.Text,True);
      end;
      FrmIPSetting.Close;
      Break;
    end;
end;

end.
