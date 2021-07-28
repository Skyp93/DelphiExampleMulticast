object DM1: TDM1
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 236
  Width = 437
  object idMyIp: TIdHTTP
    AllowCookies = True
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.ContentRangeEnd = -1
    Request.ContentRangeStart = -1
    Request.ContentRangeInstanceLength = -1
    Request.Accept = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    Request.Ranges.Units = 'bytes'
    Request.Ranges = <>
    HTTPOptions = [hoForceEncodeParams]
    Left = 64
    Top = 48
  end
  object idWatch: TIdIPWatch
    Active = False
    HistoryEnabled = False
    HistoryFilename = 'iphist.dat'
    OnStatusChanged = idWatchStatusChanged
    Left = 200
    Top = 104
  end
  object idCastClient: TIdUDPServer
    Bindings = <>
    DefaultPort = 0
    OnUDPRead = idCastClientUDPRead
    Left = 344
    Top = 52
  end
  object idCastSrv: TIdIPMCastServer
    BoundPort = 0
    MulticastGroup = '224.0.0.1'
    Port = 0
    Left = 344
    Top = 184
  end
end
