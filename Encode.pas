unit Encode;

interface

uses Windows, Messages, SysUtils, Classes, ExtCtrls,  Graphics, Controls, Forms, CPort;

type
  TEncode = class
  private
    Timer: TTimer;
    ComPort: TComPort;
    AbsValue, Offset:Single;

    procedure ComPortEvent(Sender: TObject; Count: Integer);
  public
    Value:Single;
    RecCount:Integer;

    constructor Create(ComName:String);
    procedure SetZero;
  end;

implementation


constructor TEnCode.Create(ComName:String);
begin
  ComPort:=TComPort.Create(Application);
  ComPort.PortNum:=ComName;
  ComPort.OnRxChar:=ComPortEvent;
  //ComPort.Close;
  ComPort.Open;
  Offset:=0;
end;

procedure TEncode.ComPortEvent(Sender: TObject; Count: Integer);
var Buf:array[0..100]of Byte;
    i:Integer;
begin
  if Count>0 then
  begin
    ComPort.Read(Buf,Count);
    ComPort.ClearBuffer(True,True);

    if Count>=5 then //and (Buf[0]=$A5) then
    begin
      for i:=0 to Count-4 do
      begin
        if (Buf[i]=$A5) and (Buf[i+1] in [$1,$2,$5A]) then
        begin
          AbsValue:=(Buf[i+2]*256+Buf[i+3])*0.005493;
          Value:=AbsValue-Offset;
          Inc(RecCount);
          Break;
        end;
      end;
    end;
  end;
end;

procedure TEncode.SetZero;
begin
  Offset:=AbsValue;
end;

end.
