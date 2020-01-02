unit EController;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, NMUDP, ExtCtrls, IniFiles;

type
  TSysInfo = record          //  为底层电动缸系统信息
    channum: Word;
    chanstate: array[0..5]of Word;
  end;

  TTestData = record
    chid,ctrmode:Word;
    givpos, actpos:single;  //actpos  为转角信息 G
    givforce, actforce:single;  //actforce  为扭矩信息 G
    openvalue:single;
    speed:single;
    cv:single;
    runcount:integer;
    runstate:integer;
  end;

  TSigItem = record
    ctrmode,sigtype: word;
    count: integer;
    data: array[0..9]of single;
  end;

  TCommand = record
    runflag,ch: word;
    sigindex,sigcount: word;
    runcount, maxruncount: Integer;
    sigitem: array[0..9] of TSigItem;
  end;

  TEcyPara = record
    ch: integer;
    force_limit,screw_limit: word;
    force_gain,force_off: single;
    force_max,force_min: single;
    screw_lead: single;
    screw_max,screw_min: single;
    control_kp,control_ki,control_kd: single;
  end;

  TMyTimer = class
    Start:array[0..100]of Int64;

    constructor Create;
    procedure ClearAll;
    procedure Clear(ID:Integer);
    function GetTime(ID:Integer):Single;
  end;

  TEController = class;

  TECylinder = class
  private
    EP: TECyPara;

    procedure AddSig(CtrMode,SigType:Integer;Data:array of Single);  overload;
    procedure Run(CtrMode,SigType:Integer;Data:array of Single); overload;
  public
    CH: Integer;
    Caption: String;
    LogicState: Integer;
    ActiveState: Boolean;
    TD: TTestData;
    Cmd: TCommand;
    ECtr: TEController;

    Constructor Create(ec:TEController; id:Integer);

    procedure Run(maxcount:Integer=0); overload;
    procedure Stop;
    procedure AddSigFix(CtrMode:Integer; Value:Single; Duration: Single=-1);
    procedure AddSigSpeed(CtrMode:Integer; value1,value2,speed,stoptime1,stoptime2:Single); overload;
    procedure AddSigSpeed(CtrMode:Integer; value1,value2,speed,stoptime1,stoptime2:Single; runcount:Integer); overload;
    procedure AddSigSin(CtrMode:Integer; amp,freq,off:Single; runcount:Integer);
    procedure AddSig(Str:String);  overload;
    procedure RunFix(CtrMode:Integer; Value:Single; Duration: Single=-1);
    procedure RunSpeed(CtrMode:Integer; value1,value2,speed,stoptime1,stoptime2:Single); overload;
    procedure RunSpeed(CtrMode:Integer; value1,value2,speed,stoptime1,stoptime2:Single; runcount:Integer); overload;
    procedure RunSin(CtrMode:Integer; amp,freq,off:Single; runcount:Integer);  overload;
    procedure AutoRun;
    procedure ClearSig;
    procedure SetZero;
    function SelfCheck:Boolean;
    procedure GetEcyPara(var P:TEcyPara);
    procedure SetEcyPara(P: TEcyPara);

    procedure ShowECyParaSetting;
    procedure ShowRunSigSetting;
    procedure ShowSingleCyTest;

  end;

  TEController = class
  private
    { Private declarations }
    UDPComm_Count: Integer;
    IPAddr: String;
    NetOK: Boolean;

    procedure MyTimerEvent(Sender: TObject);
  protected
    { Protected declarations }
  public
    { Public declarations }
    Caption: String;
    Connected: Boolean;
    ECys: array[0..5]of TECylinder;
    UDPComm_Rate: Integer;
    DataChanged: Boolean;

    Constructor Create(IP:String);
    procedure SetIPAddr(IP:String; Change:Boolean=False);
    function GetIPAddr: String;
    destructor Destroy;
    procedure Reset;
    function NetCheck:Boolean;
    procedure UDPEvent(Sender: TComponent; NumberBytes: Integer; FromIP: String; Port: Integer);
  end;


