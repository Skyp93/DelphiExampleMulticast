unit UfrmMain1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, udm1, FMX.Layouts, FMX.EditBox,
  FMX.NumberBox, FMX.Edit, idglobal, FMX.dialogservice, idstack,
  androidapi.jni.wifimanager, IPPeerClient, IPPeerServer, System.Tether.Manager,
  IdBaseComponent, IdComponent, IdUDPBase, IdUDPServer, System.NetEncoding,
  IdSocketHandle, FMX.ScrollBox, FMX.Memo{$IFDEF Android} ,  Androidapi.jni.javatypes,
  androidapi.Helpers{$ENDIF};

type
  TfrmMain = class(TForm)
    GbSetting: TGroupBox;
    lbipCap: TLabel;
    LbSetIp: TLabel;
    lbCastIndex: TLabel;
    ESrvIndex: TEdit;
    LbPort: TLabel;
    NBPort: TNumberBox;
    lbCastGroup: TLabel;
    EMCastGroup: TEdit;
    LayManageSrv: TLayout;
    BtnStartSrv: TButton;
    lbTtl: TLabel;
    NBTttl: TNumberBox;
    BtnStartList: TButton;
    tmIpChangeIp: TTimer;
    MChat: TMemo;
    mainVertScb: TVertScrollBox;
    GbMes: TGroupBox;
    MMessage: TMemo;
    sb1: TStyleBook;
    CBUseSugar: TCheckBox;
    procedure BtnStartSrvClick(Sender: TObject);
    procedure BtnStartListClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmIpChangeIpTimer(Sender: TObject);

  private
{$IFDEF Android}
    fWifimanager: JWiFiManager;
    FmCastLock: JWifiManagerMulticastLock;
{$ENDIF}
    { Private declarations }
    procedure RefreshIpAddress;
    function GetIpOnAndroid: string;

  const
    CDefPrefVal: TBytes = [36, 98, 54, 3];
  public
    { Public declarations }
    procedure getMes(aBytes: TIdBytes; aClientIp: string);
    constructor Create(aowner: TComponent); override;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}

procedure TfrmMain.BtnStartListClick(Sender: TObject);
begin
  if Sender is TButton then
  begin
    with DM1.idCastClient do
    begin
      if TButton(Sender).Text = 'Начать слушать' then
      begin
        Active := False;

{$IFDEF Android}
        FmCastLock.acquire();

