unit NI_Delphi;

interface

uses Dialogs, SysUtils, nidaqmx, NIDAQmxCAPI_TLB, Windows;

type

  TNI_AD = class
  private
    NumPerChan: Integer;
    EveryN: Integer;

  public
    Handle:LongInt;
    ID1,ID2:LongInt;
    ChannelDataBuf:array[0..7,0..50000]of Single;
    ChannelDataBufCount:Integer;
    ChannelData:array[0..100]of Double;
    Rate: Single;

    constructor Create(DevName:String='Dev1/ai0:7');
    destructor Destroy;
    procedure GetData;
    procedure SetPara(rateperchan:Integer; en:Integer=0; callbackFunction:Longint=0);
    procedure Start;
  end;

  TNI_DA = class
  public
    Handle:LongInt;
    constructor Create(DevName:String='Dev1/ao0');
    destructor Destroy;
    procedure OutputValue(value:single);
    procedure OutputSin(amp,freq,offset:Double);
    procedure OutputTri(amp,freq,offset:Double);
    procedure OutputStep(v1,v2,dt:Single);
  end;

  TNI_DI = class
  public
    Handle:LongInt;
    Value:array[0..100]of Byte;

    constructor Create(DevName:String='Dev1/port0/line0:1');
    destructor Destroy;
    procedure Read;
  end;

  TNI_DO = class
  public
    Handle:LongInt;
    Value:array[0..100]of Byte;

    constructor Create(DevName:String='Dev1/port0/line2:3');
    destructor Destroy;
    procedure Write;
  end;

  TNI_CIFreq = class
  public
    Handle:LongInt;
    Value:Double;

    constructor Create(DevName:String);
    procedure GetData;
    //destructor Destroy;
  end;

  TNI_Encode = class
  private
    NumPerChan: Integer;
    EveryN: Integer;

  public
    Handle:LongInt;
    DataBuf:array[0..100000]of Double;
    DataBufCount:Integer;
    Value:Double;

    constructor Create(DevName:String='Dev1/ctr0');
    destructor Destroy;
    procedure SetPara(rateperchan:Integer; en:Integer=0; callbackFunction:Longint=0);
    procedure GetData;
    procedure Start;
    procedure Clear;
  end;

  var Runcount:Integer;

implementation


function GetTerminalNameWithDevPrefix(Handle:LongInt; terminalName:string; var triggerName: string):Integer;
var device: array[0..200]of Char;
    productCategory: DAQmxProductCategory;
    numDevices,i: Integer;
begin
  DAQmxGetTaskNumDevices(Handle,@numDevices);

  i:=0;
  while i<=numDevices do
  begin
    Inc(i);
    DAQmxGetNthTaskDevice(Handle,i,@device,256);
    DAQmxGetDevProductCategory(@device,productCategory);
    if((productCategory<>DAQmx_Val_ProductCategory_CSeriesModule) and (productCategory<>DAQmx_Val_ProductCategory_SCXIModule)) then
    begin
      triggerName:=device;
      triggerName:='/'+triggername+'/'+terminalName;
      Break;
    end;
  end;
end;


constructor TNI_AD.Create(DevName:String);
var res: integer;
    p1,p2:Integer;
begin
  DAQmxCreateTask('',@Handle);

  p1:=pos('ai',DevName);
  p2:=pos(':',DevName);
  if p2>p1 then
  begin
    ID1:=StrToInt(Copy(DevName,p1+2,p2-p1-2));
    ID2:=StrToInt(Copy(DevName,p2+1,2));
  end
  else
  begin
    ID1:=StrToInt(Copy(DevName,p1+2,2));
    ID2:=ID1;
  end;
  res:=DAQmxCreateAIVoltageChan(Handle,pChar(DevName),'',DAQmx_Val_InputTermCfg_RSE,-10.0,10.0,DAQmx_Val_VoltageUnits2_Volts,'');
  if(res<0) then showmessage('NI_AD³õÊ¼»¯´íÎó£¡')
  else
  begin
    //SetPara(1,2000,0.2);
    //SetPara(0,2000);
    //Start;
  end;
end;

destructor TNI_AD.Destroy;
begin
  DAQmxClearTask(Handle);
end;

procedure TNI_AD.GetData;
var ch,k,i:Integer;
    Buf:array[0..100000]of double;
    ReadNum:LongInt;
begin
  NumPerChan:=EveryN;
  DAQmxReadAnalogF64(Handle,NumPerChan,1.0,DAQmx_Val_GroupByScanNumber,@Buf,(ID2-ID1+1)*NumPerChan,@ReadNum,nil);
  for i:=0 to ReadNum*(ID2-ID1+1)-1 do
  begin
    ch:=(i mod (ID2-ID1+1));
    k:=i div (ID2-ID1+1);
    ChannelDataBuf[ch,k]:=Buf[i];
  end;
  ChannelDataBufCount:=ReadNum;

  {
  for i:=ID1 to ID2 do
  begin
    ChannelData[i]:=0;
    for k:=0 to ReadNum-1 do ChannelData[i]:=ChannelData[i]+ChannelDataBuf[i,k];
    ChannelData[i]:=ChannelData[i]/ReadNum;
  end; }
