unit IPSetting;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, LbButton;

type
  TFrmIPSetting = class(TForm)
    Label1: TLabel;
    ComboBox1: TComboBox;
    Btn_OK: TLbButton;
    Btn_Cancel: TLbButton;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmIPSetting: TFrmIPSetting;

implementation

{$R *.DFM}

procedure TFrmIPSetting.FormCreate(Sender: TObject);
var i:Integer;
begin
  ComboBox1.Items.Clear;
  for i:=0 to 99 do ComboBox1.Items.Add(inttostr(100+i));
  ComboBox1.ItemIndex:=0;
end;

end.
