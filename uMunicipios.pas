unit uMunicipios;

interface

uses
  Contnrs, System.SysUtils, Math;

type
  TMunicipioStatus = (OK, NAO_ENCONTRADO, ERRO_API, AMBIGUO);

  TMunicipio = class
  private
    FMunicipio: string;
    FPopulacao: LongInt;
    FIbgeRegiao: string;
    FIbgeUF: string;
    FIbgeCodigo: integer;
    FIbgeStatus: TMunicipioStatus;
    FIbgeMunicipio: string;
    procedure SetIbgeRegiao(const Value: string);
    procedure SetIbgeUF(const Value: string);
    procedure SetIbgeCodigo(const Value: integer);
    procedure SetIbgeStatus(const Value: TMunicipioStatus);
    procedure SetIbgeMunicipio(const Value: string);

    function GetStatusStr: string;
  public
    constructor Create(const sMunicipio: string; iPopulacao: LongInt;
      sIbgeUF: string = '';
      sIbgeMunicipio: string = '';
      sIbgeRegiao: string = '';
      iIbgeCodigo: integer = 0);

    property Municipio: string read FMunicipio write FMunicipio;
    property Populacao: LongInt read FPopulacao write FPopulacao;

    { IBGE }
    property IbgeMunicipio: string read FIbgeMunicipio write SetIbgeMunicipio;
    property IbgeUF: string read FIbgeUF write SetIbgeUF;
    property IbgeRegiao: string read FIbgeRegiao write SetIbgeRegiao;
    property IbgeCodigo: integer read FIbgeCodigo write SetIbgeCodigo;
    property IbgeStatus: TMunicipioStatus read FIbgeStatus write SetIbgeStatus;
  end;

 TMunicipioList = class(TObjectList)
  private

  public
    function CarregarCSV(sCSVFile: string = ''): boolean;
    procedure PreencherDadosUsandoListaIBGE(oMunicipiosIBGELista: TMunicipioList);
    procedure SalvarCsvFinal(sCSVFile: string);
  end;

implementation

uses
  System.Classes;

{ TMunicipio }

constructor TMunicipio.Create(const sMunicipio: string; iPopulacao: LongInt;
  sIbgeUF: string = '';
  sIbgeMunicipio: string = '';
  sIbgeRegiao: string = '';
  iIbgeCodigo: integer = 0);
begin
  FMunicipio := sMunicipio;
  FPopulacao := iPopulacao;

  FIbgeUF := sIbgeUF;
  FIbgeRegiao := sIbgeRegiao;
  FIbgeCodigo := iIbgeCodigo;
  FIbgeMunicipio := sIbgeMunicipio;
end;

function TMunicipio.GetStatusStr: string;
begin
  case FIbgeStatus of
    OK: result := 'OK';
    NAO_ENCONTRADO: result := 'NAO_ENCONTRADO';
    ERRO_API: result := 'ERRO_API';
    AMBIGUO: result := 'AMBIGUO';
  end;
end;

procedure TMunicipio.SetIbgeCodigo(const Value: integer);
begin
  FIbgeCodigo := Value;
end;

procedure TMunicipio.SetIbgeMunicipio(const Value: string);
begin
  FIbgeMunicipio := Value;
end;

procedure TMunicipio.SetIbgeRegiao(const Value: string);
begin
  FIbgeRegiao := Value;
end;

procedure TMunicipio.SetIbgeStatus(const Value: TMunicipioStatus);
begin
  FIbgeStatus := Value;
end;

procedure TMunicipio.SetIbgeUF(const Value: string);
begin
  FIbgeUF := Value;
end;

{ TMunicipioList }
function TMunicipioList.CarregarCSV(sCSVFile: string): boolean;
var
  stlCSV: TStringList;
  arrCampos: TArray<string>;
  I: Integer;
begin
  stlCSV := TStringList.Create;
  try
    if FileExists(sCSVFile) then
      stlCSV.LoadFromFile(sCSVFile)
    else
      stlCSV.Text :=
        'municipio,populacao'+ sLineBreak +
        'Niteroi,515317'+ sLineBreak +
        'Sao Gonçalo,1091737'+ sLineBreak +
        'Sao Paulo,12396372'+ sLineBreak +
        'Belo Horzionte,2530701'+ sLineBreak +
        'Florianopolis,516524'+ sLineBreak +
        'Santo Andre,723889'+ sLineBreak +
        'Santoo Andre,700000'+ sLineBreak +
        'Rio de Janeiro,6718903'+ sLineBreak +
        'Curitba,1963726'+ sLineBreak +
        'Brasilia,3094325';

  for I := 1 to stlCSV.Count - 1 do
  begin
    arrCampos := stlCSV[I].Split([',']);
    if Length(arrCampos) = 2 then
      Add(TMunicipio.Create(arrCampos[0], StrToIntDef(arrCampos[1], 0)) );
  end;

  Result := True;

  finally
    FreeAndNil(stlCSV);
  end;