end;


procedure TNI_AD.SetPara(rateperchan:Integer; en:Integer; callbackFunction:Longint);
begin
  DAQmxStopTask(Handle);
  NumPerChan:=Round(1*RatePerChan);

  DAQmxCfgSampClkTiming(Handle,'',RatePerChan,DAQmx_Val_Rising,DAQmx_Val_AcquisitionType_ContSamps,NumPerChan);
  //if callbackFunction1<>0 then DAQmxRegisterDoneEvent(Handle,0, callbackFunction1, nil);
  if (en>0) and (callbackFunction>0) then DAQmxRegisterEveryNSamplesEvent(Handle,DAQmx_Val_Acquired_Into_Buffer,en,0, callbackFunction, nil);
  EveryN:=en;
  Rate:=rateperchan;

  DAQmxStopTask(Handle);
end;

procedure TNI_AD.Start;
begin
  DAQmxStartTask(Handle);
end;

constructor TNI_DA.Create(DevName:String);
var res: integer;
begin
  DAQmxCreateTask('',@Handle);
  res:=DAQmxCreateAOVoltageChan(Handle,pChar(DevName),'',-10.0,10.0,DAQmx_Val_VoltageUnits2_Volts,'');
  if(res<0) then showmessage('NI_DA³õÊ¼»¯´íÎó£¡');
end;

destructor TNI_DA.Destroy;
begin
  DAQmxClearTask(Handle);
end;

procedure TNI_DA.OutputValue(value:single);
var Data:array[0..100]of Double;
    Count:Integer;
    i:integer;
begin
  Count:=2;
  for i:=0 to Count-1 do Data[i]:=Value;

  DAQmxStopTask(Handle);
  //DAQmxCfgSampClkTiming(Handle,'',1000,DAQmx_Val_Rising,DAQmx_Val_AcquisitionType_FiniteSamps,Count);
  DAQmxWriteAnalogF64(Handle,Count,True,10.0,DAQmx_Val_GroupByChannel,@Data,nil,nil);
end;

procedure TNI_DA.OutputSin(amp,freq,offset:Double);
var Rate:Double;
    DataCount,i:LongInt;
    Data:array[0..2000]of Double;
begin
  if Freq=0 then Freq:=1;

  DataCount:=500;
  Rate:=DataCount*Freq;
  if Rate>5000 then Rate:=5000;
  DataCount:=Round(Rate/Freq);
  for i:=0 to DataCount-1 do Data[i]:=Amp*Sin(i*2.0*PI/DataCount)+Offset;

  DAQmxStopTask(Handle);
  DAQmxCfgSampClkTiming(Handle,'',Rate,DAQmx_Val_Rising,DAQmx_Val_AcquisitionType_ContSamps,DataCount);
  DAQmxWriteAnalogF64(Handle,DataCount,True,10.0,DAQmx_Val_GroupByChannel,@Data,nil,nil);
end;

procedure TNI_DA.OutputTri(amp,freq,offset:Double);
var Rate:Double;
    DataCount,i:LongInt;
    Data:array[0..2000]of Double;
    d:single;
begin
  if Freq=0 then Freq:=1;

  DataCount:=500;
  Rate:=DataCount*Freq;
  if Rate>5000 then Rate:=5000;
  DataCount:=Round(Rate/Freq);

  d:=Amp*4/DataCount;
  for i:=0 to DataCount-1 do
  begin
    if i<DataCount/4 then Data[i]:=i*d
    else if i<DataCount*3/4 then Data[i]:=Amp-(i-DataCount/4)*d
    else Data[i]:=-Amp+(i-DataCount*3/4)*d;
    Data[i]:=Data[i]+Offset;
  end;

  DAQmxStopTask(Handle);
  DAQmxCfgSampClkTiming(Handle,'',Rate,DAQmx_Val_Rising,DAQmx_Val_AcquisitionType_ContSamps,DataCount);
  DAQmxWriteAnalogF64(Handle,DataCount,True,10.0,DAQmx_Val_GroupByChannel,@Data,nil,nil);
end;

procedure TNI_DA.OutputStep(v1,v2,dt:Single);
var Rate:Double;
    i,DataCount:Integer;
    Data:array[0..2000]of Double;
