unit wdcMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TAStyles, TASources, TASeries, TAGraph, FileUtil, ComCtrls,
  Forms, Controls, Graphics, Dialogs, ExtCtrls, Grids, Spin, StdCtrls, CheckLst,
  inifiles, TACustomSource;

type

  { TMainForm }

  TMainForm = class(TForm)
    Bevel1:TBevel;
    BtnCalc: TButton;
    CbRegion: TComboBox;
    Chart:TChart;
    BarSeries:TBarSeries;
    ChartStyles:TChartStyles;
    CbRegions: TCheckListBox;
    EdYear: TSpinEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Notebook: TNotebook;
    PgYear: TPage;
    PgRegions: TPage;
    PanelCalcButton:TPanel;
    Label4: TLabel;
    Label5: TLabel;
    PanelYearDependence: TPanel;
    PanelRegionDependence: TPanel;
    RgSortRegions: TRadioGroup;
    RgXData: TRadioGroup;
    Splitter1: TSplitter;
    UserDefinedChartSource: TUserDefinedChartSource;
    PageControl:TPageControl;
    Panel1: TPanel;
    EdStartYear: TSpinEdit;
    EdEndYear: TSpinEdit;
    Panel2:TPanel;
    ResultGrid: TStringGrid;
    PgTable:TTabSheet;
    PgDiagram:TTabSheet;
    procedure BtnCalcClick(Sender: TObject);
    procedure CbRegionsClickCheck(Sender:TObject);
    procedure CbRegionSelect(Sender:TObject);
    procedure EdEndYearChange(Sender: TObject);
    procedure EdStartYearChange(Sender: TObject);
    procedure FormCloseQuery(Sender:TObject; var CanClose:boolean);
    procedure FormCreate(Sender: TObject);
    procedure ResultGridCompareCells(Sender: TObject; ACol, ARow, BCol,
      BRow: Integer; var Result: integer);
    procedure RgXDataClick(Sender: TObject);
    procedure ResultGridPrepareCanvas(Sender:TObject; ACol, ARow:Integer;
      AState:TGridDrawState);
    procedure UserDefinedChartSourceGetChartDataItem(
      ASource: TUserDefinedChartSource; AIndex: Integer;
      var AItem: TChartDataItem);
  private
    { private declarations }
    FUpdateLock: integer;
    procedure CalcByRegions;
    procedure CalcByYears;
    procedure Calculate;
    function  CreateIni: TCustomIniFile;
    procedure ReadFromIni;
    procedure WriteToIni;
  public
    { public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

uses
  Math, DateUtils,
  TAChartUtils,
  wdcDateTools;


{ TMainForm }

function SortDates(List: TStringList; Index1, Index2: Integer): Integer;
var
  diff1, diff2: PtrInt;
begin
  diff1 := PtrInt(List.Objects[Index1]);
  diff2 := PtrInt(List.Objects[Index2]);
  result := CompareValue(diff1, diff2);
end;

procedure TMainForm.BtnCalcClick(Sender: TObject);
begin
  Calculate;
end;

procedure TMainForm.Calculate;
var
  crs: TCursor;
begin
  if FUpdateLock > 0 then
    exit;
  crs := Screen.Cursor;
  Screen.Cursor := crHourglass;
  try
    if RgXData.ItemIndex = 0 then
      CalcByYears
    else
      CalcByRegions;
  finally
    Screen.Cursor := crs;
  end;
end;

procedure TMainForm.CbRegionsClickCheck(Sender:TObject);
begin
  Calculate;
end;

procedure TMainForm.CalcByRegions;
var
  Holidays: TStringList;
  List: TDateArray = nil;
  i, j, k, k0, n: Integer;
  c, r: Integer;
  year: Integer;
  s, hn: String;
  d, startdate: TDate;
  dow: Integer;
  sumF: Integer;
  sumB: Integer;
begin
  year := EdYear.Value;
  startdate := EncodeDate(year, 1, 1);

  n := 0;
  Holidays := TStringList.Create;
  try
    Holidays.Duplicates := dupIgnore;
    Holidays.Sorted := true;

    for i:=0 to CbRegions.Items.Count-1 do
      if CbRegions.Checked[i] then begin
        inc(n);
        RegisterHolidays(THolidayRegion(i));
        GetRegisteredHolidays(year, List);
        for j:=Low(List) to High(List) do begin
          k := Holidays.Add(WhichHoliday(List[j]));
          if Holidays.Objects[k] = nil then
            Holidays.Objects[k] := TObject(PtrInt(round(List[j] - startdate)));
          // Tage ab 1.1., zum Sortieren
        end;
      end;
    Holidays.Sorted := false;
    Holidays.CustomSort(@SortDates);

    with ResultGrid do begin
      FixedCols := 2;
      ColCount := n + FixedCols;
      Rows[0].Clear;
      c := FixedCols;
      for i:=0 to CbRegions.Items.Count-1 do
        if CbRegions.Checked[i] then begin
          s := CbRegions.Items[i];
          Cells[c, 0] := s;
          inc(c);
        end;

      RowCount := Holidays.Count + FixedRows + 3;
      for r:=FixedRows to RowCount-4 do begin
        j := r - FixedRows;
        d := startdate + PtrInt(Holidays.Objects[j]);
        Cells[0, r] := Holidays[j];
        Cells[1, r] := FormatDateTime('DDD, DD.MM.', d);
      end;
      Cells[0, RowCount-3] := 'Feiertage an Arbeitstagen';
      Cells[0, RowCount-2] := 'Brückentage';
      Cells[0, RowCount-1] := 'Gesamt';
      for r:=RowCount-3 to RowCount-1 do
        Cells[1, r] := '';

      c := FixedCols;
      for i:=0 to CbRegions.Items.Count-1 do
        if CbRegions.Checked[i] then begin
          for r:=FixedRows to RowCount-1 do
            Cells[c, r] := '';
          RegisterHolidays(THolidayRegion(i));
          GetRegisteredHolidays(year, List);
          sumF := 0;
          sumB := 0;
          for j:=Low(List) to High(List) do begin
            d := List[j];
            hn := WhichHoliday(d);
            k := Holidays.IndexOf(hn);
            if (k <> -1) and IsHoliday(d) then begin
              r := k + FixedRows;
              dow := DayOfWeek(d);   // 1=So, 2=Mo, ... 7=Sa
              if dow in [2..6] then
                inc(sumF);
              if dow in [3,5] then
                inc(sumB);
              Cells[c, r] := 'x'; //FormatDateTime('DDD, DD.MM.', d);
            end;
          end;
          Cells[c, RowCount-3] := IntToStr(sumF);
          Cells[c, RowCount-2] := IntToStr(sumB);
          Cells[c, RowCount-1] := IntToStr(sumF+sumB);
          inc(c);
        end;

      if RgSortRegions.ItemIndex = 1 then
        SortColRow(false, RowCount-1, FixedCols, ColCount-1);
    end;

    UserDefinedChartSource.PointsNumber := n;
    UserDefinedChartSource.YCount := 2;
    UserDefinedChartSource.Reset;
    Chart.BottomAxis.Marks.LabelFont.Orientation := 900;
    Chart.Title.Text.Text := EdYear.Text;

  finally
    Holidays.Free;
  end;
end;

procedure TMainForm.CalcByYears;
var
  Holidays: TStringList;
  List: TDateArray;
  i, j, k, k0: Integer;
  c, r: Integer;
  year, startyear, endyear: Integer;
  hn: String;
  d, startdate: TDate;
  dow: Integer;
  sumF: Integer;
  sumB: Integer;
begin
  RegisterHolidays(THolidayRegion(CbRegion.ItemIndex));

  if EdStartYear.Value <= EdEndYear.Value then begin
    startyear := EdStartYear.Value;
    endyear := EdEndYear.Value;
  end else begin
    startyear := EdEndYear.Value;
    endyear := EdStartYear.Value;
  end;

  Holidays := TStringList.Create;
  try
    Holidays.Duplicates := dupIgnore;
    Holidays.Sorted := true;

    for year := startyear to endyear do begin
      startdate := EncodeDate(year, 1, 1);
      GetRegisteredHolidays(year, List);
      for i:=Low(List) to High(List) do begin
        d := List[i];
        k := Holidays.Add(WhichHoliday(d));
        if Holidays.Objects[k] = nil then
          Holidays.Objects[k] := TObject(PtrInt(round(d - startdate)));
          // Tage ab 1.1., zum Sortieren
      end;
    end;
    Holidays.Sorted := false;
    Holidays.CustomSort(@SortDates);

    with ResultGrid do begin
      FixedCols := 1;
      ColCount := endyear - startyear + 1 + FixedCols;
      year := startyear;
      for c:=FixedCols to ColCount-1 do begin
        Cells[c, 0] := IntToStr(year);
        inc(year);
      end;

      RowCount := Holidays.Count + FixedRows + 3;
      for r:=FixedRows to RowCount-4 do
        Cells[0, r] := Holidays[r-FixedRows];
      Cells[0, RowCount-3] := 'Feiertage an Arbeitstagen';
      Cells[0, RowCount-2] := 'Brückentage';
      Cells[0, RowCount-1] := 'Gesamt';

      year := startyear;
      for c:=FixedCols to ColCount-1 do begin
        for r:=FixedRows to RowCount-1 do
          Cells[c, r] := '';
        startdate := EncodeDate(year, 1, 1);
        GetRegisteredHolidays(year, List);
        sumF := 0;
        sumB := 0;
        for j := Low(List) to High(List) do begin
          d := List[j];
          hn := WhichHoliday(d);
          k := Holidays.IndexOf(hn);
          if (k <> -1) then begin
            r := k + FixedRows;
            dow := DayOfWeek(d);   // 1=So, 2=Mo, ... 7=Sa
            if dow in [2..6] then
              inc(sumF);
            if dow in [3,5] then
              inc(sumB);
            Cells[c, r] := FormatDateTime('DDD, DD.MM.', d);
          end;
        end;
        Cells[c, RowCount-3] := IntToStr(sumF);
        Cells[c, RowCount-2] := IntToStr(sumB);
        Cells[c, RowCount-1] := IntToStr(sumF+sumB);
        inc(year);
      end;
    end;

    UserDefinedChartSource.PointsNumber := endyear - startyear + 1;
    UserDefinedChartSource.YCount := 2;
    UserDefinedChartSource.Reset;
    Chart.BottomAxis.Marks.LabelFont.Orientation := 0;
    Chart.Title.Text.Text := CbRegion.Text;

  finally
    Holidays.Free;
  end;
end;

procedure TMainForm.CbRegionSelect(Sender:TObject);
begin
  Calculate;
end;

function TMainForm.CreateIni: TCustomIniFile;
var
  cfg : string;
begin
  cfg := GetAppConfigDir(false);
  if not DirectoryExists(cfg) then CreateDir(cfg);
  result := TMemIniFile.Create(GetAppConfigFile(false));
end;

procedure TMainForm.EdEndYearChange(Sender: TObject);
begin
  Calculate;
end;

procedure TMainForm.EdStartYearChange(Sender: TObject);
begin
  Calculate;
end;

procedure TMainForm.FormCloseQuery(Sender:TObject; var CanClose:boolean);
begin
  if CanClose then
    try
      WriteToIni;
    except
    end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  with ResultGrid do begin
    ColWidths[0] := 180;
  end;

  CbRegions.Items.Assign(CbRegion.Items);
  CbRegions.CheckAll(cbChecked);

  ReadFromIni;
end;

procedure TMainForm.ResultGridCompareCells(Sender: TObject; ACol, ARow, BCol,
  BRow: Integer; var Result: integer);
var
  SA, SB: String;
begin
  SA := ResultGrid.Cells[ACol, ARow];
  SB := ResultGrid.Cells[BCol, BRow];
  if (SA <> '') and (SB <> '') then
    Result := CompareValue(StrToInt(SA), StrToInt(SB))
  else
  if (SA <> '') then
    Result := -1
  else
  if (SB <> '') then
    Result := +1
  else
    Result := 0;
  Result := -Result;
end;

procedure TMainForm.ReadFromIni;
var
  ini: TCustomIniFile;
  L,T,W,H: integer;
  IsMax: Boolean;
  s: String;
  i, j: Integer;
  List: TStringList;
begin

  ini := CreateIni;
  try
    inc(FUpdateLock);
    try
      L := ini.ReadInteger('MainForm', 'Left', Left);
      T := Ini.ReadInteger('MainForm', 'Top', Top);
      W := ini.ReadInteger('MainForm', 'Width', Width);
      H := ini.ReadInteger('MainForm', 'Height', Height);
      IsMax := ini.ReadBool('MainForm', 'Maximized', WindowState = wsMaximized);
      if W > Screen.Width then W := Screen.Width;
      if H > Screen.Height then H := Screen.Height;
      if L < 0 then L := 0;
      if T < 0 then T := 0;
      if L + W > Screen.Width then L := Screen.Width - W;
      if T + H > Screen.Height then T := Screen.Height - H;
      Left := L;
      Top := T;
      Width := W;
      Height := H;
      if IsMax then
        WindowState := wsMaximized
      else
        WindowState := wsNormal;

      i := ini.ReadInteger('MainForm', 'PanelWidth', -1);
      if i <> -1 then
        Panel1.Width := i;

      i := ini.ReadInteger('MainForm', 'PageControl', -1);
      if i <> -1 then
        PageControl.PageIndex := i;

      i := ini.ReadInteger('MainForm', 'Abscissa', -1);
      if i <> -1 then
        RgXData.ItemIndex := i;

      s := ini.ReadString('MainForm', 'Region', '');
      if s <> '' then begin
        i := CbRegion.Items.IndexOf(s);
        if i <> -1 then CbRegion.ItemIndex := i;
      end;

      i := ini.ReadInteger('MainForm', 'StartYear', -1);
      if i <> -1 then
        EdStartYear.Value := i;

      i := ini.ReadInteger('MainForm', 'EndYear', -1);
      if i <> -1 then
        EdEndYear.Value := i;

      i := ini.ReadInteger('MainForm', 'Year', -1);
      if i <> -1 then
        EdYear.Value := i;

      List := TStringList.Create;
      try
        List.Delimiter := ';';
        List.StrictDelimiter := true;
        List.DelimitedText := ini.ReadString('MainForm', 'Regions', '');
        if List.Count = 0 then
          CbRegions.CheckAll(cbChecked)
        else begin
          CbRegions.CheckAll(cbUnchecked);
          for i:=0 to List.Count-1 do begin
            j := CbRegions.Items.IndexOf(List[i]);
            if j <> -1 then
              CbRegions.Checked[j] := true;
          end;
        end;
      finally
        List.Free;
      end;

    finally
      dec(FUpdateLock);
      Calculate;
    end;

  finally
    ini.Free;
  end;
end;

procedure TMainForm.RgXDataClick(Sender: TObject);
begin
  Notebook.PageIndex := RgXData.ItemIndex;
  Calculate;
end;

procedure TMainForm.ResultGridPrepareCanvas(sender:TObject; aCol, aRow:Integer;
  aState:TGridDrawState);
var
  ts: TTextStyle;
  s: String;
begin
  if (aRow = 0) or (ARow >= ResultGrid.RowCount-3) then
    ResultGrid.Canvas.Font.Style := [fsBold];
  if ACol > 0 then begin
    ts := ResultGrid.Canvas.TextStyle;
    ts.Alignment := taCenter;
    if (ARow = 0) and (RgXData.ItemIndex = 1) then begin
      s := ResultGrid.Cells[aCol, aRow];
      if ResultGrid.Canvas.TextWidth(s) > ResultGrid.ColWidths[aCol] then
        ts.Alignment := taLeftJustify
    end;
    ResultGrid.Canvas.TextStyle := ts;
  end;
end;

procedure TMainForm.UserDefinedChartSourceGetChartDataItem(
  ASource: TUserDefinedChartSource; AIndex: Integer; var AItem: TChartDataItem);
var
  c: Integer;
begin
  with ResultGrid do begin
    c := FixedCols + AIndex;
    AItem.X := AIndex;
    AItem.Y := StrToInt(Cells[c, RowCount-3]);
    AItem.YList[0] := StrToInt(Cells[c, RowCount-2]);
    AItem.Text := Cells[c, 0];
  end;
end;

procedure TMainForm.WriteToIni;
var
  ini: TCustomIniFile;
  List: TStringList;
  i: Integer;
begin
  ini := CreateIni;
  try
    ini.EraseSection('MainForm');

    ini.WriteInteger('MainForm', 'Left', Left);
    ini.WriteInteger('MainForm', 'Top', Top);
    ini.WriteInteger('MainForm', 'Width', Width);
    ini.WriteInteger('MainForm', 'Height', Height);
    ini.WriteInteger('MainForm', 'PanelWidth', Panel1.Width);
    ini.WriteBool('MainForm', 'Maximized', WindowState = wsMaximized);
    ini.WriteInteger('MainForm', 'PageControl', PageControl.ActivePageIndex);
    ini.WriteInteger('MainForm', 'Abscissa', RgXData.ItemIndex);
    if CbRegion.ItemIndex > -1 then
      ini.WriteString('MainForm', 'Region', CbRegion.Items[CbRegion.ItemIndex]);
    ini.WriteInteger('MainForm', 'StartYear', EdStartYear.Value);
    ini.WriteInteger('MainForm', 'EndYear', EdEndYear.Value);
    ini.WriteInteger('MainForm', 'Year', EdYear.Value);
    List := TStringList.Create;
    try
      List.Delimiter := ';';
      List.StrictDelimiter := true;
      for i:=0 to CbRegions.Items.Count-1 do
        if CbRegions.Checked[i] then
          List.Add(CbRegions.Items[i]);
      ini.WriteString('MainForm', 'Regions', List.DelimitedText);
    finally
      List.Free;
    end;
  finally
    ini.Free;
  end;
end;

end.

