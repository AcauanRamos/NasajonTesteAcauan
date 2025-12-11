unit uIBGE;

interface

uses
  uMunicipios;

  function ConsultarMunicipiosIBGE(out oDTOMunicipiosIBGELista: TMunicipioList): boolean;

implementation

uses
  System.Net.HttpClient, System.Net.HttpClientComponent,
  System.JSON, System.SysUtils, System.Generics.Collections,
  System.Classes, System.Contnrs;

function ConsultarMunicipiosIBGE(out oDTOMunicipiosIBGELista: TMunicipioList): boolean;
var
  HTTP: TNetHTTPClient;
  Resp: IHTTPResponse;
  JSONObj: TJSONArray;
  Obj: TJSONObject;
  sMunicipio, sRegiao, sUF: string;
  iCodIBGE: Integer;
  i: Integer;
begin
  HTTP := TNetHTTPClient.Create(nil);
  try
    { Atenção à ordenação pelo nome, facilita ao percorrer a lista depois }
    Resp := HTTP.Get('https://servicodados.ibge.gov.br/api/v1/localidades/municipios?orderBy=nome');

    if Resp.StatusCode = 200 then
    begin
      JSONObj := TJSONObject.ParseJSONValue(Resp.ContentAsString) as TJSONArray;
      if not Assigned(oDTOMunicipiosIBGELista) then
        oDTOMunicipiosIBGELista := TMunicipioList.Create;

      try
        for i := 0 to JSONObj.Count - 1 do
        begin
          try
          { município }
          Obj := JSONObj.Items[I] as TJSONObject;
          sMunicipio := Obj.GetValue<string>('nome');
          iCodIBGE := Obj.GetValue<Integer>('id');

          { UF }
          Obj := Obj.GetValue<TJSONObject>('regiao-imediata').
            GetValue<TJSONObject>('regiao-intermediaria').
            GetValue<TJSONObject>('UF');
          sUF := Obj.GetValue<string>('sigla');

          { região }
          Obj := Obj.GetValue<TJSONObject>('regiao');
          sRegiao := Obj.GetValue<string>('nome');

          oDTOMunicipiosIBGELista.Add(TMunicipio.Create(sMunicipio, 0, sUF, sMunicipio, sRegiao, iCodIBGE));
          except
            raise Exception.Create('Erro na leitura de municípios do IBGE.');
          end;
        end;

        Result := True;
      finally
        FreeAndNil(JSONObj);
      end;
    end
    else
      raise Exception.Create(Format('Erro na chamada da API IBGE (StatusCode: %d)', [Resp.StatusCode]));

  finally
    FreeAndNil(HTTP);
  end;
end;

end.