begin
  if dt<0.1 then dt:=0.1;

  DataCount:=2000;
  Rate:=DataCount/dt;

  for i:=0 to DataCount-1 do
  begin
    if i<DataCount*0.25 then Data[i]:=v1
    else if i<DataCount*0.75 then Data[i]:=v2
    else Data[i]:=v1;
  end;
  
  DAQmxStopTask(Handle);
  DAQmxCfgSampClkTiming(Handle,'',Rate,DAQmx_Val_Rising,DAQmx_Val_AcquisitionType_ContSamps,DataCount);
  DAQmxWriteAnalogF64(Handle,DataCount,True,10.0,DAQmx_Val_GroupByChannel,@Data,nil,nil);
end;

constructor TNI_DI.Create(DevName:String);
var res: integer;
begin
  DAQmxCreateTask('',@Handle);
  res:=DAQmxCreateDIChan(Handle,pChar(DevName),'',DAQmx_Val_ChanForAllLines);
  if(res<0) then showmessage('NI_DI³õÊ¼»¯´íÎó£¡');
end;

destructor TNI_DI.Destroy;
begin
  DAQmxClearTask(Handle);
end;

procedure TNI_DI.Read;
var num:LongInt;
begin
  DAQmxReadDigitalLines(Handle,1, 20, DAQmx_Val_GroupByScanNumber, @Value, 10, @num, nil, nil);
end;

constructor TNI_DO.Create(DevName:String);
var res,i: integer;
begin
  DAQmxCreateTask('',@Handle);
  res:=DAQmxCreateDOChan(Handle,pChar(DevName),'',DAQmx_Val_ChanForAllLines);
  if(res<0) then showmessage('NI_DO³õÊ¼»¯´íÎó£¡');

  for i:=0 to 100 do Value[i]:=0;
end;

destructor TNI_DO.Destroy;
begin
  DAQmxClearTask(Handle);
end;

procedure TNI_DO.Write;
begin
  DAQmxWriteDigitalLines(Handle,1,True,20, DAQmx_Val_GroupByScanNumber, @Value, nil, nil);
end;


constructor TNI_CIFreq.Create(DevName:String);
var res: integer;
begin
  DAQmxCreateTask('',@Handle);
  //res:=DAQmxCreateCOPulseChanFreq(Handle,pChar(DevName),nil,DAQmx_Val_FrequencyUnits2_Hz,DAQmx_Val_Level1_Low,0,freq,0.5);
  res:=DAQmxCreateCIFreqChan(Handle,pChar(DevName),'',1.192093,10000000.000000,DAQmx_Val_FrequencyUnits3_Hz,DAQmx_Val_Edge1_Rising,DAQmx_Val_CounterFrequencyMethod_LowFreq1Ctr,0.001,4,'');
  if(res<0) then showmessage('NI_Ctr³õÊ¼»¯´íÎó£¡')
  else
  begin
    //DAQmxCfgImplicitTiming(Handle,DAQmx_Val_AcquisitionType_ContSamps,100);
    DAQmxStartTask(Handle)
  end;
end;

procedure TNI_CIFreq.GetData;
begin
  //DAQmxStartTask(Handle);
  DAQmxReadCounterScalarF64(Handle,0.5,@Value,0)
  //DAQmxReadCounterF64(Handle,NumPerChan,1,@DataBuf,NumPerChan,@num,nil);
end;

constructor TNI_Encode.Create(DevName:String);
var res: integer;
    pulsesPerRev:Longint;
begin
  DAQmxCreateTask('',@Handle);
  pulsesPerRev:=10000;
  res:=DAQmxCreateCIAngEncoderChan(Handle,pChar(DevName),nil,DAQmx_Val_EncoderType2_X4,False,0,DAQmx_Val_EncoderZIndexPhase1_AHighBHigh,DAQmx_Val_AngleUnits2_Degrees,pulsesPerRev,0,nil);
  if(res<0) then showmessage('NI_Ctr³õÊ¼»¯´íÎó£¡')
  else
  begin
    SetPara(0,1000);     Start;
  end;
end;

procedure TNI_Encode.SetPara(rateperchan:Integer; en:Integer; callbackFunction:Longint);
begin
  DAQmxStopTask(Handle);
  NumPerChan:=round(rateperchan*1);
  DAQmxCfgSampClkTiming(Handle,'/Dev1/ai/SampleClock',1000.0,DAQmx_Val_Rising,DAQmx_Val_AcquisitionType_ContSamps,NumPerChan);
  DAQmxStopTask(Handle);
end;

procedure TNI_Encode.Start;
begin
  DAQmxStartTask(Handle);
end;

destructor TNI_Encode.Destroy;
begin
  DAQmxClearTask(Handle);
end;

procedure TNI_Encode.GetData;
var num:LongInt;
begin
  begin
    DAQmxReadCounterF64(Handle,NumPerChan,1,@DataBuf,NumPerChan,@num,nil);
    if num>0 then
    begin
      DataBufCount:=num;
      value:=DataBuf[num-1];
    end;
  end;
end;

procedure TNI_Encode.Clear;
begin
  DAQmxStopTask(Handle);
end;




end.
