unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  iComponent, iVCLComponent, iAnalogDisplay, NI_Delphi, ExtCtrls, EController,
  iEditCustom, iAnalogOutput, iSevenSegmentDisplay, iSevenSegmentAnalog,
  iPlotComponent, iXYPlot, StdCtrls, LbSpeedButton,IniFiles, ComCtrls,
  iPlot;

type
  TMyThread = class(TThread)
    procedure Execute; override;
  end;

  TDataFilter = class
  private
    Buf:array[0..2000]of single;
    Index: Integer;
  public
    FilterCount: integer;
    Value:Single;
    Constructor Create(Count:Integer);
    function GetData(v:Single):Single;
    procedure Clear;
  end;

  TForm1 = class(TForm)
    tmr1: TTimer;
    pnl1: TPanel;
    SaveDialog1: TSaveDialog;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Panel1: TPanel;
    lbl1: TLabel;
    Display_Angle: TiSevenSegmentAnalog;
    lblDisplay_Torque: TLabel;
    Display_Torque: TiSevenSegmentAnalog;
    lbl5: TLabel;
    Disp_ActPos1: TiSevenSegmentAnalog;
    Label1: TLabel;
    Disp_Force1: TiSevenSegmentAnalog;
    Panel2: TPanel;
    Btn_In1: TLbSpeedButton;
    Btn_Out1: TLbSpeedButton;
    StartRun: TLbSpeedButton;
    StopRun: TLbSpeedButton;
    Btn_SetZero: TLbSpeedButton;
    AngleClear: TLbSpeedButton;
    TorqueSetting: TLbSpeedButton;
    iXYPlot2: TiXYPlot;
    Panel3: TPanel;
    Btn_ShowPlot: TLbSpeedButton;
    Btn_Save: TLbSpeedButton;
    Btn_RunPara: TLbSpeedButton;
    Btn_SetEP: TLbSpeedButton;
    LbSpeedButton1: TLbSpeedButton;
    LbSpeedButton2: TLbSpeedButton;
    Btn_Close: TLbSpeedButton;
    GroupBox1: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    OutputA1: TiAnalogOutput;
    OutputA2: TiAnalogOutput;
    OutputA3: TiAnalogOutput;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Display_MaxAngle: TiSevenSegmentAnalog;
    Display_MinAngle: TiSevenSegmentAnalog;
    Display_MaxTorque: TiSevenSegmentAnalog;
    Display_MinTorque: TiSevenSegmentAnalog;
    Disp_GivPos1: TiSevenSegmentAnalog;
    Disp_DvPos1: TiSevenSegmentAnalog;
    Disp_MaxForce1: TiSevenSegmentAnalog;
    Disp_MinForce1: TiSevenSegmentAnalog;
    iPlot1: TiPlot;
    TorqueStartRun: TLbSpeedButton;
    InitPosition: TLbSpeedButton;
    Label15: TLabel;
    Button1: TButton;
    GroupBox2: TGroupBox;
    Label16: TLabel;
    OutputA4: TiAnalogOutput;
    Label4: TLabel;
    Disp_RunCount1: TiSevenSegmentAnalog;
    Btn_ClearCount: TLbSpeedButton;
    GroupBox3: TGroupBox;
    Label14: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    AngleRunStart: TLbSpeedButton;
    OutputA5: TiAnalogOutput;
    OutputA6: TiAnalogOutput;
    OutputA7: TiAnalogOutput;
    procedure FormCreate(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure StartRunClick(Sender: TObject);
    procedure Btn_RunParaClick(Sender: TObject);
    procedure AngleClearClick(Sender: TObject);
    procedure TorqueSettingClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure StopRunClick(Sender: TObject);
    procedure Btn_SetEPClick(Sender: TObject);
    procedure LbSpeedButton1Click(Sender: TObject);
    procedure Btn_ShowPlotClick(Sender: TObject);
    procedure Btn_SaveClick(Sender: TObject);
    procedure Btn_CloseClick(Sender: TObject);
    procedure LbSpeedButton2Click(Sender: TObject);
    procedure Btn_In1Click(Sender: TObject);
    procedure Btn_SetZeroClick(Sender: TObject);
    procedure OutputA1Change(Sender: TObject);
    procedure OutputA2Change(Sender: TObject);
    procedure OutputA3Change(Sender: TObject);
    procedure TorqueStartRunClick(Sender: TObject);
    procedure InitPositionClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure OutputA4Change(Sender: TObject);
    procedure Btn_ClearCountClick(Sender: TObject);
    procedure ComPort1RxFlag(Sender: TObject);
    procedure OutputA5Change(Sender: TObject);
    procedure OutputA6Change(Sender: TObject);
    procedure OutputA7Change(Sender: TObject);
    procedure AngleRunStartClick(Sender: TObject);


  private
    { Private declarations }
    mytime: Single;
  public
    { Public declarations }

  end;
 // const TorqueGain =-0.0835*50;
  const Pi = 3.1415926;

procedure InitRunPara;
procedure SaveDataToText;
procedure StopSetPara;

var

  Form1: TForm1;
  ActiveEC: TEController;
  IniFile:TIniFile;
  Ecys: array[0..3]of TECylinder;
  NI_AD: TNI_AD;
  NI_Encode: TNI_Encode;
  DF: array[0..7]of TDataFilter;
  ReadTorque,TorqueOff,MaxTorque,MinTorque,MaxAngle,MinAngle,AngleFre,RunSpeed:Single;   //�趨���й�����Ť�صķ�ֵ�������ٶ�
  MaxRunTorque,MinRunTorque,MaxRunAngle,MinRunAngle,MaxRunForce,MinRunForce,DV_Position:Single;
  LastTwoMaxTorque,LastMaxTorque,NowMaxTorque,LastTwoTorqueOff,LastTorqueOff:Single;  //�������ڣ���һ���ڣ���ǰ���ڵ�Ť�����ֵ��
  NowTorque,ReadAngle,AngleOff,ActualAngle:Single;
  TotalRunCount,NowRuncount,LastRunCount,PreRunCount,SingleRunCount,States,InitPositionIndex,TorqueProtectIndex,ReachMaxCountIndex:Int64;
  NormalRun,TorqueRun,AngleRun,CountFlag,InitPositionFlag,SaveFlag,SetPosZeroFlag:Boolean;//Torque��ʾת�������˶�ģʽ
  MyTimer1,MyTimer2:TMyTimer;
  AngleRunAmp,AngleRunFre:Single;
  SaveTime,SaveFile:string;
  FilT:TextFile;
  PreTorque: array[0..9] of Single;
  AveMaxTorque,AveMinTorque,SumMaxTorque,SumMinTorque:Single;
  JudgeMaxTorque,JudgeMinTorque:array[0..9] of Single;
  GetAveTorque:Boolean;
  GetTorqueNumber,GetTorqueIndex:Integer;


implementation

{$R *.DFM}
function DeleteStr(str:String; var str1:string; c:char):string;
var strdata: array[0..20] of string;
    i,length:integer;
begin
  length:=GetStrFromString(Str,strdata,c);
  for i:=0 to length-1 do
  str1:=Str1+strdata[i];
  Result:=str1;
end;
procedure StopSetPara;
begin
  Ecys[0].Stop;
  NormalRun:=False;
  TorqueRun:=False;
  AngleRun:=False;
  InitPositionFlag:=False;
  InitPositionIndex:=0;
  SetPosZeroFlag:=False;
  SaveDataToText;
  Form1.Btn_ShowPlot.Color:=clSilver;
end;

function GetDataFromString(str:String; var Data:array of single; c:char):integer;
var strdata: array[0..20] of string;
    i:integer;
begin
  Result:=GetStrFromString(Str,strdata,c);
  for i:=0 to Result-1 do
    Data[i]:=StrToFloat(strdata[i]);
end;


function GetStrFromString(str:String; var Data:array of string; c:char):integer; //����c��str�еĸ��� ��+1  G   Data��ʲô���ã�
begin
  str:=trim(str); //���ַ���ǰ��Ŀհ׼�������Ԫ���.ע��Trim����ֻ������ַ���ǰ��Ŀո񼰿�����Ԫ����������ַ����м�Ŀո�  G
  Result:=0;
  if str='' then Exit;

  while Pos(c,Str)>0 do  //�Ӵ�c�ڸ���str�е�һ�γ��ֵ�λ�� G
  begin
    data[Result]:=copy(Str,1,Pos(c,Str)-1);  
    delete(Str,1,Pos(c,Str));  //�÷��� delete(str,//��ɾ�����ַ��� index,//�ӵڼ����ַ���ʼɾ��count //ɾ������  G
    Inc(Result);
  end;
  Data[Result]:=Str;
  Result:=Result+1;
end;


procedure TMyThread.Execute;
begin
  while not Application.Terminated do
  begin
   // NI_AD.SingleSample;
   // NI_Encode.SingleRead;
   // DF[0].GetData(NI_AD.ChannelData[0]);
   // NowTorque:=DF[0].Value;
    ReadTorque:=-Ecys[1].TD.actforce;
    ReadAngle:=-Ecys[1].TD.actpos;
    ActualAngle:=ReadAngle-AngleOff;

  end;
end;

procedure GetMaxAndMinValue;
begin
  if  NowTorque>=MaxRunTorque then MaxRunTorque:=NowTorque;
  if  NowTorque<=MinRunTorque then MinRunTorque:=NowTorque;
  if  ActualAngle>=MaxRunAngle then MaxRunAngle:=ActualAngle;
  if  ActualAngle<=MinRunAngle then MinRunAngle:=ActualAngle;
  if  Ecys[0].TD.actforce>=MaxRunForce then MaxRunForce:=Ecys[0].TD.actforce;
  if  Ecys[0].TD.actforce<=MinRunForce then MinRunForce:=Ecys[0].TD.actforce;
end;
procedure ClearMaxMin;
begin
  MaxRunTorque:=0;
  MinRunTorque:=0;
  MaxRunAngle:=0;
  MinRunAngle:=0;
  MaxRunForce:=0;
  MinRunForce:=0;
end;

procedure InitRunPara;  //��ʼ����TorqueOff��AngleOff �͵��ܽ����Ұ벿�� Ť�ؿ��ƺͽǶȿ��� ģʽ  G
var j:Integer;
    FNAME,str:string;
    RunPara:array[0..10] of Single;
    AngleRunPara:array[0..10] of Single;
begin
  FName:=ExtractFilePath(Application.ExeName)+'�����ļ�.Ini';
  IniFile:=TIniFile.Create(FName);   //��Inifile��INI������ϵ���Ϳ���ͨ��Inifile����ȡini�ļ��е�ֵ G
  str:=IniFile.ReadString('Ť��','��ƫ','0');
  TorqueOff:=StrToFloat(str);               //TorqueOff=-0.91 G
  str:=IniFile.ReadString('ת��','��ƫ','0');
  AngleOff:=StrToFloat(str);     //AngleOff=0 G
  for j:=0 to 8 do
   begin
     PreTorque[j]:=0;
   end;
  PreRunCount:=StrToInt(IniFile.ReadString('Ť��','���д���','0'));//������ֵΪȱʡֵ����INI�ļ������ڸùؼ���ʱ���ص�ȱʡֵ 
  NowRuncount:=PreRunCount;
  LastRunCount:=NowRuncount;
  GetDataFromString(IniFile.ReadString('Ť���趨','��������','0 0 0'),RunPara,' ');
  Form1.OutputA1.Value:=RunPara[0];
  Form1.OutputA2.Value:=RunPara[1];
  Form1.OutputA3.Value:=RunPara[2];
  Form1.OutputA4.Value:=RunPara[3];
  MaxTorque:=RunPara[0];
  MinTorque:=RunPara[1];
  RunSpeed:=RunPara[2];
  GetDataFromString(IniFile.ReadString('ת���趨','��������','0 0 0'),AngleRunPara,' ');
  Form1.OutputA5.Value:=AngleRunPara[0];
  Form1.OutputA6.Value:=AngleRunPara[1];
  Form1.OutputA7.Value:=AngleRunPara[2];
  MaxAngle:=AngleRunPara[0];
  MinAngle:=AngleRunPara[1];
  AngleFre:=AngleRunPara[2];
end;

Constructor TDataFilter.Create(count:integer);
begin
  FilterCount:=count;
  Index:=0;
end;

function TDataFilter.GetData(v:single):single;
var i:integer;
begin
  if Index>=FilterCount then
  begin
    for i:=0 to FilterCount-2 do Buf[i]:=Buf[i+1];
    Buf[FilterCount-1]:=v;
  end
  else
  begin
    Buf[Index]:=v;
    Inc(Index);
  end;

  Result:=0;
  for i:=0 to Index-1 do Result:=Result+Buf[i];
  Result:=Result/Index;
  Value:=Result;
end;

procedure TDataFilter.Clear;
begin
  Index:=0;
end;

procedure TForm1.FormCreate(Sender: TObject);
var i:Integer;
begin
  InitECSystem;//���ø�����׿�����ECS[i]��ʼ���� ��IPֵ  G
  InitRunPara;  //��ʼ�����ֵ���ò������˶����� G
  ActiveEC:=ShowControllerList;  //ѡ��IPֵ���� ����ѡ��ĵ�׿�����    ��������ַ��192.168.1.100-192.168.1.199֮�� G
  if ActiveEC=nil then ActiveEC:=ECs[0];  
  for i:=0 to 3 do ECys[i]:=ActiveEC.ECys[i];   //�����������G
 // NI_AD:=TNI_AD.Create('Dev1/ai0:7');
//  NI_Encode:=TNI_Encode.Create('Dev1/ctr0');
//  for i:=0 to 7 do DF[i]:=TDataFilter.Create(10);
  tmr1.Enabled:=True;//����ʱ��1 G
  mytime:=0; //����ʵ������ G
  TMyThread.Create(False); //��TThread���г��� False�����̲߳�ִ��   True �����̺߳��ȹ��𣬵ȴ��û���������ִ�� G
  MyTimer1:=TMyTimer.Create;
  MyTimer2:=TMyTimer.Create;  //����TMyTimer�����    G
  NormalRun:=False;   //
  TorqueRun:=False;   //ת�������˶�ģʽ   
  SetPosZeroFlag:=False;  //���λ����0��־λ
  InitPositionIndex:=0;
  ReachMaxCountIndex:=0;  
  States:=0;
  InitPositionFlag:=False;
  SaveFile:='D:\ʵ������\';
 
end;

procedure TForm1.tmr1Timer(Sender: TObject);      //��ʱ��
{ var ActivePlot:TiPlot; }
    i,j,k,downCount:Integer;
    //var StopRun,StartRun,Btn_In1,Btn_Out1:TLbSpeedButton;
    //Display_Angle,Display_Torque,Disp_ActPos1,Disp_Force:TiSevenSegmentAnalog;
begin
  downCount:=0;
  NowTorque:=-ReadTorque;
  //NowTorque:=(ReadTorque-Torqueoff)*torquegain;
  Display_Angle.Value:=Ecys[1].TD.actpos; //�Ƕ� G ???
  Display_Torque.Value:=NowTorque;  //��ǰŤ��
  Disp_ActPos1.Value:=Ecys[0].TD.actpos;//���λ�� G  ???
  Disp_Force1.Value:=Ecys[0].TD.actforce; //ʵ����G
  Display_MaxTorque.Value:=MaxRunTorque;
  Display_MinTorque.Value:=MinRunTorque;
  Display_MaxAngle.Value:=MaxRunAngle;
  Display_MinAngle.Value:=MinRunAngle;
  Disp_MaxForce1.Value:=MaxRunForce;
  Disp_MinForce1.Value:=MinRunForce;
  Disp_GivPos1.Value:=Ecys[0].TD.givpos; //����λ��G
  Disp_DvPos1.Value:=(Ecys[0].TD.givpos-Ecys[0].TD.actpos);
  Disp_RunCount1.Value:=NowRuncount;
  Display_Angle.Value:=ActualAngle; //��ǰ�Ƕ� ��364���Ǵ�İɣ�
  GetMaxAndMinValue;   //��ȡ�������������Сֵ
  if (NormalRun=True)or (AngleRun=True) then
  begin
    NowRuncount:=Ecys[0].TD.runcount+PreRunCount;

    if LastRunCount<>NowRuncount then  //λ��ģʽ��  һ���˶����ڽ���
    begin
      { for i:=0 to 8 do
       begin
          PreTorque[i]:=PreTorque[i+1];
       end;
       PreTorque[9]:=MaxRunTorque;
       if(PreTorque[7]<>0) and(PreTorque[8]<>0) then
       begin
          LastTwoTorqueOff:=(PreTorque[7]-PreTorque[8])/PreTorque[7];
          LastTorqueOff:=(PreTorque[8]-PreTorque[9])/PreTorque[8];
       end;
       for j:=0 to 8 do
       begin
          if PreTorque[j]> PreTorque[j+1] then
          begin
             downCount:=downCount+1;
          end;
       end;
       if((LastTwoTorqueOff>0.05) and(LastTorqueOff>0.15))  then
       begin
         Ecys[0].Stop;       //�Զ�ͣ��
         StopSetPara;
         Form1.Btn_ShowPlot.Color:=clSilver;
           for j:=0 to 8 do
           begin
             PreTorque[j]:=0;
           end;
           LastTwoTorqueOff:=0;
           LastTorqueOff:=0;
       end;    }

       if (GetTorqueIndex=1) and(AveMaxTorque<>0) and(AveMinTorque<>0)then
        begin
          if((MaxRunTorque/AveMaxTorque)<0.5) and((Abs(MinRunTorque)/Abs(AveMinTorque))<0.5)  then
          begin
             ECys[0].Stop;
             StopSetPara;
             AveMaxTorque:=0;
             AveMinTorque:=0;
             GetTorqueNumber:=0;
             GetTorqueIndex:=0;
             SumMaxTorque:=0;
             SumMinTorque:=0;
             Form1.Btn_ShowPlot.Color:=clSilver;
          end;
        end;


        if GetAveTorque=True then                 //ÿ�ε����ʼ����ʱ ȡ�õ������е������Сͣ��Ť��
        begin
           JudgeMaxTorque[GetTorqueNumber]:=MaxRunTorque;
           JudgeMinTorque[GetTorqueNumber]:=MinRunTorque;
           SumMaxTorque:=SumMaxTorque+JudgeMaxTorque[GetTorqueNumber];
           SumMinTorque:=SumMinTorque+JudgeMinTorque[GetTorqueNumber];
           GetTorqueNumber:= GetTorqueNumber+1;

           if GetTorqueNumber = 10 then     //ȡ��10�����ڵ������Сֵ�󣬼�¼�жϵ������СŤ��
           begin
             GetAveTorque:=False;
             GetTorqueNumber:=0;
             AveMaxTorque:=SumMaxTorque*0.1;  //�õ�ͣ����Ť��ƽ�������СŤ��
             AveMinTorque:=SumMinTorque*0.1;
             GetTorqueIndex:=1;
             for k:=0 to 9 do
               begin
                 JudgeMaxTorque[k]:=0;
                 JudgeMinTorque[k]:=0;
               end;
           end;

        end;


       ClearMaxMin; //��������Сֵ
       IniFile.WriteString('Ť��','���д���',Trim(IntToStr(NowRuncount)));
       LastRunCount:=NowRuncount;



    end;
    if (NowTorque>=MaxTorque) or (NowTorque<=MinTorque) then     //�����СŤ�ر���
    begin
       TorqueProtectIndex:=TorqueProtectIndex+1;
    end
    else if (NowTorque<=MaxTorque) or (NowTorque>=MinTorque)  then
    begin
       TorqueProtectIndex:=0;
    end;
    if TorqueProtectIndex=10 then
    begin
       TorqueProtectIndex:=0;
       StopSetPara;   //�����趨�������СŤ�غ�0.5 ��ֹͣ
    end;
    if Ecys[0].TD.runstate=0 then
    begin
        Form1.Btn_ShowPlot.Color:=clSilver;
    end;
  end;

  if  Form1.Btn_ShowPlot.Color=clYellow then   //��ͼ
  begin
      if   Form1.PageControl1.ActivePageIndex = 0 then
      begin
        ActivePlot:=Form1.iPlot1;
        if MyTimer1.GetTime(0)>600then  //600��ms��G
          begin
              SaveDataToText;
              MyTimer1.Clear(0);//��ȡ����������ֵ�����MyTimer��Start�����[0]��Ԫ�أ�  
              ActivePlot.ClearAllData;
              ActivePlot.XAxis[0].Min:=0;
          end;
       // if DF[0].Value>100 then DF[0].Value:=100;
       // if DF[0].Value<-100 then DF[0].Value:=-100;

          with ActivePlot.Channel[0] do if Visible then AddXY(MyTimer1.GetTime(0),ActualAngle);   //  ʵʱ�Ƕ�G
          with ActivePlot.Channel[1] do if Visible then AddXY(MyTimer1.GetTime(0),ECys[0].TD.actforce);// ʵʱ��G
          with ActivePlot.Channel[2] do if Visible then AddXY(MyTimer1.GetTime(0),NowTorque);  //  ʵʱŤ��G
          with ActivePlot.Channel[3] do if Visible then AddXY(MyTimer1.GetTime(0),ECys[0].TD.actpos);  // ʵʱλ��G
          with ActivePlot.Channel[4] do if Visible then AddXY(MyTimer1.GetTime(0),ECys[0].TD.givpos);  // ����λ��G
         

        if MyTimer1.GetTime(0)>ActivePlot.XAxis[0].Max then ActivePlot.XAxis[0].Min:=ActivePlot.XAxis[0].Min+ActivePlot.XAxis[0].Span/4;//�������굽����󣬲��ϸ���������Сֵ  span/4����
        if MyTimer1.GetTime(0)>3600 then
        begin
          MyTimer1.Clear(0);
          ActivePlot.ClearAllData;
          ActivePlot.XAxis[0].Min:=0;
        end;
      end;
      if  Form1.PageControl1.ActivePageIndex = 1 then   //������ʾŤ��ת�ǹ�ϵ��ԭ�� G
      begin
      end;
  end;

  if (NowRuncount>=TotalRunCount) and(ReachMaxCountIndex=0) then
  begin
     Ecys[0].Stop;       //�Զ�ͣ��
     StopSetPara;
     Form1.Btn_ShowPlot.Color:=clSilver;
     Inc(ReachMaxCountIndex);
  end;
  with Ecys[0] do
  begin
    if TD.runstate=0 then StopRun.Color:=clRed
    else StopRun.Color:=$00ECCE94;
    if TD.runstate=1 then StartRun.Color:=clLime
    else StartRun.Color:=$00ECCE94;
    if TD.runstate=2 then Btn_In1.Color:=clLime
    else Btn_In1.Color:=$00ECCE94;
    if TD.runstate=3 then Btn_Out1.Color:=clLime
    else Btn_Out1.Color:=$00ECCE94;
  end;
  if InitPositionFlag = True then  //��ʼ��λ��
  begin
     if(InitPositionIndex=1)then
     begin
       if NowTorque>0 then
       begin
         ECys[0].ClearSig;
         ECys[0].RunFix(SPEED_CONTROL,1*RunSpeed*0.2);
         Inc(InitPositionIndex);
       end;
       if NowTorque<0 then
       begin
         ECys[0].ClearSig;
         ECys[0].RunFix(SPEED_CONTROL,-1*RunSpeed*0.2);
         Inc(InitPositionIndex);
       end;
     end
     else if(InitPositionIndex=2) then
     begin
       if  Abs(NowTorque) <1 then
       begin
         ECys[0].Stop;
         InitPositionIndex:=0;
         InitPositionFlag:=False;
       end;
     end;
  end;

  if TorqueRun = True then    //Ť�ؿ���ģʽ
  begin
    if(SetPosZeroFlag=True) and(DF[0].Value < 1)and (DF[0].Value > -1) then
    begin
       Ecys[0].SetZero;
       SetPosZeroFlag:=False;
    end;
    if States =1 then
    begin
      if (DF[0].Value < MaxTorque) and (DF[0].Value > MinTorque) then
      begin
        ECys[0].ClearSig;
        ECys[0].RunFix(SPEED_CONTROL,-1*RunSpeed);   //ȫ���
        Inc(States);
      end;
    end
    else if States = 2 then
    begin
      if(Ecys[0].TD.actpos>=0) and(CountFlag) then    //��������������ʱ������Ť�ؿ��Ʒ�ʽһ�����ڽ���
      begin
        CountFlag:=False;
        ClearMaxMin; //һ�����ڽ�������������С
        NowRuncount:=NowRuncount+1;
      end;
      if(DF[0].Value>=MaxTorque) then
      begin
        ECys[0].ClearSig;
        ECys[0].RunFix(SPEED_CONTROL,1*RunSpeed);   //ȫ����
        Inc(States);
      end;
    end
    else if States = 3 then
    begin
      if(DF[0].Value<=MinTorque) then
      begin
         ECys[0].ClearSig;
         ECys[0].RunFix(SPEED_CONTROL,-1*RunSpeed);  //ȫ���
         States:=2;
         CountFlag:=True;
      end;
    end;
  end;

end;

procedure TForm1.StartRunClick(Sender: TObject);
begin
  mytime:=0;
  ReachMaxCountIndex:=0;
  iPlot1.ClearAllData;
  iPlot1.XAxis[0].Min:=0;

  GetAveTorque:=True;
  AveMaxTorque:=0;
  AveMinTorque:=0;
  SumMaxTorque:=0;
  SumMinTorque:=0;
  GetTorqueNumber:=0;
  GetTorqueIndex:=0;

  MyTimer1.Clear(0);
  NormalRun:=True;
  ECys[0].AutoRun;
  Btn_ShowPlot.Color:=clYellow;
  PreRunCount:=StrToInt(IniFile.ReadString('Ť��','���д���','0'));
  NowRuncount:=PreRunCount;
  LastRunCount:=NowRuncount;
end;

procedure SaveDataToText;   //2020/1/1  ����9:49û����
var FileT:TextFile;
    str1,str2,str3: String;
    ActivePlot:TiPlot;
begin
   ActivePlot:=Form1.iPlot1;
   SaveTime:=DateTimeToStr(Now());  //��ȡ��ǰϵͳʱ�� G
   SaveTime:=DeleteStr(SaveTime,str1,'/');
   SaveTime:=DeleteStr(SaveTime,str2,':');
   str3:=SaveFile+str2+'.txt'; //str3�ĸ�ʽΪD:\ʵ������\202012 92024.txt��G
   AssignFile(FileT,str3);
   Form1.Label15.Caption:=str3;
   Rewrite(FileT);
   CloseFile(FileT);
   ActivePlot.SaveDataToFile(str3);  //      û�ҵ���Ӧ���� G   
  // SaveFile:='D:\ʵ������\';
   str1:='';Str2:='';str3:='';
   IniFile.WriteString('Ť��','���д���',Trim(IntToStr(NowRuncount)));
end;
procedure TForm1.Btn_RunParaClick(Sender: TObject);
begin
  Ecys[0].ShowRunSigSetting;

end;

procedure TForm1.AngleClearClick(Sender: TObject);
begin
   AngleOff:=ReadAngle;
   IniFile.WriteString('ת��','��ƫ',Trim(FloatToStr(AngleOff)));
end;

procedure TForm1.TorqueSettingClick(Sender: TObject);
begin
   TorqueOff:=Ecys[1].TD.actforce;
 //  TorqueOff:=NowTorque;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
var Str:string;
    i:Integer;
    Output:TiAnalogOutput;
begin
  Ecys[0].Stop;
  IniFile.WriteString('Ť��','��ƫ',Trim(FloatToStr(TorqueOff)));
  IniFile.WriteString('ת��','��ƫ',Trim(FloatToStr(AngleOff)));
  Str:='';
  for i:=0 to 3 do
  begin
    Output:=FindComponent('Output'+Chr(Ord('A'))+inttostr(i+1)) as TiAnalogOutput;
    if Output<>nil then Str:=Str+' '+Output.Text;
  end;
  Str:=Trim(Str);
  IniFile.WriteString('Ť���趨','��������',Str);
  Str:='';
  for i:=4 to 6 do
  begin
    Output:=FindComponent('Output'+Chr(Ord('A'))+inttostr(i+1)) as TiAnalogOutput;
    if Output<>nil then Str:=Str+' '+Output.Text;
  end;
  Str:=Trim(Str);
  IniFile.WriteString('ת���趨','��������',Str);
  IniFile.WriteString('Ť��','���д���',Trim(IntToStr(NowRuncount)));

end;

procedure TForm1.StopRunClick(Sender: TObject);
begin
  StopSetPara;
end;

procedure TForm1.Btn_SetEPClick(Sender: TObject);
begin
  ECys[0].ShowEcyParaSetting;
end;

procedure TForm1.LbSpeedButton1Click(Sender: TObject);
var i:Integer;
    ec:TEController;
begin
  ec:=ShowControllerList;
  if ec<>nil then ActiveEC:=EC;
  for i:=0 to 3 do ECys[i]:=ActiveEC.ECys[i];
  Caption:='��ͨ���綯���ۺϲ�����-Զ�̿�����'+ActiveEC.GetIPAddr;
end;

procedure TForm1.Btn_ShowPlotClick(Sender: TObject);
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
    MyTimer2.Clear(0);
  end;
end;

procedure TForm1.Btn_SaveClick(Sender: TObject);
begin
  SaveDialog1.InitialDir:=ExtractFilePath(Application.ExeName);
  if SaveDialog1.Execute then
  begin
    if PageControl1.ActivePageIndex = 0 then iPlot1.SaveDataToFile(SaveDialog1.FileName)
    else iPlot1.SaveDataToFile(SaveDialog1.FileName)
  end;
end;

procedure TForm1.Btn_CloseClick(Sender: TObject);
begin
 Close;
end;

procedure TForm1.LbSpeedButton2Click(Sender: TObject);
var FName:String;
begin
  FName:=ExtractFilePath(Application.ExeName)+'\TeamViewer\TeamViewer.exe';
  WinExec(pChar(FName), SW_SHOW);
end;


procedure TForm1.Btn_In1Click(Sender: TObject);
begin
  if (Sender as TLbSpeedbutton)=Btn_In1 then ECys[0].RunFix(SPEED_CONTROL,1*0.2)
  else ECys[0].RunFix(SPEED_CONTROL,-1*0.2);
end;

procedure TForm1.Btn_SetZeroClick(Sender: TObject);
begin
  ECys[0].SetZero;
end;

procedure TForm1.OutputA1Change(Sender: TObject);
begin
  MaxTorque:=OutputA1.Value;
end;

procedure TForm1.OutputA2Change(Sender: TObject);
begin
  MinTorque:=OutputA2.Value;
end;

procedure TForm1.OutputA3Change(Sender: TObject);
begin
  RunSpeed:=Round(OutputA3.Value);
end;

procedure TForm1.TorqueStartRunClick(Sender: TObject);
begin
   Btn_ShowPlot.Color:=clYellow;
   iPlot1.ClearAllData;
   iPlot1.XAxis[0].Min:=0;
   MyTimer1.Clear(0);
   MyTimer2.Clear(0);
   TorqueRun:=True;
   States:=1;
   Ecys[0].SetZero;
   SetPosZeroFlag:=True;
end;

procedure TForm1.InitPositionClick(Sender: TObject);
begin
  InitPositionIndex:=1;
  InitPositionFlag:=True;
end;

procedure TForm1.Button1Click(Sender: TObject);
var FileT:TextFile;
    str1,str2: String;
begin
    SaveTime:=DateTimeToStr(Now());
           SaveTime:=DeleteStr(SaveTime,str1,'/');
           SaveTime:=DeleteStr(SaveTime,str2,':');
           SaveFile:=SaveFile+str2+'.txt';
           AssignFile(FileT,SaveFile);
           Label15.Caption:=SaveFile;
           Rewrite(FileT);
           iPlot1.SaveDataToFile('D:\ʵ������\2017930 113711.txt');
         //  Flush(FileT);
         //  CloseFile(FileT);
         //  SaveFile:='D:\ʵ������\';
            // iPlot1.SaveDataToFile(SaveFile);

end;

procedure TForm1.OutputA4Change(Sender: TObject);
begin
  TotalRunCount:=Round(OutputA4.Value);
end;

procedure TForm1.Btn_ClearCountClick(Sender: TObject);
begin
  NowRuncount:=0;
  IniFile.WriteString('Ť��','���д���',Trim(IntToStr(NowRuncount)));
end;

procedure TForm1.ComPort1RxFlag(Sender: TObject);
begin
 // C:=ComPort1.Read(Buf,ComPort1.InputCount);
 // if (C=5) and (Buf[0]=$5A) then
 // begin
 //   ReadAngle:=(Buf[1]*256+Buf[2])/65535*360;
 // end;
 // ComPort1.ClearBuffer(True,True);
  end;
procedure TForm1.OutputA5Change(Sender: TObject);
begin
  MaxAngle:=OutputA5.Value;
end;

procedure TForm1.OutputA6Change(Sender: TObject);
begin
  MinAngle:=OutputA6.Value;
end;

procedure TForm1.OutputA7Change(Sender: TObject);
begin
  AngleFre:=OutputA7.Value;
end;

procedure TForm1.AngleRunStartClick(Sender: TObject);
var Str:string;
begin
   Str:='';
   AngleRun:=True;
   AngleRunAmp:=Sin(MaxAngle*pi/180)*230;
   AngleRunFre:=AngleFre;
   mytime:=0;
   ReachMaxCountIndex:=0;
   iPlot1.ClearAllData;
   iPlot1.XAxis[0].Min:=0;
   MyTimer1.Clear(0);
   NormalRun:=False;
   Btn_ShowPlot.Color:=clYellow;
   PreRunCount:=StrToInt(IniFile.ReadString('Ť��','���д���','0'));
   NowRuncount:=PreRunCount;
   LastRunCount:=NowRuncount;
   Ecys[0].ClearSig;
   Str:='λ�ÿ���,�����˶�,��ֵ:'+FloatToStr(AngleRunAmp)+' Ƶ��:'+FloatToStr(AngleRunFre)+' ��λ:0.0'+' ����:1';
   Ecys[0].AddSig(Str);
   Ecys[0].Run(TotalRunCount);
  // Ecys[0].AddSigSin(0,AngleRunAmp,AngleRunFre,0,1);
  // Ecys[0].Run(TotalRunCount);

end;



end.

