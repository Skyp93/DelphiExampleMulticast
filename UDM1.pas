unit UDM1;

interface

uses
  System.SysUtils, System.Classes, IdBaseComponent, IdComponent, IdIPMCastBase,
  IdIPMCastServer, IdTCPConnection, IdTCPClient, IdHTTP, System.json,
  FMX.DialogService,
  System.UITypes, IdIPWatch, System.threading, IdGlobal, IdSocketHandle,
  IdIPMCastClient, IPPeerClient, IPPeerServer, System.Tether.Manager,
  IdUDPServer, IdUDPBase;

type
  TWatchIpProc = procedure of object;

  RMyIp = record
    postal, provider, region, country, city, ip, hostname, timezone,
      locationonip: string;
  end;

  TDM1 = class(TDataModule)
    idMyIp: TIdHTTP;
    idWatch: TIdIPWatch;
    idCastClient: TIdUDPServer;
    idCastSrv: TIdIPMCastServer;
    procedure idWatchStatusChanged(Sender: TObject);
    procedure DataModuleCreate(Sender: TObject);
    procedure idCastClientUDPRead(AThread: TIdUDPListenerThread;
      const AData: TIdBytes; ABinding: TIdSocketHandle);
  private
    FIpInfo: RMyIp;
    FRefreshOnWatch: TWatchIpProc;
    fisShow: Boolean;
    function GetMyWhiteIp: RMyIp;

  const
    CDefQueryIndex: string = 'http://ipinfo.io/json';
    { Private declarations }
  public
    property MyIpInfo: RMyIp read GetMyWhiteIp;
    property WatchIpProc: TWatchIpProc read FRefreshOnWatch
      write FRefreshOnWatch;
    property isShowMainApp: Boolean read fisShow write fisShow;
    { Public declarations }
  end;

var
  DM1: TDM1;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}
{$R *.dfm}

{ TDM1 }
uses
  ufrmmain1;

procedure TDM1.DataModuleCreate(Sender: TObject);
begin
  fisShow := False;

end;

function TDM1.GetMyWhiteIp: RMyIp;
var
  ljsoo: TJSONObject;
  lstr: String;
begin
  try
    if idMyIp.Connected then
      idMyIp.Disconnect;
    lstr := idMyIp.Get(CDefQueryIndex);
    ljsoo := TJSONObject.ParseJSONValue(lstr) as TJSONObject;
    with result do
    begin
      ip := ljsoo.Get('ip').JsonValue.Value;
      timezone := ljsoo.Get('timezone').JsonValue.Value;
      city := ljsoo.Get('city').JsonValue.Value;
      country := ljsoo.Get('country').JsonValue.Value;
      region := ljsoo.Get('region').JsonValue.Value;
      locationonip := ljsoo.Get('loc').JsonValue.Value;
      postal := ljsoo.Get('postal').JsonValue.Value;
      provider := ljsoo.Get('org').JsonValue.Value;
      hostname := ljsoo.Get('hostname').JsonValue.Value;
      if idMyIp.Connected then
        idMyIp.Disconnect;
    end;
  except
    result := GetMyWhiteIp;
  end;
end;

procedure TDM1.idCastClientUDPRead(AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
begin
  frmMain.getMes(AData, ABinding.PeerIP + ':' + ABinding.PeerPort.ToString);
end;

procedure TDM1.idWatchStatusChanged(Sender: TObject);
begin
  if not fisShow then
    exit;
  if Assigned(FRefreshOnWatch) then
    TThread.CreateAnonymousThread(
      procedure()
      begin
        FRefreshOnWatch;
      end).Start;
end;

end.