function GetDataFromString(str:String; var Data:array of single; c:char):integer;
function GetStrFromString(str:String; var Data:array of string; c:char):integer;
procedure GetSigFromStr(Str:String; var CtrMode,SigType:Integer;var data: array of Single);
function ShowControllerList: TEController;
procedure ShowEcyTest;
procedure InitECSystem;
procedure CloseECSystem;
function GetEController(str:String): TEController;
function GetActiveECIP:TStringList;

const POS_CONTROL=0;
const FORCE_CONTROL=1;
const SPEED_CONTROL=2;

const SIG_FIX=0;
const SIG_SIN=1;
const SIG_SPEEDMOVE=2;
const SIG_TRIMOVE=3;
const NONE=-1;
const MAX_EC_COUNT=100;
const REALTIMEPOS=65432;

var MyUDP: TNMUDP=nil;
    CtrTimer: TTimer=nil;
    ECs: array[0..MAX_EC_COUNT-1] of TEController;
    InitFlag:Boolean=True;

//procedure Register;

implementation

uses EcySetting, RunSig, ControllerSel, SingleCyTest, MainTest;


//procedure Register;
//begin
//  RegisterComponents('WSK', [TEController]);
//end;

function GetDataFromString(str:String; var Data:array of single; c:char):integer;
var strdata: array[0..20] of string;
    i:integer;
begin
  Result:=GetStrFromString(Str,strdata,c);
  for i:=0 to Result-1 do
    Data[i]:=StrToFloat(strdata[i]);
end;

function GetStrFromString(str:String; var Data:array of string; c:char):integer;
begin
  str:=trim(str);
  Result:=0;
  while Pos(c,Str)>0 do
  begin
    data[Result]:=copy(Str,1,Pos(c,Str)-1);
    delete(Str,1,Pos(c,Str));
    Inc(Result);
  end;
  Data[Result]:=Str;
  Result:=Result+1;
end;

procedure GetSigFromStr(Str:String; var CtrMode,SigType:Integer;var data: array of Single);
var StrData1,StrData2:array[0..10]of String;
    n,j:Integer;
begin
  GetStrFromString(Str,strdata1,',');

  if strdata1[0]='位置控制' then CtrMode:=POS_CONTROL
  else if strdata1[0]='力控制' then CtrMode:=FORCE_CONTROL
  else if strdata1[0]='速度控制' then CtrMode:=SPEED_CONTROL;

  if strdata1[1]='正弦运动' then SigType:=SIG_SIN
  else if strdata1[1]='等速单次' then SigType:=SIG_SPEEDMOVE
  else if strdata1[1]='等速连续' then SigType:=SIG_TRIMOVE
  else if strdata1[1]='定值输出' then SigType:=SIG_FIX;

  n:=GetStrFromString(strdata1[2],strdata2,' ');
  for j:=0 to n-1 do data[j]:=StrToFloat(Copy(Strdata2[j],1+pos(':',Strdata2[j]),100));
end;

constructor TMyTimer.Create;
begin
  ClearAll;
end;

procedure TMyTimer.Clear(ID:Integer);
begin
  QueryPerformanceCounter(Start[ID]);//给Tmytimer中Start数组 赋计数值
end;

procedure TMyTimer.ClearAll;
var C:Int64;
    i:Integer;
begin
  QueryPerformanceCounter(C);
  for i:=0 to 99 do Start[i]:=C;
end;

function TMyTimer.GetTime(ID:Integer):Single;
var C,CF:Int64;
begin
  QueryPerformanceFrequency(CF); //精确获取时间，返回硬件支持的高精度计数器的频率  G
  QueryPerformanceCounter(C); //  返回计数器次数G
  Result:=(C-Start[ID])*1.0/CF;  //返回精确时间G
end;

Constructor TECylinder.Create(ec:TEController; ID:Integer);
begin
  CH:=ID;   ECtr:=ec;
  Cmd.ch:=CH;
  LogicState:=0;
  ActiveState:=False;