end;

procedure TMunicipioList.PreencherDadosUsandoListaIBGE(oMunicipiosIBGELista: TMunicipioList);
var
  iMunicipio, iIBGEMunicipio: integer;
  sMunicipio, sIBGEMunicipio: string;
  dSimilaridadePerc: double;

  function LevenshteinDistance(const s, t: string): Integer;
  var
    d: array of array of Integer;
    n, m, i, j, cost: Integer;
  begin
    n := Length(s);
    m := Length(t);

    SetLength(d, n + 1, m + 1);

    for i := 0 to n do
      d[i, 0] := i;

    for j := 0 to m do
      d[0, j] := j;

    for i := 1 to n do
      for j := 1 to m do
      begin
        if s[i] = t[j] then
          cost := 0
        else
          cost := 1;

        d[i, j] := Min(
          Min(
            d[i - 1, j] + 1,     // deleção
            d[i, j - 1] + 1),    // inserção
          d[i - 1, j - 1] + cost // substituição
        );
      end;

    Result := d[n, m];
  end;

  function Similaridade(const A, B: string): Double;
  var
    Dist, MaxLen: Integer;
  begin
    Dist := LevenshteinDistance(A, B);
    MaxLen := Max(Length(A), Length(B));

    Result := (1 - Dist / MaxLen) * 100;
  end;

begin
  for iMunicipio := 0 to Count-1 do
  begin
    sMunicipio := TMunicipio(Items[iMunicipio]).Municipio;
    TMunicipio(Items[iMunicipio]).IbgeStatus := NAO_ENCONTRADO;

    for iIBGEMunicipio := 0 to oMunicipiosIBGELista.Count-1 do
      begin
        sIBGEMunicipio := TMunicipio(oMunicipiosIBGELista[iIBGEMunicipio]).Municipio;

        dSimilaridadePerc := Similaridade(sIBGEMunicipio, sMunicipio);
        if (dSimilaridadePerc > 85) then
        begin
          TMunicipio(Items[iMunicipio]).IbgeStatus := OK;

          TMunicipio(Items[iMunicipio]).IbgeMunicipio := sIBGEMunicipio;
          TMunicipio(Items[iMunicipio]).IbgeUF := TMunicipio(oMunicipiosIBGELista[iIBGEMunicipio]).IbgeUF;
          TMunicipio(Items[iMunicipio]).IbgeRegiao := TMunicipio(oMunicipiosIBGELista[iIBGEMunicipio]).IbgeRegiao;
          TMunicipio(Items[iMunicipio]).IbgeCodigo := TMunicipio(oMunicipiosIBGELista[iIBGEMunicipio]).IbgeCodigo;

          Break;
        end;
      end;
  end;
end;

procedure TMunicipioList.SalvarCsvFinal(sCSVFile: string);
var
  stlCSV: TstringList;
  i: Integer;
  oMunicipio: TMunicipio;
  sLinhaCSV: String;
begin
  stlCSV := TstringList.Create;
  try

  { Cabeçalho CSV }
  sLinhaCSV := ''.Join(',',
    ['municipio_input',
     'populacao_input',
     'municipio_ibge',
     'uf',
     'regiao',
     'id_ibge',
     'status']);
  stlCSV.Add( sLinhaCSV );

  { detalhe CSV }
  for i := 0 to Count-1 do
  begin
    oMunicipio := TMunicipio(Items[i]);
    sLinhaCSV := ''.Join(',',
      [oMunicipio.FMunicipio,
       oMunicipio.Populacao.ToString,
       oMunicipio.IbgeMunicipio,
       oMunicipio.IbgeUF,
       oMunicipio.IbgeRegiao,
       oMunicipio.IbgeCodigo.ToString,
       oMunicipio.GetStatusStr]);

    stlCSV.Add( sLinhaCSV );
  end;
  if (stlCSV.Count > 0) then
    stlCSV.SaveToFile(sCSVFile);

  finally
    FreeAndNil(stlCSV);
  end;
end;

end.
