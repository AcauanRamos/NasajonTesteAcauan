program prjNasajonIBGE;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.Contnrs,
  uMunicipios in 'uMunicipios.pas',
  uIBGE in 'uIBGE.pas',
  uMunicipiosEstatisticas in 'uMunicipiosEstatisticas.pas';

  procedure MensagemInicial;
  begin
    Writeln('NASAJON: consultar e validar municípios no IBGE (via API)');
  end;

  procedure MensagemFinal;
  begin
    Writeln;
    Writeln;
    Writeln('Tecle qualquer tecla para finallizar o programa.');
    Readln;
  end;

  function LerExibirArquivoCSV: TMunicipioList;
  var
    oMunicipiosLista: TMunicipioList;
    i: integer;
  begin
    oMunicipiosLista := TMunicipioList.Create;

    oMunicipiosLista.CarregarCSV();
    for i := 0 to oMunicipiosLista.Count-1 do
      Writeln(Format('%s | %d', [TMunicipio(oMunicipiosLista.Items[i]).Municipio,  TMunicipio(oMunicipiosLista.Items[i]).Populacao]));

    Result := oMunicipiosLista;
  end;

  procedure LerExibirMunicipiosIBGE;
  var
    oMunicipiosLista: TMunicipioList;
    i: integer;
  begin
    oMunicipiosLista := nil;
    if uIBGE.ConsultarMunicipiosIBGE(oMunicipiosLista) then
    begin
      for i := 0 to oMunicipiosLista.Count-1 do
        Writeln(Format('%s | %d', [TMunicipio(oMunicipiosLista.Items[i]).Municipio,  TMunicipio(oMunicipiosLista.Items[i]).Populacao]));
    end
    else
    begin
      Writeln('Não foi possível obter a lista de municípios do IBGE');
    end;
  end;

  procedure AtualizarStatusErroAPI(var oMunicipios: TMunicipioList);
  var
    i: Integer;
  begin
    for i := 0 to oMunicipios.Count-1 do
      TMunicipio(oMunicipios.Items[i]).IbgeStatus := ERRO_API;
  end;

var
  oMunicipios, oMunicipiosIBGE: TMunicipioList;
  bConsultaIBGEOK: boolean;
  meMunicipiosEstats: TMunicipiosEstatisticas;
  oResultadoCorrecao: string;
begin
  try
    MensagemInicial;

    oMunicipios := LerExibirArquivoCSV;
    bConsultaIBGEOK := uIBGE.ConsultarMunicipiosIBGE(oMunicipiosIBGE);
    if bConsultaIBGEOK then
    begin
      oMunicipios.PreencherDadosUsandoListaIBGE(oMunicipiosIBGE);
      oMunicipios.SalvarCsvFinal('resultado.csv');

      meMunicipiosEstats := TMunicipiosEstatisticas.Create;
      try
      meMunicipiosEstats.CalcularEstatisticas(oMunicipios);

      if meMunicipiosEstats.ConsultarCorrecao(oResultadoCorrecao) then
        writeln(oResultadoCorrecao)
      else
        writeln('Erro: ' + oResultadoCorrecao);

      finally
        FreeAndNil(meMunicipiosEstats);
      end;
    end
    else
      AtualizarStatusErroAPI(oMunicipios);

    MensagemFinal;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