end;

procedure TECylinder.ClearSig;
begin
  Cmd.ch:=ch;
  Cmd.sigcount:=0;
  Cmd.sigindex:=0;
end;

procedure TECylinder.AddSig(ctrmode,sigtype:integer;data:array of single);
var id,i,count:Integer;
begin
  id:=Cmd.sigcount;
  count:=0;
  if id>=10 then exit;

  Inc(Cmd.sigcount);
  Cmd.sigitem[id].ctrmode:=ctrmode;
  Cmd.sigitem[id].sigtype:=sigtype;

  if sigtype=SIG_FIX then count:=2
  else if sigtype=SIG_SIN then count:=4
  else if sigtype=SIG_SPEEDMOVE then count:=5
  else if sigtype=SIG_TRIMOVE then count:=6;

  for i:=0 to 9 do
    if i<count then Cmd.sigitem[id].data[i]:=data[i]
    else Cmd.sigitem[id].data[i]:=0;
end;

procedure TECylinder.AddSig(str:String);
var CtrMode,SigType:Integer;
    Data:array[0..20]of Single;
begin
  GetSigFromStr(Str,CtrMode,SigType,Data);
  AddSig(CtrMode,SigType,Data);
end;

procedure TECylinder.AddSigFix(CtrMode:Integer; Value:Single; Duration: Single=-1);
var data:array[0..10]of single;
begin
  data[0]:=Value;   data[1]:=Duration;
  AddSig(ctrmode,SIG_FIX,data);
end;

procedure TECylinder.AddSigSpeed(CtrMode:Integer; value1,value2,speed,stoptime1,stoptime2:Single);
var data:array[0..10]of single;
begin
  data[0]:=Value1;   data[1]:=value2;   data[2]:=speed;
  data[3]:=stoptime1;   data[4]:=stoptime2;
  AddSig(ctrmode,SIG_SPEEDMOVE,data);
end;

procedure TECylinder.AddSigSpeed(CtrMode:Integer; value1,value2,speed,stoptime1,stoptime2:Single; runcount:Integer);
var data:array[0..10]of single;
begin
  data[0]:=Value1;   data[1]:=value2;   data[2]:=speed;
  data[3]:=stoptime1;   data[4]:=stoptime2;    data[5]:=runcount;
  AddSig(ctrmode,SIG_TRIMOVE,data);
end;

procedure TECylinder.AddSigSin(CtrMode:Integer; amp,freq,off:Single; runcount:Integer);
var data:array[0..10]of single;
begin
  data[0]:=amp;   data[1]:=freq;   data[2]:=off;  data[3]:=runcount;
  AddSig(ctrmode,SIG_SIN,data);
end;

procedure TECylinder.RunFix(CtrMode:Integer; Value:Single; Duration: Single);
begin
  ClearSig;
  AddSigFix(CtrMode,Value,Duration);
  Run;
end;

procedure TECylinder.RunSpeed(CtrMode:Integer; value1,value2,speed,stoptime1,stoptime2:Single);
begin
  ClearSig;
  AddSigSpeed(CtrMode, value1,value2,speed,stoptime1,stoptime2);
  Run;
end;

procedure TECylinder.RunSpeed(CtrMode:Integer; value1,value2,speed,stoptime1,stoptime2:Single; runcount:Integer);
begin
  ClearSig;
  AddSigSpeed(CtrMode, value1,value2,speed,stoptime1,stoptime2,runcount);
  Run;
end;

procedure TECylinder.RunSin(CtrMode:Integer; amp,freq,off:Single; runcount:Integer);
begin
  ClearSig;
  AddSigSin(CtrMode, amp,freq,off,runcount);
  Run;
end;

procedure TECylinder.Run(maxcount:Integer);
var UDP_Send:array[0..999]of Char;
begin
  if not ActiveState then Exit;

  with Cmd do
  begin
    runflag:=1;
    sigindex:=0;
    runcount:=0;
    maxruncount:=maxcount;
  end;

  CopyMemory(@UDP_Send,@Cmd,sizeof(TCommand));
  MyUDP.RemoteHost:=ECtr.GetIPAddr;
  MyUDP.SendBuffer(UDP_Send,16+sizeof(TSigItem)*Cmd.sigcount);
  Sleep(1);
