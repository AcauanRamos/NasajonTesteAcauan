unit uMunicipiosEstatisticas;

interface

uses
  uMunicipios, System.Contnrs, System.Classes, System.JSON,
  System.Net.HttpClient, System.Net.HttpClientComponent, System.SysUtils;

type
  TRegiaoMedia = class
  private
    FMedia: double;
    FNome: string;
    FPopTotal: LongInt;
    FTotalMunicipios: integer;
    procedure SetMedia(const Value: double);
    procedure SetNome(const Value: string);
    procedure SetPopTotal(const Value: LongInt);
    procedure SetTotalMunicipios(const Value: integer);

  public
    property Nome: string read FNome write SetNome;
    property TotalMunicipios: integer read FTotalMunicipios write SetTotalMunicipios;
    property PopTotal: LongInt read FPopTotal write SetPopTotal;
    property Media: double read FMedia write SetMedia;
  end;

  TRegiaoList = class(TObjectList)
    function GetRegiaoPorNome(sRegiao: string): TRegiaoMedia;
  end;

  TMunicipiosEstatisticas = class
  private
    FTotal_ok: integer;
    FTotal_municipios: integer;
    FPop_total_ok: LongInt;
    FTotal_nao_encontrado: integer;
    FTotal_erro_api: integer;
    FMediasRegioes: TRegiaoList;
    procedure SetPop_total_ok(const Value: LongInt);
    procedure SetTotal_erro_api(const Value: integer);
    procedure SetTotal_municipios(const Value: integer);
    procedure SetTotal_nao_encontrado(const Value: integer);
    procedure SetTotal_ok(const Value: integer);
    procedure SetMediasRegioes(const Value: TRegiaoList);

    function GetAccessToken: string;

  public
    property Total_municipios: integer read FTotal_municipios write SetTotal_municipios;
    property Total_ok: integer read FTotal_ok write SetTotal_ok;
    property Total_nao_encontrado: integer read FTotal_nao_encontrado write SetTotal_nao_encontrado;
    property Total_erro_api: integer read FTotal_erro_api write SetTotal_erro_api;
    property Pop_total_ok: LongInt read FPop_total_ok write SetPop_total_ok;

    property MediasRegioes: TRegiaoList read FMediasRegioes write SetMediasRegioes;

    procedure Clear;
    procedure CalcularEstatisticas(oListamunicipios: TMunicipioList);
    function GetJsonEstatisticas: TJSONObject;
    function ConsultarCorrecao(out sJsonStr: string): boolean;

    constructor Create; reintroduce;
  end;

implementation

{ TMunicipiosEstatisticas }
procedure TMunicipiosEstatisticas.CalcularEstatisticas(oListamunicipios: TMunicipioList);
var
  i: Integer;
  oMunicipio: TMunicipio;
  sRegiao: string;
  oRegiaoMed: TRegiaoMedia;
begin
  Clear;

  FTotal_municipios := oListamunicipios.Count;

  for i := 0 to oListamunicipios.Count-1 do
  begin
    oMunicipio := TMunicipio(oListamunicipios.Items[i]);
    sRegiao := oMunicipio.IbgeRegiao;

    case oMunicipio.IbgeStatus of
      OK: begin
        Inc(FTotal_ok);
        FPop_total_ok := FPop_total_ok + oMunicipio.Populacao;

        { Calcular a região a cada item }
        oRegiaoMed := FMediasRegioes.GetRegiaoPorNome(sRegiao);
        if not Assigned(oRegiaoMed) then
        begin
          oRegiaoMed := TRegiaoMedia.Create;
          oRegiaoMed.Nome := sRegiao;
          FMediasRegioes.Add(oRegiaoMed);
        end;

        oRegiaoMed.TotalMunicipios := oRegiaoMed.TotalMunicipios + 1;
        oRegiaoMed.PopTotal := oRegiaoMed.PopTotal + oMunicipio.Populacao;
        if (oRegiaoMed.TotalMunicipios > 0) then
          oRegiaoMed.Media := (oRegiaoMed.PopTotal / oRegiaoMed.TotalMunicipios);
      end;
      NAO_ENCONTRADO: begin
        Inc(FTotal_nao_encontrado);
      end;
      ERRO_API: begin
        Inc(FTotal_erro_api);
      end;
      AMBIGUO: begin
      end;
    end;
  end;
end;

procedure TMunicipiosEstatisticas.Clear;
begin
  FTotal_ok := 0;
  FTotal_municipios := 0;
  FPop_total_ok := 0;
  FTotal_nao_encontrado := 0;
  FTotal_erro_api := 0;

  FMediasRegioes.Clear;
end;

constructor TMunicipiosEstatisticas.Create;
begin
  FMediasRegioes := TRegiaoList.Create;
  Clear;
end;

