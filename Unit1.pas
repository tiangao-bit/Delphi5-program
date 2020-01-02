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
  ReadTorque,TorqueOff,MaxTorque,MinTorque,MaxAngle,MinAngle,AngleFre,RunSpeed:Single;   //设定运行过程中扭矩的峰值，运行速度
  MaxRunTorque,MinRunTorque,MaxRunAngle,MinRunAngle,MaxRunForce,MinRunForce,DV_Position:Single;
  LastTwoMaxTorque,LastMaxTorque,NowMaxTorque,LastTwoTorqueOff,LastTorqueOff:Single;  //上上周期，上一周期，当前周期的扭矩最大值；
  NowTorque,ReadAngle,AngleOff,ActualAngle:Single;
  TotalRunCount,NowRuncount,LastRunCount,PreRunCount,SingleRunCount,States,InitPositionIndex,TorqueProtectIndex,ReachMaxCountIndex:Int64;
  NormalRun,TorqueRun,AngleRun,CountFlag,InitPositionFlag,SaveFlag,SetPosZeroFlag:Boolean;//Torque表示转矩限制运动模式
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


function GetStrFromString(str:String; var Data:array of string; c:char):integer; //返回c在str中的个数 并+1  G   Data是什么作用？
begin
  str:=trim(str); //将字符串前后的空白及控制字元清掉.注意Trim函数只能清掉字符串前后的空格及控制字元，不能清除字符串中间的空格  G
  Result:=0;
  if str='' then Exit;

  while Pos(c,Str)>0 do  //子串c在父串str中第一次出现的位置 G
  begin
    data[Result]:=copy(Str,1,Pos(c,Str)-1);  
    delete(Str,1,Pos(c,Str));  //用法是 delete(str,//被删除的字符串 index,//从第几个字符开始删除count //删除几个  G
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

procedure InitRunPara;  //初始化了TorqueOff，AngleOff 和单杠截面右半部分 扭矩控制和角度控制 模式  G
var j:Integer;
    FNAME,str:string;
    RunPara:array[0..10] of Single;
    AngleRunPara:array[0..10] of Single;
begin
  FName:=ExtractFilePath(Application.ExeName)+'配置文件.Ini';
  IniFile:=TIniFile.Create(FName);   //将Inifile与INI建立联系，就可以通过Inifile来读取ini文件中的值 G
  str:=IniFile.ReadString('扭矩','零偏','0');
  TorqueOff:=StrToFloat(str);               //TorqueOff=-0.91 G
  str:=IniFile.ReadString('转角','零偏','0');
  AngleOff:=StrToFloat(str);     //AngleOff=0 G
  for j:=0 to 8 do
   begin
     PreTorque[j]:=0;
   end;
  PreRunCount:=StrToInt(IniFile.ReadString('扭矩','运行次数','0'));//第三个值为缺省值，该INI文件不存在该关键字时返回的缺省值 
  NowRuncount:=PreRunCount;
  LastRunCount:=NowRuncount;
  GetDataFromString(IniFile.ReadString('扭矩设定','参数设置','0 0 0'),RunPara,' ');
  Form1.OutputA1.Value:=RunPara[0];
  Form1.OutputA2.Value:=RunPara[1];
  Form1.OutputA3.Value:=RunPara[2];
  Form1.OutputA4.Value:=RunPara[3];
  MaxTorque:=RunPara[0];
  MinTorque:=RunPara[1];
  RunSpeed:=RunPara[2];
  GetDataFromString(IniFile.ReadString('转角设定','参数设置','0 0 0'),AngleRunPara,' ');
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
  InitECSystem;//设置各个电缸控制器ECS[i]初始参数 ，IP值  G
  InitRunPara;  //初始化最大值设置参数和运动次数 G
  ActiveEC:=ShowControllerList;  //选择IP值界面 返回选择的电缸控制器    控制器地址在192.168.1.100-192.168.1.199之间 G
  if ActiveEC=nil then ActiveEC:=ECs[0];  
  for i:=0 to 3 do ECys[i]:=ActiveEC.ECys[i];   //各个电缸属性G
 // NI_AD:=TNI_AD.Create('Dev1/ai0:7');
