unit RunSig;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, BaseGrid, AdvGrid, iComponent, iVCLComponent, iEditCustom, IniFiles,
  iAnalogOutput, StdCtrls, ComCtrls, LbSpeedButton, EController;

type
  TFrmRunSig = class(TForm)
    PC1: TPageControl;
    TabSheet23: TTabSheet;
    Label58: TLabel;
    Label59: TLabel;
    Label60: TLabel;
    Input_A1: TiAnalogOutput;
    Input_A2: TiAnalogOutput;
    Input_A3: TiAnalogOutput;
    TabSheet24: TTabSheet;
    Label61: TLabel;
    Label62: TLabel;
    Label63: TLabel;
    Input_B1: TiAnalogOutput;
    Input_B2: TiAnalogOutput;
    Input_B3: TiAnalogOutput;
    Input_B4: TiAnalogOutput;
    Input_B5: TiAnalogOutput;
    TabSheet1: TTabSheet;
    Input_C1: TiAnalogOutput;
    Btn_OK: TLbSpeedButton;
    Btn_Cancel: TLbSpeedButton;
    Grid1: TAdvStringGrid;
    Label2: TLabel;
    Input_A4: TiAnalogOutput;
    Label3: TLabel;
    Input_B6: TiAnalogOutput;
    Label4: TLabel;
    RB2: TRadioButton;
    RB1: TRadioButton;
    Input_C2: TiAnalogOutput;
    Label5: TLabel;
    Btn_Add: TLbSpeedButton;
    Btn_Del: TLbSpeedButton;
    LbSpeedButton3: TLbSpeedButton;
    Btn_Task1: TLbSpeedButton;
    Btn_Task2: TLbSpeedButton;
    RB_B1: TRadioButton;
    RB_B2: TRadioButton;
    Label1: TLabel;
    Input_TotalCount: TiAnalogOutput;
    Btn_Task3: TLbSpeedButton;
    Btn_Task4: TLbSpeedButton;
    Btn_Task5: TLbSpeedButton;
    Btn_Task6: TLbSpeedButton;
    Label6: TLabel;
    Label7: TLabel;
    procedure Btn_OKClick(Sender: TObject);
    procedure Grid1GetAlignment(Sender: TObject; ARow, ACol: Integer;
      var HAlign: TAlignment; var VAlign: TVAlignment);
    procedure Btn_AddClick(Sender: TObject);
    procedure Btn_CancelClick(Sender: TObject);
    procedure Btn_DelClick(Sender: TObject);
    procedure LbSpeedButton3Click(Sender: TObject);
    procedure Grid1SelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure Btn_Task1Click(Sender: TObject);
    procedure Input_TotalCountKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    SelectID,SelectTaskID: Integer;
    IniFile:TIniFile;
  public
    { Public declarations }
    ECy: TECylinder;

    procedure GridAdd(id:Integer);
    procedure SaveGridToIniFile(ch,id:Integer);
    procedure LoadGridFromIniFile(ch,id:Integer);
  end;

var
  FrmRunSig: TFrmRunSig;

implementation

{$R *.DFM}

procedure TFrmRunSig.SaveGridToIniFile(ch,id:Integer);  //将ch通道 与 任务号 对应数据写入INI  G
var SecName:String;
    i:Integer;
    R:Boolean;
begin
  SecName:='CH'+IntToStr(ch)+'-'+'Task'+inttostr(id);
  IniFile.EraseSection(SecName);
  R:=False;
  for i:=1 to Grid1.RowCount-1 do
    if Grid1.Cells[0,i]<>'' then
    begin
      IniFile.WriteString(SecName,inttostr(i),Grid1.Cells[1,i]+','+Grid1.Cells[2,i]+','+Grid1.Cells[3,i]);//inifile.writestring('小节名','关键字',变量或字符串值);
      R:=True;
    end;
  if R then IniFile.WriteInteger(SecName,'Count',Round(Input_TotalCount.Value));
  IniFile.UpdateFile;  //???   G