end;

procedure TECylinder.Run(CtrMode,SigType:Integer;Data:array of Single);
begin
  ClearSig;
  AddSig(CtrMode,SigType,data);
  Run;
end;

procedure TECylinder.Stop;
var UDP_Send:array[0..999]of Char;
begin
//  if not ActiveState then Exit;
  with Cmd do
  begin
    runflag:=0;
    sigindex:=0;
  end;

  CopyMemory(@UDP_Send,@Cmd,sizeof(TCommand));
  MyUDP.RemoteHost:=ECtr.GetIPAddr;
  MyUDP.SendBuffer(UDP_Send,16);
  Sleep(1);
end;

procedure TECylinder.SetZero;
var UDP_Send:array[0..999]of Char;
begin
  if not ActiveState then Exit;

  UDP_Send:='Set Zero ';
  UDP_Send[9]:=chr(CH+ord('0'));
  MyUDP.RemoteHost:=ECtr.GetIPAddr;
  MyUDP.SendBuffer(UDP_Send,10);
  Sleep(2);
end;

function TECylinder.SelfCheck:Boolean;
var data:array[0..10]of Single;
    i:Integer;
    givpos:Single;
begin
  Result:=True;

  ClearSig;
  givpos:=TD.actpos+2;
  data[0]:=givpos;    data[1]:=-1;
  Run(POS_CONTROL,SIG_FIX,data);
  for i:=0 to 100 do
  begin
    Sleep(1);  Application.ProcessMessages;
  end;
  if Abs(TD.actpos-givpos)>0.5 then Result:=False;

  ClearSig;
  givpos:=TD.actpos-2;
  data[0]:=givpos;    data[1]:=-1;
  Run(POS_CONTROL,SIG_FIX,data);
  for i:=0 to 100 do
  begin
    Sleep(1);  Application.ProcessMessages;
  end;
  if Abs(TD.actpos-givpos)>0.5 then Result:=False;
  Stop;
end;

procedure TECylinder.GetEcyPara(var P:TEcyPara);
var UDP_Send:array[0..999]of Char;
    i:Integer;
begin
  UDP_Send:='Get EcyPara ';
  UDP_Send[12]:=chr(Self.CH+ord('0'));
  MyUDP.RemoteHost:=ECtr.GetIPAddr;
  MyUDP.SendBuffer(UDP_Send,StrLen(UDP_Send));

  EP.ch:=-1;
  for i:=0 to 10 do
  begin
    application.ProcessMessages;
    sleep(10);
  end;
  if EP.ch<0 then MessageDlg('通讯故障，无法获取参数！',mtWarning,[mbOK],0); 
  P:=EP;
end;

procedure TECylinder.AutoRun;
var IniFile:TIniFile;
    FName,SecName,Str:String;
    Strs:TStringList;
    SelectTaskID,i:Integer;
begin
  FName:=ExtractFilePath(Application.ExeName)+'Setup('+ECtr.GetIPAddr+').Ini';
  IniFile:=TIniFile.Create(FName);

  SelectTaskID:=IniFile.ReadInteger('Task Select','CH'+inttostr(ch+1),-1);
  SecName:='CH'+IntToStr(ch+1)+'-'+'Task'+inttostr(SelectTaskID);
  Strs:=TStringList.create;
  IniFile.ReadSection(SecName,Strs);
  if Strs.Count<2 then ShowMessage('通道'+inttostr(ch+1)+'未设置自动运行信号')
  else
  begin
    ClearSig;
    for i:=0 to Strs.Count-2 do
    begin
      Str:=IniFile.ReadString(SecName,inttostr(i+1),'');
      AddSig(Str);
    end;
    Run(IniFile.ReadInteger(SecName,'Count',0));
  end;

  Strs.Free;
  IniFile.Free;