//  NI_Encode:=TNI_Encode.Create('Dev1/ctr0');
//  for i:=0 to 7 do DF[i]:=TDataFilter.Create(10);
  tmr1.Enabled:=True;//激活时钟1 G
  mytime:=0; //单独实数变量 G
  TMyThread.Create(False); //在TThread类中常见 False创建线程并执行   True 创建线程后先挂起，等待用户操作后再执行 G
  MyTimer1:=TMyTimer.Create;
  MyTimer2:=TMyTimer.Create;  //创建TMyTimer类变量    G
  NormalRun:=False;   //
  TorqueRun:=False;   //转矩限制运动模式   
  SetPosZeroFlag:=False;  //电缸位置置0标志位
  InitPositionIndex:=0;
  ReachMaxCountIndex:=0;  
  States:=0;
  InitPositionFlag:=False;
  SaveFile:='D:\实验数据\';
 
end;

procedure TForm1.tmr1Timer(Sender: TObject);      //主时钟
{ var ActivePlot:TiPlot; }
    i,j,k,downCount:Integer;
    //var StopRun,StartRun,Btn_In1,Btn_Out1:TLbSpeedButton;
    //Display_Angle,Display_Torque,Disp_ActPos1,Disp_Force:TiSevenSegmentAnalog;
begin
  downCount:=0;
  NowTorque:=-ReadTorque;
  //NowTorque:=(ReadTorque-Torqueoff)*torquegain;
  Display_Angle.Value:=Ecys[1].TD.actpos; //角度 G ???
  Display_Torque.Value:=NowTorque;  //当前扭矩
  Disp_ActPos1.Value:=Ecys[0].TD.actpos;//电缸位置 G  ???
  Disp_Force1.Value:=Ecys[0].TD.actforce; //实际力G
  Display_MaxTorque.Value:=MaxRunTorque;
  Display_MinTorque.Value:=MinRunTorque;
  Display_MaxAngle.Value:=MaxRunAngle;
  Display_MinAngle.Value:=MinRunAngle;
  Disp_MaxForce1.Value:=MaxRunForce;
  Disp_MinForce1.Value:=MinRunForce;
  Disp_GivPos1.Value:=Ecys[0].TD.givpos; //给定位置G
  Disp_DvPos1.Value:=(Ecys[0].TD.givpos-Ecys[0].TD.actpos);
  Disp_RunCount1.Value:=NowRuncount;
  Display_Angle.Value:=ActualAngle; //当前角度 第364行是错的吧？
  GetMaxAndMinValue;   //获取各参数的最大最小值
  if (NormalRun=True)or (AngleRun=True) then
  begin
    NowRuncount:=Ecys[0].TD.runcount+PreRunCount;

    if LastRunCount<>NowRuncount then  //位控模式下  一个运动周期结束
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
         Ecys[0].Stop;       //自动停机
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


        if GetAveTorque=True then                 //每次点击开始运行时 取得当次运行的最大最小停机扭矩
        begin
           JudgeMaxTorque[GetTorqueNumber]:=MaxRunTorque;
           JudgeMinTorque[GetTorqueNumber]:=MinRunTorque;
           SumMaxTorque:=SumMaxTorque+JudgeMaxTorque[GetTorqueNumber];
           SumMinTorque:=SumMinTorque+JudgeMinTorque[GetTorqueNumber];
           GetTorqueNumber:= GetTorqueNumber+1;

           if GetTorqueNumber = 10 then     //取了10个周期的最大最小值后，记录判断的最大最小扭矩
           begin
             GetAveTorque:=False;
             GetTorqueNumber:=0;
             AveMaxTorque:=SumMaxTorque*0.1;  //得到停机的扭矩平均最大最小扭矩
             AveMinTorque:=SumMinTorque*0.1;
             GetTorqueIndex:=1;
             for k:=0 to 9 do
               begin
                 JudgeMaxTorque[k]:=0;
                 JudgeMinTorque[k]:=0;
               end;
           end;

        end;


       ClearMaxMin; //清除最大最小值
       IniFile.WriteString('扭矩','运行次数',Trim(IntToStr(NowRuncount)));
       LastRunCount:=NowRuncount;



    end;
    if (NowTorque>=MaxTorque) or (NowTorque<=MinTorque) then     //最大最小扭矩保护
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
       StopSetPara;   //超过设定的最大最小扭矩后0.5 秒停止
    end;
    if Ecys[0].TD.runstate=0 then
    begin
        Form1.Btn_ShowPlot.Color:=clSilver;
    end;
  end;

  if  Form1.Btn_ShowPlot.Color=clYellow then   //画图
  begin
      if   Form1.PageControl1.ActivePageIndex = 0 then
      begin
        ActivePlot:=Form1.iPlot1;
        if MyTimer1.GetTime(0)>600then  //600是ms吗？G
          begin
              SaveDataToText;
              MyTimer1.Clear(0);//获取计数器计数值赋予给MyTimer的Start数组第[0]个元素；  
              ActivePlot.ClearAllData;
              ActivePlot.XAxis[0].Min:=0;
          end;
       // if DF[0].Value>100 then DF[0].Value:=100;
       // if DF[0].Value<-100 then DF[0].Value:=-100;

          with ActivePlot.Channel[0] do if Visible then AddXY(MyTimer1.GetTime(0),ActualAngle);   //  实时角度G
          with ActivePlot.Channel[1] do if Visible then AddXY(MyTimer1.GetTime(0),ECys[0].TD.actforce);// 实时力G
          with ActivePlot.Channel[2] do if Visible then AddXY(MyTimer1.GetTime(0),NowTorque);  //  实时扭矩G
          with ActivePlot.Channel[3] do if Visible then AddXY(MyTimer1.GetTime(0),ECys[0].TD.actpos);  // 实时位置G
          with ActivePlot.Channel[4] do if Visible then AddXY(MyTimer1.GetTime(0),ECys[0].TD.givpos);  // 给定位移G
         

        if MyTimer1.GetTime(0)>ActivePlot.XAxis[0].Max then ActivePlot.XAxis[0].Min:=ActivePlot.XAxis[0].Min+ActivePlot.XAxis[0].Span/4;//当横坐标到达最大，不断更改坐标最小值  span/4？？
        if MyTimer1.GetTime(0)>3600 then
        begin
          MyTimer1.Clear(0);
          ActivePlot.ClearAllData;
          ActivePlot.XAxis[0].Min:=0;
        end;
      end;
      if  Form1.PageControl1.ActivePageIndex = 1 then   //不能显示扭矩转角关系的原因 G
      begin
      end;
  end;

  if (NowRuncount>=TotalRunCount) and(ReachMaxCountIndex=0) then
  begin
     Ecys[0].Stop;       //自动停机
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
  if InitPositionFlag = True then  //初始化位置
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

  if TorqueRun = True then    //扭矩控制模式
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
        ECys[0].RunFix(SPEED_CONTROL,-1*RunSpeed);   //全伸出
        Inc(States);
      end;
    end
    else if States = 2 then
    begin
      if(Ecys[0].TD.actpos>=0) and(CountFlag) then    //满足这两个条件时，代表扭矩控制方式一个周期结束
      begin
        CountFlag:=False;
        ClearMaxMin; //一个周期结束，清除最大最小
        NowRuncount:=NowRuncount+1;
      end;
      if(DF[0].Value>=MaxTorque) then
      begin
        ECys[0].ClearSig;
        ECys[0].RunFix(SPEED_CONTROL,1*RunSpeed);   //全缩回
        Inc(States);
      end;
    end
    else if States = 3 then
    begin
      if(DF[0].Value<=MinTorque) then
      begin
         ECys[0].ClearSig;
         ECys[0].RunFix(SPEED_CONTROL,-1*RunSpeed);  //全伸出
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
  PreRunCount:=StrToInt(IniFile.ReadString('扭矩','运行次数','0'));
  NowRuncount:=PreRunCount;
  LastRunCount:=NowRuncount;