end;

procedure TFrmRunSig.LoadGridFromIniFile(ch,id:Integer);
var SecName,Str:String;
    Strs:TStringList;
    data:array[0..10]of String;
    i:Integer;
begin
  SecName:='CH'+IntToStr(ch)+'-'+'Task'+inttostr(id);
  Grid1.ClearRows(1,100);
  Strs:=TStringList.Create;
  IniFile.ReadSection(SecName,Strs);
  for i:=0 to Strs.Count-2 do
  begin
    Str:=IniFile.ReadString(SecName,inttostr(i+1),'');
    Grid1.Ints[0,i+1]:=i+1;
    GetStrFromString(Str,data,',');
    Grid1.Cells[1,i+1]:=data[0];
    Grid1.Cells[2,i+1]:=data[1];
    Grid1.Cells[3,i+1]:=data[2];
  end;
  Input_TotalCount.Value:=IniFile.ReadInteger(SecName,'Count',1);
  Strs.Free;
end;

procedure TFrmRunSig.Btn_OKClick(Sender: TObject);
Begin
  IniFile.WriteString('Task Select','CH'+inttostr(ECy.CH+1),inttostr(SelectTaskID));
  IniFile.Free;
  Close;
end;

procedure TFrmRunSig.Grid1GetAlignment(Sender: TObject; ARow, ACol: Integer;
  var HAlign: TAlignment; var VAlign: TVAlignment);
begin
  //if ACol<3 then
  HAlign := taCenter;
  VAlign := vtaCenter;
end;

procedure TFrmRunSig.GridAdd(id:Integer); //增加第i行数据G
begin
  Grid1.Ints[0,id]:=id;
  if RB1.Checked then Grid1.Cells[1,id]:='力控制'
  else Grid1.Cells[1,id]:='位置控制';

  if PC1.ActivePageIndex=0 then
  begin
    Grid1.Cells[2,id]:='正弦运动';
    Grid1.Cells[3,id]:=Format('幅值:%.1f 频率:%.2f 零位:%.1f 次数:%.0f',[Input_A1.Value,Input_A2.Value,Input_A3.Value,Input_A4.Value]);//Format 根据指定所需要的格式，格式化字符串。G
  end
  else if PC1.ActivePageIndex=1 then
  begin
    if RB_B1.Checked then Grid1.Cells[2,id]:='等速单次'
    else Grid1.Cells[2,id]:='等速连续';
    Grid1.Cells[3,id]:=Format('起始:%.1f 结束:%.1f 速度:%.0f 起始停:%.1f 结束停:%.1f',[Input_B1.Value,Input_B2.Value,Input_B3.Value,Input_B4.Value,Input_B5.Value]);
    if RB_B2.Checked then Grid1.Cells[3,id]:=Grid1.Cells[3,id]+Format(' 次数:%.0f',[Input_B6.Value]);
  end
  else
  begin
    Grid1.Cells[2,id]:='定值输出';
    Grid1.Cells[3,id]:=Format('固定值:%.1f 持续时间:%.1f',[Input_C1.Value,Input_C2.Value]);
  end;
end;

procedure TFrmRunSig.Btn_AddClick(Sender: TObject);
var i:Integer;
begin
  for i:=1 to Grid1.RowCount-1 do  //顺次添加  G
    if Grid1.Cells[1,i]='' then
    begin
      GridAdd(i);
      Break;
    end;
  SaveGridToIniFile(ECy.CH+1,SelectTaskID);
end;

procedure TFrmRunSig.Btn_CancelClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmRunSig.Btn_DelClick(Sender: TObject);
var i:Integer;
begin
  for i:=Grid1.RowCount-1 downto 1 do
    if Grid1.Cells[0,i]<>'' then
    begin
      Grid1.ClearRows(i,1);
      Break;
    end;
  SaveGridToIniFile(ECy.CH+1,SelectTaskID);
end;