function TMunicipiosEstatisticas.GetAccessToken: string;
begin
  Result := 'eyJhbGciOiJIUzI1NiIsImtpZCI6ImR0TG03UVh1SkZPVDJwZEciLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL215bnhsdWJ5a3lsbmNpbnR0Z2d1LnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiIwN2Y4MTg0ZS1iYWU4LTQxYTQtYmRiMi05M2EzM2Y4NWQ5YTUiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzY1NDAyOTQ4LCJpYXQiOjE3NjUzOTkzNDgsImVtYWlsIjoiYWNhdWFucmFtb3NAaG90bWFpbC5jb20iLCJwaG9uZSI6IiIsImFwcF9tZXRhZGF0YSI6eyJwcm92aWRlciI6ImVtYWlsIiwicHJvdmlkZXJzIjpbImVtYWlsIl19LCJ1c2VyX21ldGFkYXRhIjp7ImVtYWlsIjoiYWNhdWFucmFtb3NAaG90bWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwibm9tZSI6IkFjYXVhbiBSaWJlaXJvIFJhbW9zIiwicGhvbmVfdmVyaWZpZWQiOmZhbHNlLCJzdWIiOiIwN2Y4MTg0ZS1iYWU4LTQxYTQtYmRiMi05M2EzM2Y4NWQ5YTUifSwicm9sZSI6ImF1dGhlbnRpY2F0ZWQiLCJhYWwiOiJhYWwxIiwiYW1yIjpbeyJtZXRob2QiOiJwYXNzd29yZCIsInRpbWVzdGFtcCI6MTc2NTM5OTM0OH1dLCJzZXNzaW9uX2lkIjoiYTdjMDE1NmQtYWM5Mi00MjkyLWE0MDMtODRlYjA1ZmRhZjZlIiwiaXNfYW5vbnltb3VzIjpmYWxzZX0.TRiGgggq4ce0kCf2cbSyiWZxg9lgn8N91gHlBK6_FF4';
end;

function TMunicipiosEstatisticas.GetJsonEstatisticas: TJSONObject;
var
  jsStats, jsMedias: TJSONObject;
  i: Integer;
  oRegiaoM: TRegiaoMedia;
begin
  Result := TJSONObject.Create;

  jsStats := TJSONObject.Create;
  jsStats.AddPair('total_municipios',FTotal_municipios);
  jsStats.AddPair('total_ok',FTotal_ok);
  jsStats.AddPair('total_nao_encontrado',FTotal_nao_encontrado);
  jsStats.AddPair('total_erro_api',FTotal_erro_api);
  jsStats.AddPair('pop_total_ok',FPop_total_ok);

  Result.AddPair('stats',jsStats);

  if (FMediasRegioes.Count > 0) then
  begin
    jsMedias := TJSONObject.Create;
    for i := 0 to FMediasRegioes.Count-1 do
    begin
      oRegiaoM := TRegiaoMedia(FMediasRegioes.Items[i]);
      jsMedias.AddPair( oRegiaoM.Nome, oRegiaoM.FMedia );
    end;
    Result.AddPair('medias_por_regiao',jsMedias);
  end;
end;

procedure TMunicipiosEstatisticas.SetMediasRegioes(const Value: TRegiaoList);
begin
  FMediasRegioes := Value;
end;

procedure TMunicipiosEstatisticas.SetPop_total_ok(const Value: LongInt);
begin
  FPop_total_ok := Value;
end;

procedure TMunicipiosEstatisticas.SetTotal_erro_api(const Value: integer);
begin
  FTotal_erro_api := Value;
end;

procedure TMunicipiosEstatisticas.SetTotal_municipios(const Value: integer);
begin
  FTotal_municipios := Value;
end;

procedure TMunicipiosEstatisticas.SetTotal_nao_encontrado(const Value: integer);
begin
  FTotal_nao_encontrado := Value;
end;

procedure TMunicipiosEstatisticas.SetTotal_ok(const Value: integer);
begin
  FTotal_ok := Value;
end;

function TMunicipiosEstatisticas.ConsultarCorrecao(out sJsonStr: string): boolean;
var
  HTTP: TNetHTTPClient;
  Resp: IHTTPResponse;
  JSONObj: TJSONObject;
  Stream: TStringStream;
begin
  HTTP := TNetHTTPClient.Create(nil);
  HTTP.CustHeaders.Add('Authorization', Format('Bearer %s',[GetAccessToken]));
  HTTP.CustHeaders.Add('Content-Type', 'application/json');

  try
    Stream := TStringStream.Create(GetJsonEstatisticas.ToString, TEncoding.UTF8);
    Resp := HTTP.Post('https://mynxlubykylncinttggu.functions.supabase.co/ibge-submit', Stream);

    if Resp.StatusCode in[200, 201, 202] then
    begin
      JSONObj := TJSONObject.ParseJSONValue(Resp.ContentAsString) as TJSONObject;
      sJsonStr := JSONObj.ToString;
    end
    else
      sJsonStr := Format('Erro na chamada da API de corrreção (StatusCode: %d)', [Resp.StatusCode]);

    Result := True;
  finally
    FreeAndNil(HTTP);
  end;
end;


{ TRegiaoMedia }

procedure TRegiaoMedia.SetMedia(const Value: double);
begin
  FMedia := Value;
end;

procedure TRegiaoMedia.SetNome(const Value: string);
begin
  FNome := Value;
end;

procedure TRegiaoMedia.SetPopTotal(const Value: LongInt);
begin
  FPopTotal := Value;
end;

procedure TRegiaoMedia.SetTotalMunicipios(const Value: integer);
begin
  FTotalMunicipios := Value;
end;

{ TRegiaoList }

function TRegiaoList.GetRegiaoPorNome(sRegiao: string): TRegiaoMedia;
var
  i: Integer;
begin
  Result := nil;
  if (Count = 0) then
    Exit;

  for i := 0 to Count-1 do
  begin
    if (TRegiaoMedia(Items[i]).Nome = sRegiao) then
      Result := TRegiaoMedia(Items[i]);
  end;
end;


end.