end;

procedure SaveDataToText;   //2020/1/1  晚上9:49没读懂
var FileT:TextFile;
    str1,str2,str3: String;
    ActivePlot:TiPlot;
begin
   ActivePlot:=Form1.iPlot1;
   SaveTime:=DateTimeToStr(Now());  //获取当前系统时间 G
   SaveTime:=DeleteStr(SaveTime,str1,'/');
   SaveTime:=DeleteStr(SaveTime,str2,':');
   str3:=SaveFile+str2+'.txt'; //str3的格式为D:\实验数据\202012 92024.txt；G
   AssignFile(FileT,str3);
   Form1.Label15.Caption:=str3;
   Rewrite(FileT);
   CloseFile(FileT);
   ActivePlot.SaveDataToFile(str3);  //      没找到对应功能 G   
  // SaveFile:='D:\实验数据\';
   str1:='';Str2:='';str3:='';
   IniFile.WriteString('扭矩','运行次数',Trim(IntToStr(NowRuncount)));
end;
procedure TForm1.Btn_RunParaClick(Sender: TObject);
begin
  Ecys[0].ShowRunSigSetting;

end;

procedure TForm1.AngleClearClick(Sender: TObject);
begin
   AngleOff:=ReadAngle;
   IniFile.WriteString('转角','零偏',Trim(FloatToStr(AngleOff)));
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
  IniFile.WriteString('扭矩','零偏',Trim(FloatToStr(TorqueOff)));
  IniFile.WriteString('转角','零偏',Trim(FloatToStr(AngleOff)));
  Str:='';
  for i:=0 to 3 do
  begin
    Output:=FindComponent('Output'+Chr(Ord('A'))+inttostr(i+1)) as TiAnalogOutput;
    if Output<>nil then Str:=Str+' '+Output.Text;
  end;
  Str:=Trim(Str);
  IniFile.WriteString('扭矩设定','参数设置',Str);
  Str:='';
  for i:=4 to 6 do
  begin
    Output:=FindComponent('Output'+Chr(Ord('A'))+inttostr(i+1)) as TiAnalogOutput;
    if Output<>nil then Str:=Str+' '+Output.Text;
  end;
  Str:=Trim(Str);
  IniFile.WriteString('转角设定','参数设置',Str);
  IniFile.WriteString('扭矩','运行次数',Trim(IntToStr(NowRuncount)));

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
  Caption:='多通道电动缸综合测控软件-远程控制器'+ActiveEC.GetIPAddr;
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
           iPlot1.SaveDataToFile('D:\实验数据\2017930 113711.txt');
         //  Flush(FileT);
         //  CloseFile(FileT);
         //  SaveFile:='D:\实验数据\';
            // iPlot1.SaveDataToFile(SaveFile);

end;

procedure TForm1.OutputA4Change(Sender: TObject);
begin
  TotalRunCount:=Round(OutputA4.Value);
end;

procedure TForm1.Btn_ClearCountClick(Sender: TObject);
begin
  NowRuncount:=0;
  IniFile.WriteString('扭矩','运行次数',Trim(IntToStr(NowRuncount)));
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
   PreRunCount:=StrToInt(IniFile.ReadString('扭矩','运行次数','0'));
   NowRuncount:=PreRunCount;
   LastRunCount:=NowRuncount;
   Ecys[0].ClearSig;
   Str:='位置控制,正弦运动,幅值:'+FloatToStr(AngleRunAmp)+' 频率:'+FloatToStr(AngleRunFre)+' 零位:0.0'+' 次数:1';
   Ecys[0].AddSig(Str);
   Ecys[0].Run(TotalRunCount);
  // Ecys[0].AddSigSin(0,AngleRunAmp,AngleRunFre,0,1);
  // Ecys[0].Run(TotalRunCount);

end;



end.