{$ENDIF}
        if (not DM1.idCastSrv.IsValidMulticastGroup(EMCastGroup.Text)) then
        begin
          TDialogService.MessageDialog('Указанна некорректная "' +
            EMCastGroup.Text + '" группа.', TMsgDlgType.mtError,
            [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
          EMCastGroup.SetFocus;
{$IFDEF android}
          if Assigned(FmCastLock) then
            FmCastLock.release;
{$ENDIF}
          exit;
        end;
        TButton(Sender).Text := 'Окончить слушать';
        DefaultPort := NBPort.Text.ToInteger;
        Binding.AddMulticastMembership(EMCastGroup.Text);
        Active := true;
        CBUseSugar.Enabled := False;
      end
      else
      begin
        TButton(Sender).Text := 'Начать слушать';
{$IFDEF Android}
        if Assigned(FmCastLock) then
        begin
          FmCastLock.release();
        end;
{$ENDIF}
        Active := False;
        CBUseSugar.Enabled := true;
      end;
    end;
  end;
end;

procedure TfrmMain.BtnStartSrvClick(Sender: TObject);
var
  lmes: string;
begin
  if (not DM1.idCastSrv.IsValidMulticastGroup(EMCastGroup.Text)) then
  begin
    TDialogService.MessageDialog('Указанна некорректная "' + EMCastGroup.Text +
      '" группа.', TMsgDlgType.mtError, [TMsgDlgBtn.mbOK],
      TMsgDlgBtn.mbOK, 0, nil);
    exit;
  end;
  if StringReplace(MMessage.Text, ' ', EmptyStr, [rfReplaceAll, rfIgnoreCase]).IsEmpty
  then
  begin
    TDialogService.MessageDialog('Нельзя отправить пустое сообщение',
      TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
    MMessage.SetFocus;
    exit;
  end;
  with DM1 do
  begin
    idCastSrv.Active := False;
    idCastSrv.Port := NBPort.Text.ToInteger;
    idCastSrv.Binding.AddMulticastMembership(EMCastGroup.Text);

    if CBUseSugar.IsChecked then
    begin
      lmes := TEncoding.utf8.GetString
        (CDefPrefVal + BytesOf(TNetEncoding.Base64.Encode(MMessage.Text)));
      idCastSrv.Send(lmes);
    end
    else
    begin
      lmes := TEncoding.utf8.GetString
        (BytesOf(TNetEncoding.Base64.Encode(MMessage.Text)));;
      idCastSrv.Send(TEncoding.utf8.GetString(BytesOf(lmes)));
    end;
  end;
  MMessage.Lines.Clear;
end;

constructor TfrmMain.Create(aowner: TComponent);
begin
  inherited;
  DM1.WatchIpProc := RefreshIpAddress;
  DM1.isShowMainApp := true;
  try
    RefreshIpAddress;
  except
    on e: exception do
      TDialogService.MessageDialog('Не удалось определить внешний ip адрес.' +
        sLineBreak + e.Message, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK],
        TMsgDlgBtn.mbOK, 0, nil);

  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);

begin
  tmIpChangeIp.Enabled := False;
{$IFDEF Android}
  fWifimanager := getWifiManager;
  FmCastLock := fWifimanager.createMulticastLock
    (StringToJString(string(application.Name)));
  FmCastLock.setReferenceCounted(true);
  DM1.idWatch.Active := False;
{$ELSE}
  DM1.idWatch.Active := true;
{$ENDIF}
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
{$IFDEF Android}
  ESrvIndex.Text := GetIpOnAndroid;
  tmIpChangeIp.Enabled := true;
{$ELSE}
  ESrvIndex.Text := DM1.idWatch.LocalIP;
{$ENDIF}
end;

function TfrmMain.GetIpOnAndroid: string;
{$IFDEF Android}
var
  lWifiInfo: JWifiInfo;
  lip: Integer;
  lStringList: TStringList;
{$ENDIF}
begin
  result := EmptyStr;
{$IFDEF Android}
  try
    if Assigned(fWifimanager) then
    begin
      lWifiInfo := fWifimanager.getConnectionInfo();
      /// способ получения ip адреса wi-fi адаптера
      lip := lWifiInfo.getIpAddress and $FFFFFFF;
      result := Format('%d.%d.%d.%d', [(lip) and $FF, (lip shr 8) and $FF,
        (lip shr 16) and $FF, (lip shr 24) and $FF]);
      if (result.IsEmpty) or (result = '0.0.0.0') then
      begin
         /// Здесь можно получить все ip адреса
        lStringList := GetAllLocalIndexList(true);
        result := lStringList[0];

      end;

    end;
  except
    on e: exception do
      TDialogService.MessageDialog('Не удалось получить ip:' + sLineBreak +
        e.Message, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK],
        TMsgDlgBtn.mbOK, 0, nil);

  end;
{$ENDIF}
end;

procedure TfrmMain.getMes(aBytes: TIdBytes; aClientIp: string);

var
  lmes: string;
  li, lLenBytes: Integer;
  lbytes: TIdBytes;
begin
  try
    if CBUseSugar.IsChecked then
    begin
      lLenBytes := Length(CDefPrefVal);
      /// попределяем что он свой - клиент и сообщение
      for li := 0 to lLenBytes - 1 do
        if aBytes[li] <> CDefPrefVal[li] then
          exit;
      /// обрезаем служебную строку
      lbytes := Copy(aBytes, lLenBytes, Length(aBytes) - lLenBytes);
    end
    else
      lbytes := aBytes;
    lmes := TNetEncoding.Base64.decode(BytesToString(lbytes));
    MChat.Lines.Add('[' + datetimetostr(now) + '] ' + '[' + aClientIp +
      '] ' + lmes);
  except
    lmes := BytesToString(lbytes);
    MChat.Lines.Add('[' + datetimetostr(now) + '] ' + '[' + aClientIp +
      '] ' + lmes);

  end;
end;

procedure TfrmMain.RefreshIpAddress;
var
  lmyip: RMyIp;
  lstr: string;
begin
  lmyip := DM1.MyIpInfo;
  TThread.Synchronize(nil,
    procedure()
    begin
{$IFDEF Android}
      lstr := GetIpOnAndroid;
{$ELSE}
      lstr := DM1.idWatch.LocalIP;
{$ENDIF}
      if DM1.idCastClient.Active then
      begin
        DM1.idCastClient.Active := False;
        DM1.idCastClient.Active := true;
      end;
      ESrvIndex.Text := lstr;
      LbSetIp.Text := lmyip.ip + ' ( Provider: ' + lmyip.provider + ' (' +
        lmyip.city + ' [' + lmyip.country + ']))';
    end);
end;

procedure TfrmMain.tmIpChangeIpTimer(Sender: TObject);
begin
{$IFDEF Android}
  if ESrvIndex.Text <> GetIpOnAndroid then
    DM1.idWatchStatusChanged(nil);
{$ENDIF}
end;

end.