procedure TFrmRunSig.LbSpeedButton3Click(Sender: TObject);
begin
  if (SelectID>0) and (SelectID<Grid1.RowCount-1) and (Grid1.Cells[0,SelectID]<>'') then
  begin
    GridAdd(SelectID);
    SaveGridToIniFile(ECy.CH+1,SelectTaskID);
  end;
end;

procedure TFrmRunSig.Grid1SelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
var Str:String;
    data:array[0..10]of Single;
    CtrMode,SigType:Integer;
begin
  SelectID:=ARow;
  if Grid1.Cells[1,ARow]<>'' then
  begin
    Str:=Grid1.Cells[1,ARow]+','+Grid1.Cells[2,ARow]+','+Grid1.Cells[3,ARow];
    GetSigFromStr(Str, CtrMode,SigType, data);
    if SigType=SIG_SIN then
    begin
      PC1.ActivePageIndex:=0;
      Input_A1.Value:=data[0];
      Input_A2.Value:=data[1];
      Input_A3.Value:=data[2];
      Input_A4.Value:=data[3];
    end
    else if SigType in [SIG_SPEEDMOVE,SIG_TRIMOVE] then
    begin
      PC1.ActivePageIndex:=1;
      RB_B1.Checked:=(SigType=SIG_SPEEDMOVE);
      RB_B2.Checked:=not RB_B1.Checked;
      Input_B1.Value:=data[0];
      Input_B2.Value:=data[1];
      Input_B3.Value:=data[2];
      Input_B4.Value:=data[3];
      Input_B5.Value:=data[4];
      if SigType=SIG_SPEEDMOVE then Input_B6.Value:=-1
      else Input_B6.Value:=data[5];
    end
    else if SigType=SIG_FIX then
    begin
      PC1.ActivePageIndex:=2;
      Input_C1.Value:=data[0];
      Input_C2.Value:=data[1];
    end;
    RB1.Checked:=(CtrMode=FORCE_CONTROL);
    RB2.Checked:=not RB1.Checked;
  end;
  //showmessage(Grid1.Cells[2,ARow]);
end;

procedure TFrmRunSig.Btn_Task1Click(Sender: TObject);
var i:Integer;
    Btn:TLbSpeedButton;
begin
  for i:=0 to 9 do
  begin
    Btn:=FindComponent('Btn_Task'+inttostr(i+1)) as TLbSpeedButton;
    if (Btn<>nil) and (Btn.Color=clLime) then Btn.Color:=$00FCE6D4;
  end;
  (Sender as TLbSpeedButton).Color:=clLime;
  LoadGridFromIniFile(ECy.CH+1,(Sender as TLbSpeedButton).Tag);
  SelectTaskID:=(Sender as TLbSpeedButton).Tag;
end;

procedure TFrmRunSig.Input_TotalCountKeyPress(Sender: TObject; var Key: Char);
var SecName:String;
begin
  if Key=Chr(13) then
  begin
    Input_TotalCount.Apply;

    SecName:='CH'+IntToStr(ECy.CH+1)+'-'+'Task'+inttostr(SelectTaskID);
    IniFile.WriteInteger(SecName,'Count',Round(Input_TotalCount.Value));
    IniFile.UpdateFile;
  end;
end;

procedure TFrmRunSig.FormShow(Sender: TObject);
var FName:String;
    Btn:TLbSpeedButton;
begin
  With Grid1 do
  begin
    Cells[0,0]:='NO';
    Cells[1,0]:='控制模式';
    Cells[2,0]:='运动规律';
    Cells[3,0]:='运动参数';
  end;

  FName:=ExtractFilePath(Application.ExeName)+'Setup('+ECy.ECtr.GetIPAddr+').Ini';
  IniFile:=TIniFile.Create(FName);
  SelectTaskID:=IniFile.ReadInteger('Task Select','CH'+inttostr(ECy.CH+1),1);
  Btn:=FindComponent('Btn_Task'+inttostr(SelectTaskID))as TLbSpeedbutton;
  if Btn<>nil then Btn.Click;
  SelectID:=1;
end;

end.