end;

procedure TECylinder.SetEcyPara(P:TEcyPara);
var UDP_Send:array[0..999]of Char;
begin
  CopyMemory(@UDP_Send,@P,sizeof(TEcyPara));
  MyUDP.RemoteHost:=ECtr.GetIPAddr;
  MyUDP.SendBuffer(UDP_Send,sizeof(TEcyPara));
  Sleep(2);
end;

procedure TECylinder.ShowECyParaSetting;
var FrmEcySetting: TFrmEcySetting;
begin
  FrmEcySetting:=TFrmEcySetting.Create(Application);
  FrmEcySetting.ECy:=Self;
  FrmEcySetting.ShowModal;
  FrmEcySetting.Close;
end;

procedure TECylinder.ShowRunSigSetting;
var FrmRunSig: TFrmRunSig;
begin
  FrmRunSig:=TFrmRunSig.Create(Application);
  FrmRunSig.ECy:=Self;
  FrmRunSig.ShowModal;
  FrmRunSig.Close;
end;

procedure TECylinder.ShowSingleCyTest;
var FrmSingleCyTest: TFrmSingleCyTest;
begin
  FrmSingleCyTest:=TFrmSingleCyTest.Create(Application);
  FrmSingleCyTest.ECy:=Self;
  FrmSingleCyTest.ShowModal;
  FrmSingleCyTest.Close;
end;


procedure InitECSystem;
var i:Integer;
begin
  if InitFlag then
  begin
    for i:=0 to MAX_EC_COUNT-1 do  //MAX_EC_COUNT=100
    begin
      ECs[i]:=TEController.Create('192.168.1.'+inttostr(100+i));  //192.168.1.100-192.168.1.199
      ECs[i].Caption:='控制器'+inttostr(i);
    end;
    InitFlag:=False;
  end;
end;

procedure CloseECSystem;
var i:Integer;
begin
  for i:=0 to MAX_EC_COUNT-1 do ECs[i].Free;
end;

function GetActiveECIP:TStringList;
var i:Integer;
begin
  Result:=TStringList.Create;
  for i:=0 to MAX_EC_COUNT-1 do
    if ECs[i].DataChanged or ECs[i].Connected then Result.Add(ECs[i].IPAddr);
end;

function GetEController(str:String): TEController;
var i:Integer;
begin
  Result:=nil;

  for i:=0 to MAX_EC_COUNT-1 do
    if (ECs[i].IPAddr=str) or (ECs[i].Caption=str) then
    begin
      Result:=ECs[i];
      Break;
    end;
end;

Constructor TEController.Create(IP:String);
var i:Integer;
begin
  Connected:=False;
  UDPComm_Rate:=0;
  DataChanged:=False;
  IPAddr:=IP;

  for i:=0 to 5 do
  begin
    ECys[i]:=TECylinder.Create(self,i);
    ECys[i].Caption:='通道'+inttostr(i);
  end;

  if CtrTimer=nil then
  begin
    CtrTimer:=TTimer.Create(nil);
    CtrTimer.Enabled:=True;
    CtrTimer.Interval:=100;
    CtrTimer.OnTimer:=MyTimerEvent;
  end;
  if MyUDP=nil then
  begin
    MyUDP:=TNMUDP.Create(nil);
    MyUDP.RemoteHost:=IPAddr;
    MyUDP.RemotePort:=619;
    MyUDP.LocalPort:=629;
    MyUDP.OnDataReceived:=UDPEvent;
  end;
end;

destructor TEController.Destroy;
var i:Integer;
begin
  for i:=0 to 5 do ECys[i].Free;
end;

procedure TEController.MyTimerEvent(Sender: TObject);
var i:Integer;
begin
  if CtrTimer.Tag>8 then
  begin
    CtrTimer.Tag:=0;
    for i:=0 to MAX_EC_COUNT-1 do
      with ECs[i] do
      begin
        UDPComm_Rate:=UDPComm_Count;
        UDPComm_Count:=0;
        Connected:=(UDPComm_Rate>40);
        if not Connected then DataChanged:=False;
      end;  
  end
  else CtrTimer.Tag:=CtrTimer.Tag+1;

