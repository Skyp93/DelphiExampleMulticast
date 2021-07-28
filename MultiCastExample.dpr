program MultiCastExample;

uses
  System.StartUpCopy,
  FMX.Forms,
  UfrmMain1 in 'UfrmMain1.pas' {frmMain} ,
  UDM1 in 'UDM1.pas' {DM1: TDataModule} ,
  Androidapi.JNI.WiFiManager in 'Androidapi.JNI.WiFiManager.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDM1, DM1);
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;

end.