end;

procedure TEController.Reset;
var UDP_Send:array[0..999]of Char;
begin
  UDP_Send:='Reset';
  MyUDP.RemoteHost:=IPAddr;
  MyUDP.SendBuffer(UDP_Send,StrLen(UDP_Send));
  Sleep(2);
end;

procedure TEController.SetIPAddr(IP:String;Change:Boolean);
var UDP_Send:array[0..999]of Char;
begin
  //if MyUDP<>nil then MyUDP.RemoteHost:=IP;
  if Change then
  begin
    StrpCopy(UDP_Send,'Set IP:'+IP);
    MyUDP.RemoteHost:=IPAddr;
    MyUDP.SendBuffer(UDP_Send,StrLen(UDP_Send));
    Sleep(2);
  end;
  IPAddr:=IP;
end;

function TEController.GetIPAddr: String;
begin
  Result:=IPAddr;
end;

function TEController.NetCheck:Boolean;
var UDP_Send:array[0..999]of Char;
    i:Integer;
begin
  UDP_Send:='Ready';
  NetOK:=False;
  MyUDP.RemoteHost:=IPAddr;
  MyUDP.SendBuffer(UDP_Send,StrLen(UDP_Send));

  for i:=0 to 10 do
  begin
    application.ProcessMessages;
    sleep(2);
  end;
  Result:=NetOK;
end;

procedure TEController.UDPEvent(Sender: TComponent; NumberBytes: Integer; FromIP: String; Port: Integer);
var Buffer:array [0..1024] of Char;
    i:Integer;
    ec: TEController;
    SysInfo: TSysInfo;
    TDs: array[0..5]of TTestData;
    tmpEP:TEcyPara;
begin
  MyUDP.ReadBuffer(Buffer,NumberBytes);
  Buffer[NumberBytes]:=chr(0);

  ec:=nil;
  for i:=0 to MAX_EC_COUNT-1 do
    if ECs[i].IPAddr = FromIP then
    begin
      ec:=ECs[i];
      Break;
    end;
  if ec=nil then Exit;

  if ((NumberBytes-Sizeof(TSysInfo)) mod Sizeof(TTestData))=0  then
  begin
    CopyMemory(@SysInfo,@Buffer,Sizeof(TSysInfo));
    CopyMemory(@TDs,@Buffer[Sizeof(TSysInfo)],Sizeof(TTestData)*SysInfo.channum);
    Inc(ec.UDPComm_Count);
    ec.DataChanged:=True;
    for i:=0 to SysInfo.channum-1 do
    begin
      ec.ECys[i].ActiveState:=(SysInfo.chanstate[i]>0);
      ec.ECys[i].TD:=TDs[i];
    end;
  end
  else if NumberBytes=Sizeof(TEcyPara)  then
  begin
    CopyMemory(@tmpEP,@Buffer,NumberBytes);
    ec.ECys[tmpEP.ch].EP:=tmpEP;
  end
  else if Buffer='OK' then
  begin
    ec.NetOK:=True;
  end;
end;

function ShowControllerList: TEController;
var FrmControllerSel: TFrmControllerSel;
begin
  FrmControllerSel:=TFrmControllerSel.Create(Application); //	动态创建对象，当application释放时自动释放。
  FrmControllerSel.ShowModal;//SHOWMODAL时,当这个窗口显示出来后,程序不会继续自己执行,而是根据你对这个窗口的操作来执行,只有关闭了这个窗口后才会执行。
  Result:=FrmControllerSel.ActiveEC; 
  FrmControllerSel.Close;
end;

procedure ShowEcyTest;
begin
  FrmEcyTest:=TFrmEcyTest.Create(Application);
  FrmEcyTest.ShowModal;
  FrmEcyTest.Close;
end;

end.
