//==============================================================================
//                           DateTools
//==============================================================================

unit wdcDateTools;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

const
  OneHour = 1/24;
  OneMinute = 1/(60*24);
  OneSecond = 1/(60*60*24);
  OneMilliSecond = 1/(1000*60*60*24);

  NullDate: TDateTime = 0;

function  LastDayOfMonth(date:TDateTime) : TDateTime;
function  NextWeekDay(Day:integer; date:TDateTime) : TDateTime;
function  PrevWeekDay(Day:integer; date:TDateTime) : TDateTime;

function  AgeAtDate (const DateOfBirth,date:TDateTime) : integer;
function  AgeNow(const DateOfBirth:TDateTime) : integer;

function  CurrentDay : word;
function  CurrentMonth : word;
function  CurrentYear : word;

function  SameDate(const date1,date2:TDateTime) : boolean;
function  SameTime(const date1,date2:TDateTime) : boolean;

{$IFDEF MSWINDOWS}
function  GetGMTTime(const DT:TDateTime) : TDateTime;
function  GetLocalTime(const DT:TDateTime) : TDateTime;
function  GetTimeZoneName: string;
function  GetGMTDifference: string;
function  GMTNow : TDateTime;
function  GMTDate : TDateTime;
function  GMTTime : TDateTime;
function  IsDaylightSavingTime : boolean;
{$ENDIF}

type
  THolidayRegion = (hrBayern, hrBadenWuerttemberg, hrBerlin, hrBrandenburg,
    hrBremen, hrHamburg, hrHessen, hrMecklenburgVorpommern, hrNiedersachsen,
    hrNordRheinWestfalen, hrRheinlandPfalz, hrSaarland, hrSachsen,
    hrSachsenAnhalt, hrSchleswigHolstein, hrThueringen);

  TDateArray = array of TDate;

function  RegisterFixedHoliday(_Name:string; _day,_month:integer;
            _validbefore:integer=0; _validafter:integer=0) : integer;
function  RegisterFloatingHoliday(_name:string; _delta:integer; _relativeTo:string;
            _validBefore:integer=0; _validAfter:integer=0) : integer;
function  RegisterFloatingHoliday2(_name:string; _refDay,_refMonth:integer;
           _delta,_weekday:integer; _validBefore:integer=0; _validAfter:integer=0) : integer;
procedure RegisterHolidays_Bavaria;
procedure RegisterHolidays(ARegion:THolidayRegion);
procedure UnregisterHolidays;
procedure GetRegisteredHolidays(Year:Integer; var List:TDateArray);

function  Easter(year:integer) : TDateTime;
function  IsHoliday(date:TDateTime) : boolean;
function  WhichHoliday(date:TDateTime) : string;

function  IsWorkday(date:TDateTime) : boolean;
function  WorkdaysOfMonth(year,month:word) : word;
function  WorkdaysOfYear(year:word) : word;
function  NextWorkday(date:TDateTime) : TDateTime;
function  PrevWorkday(date:TDateTime) : TDateTime;

// aus RxLib, Unit dateutil.pas
type
  TDateOrder = (doMDY, doDMY, doYMD);
  TDayOfWeekName = (Sun, Mon, Tue, Wed, Thu, Fri, Sat);
  TDaysOfWeek = set of TDayOfWeekName;

const
  DefaultDateOrder = doDMY;

function DefDateFormat(FourDigitYear: Boolean): string;
function DefDateMask(BlanksChar: Char; FourDigitYear: Boolean): string;
function ExpandYear(Year: Integer): Integer;
function FourDigitYear: Boolean;
function GetDateOrder(const DateFormat: string): TDateOrder;
function IsFourDigitYear: Boolean;
function MonthFromName(const S:string; MaxLen:Byte): Byte;
function StrToDateFmt(const DateFormat, S: string): TDateTime;
function StrToDateFmtDef(const DateFormat, S: string; Default: TDateTime): TDateTime;
function ValidDate(ADate: TDateTime): Boolean;

type
  EDateError = Exception;



//==============================================================================
                              implementation
//==============================================================================

uses
  Classes, DateUtils
  {$IFDEF MSWINDOWS}
  , Windows
  {$ENDIF}
  ;

//==============================================================================

function FillString(ch:Char; Count:Integer): String;
var
  i: Integer;
begin
  SetLength(Result, Count);
  for i:=1 to Count do Result[i] := ch;
end;

function LastDayOfMonth(date:TDateTime) : TDateTime;
var
  y,m,d : word;
begin
  DecodeDate(date, y,m,d);
  d := MonthDays[IsLeapYear(y), m];
  result := EncodeDate(y, m, d);
end;

//------------------------------------------------------------------------------

function NextWeekDay(Day:integer; date:TDateTime) : TDateTime;
// übergibt, ausgehend vom Datum "date" das Datum des ersten folgenden
// Wochentags <Day>=0 fr Sonntag, 1 fr Montag etc.
// Wenn <Date> schon der gewünschte Wochentag ist, wird als Funktionswert
// <date> übergeben!
// Beispiel:  NextWeekDay(0, StrToDate('1.12.2000'))
//    ist der nächste Sonntag nach dem 1.12.2000, also der 3.12.2000.
begin
  while (abs(trunc(date)) mod 7 <> Day) do date := date + 1;
  result := date;
end;

//------------------------------------------------------------------------------

function PrevWeekDay(Day:integer; date:TDateTime) : TDateTime;
// Analog zu NextWeekDay
begin
  while (abs(trunc(date)) mod 7 <> Day) do date := date - 1;
  result := date;
end;

//------------------------------------------------------------------------------

function AgeAtDate (const DateOfBirth,date:TDateTime):integer;
// Berechnet das Alter (in Jahren) einer Person mit Geburtstag <DateOfBirth>
// am Datum <date>
// aus: ESBDates.pas
var
  d1,m1,y1 : word;
  d2,m2,y2 : word;
begin
  if date < DateOfBirth then
    result := -1
  else begin
    DecodeDate(DateOfBirth, y1,m1,d1);
    DecodeDate(date, y2,m2,d2);
    result := y2 - y1;
    if (m2<m1) or ((m2=m1) and (d2<d1)) then dec(result);
  end;
end;

//------------------------------------------------------------------------------

function AgeNow(const DateOfBirth:TDateTime):integer;
// aus: ESBDates.pas
begin
  result := AgeAtDate(DateOfBirth, date);
end;

//------------------------------------------------------------------------------

function CurrentDay : word;
begin
  result := DayOf(Date);
end;

//------------------------------------------------------------------------------

function CurrentMonth : word;
begin
  result := MonthOf(date);
end;

//------------------------------------------------------------------------------

function CurrentYear : word;
begin
  result := YearOf(Date);
end;

//------------------------------------------------------------------------------

function SameDate(const date1, date2:TDateTime) : boolean;
// Prüft, ob die beiden DateTime-Werte am selben Datum liegen
// aus: ESBDates.pas
begin
  result := (int(date1)=int(date2));
end;

//------------------------------------------------------------------------------

function SameTime(const date1,date2:TDateTime) : boolean;
// Prüft mit Genauigkeit 1 msec, ob die beiden DateTime-Werte dieselbe Uhrzeit
// haben.
// aus: ESBDates.pas
begin
  result := abs(frac(date1) - frac(date2)) < OneMillisecond;
end;

{$IFDEF MSWINDOWS}
//========================= Zeitzonen ==========================================

function GetLocalTZBias : longint;
// aus: ESBDates.pas
var
  TZ : TTimeZoneInformation;
begin
  case GetTimeZoneInformation(TZ) of
    TIME_ZONE_ID_STANDARD: Result := TZ.Bias + TZ.StandardBias;
    TIME_ZONE_ID_DAYLIGHT: Result := TZ.Bias + TZ.DaylightBias;
    else                   Result := TZ.Bias;
  end;
end;

//------------------------------------------------------------------------------

function GetGMTTime(const DT:TDateTime) : TDateTime;
// Ruft die Zeitzoneninformation von Windows auf und bestimmt, welche Uhrzeit
// zur lokalen Zeit <DT> in der GMT (Greenwich Mean Time) Zeitzone gehört.
// aus: ESBDates.pas
begin
  result := DT + GetLocalTZBias * OneMinute;
end;

//------------------------------------------------------------------------------

function GetLocalTime(const DT:TDateTime) : TDateTime;
// Ruft die Zeitzoneninformation von Windows auf und bestimmt, welche Uhrzeit
// lokal zur angegebenen GMT-Zeit <DT> gehört.
// aus: ESBDates.pas
begin
  result := DT - GetLocalTZBias * OneMinute;
end;

//------------------------------------------------------------------------------

function GMTNow : TDateTime;
// Übergibt die aktuelle DateTime bezogen auf die GMT-Zeitzone.
// aus: ESBDates.pas
begin
  result := Now + GetLocalTZBIAS * OneMinute;
end;

//------------------------------------------------------------------------------

function GMTDate: TDateTime;
// Übergibt das aktuelle Datum als GMT-Datum.
// aus: ESBDates.pas
begin
  result := int(Now + GetLocalTZBIAS * OneMinute);
end;

//------------------------------------------------------------------------------

function GMTTime: TDateTime;
// Übergibt die aktuelle GMT-Uhrzeit.
// aus: ESBDates.pas
begin
  result := frac(Now + GetLocalTZBIAS * OneMinute);
end;

//------------------------------------------------------------------------------

function GetTimeZoneName: string;
// aus: ESBDates.pas
var
  TZ : TTimeZoneInformation;
begin
  case GetTimeZoneInformation(TZ) of
    TIME_ZONE_ID_STANDARD: result := WideCharToString(TZ.StandardName);
    TIME_ZONE_ID_DAYLIGHT: result := WideCharToString(TZ.DaylightName);
    else                   result := '';
  end;
end;

//------------------------------------------------------------------------------

function GetGMTDifference: string;
// aus: ESBDates.pas
var
  TZ : TTimeZoneInformation;
begin
  GetTimeZoneInformation (TZ);
  if TZ.Bias = 0 then
    result := 'GMT'
  else if TZ.Bias < 0 then begin
    if TZ.Bias mod 60 = 0
      then result := 'GMT+' + IntToStr(abs(TZ.Bias) div 60)
      else result := 'GMT+' + FloatToStr(abs(TZ.Bias) / 60)
  end else begin
    if TZ.Bias mod 60 = 0
      then result := 'GMT-' + IntToStr(TZ.Bias div 60)
      else result := 'GMT-' + FloatToStr(TZ.Bias / 60)
  end;
end;

//------------------------------------------------------------------------------

function IsDaylightSavingTime : boolean;
var
  TZ : TTimeZoneInformation;
begin
  result := (GetTimeZoneInformation(TZ)=TIME_ZONE_ID_DAYLIGHT);
end;

{$ENDIF}

//======================= Feiertage ============================================

type
  THolidayKind = (hkFixed, hkRelative, hkWeekday);

  PHolidayItem = ^THolidayItem;
  THolidayItem = record
    Name        : string;        // Name des Feiertags
    active      : boolean;       // mehr Feiertage vorbereiten als benötigt.
    validBefore : integer;       // Jahr, bis zu dem (inkl.) es den Feiertag gab.
    validAfter  : integer;       // Jahr, seit dem (inkl.) es den Feiertag gibt.
    case kind : THolidayKind of  // Flag für festen oder beweglichen Feiertag
      hkFixed :
        (day:integer; month:integer);
           // fester Feiertag: Datum
      hkRelative :
        (delta:integer; relativeTo:integer);
           // beweglich: Differenz zu Referenzfeiert.
      hkWeekday :
        (RefDay,RefMonth:integer; diff,Weekday:integer);
          // beweglich: um diff Tage nach dem RefTag im RefMonat weitergehen
          // und den nächsten Weekday suchen, dabei zurücklaufen!
          // z.B. 1. Advent: RefDay=1, RefMonth=12, diff=-7, Weekday=1 )
  end;

var
  RegisteredHolidays : TList = nil;    // Liste der registrierten Feiertage

//------------------------------------------------------------------------------

function CreateFixedHoliday(_name:string; _day,_month:integer;
  _validBefore:integer=0; _ValidAfter:integer=0) : PHolidayItem;
begin
  GetMem(result, SizeOf(THolidayItem));
  FillChar(result^, SizeOf(THolidayItem), 0);
  with result^ do begin
    Name := _name;
    active := true;
    Kind := hkFixed;
    Day := _day;
    Month := _month;
    ValidBefore := _validBefore;
    ValidAfter := _validAfter;
  end;
end;

//------------------------------------------------------------------------------

function CreateFloatingHoliday(_name:string; _delta,_relativeTo:integer;
  _validBefore:integer=0; _ValidAfter:integer=0) : PHolidayItem;
begin
  GetMem(result, SizeOf(THolidayItem));
  FillChar(result^, SizeOf(THolidayItem), 0);
  with result^ do begin
    Name := _name;
    active := true;
    Kind := hkRelative;
    Delta := _delta;
    RelativeTo := _relativeTo;
    ValidBefore := _validBefore;
    ValidAfter := _validAfter;
  end;
end;

//------------------------------------------------------------------------------

function CreateFloatingHoliday2(_name:string;
  _RefDay,_RefMonth,_delta,_weekday:integer;
  _validBefore:integer=0; _ValidAfter:integer=0) : PHolidayItem;
begin
  GetMem(result, SizeOf(THolidayItem));
  FillChar(result^, SizeOf(THolidayItem), 0);
  with result^ do begin
    Name := _name;
    active := true;
    Kind := hkWeekday;
    diff := _delta;
    RefDay := _refDay;
    RefMonth := _refMonth;
    Weekday := _weekday;
    ValidBefore := _validBefore;
    ValidAfter := _validAfter;
  end;
end;

{
function CreateHoliday(_name:string; _kind:boolean; _d1,_d2:integer;
  _validBefore,_ValidAfter:integer) : PHolidayItem;
// interne Routine: erzeugt einen Zeiger auf einen THolidayItem-Record
begin
  GetMem(result, SizeOf(THolidayItem));
  FillChar(result^, SizeOf(THolidayItem), 0);
  with result^ do begin
    Name := _name;
    active := true;
    Fixed := _fixed;
    if Fixed then begin
      Day := _d1;
      Month := _d2;
    end else begin
      Delta := _d1;
      RelativeTo := _d2;
    end;
    ValidBefore := _validBefore;
    ValidAfter := _validAfter;
  end;
end;
 }
//------------------------------------------------------------------------------

procedure FreeHoliday(P:PHolidayItem);
// interne Routine: räumt einen PHolidayItem auf.
begin
  if P<>nil then FreeMem(P, SizeOf(THolidayItem));
end;

//------------------------------------------------------------------------------

function RegisterFixedHoliday(_Name:string; _day,_month:integer;
  _validbefore:integer=0; _validafter:integer=0) : integer;
// öffentlich: macht dem Programm die Daten eines festen Feiertags bekannt.
// _name: Bezeichnung des Feiertags.
// _day,_month: Datum des Feiertags
// _validBefore: Jahr, vor dem (einschließlich) es diesen Feiertag gab.
// _validAfter: Jahr, seit dem es (einschließlich) diesen Feiertag gibt.
begin
  if RegisteredHolidays=nil then RegisteredHolidays := TList.Create;
  result := RegisteredHolidays.Add(CreateFixedHoliday(_name, _day,_month,
    _validBefore, _ValidAfter));
end;

//------------------------------------------------------------------------------

function RegisterFloatingHoliday(_name:string; _delta:integer; _relativeTo:string;
  _validBefore:integer=0; _validAfter:integer=0) : integer;
// öffentlich: macht dem Programm die Daten eines beweglichen Feiertags bekannt.
// _name: Bezeichnung des Feiertags.
// _delta: Tagesdifferenz zum Referenzfeiertag _relativeTo
// _relativeTo: Name eines bereits registrierten Feiertags, zu dem der neue
//    Feiertag einen festen Abstand (_delta) hat.
//    _relativeTo kann ein Leerstring sein und bezieht sich dann auf den
//    Ostersonntag.
// _validBefore: Jahr, vor dem (einschließlich) es diesen Feiertag gab.
// _validAfter: Jahr, seit dem es (einschließlich) diesen Feiertag gibt.
var
  i,nr : integer;
  P : PHolidayItem;
  s : string;
begin
  if RegisteredHolidays=nil then RegisteredHolidays := TList.create;
  if _relativeTo='' then
    nr := -1
  else begin
    s := UpperCase(_relativeTo);
    nr := -1;
    for i:=0 to RegisteredHolidays.Count-1 do begin
      P := PHolidayItem(RegisteredHolidays.Items[i]);
      if Uppercase(P^.Name)=s then begin
        nr := i;
        break;
      end;
    end;
    if nr=-1 then
      raise EDateError.CreateFmt('Feiertag %s noch nicht registriert.', [_relativeTo]);
  end;
  result := RegisteredHolidays.Add(CreateFloatingHoliday(_name, _delta, nr,
    _validBefore, _validAfter));
end;

//------------------------------------------------------------------------------

function RegisterFloatingHoliday2(_name:string; _refDay,_refMonth:integer;
  _delta,_weekday:integer; _validBefore:integer=0; _validAfter:integer=0) : integer;
// öffentlich: macht dem Programm die Daten eines beweglichen Feiertags bekannt.
// Der Feiertag liegt am letzten Wochentag um _diff Tage nach einem festen
// Referenzdatum.
// _name: Bezeichnung des Feiertags.
// _refDay, _refMonth: Referenzdatum
// _delta: Tagesdifferenz zum Referenztag _refDay/_refMonth
// _weekday: Wochentagnummer, auf dem der Feiertag liegen muss
//    Sonntag=1, Samstag=7
// _validBefore: Jahr, vor dem (einschließlich) es diesen Feiertag gab.
// _validAfter: Jahr, seit dem es (einschließlich) diesen Feiertag gibt.
begin
  if RegisteredHolidays=nil then RegisteredHolidays := TList.create;
  result := RegisteredHolidays.Add(CreateFloatingHoliday2(_name, _refday,_refmonth,
    _delta, _weekday, _validBefore, _ValidAfter));
end;

//------------------------------------------------------------------------------

procedure RegisterHolidays_Bavaria;
// Registriert die in Bayern üblichen Feiertage
begin
  UnregisterHolidays;

  RegisterFixedHoliday ('Neujahr', 1, 1);
  RegisterFixedHoliday ('Dreikönigsfest', 6,1);
  RegisterFloatingHoliday('Karfreitag', -2, '');
  RegisterFloatingHoliday('Ostersonntag', 0, '');
  RegisterFloatingHoliday('Ostermontag', 1, '');
  RegisterFloatingHoliday('Himmelfahrt', 39, '');
  RegisterFloatingHoliday('Pfingstsonntag', 49, '');
  RegisterFloatingHoliday('Pfingstmontag', 50, '');
  RegisterFloatingHoliday('Fronleichnam', 60, '');
  RegisterFixedHoliday ('1.Mai', 1, 5);
  RegisterFixedHoliday ('Tag der dt. Einheit', 17, 6, 1990, 1954);
  RegisterFixedHoliday ('Mariä Himmelfahrt', 15, 8);
  RegisterFixedHoliday ('Tag der Einheit', 3, 10, 0, 1990);
  RegisterFixedHoliday ('Allerheiligen', 1, 11);
  RegisterFixedHoliday ('Heiligabend', 24, 12);
  RegisterFixedHoliday ('1.Weihnachtsfeiertag', 25, 12);
  RegisterFixedHoliday ('2.Weihnachtsfeiertag', 26, 12);
  RegisterFixedHoliday ('Silvester', 31, 12);
end;

//------------------------------------------------------------------------------

procedure RegisterHolidays(ARegion:THolidayRegion);
begin
  UnregisterHolidays;

  RegisterFixedHoliday('Neujahr', 1,1);
  RegisterFloatingHoliday('Karfreitag', -2, '');
  RegisterFloatingHoliday('Ostersonntag', 0, '');
  RegisterFloatingHoliday('Ostermontag', 1, '');
  RegisterFloatingHoliday('Pfingstsonntag', 49, '');
  RegisterFloatingHoliday('Pfingstmontag', 50, '');
  RegisterFixedHoliday ('1.Mai', 1, 5);
  RegisterFixedHoliday ('Tag der dt. Einheit', 17, 6, 1990, 1954);
  RegisterFixedHoliday ('Tag der Einheit', 3, 10, 0, 1990);
  RegisterFixedHoliday ('Heiligabend', 24, 12);
  RegisterFixedHoliday ('1.Weihnachtsfeiertag', 25, 12);
  RegisterFixedHoliday ('2.Weihnachtsfeiertag', 26, 12);
  RegisterFixedHoliday ('Silvester', 31, 12);

  case ARegion of
    hrBerlin,
    hrBremen,
    hrHamburg,
    hrNiedersachsen,
    hrSchleswigHolstein :
      begin
      end;

    hrBayern :
      begin
        RegisterFixedHoliday ('Dreikönigsfest', 6,1);
        RegisterFloatingHoliday('Himmelfahrt', 39, '');
        RegisterFloatingHoliday('Fronleichnam', 60, '');
        RegisterFixedHoliday ('Mariä Himmelfahrt', 15, 8);
        RegisterFixedHoliday ('Allerheiligen', 1, 11);
      end;

    hrBadenWuerttemberg :
      begin
        RegisterFixedHoliday ('Dreikönigsfest', 6,1);
        RegisterFloatingHoliday('Himmelfahrt', 39, '');
        RegisterFloatingHoliday('Fronleichnam', 60, '');
        RegisterFixedHoliday ('Allerheiligen', 1, 11);
      end;

    hrBrandenburg,
    hrMecklenburgVorpommern,
    hrThueringen :
      RegisterFixedHoliday ('Reformationstag', 31,10);

    hrHessen :
      RegisterFloatingHoliday('Fronleichnam', 60, '');

    hrNordRheinWestfalen,
    hrRheinlandPfalz,
    hrSaarland :
      begin
        RegisterFloatingHoliday('Fronleichnam', 60, '');
        RegisterFixedHoliday ('Allerheiligen', 1, 11);
      end;

    hrSachsen :
      begin
        RegisterFixedHoliday ('Reformationstag', 31,10);
        RegisterFloatingHoliday2('Buß- und Bettag', 23,11, -6, 4);  // 4=Mittwoch
      end;

    hrSachsenAnhalt :
      begin
        RegisterFixedHoliday ('Dreikönigsfest', 6,1);
        RegisterFixedHoliday ('Reformationstag', 31,10);
      end;
  end;
end;

//------------------------------------------------------------------------------

procedure UnregisterHolidays;
// Räumt die Feiertagsliste auf. Wird am Programmende automatisch aufgerufen.
var
  i : integer;
begin
  if RegisteredHolidays<>nil then begin
    for i:=RegisteredHolidays.count-1 downto 0 do
      FreeHoliday(PHolidayItem(RegisteredHolidays[i]));
    RegisteredHolidays.Free;
    RegisteredHolidays := nil;
  end;
end;

function HolidayActive(H:THolidayItem; year:integer) : boolean;
// interne Routine: prüft ob der angegebene HolidayItem in diesem Jahr zu einem
// Feiertag gehört.
// Mit Hilfe des Feldes "active" von THolidayItem kann ein Feiertag registriert,
// aber nicht verwendet werden: z.B. alle Feiertag von Deutschland registrieren,
// und dem Benutzer die Auswahl überlassen, welche für ihn zutreffen.
begin
  result := H.active;
  if result then begin
    if (H.ValidBefore <> 0) and (year > H.validBefore) then
      result := false
    else
    if (H.ValidAfter <> 0) and (year < H.validAfter) then
      result := false;
  end;
{
  result := H.active and (
            ((H.validBefore = 0)  and (H.validAfter = 0))
         or ((H.validBefore <> 0) and (year <= H.validBefore))
         or ((H.validAfter <> 0)  and (year >= H.validAfter))
         );
}
end;

//------------------------------------------------------------------------------

function HolidayDate(H:THolidayItem; year:integer) : TDateTime;
// Bestimmt das Datum des übergebenen Feiertags-Records im angegebenen Jahr.
var
  i : integer;
begin
  result := 0;
  if HolidayActive(H, year) then
    case H.Kind of
      hkFixed    : result := EncodeDate(year, H.Month, H.Day);
      hkRelative : if H.RelativeTo = -1 then
                     result := Easter(year) + H.Delta
                   else begin
                     H := PHolidayItem(RegisteredHolidays.Items[H.RelativeTo])^;
                     result := HolidayDate(H, year) + H.Delta;
                   end;
      hkWeekday  : begin
                     result := EncodeDate(year, H.RefMonth, H.RefDay) + H.diff;
                     i := DayOfWeek(result);
                     if i > H.Weekday
                       then result := result + 7 - i + H.Weekday
                     else if i < H.Weekday
                       then result := result - i + H.Weekday;
                   end;
    end;
end;

//------------------------------------------------------------------------------

function LocateHoliday(date:TDateTime) : PHolidayItem;
// Sucht den HolidayItem-Record zum angegebenen Datum.
// Übergibt nil, wenn es sich um keinen Feiertag handelt.
var
  i : integer;
  P : PHolidayItem;
  y : integer;
begin
  result := nil;
  if (RegisteredHolidays <> nil) and (date <> NullDate) then begin
    Y := YearOf(date);
    for i:=0 to RegisteredHolidays.Count-1 do begin
      P := PHolidayItem(RegisteredHolidays.Items[i]);
      if (round(HolidayDate(P^,y)) = round(date)) and HolidayActive(P^, y) then begin
        result := P;
        exit;
      end;
    end;
  end;
end;

//------------------------------------------------------------------------------

function IsHoliday(date:TDateTime) : boolean;
// Prüft, ob der angegebene Tag ein Feiertag ist.
begin
  result := LocateHoliday(date)<>nil;
end;

function WhichHoliday(date:TDateTime) : string;
// Übergibt den Namen des Feiertags, auf den das Datum "date" fällt, bzw. einen
// Leerstring, falls es kein Feiertag ist.
var
  P : PHolidayItem;
begin
  P := LocateHoliday(date);
  if P<>nil then result := P^.Name else result := '';
end;

procedure GetRegisteredHolidays(Year:Integer; var List:TDateArray);
var
  i,j: Integer;
  n: Integer;
  H: THolidayItem;
begin
  n := 0;
  for i:=0 to RegisteredHolidays.Count-1 do begin
    H := PHolidayItem(RegisteredHolidays[i])^;
    if HolidayActive(H, year) then inc(n);
  end;
  SetLength(List, n);
  j := 0;
  for i:=0 to RegisteredHolidays.Count-1 do begin
    H := PHolidayItem(RegisteredHolidays[i])^;
    if HolidayActive(H, year) then begin
      List[j] := HolidayDate(H, Year);
      inc(j);
    end;
  end;
end;

function Easter(year:integer) : TDateTime;
// Bestimmt das Datum des Ostersonntags im angegebenen Jahr.
var
  Day, Month    : integer;
  a,b,c,d,e,m,n : integer;
begin
  result := NullDate;
  case Year div 100 of
    17    : begin m := 23; n := 3; end;
    18    : begin m := 23; n := 4; end;
    19,20 : begin m := 24; n := 5; end;
    21    : begin m := 24; n := 6; end;
    else
            exit;
//            raise EDateError.Create('Das Oster-Datum kann nur für die Jahre '+
//              'zwischen 1700 und 2199 berechnet werden.');
// wp: Exception macht ein Problem (Hänger) beim TWPDateEdit, wenn ein Jahr
// eingegeben ist, für das Ostern nicht ausgerechnet werden kann.
  end;
  a := Year mod 19;
  b := Year mod 4;
  c := Year mod 7;
  d := (19*a + m) mod 30;
  e := (2*b + 4*c + 6*d + n) mod 7;
  day := 22 + d + e;
  Month := 3;
  if Day>31 then begin
    Day := d + e - 9;
    Month := 4;
    if (d=28) and (e=6) and (a>10) then begin
      if day=26 then day := 19;
      if day=25 then day := 18;
    end;
  end;
  result := EncodeDate(year, month, day);
end;

//------------------------------------------------------------------------------

function IsWorkday(date:TDateTime) : boolean;
var
  weekday : word;
begin
  weekday := DayOfWeek(date);
  result := (weekday > 1)  // 1 = Sonntag
     and (weekday < 7)     // 7 = Samstag
     and (not IsHoliday(date));
end;

//------------------------------------------------------------------------------

function WorkdaysOfMonth(year,month:word) : word;
// Zählt wieviele Arbeitstage im angegebenen Monat liegen.
var
  dt : integer;
  d : word;
begin
  result := 0;
  dt := round(EncodeDate(year, month, 1));
  for d := 1 to DaysInMonth(dt) do begin
    if IsWorkday(dt) then inc(result);
    inc(dt);
  end;
end;

//------------------------------------------------------------------------------

function WorkdaysOfYear(year:word) : word;
var
  m : word;
begin
  result := 0;
  for m:=1 to 12 do result := result + WorkdaysOfMonth(year, m);
end;

//------------------------------------------------------------------------------

function NextWorkday(date:TDateTime) : TDateTime;
// Berechnet ausgehend vom angegebenen Datum den nächsten Arbeitstag.
begin
  result := date + 1;
  while not IsWorkday(result) do result := result + 1;
end;

//------------------------------------------------------------------------------

function PrevWorkday(date:TDateTime) : TDateTime;
// Berechnet ausgehend vom angegebenen Datum den verhergegangenen Arbeitstag.
begin
  result := date - 1;
  while not isWorkDay(result) do result := result - 1;
end;


//------------------------------------------------------------------------------
// einige Routinen aus RxLib bzw. Jedi JVCL
//------------------------------------------------------------------------------

function DefDateFormat(FourDigitYear: Boolean): string;
begin
  if FourDigitYear then begin
    case GetDateOrder(ShortDateFormat) of
      doMDY : Result := 'MM/DD/YYYY';
      doDMY : Result := 'DD/MM/YYYY';
      doYMD : Result := 'YYYY/MM/DD';
    end;
  end
  else begin
    case GetDateOrder(ShortDateFormat) of
      doMDY : Result := 'MM/DD/YY';
      doDMY : Result := 'DD/MM/YY';
      doYMD : Result := 'YY/MM/DD';
    end;
  end;
end;

//------------------------------------------------------------------------------

function DefDateMask(BlanksChar:Char; FourDigitYear:Boolean): string;
begin
  if FourDigitYear then begin
    case GetDateOrder(ShortDateFormat) of
      doMDY, doDMY : Result := '!99/99/9999;1;';
      doYMD        : Result := '!9999/99/99;1;';
    end;
  end else begin
    case GetDateOrder(ShortDateFormat) of
      doMDY, doDMY : Result := '!99/99/99;1;';
      doYMD        : Result := '!99/99/99;1;';
    end;
  end;
  if Result <> '' then Result := Result + BlanksChar;
end;

//------------------------------------------------------------------------------

function ExpandYear(Year: Integer): Integer;
var
  N: Longint;
begin
  if Year = -1 then
    Result := CurrentYear
  else begin
    Result := Year;
    if Result < 100 then begin
      N := CurrentYear - TwoDigitYearCenturyWindow;
      inc(Result, N div 100 * 100);
      if (TwoDigitYearCenturyWindow > 0) and (Result < N)
        then inc(result, 100);
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure ExtractMask(const Format, S: string; Ch: Char; Cnt: Integer;
  var I: Integer; Blank, Default: Integer);
var
  Tmp: string[20];
  J, L: Integer;
begin
  I := Default;
  Ch := UpCase(Ch);
  L := Length(Format);
  if Length(S) < L then
    L := Length(S)
  else if Length(S) > L then
    Exit;
  J := Pos(FillString(Ch, Cnt), AnsiUpperCase(Format));
  if J <= 0 then Exit;
  Tmp := '';
  while (UpCase(Format[J]) = Ch) and (J <= L) do begin
    if S[J] <> ' ' then
      Tmp := Tmp + S[J];
    Inc(J);
  end;
  if Tmp = '' then
    I := Blank
  else
  if Cnt > 1 then begin
    I := MonthFromName(Tmp, Length(Tmp));
    if I = 0 then I := -1;
  end else
    I := StrToIntDef(Tmp, -1);
end;

//------------------------------------------------------------------------------

function FourDigitYear: Boolean;
begin
  Result := Pos('YYYY', AnsiUpperCase(ShortDateFormat)) > 0;
end;

//------------------------------------------------------------------------------

function GetDateOrder(const DateFormat: string): TDateOrder;
var
  i : Integer;
begin
  i := 1;
  while i <= Length(DateFormat) do begin
    case Chr(Ord(DateFormat[i]) and $DF) of
      'E': result := doYMD;
      'Y': result := doYMD;
      'M': result := doMDY;
      'D': result := doDMY;
    else
      inc(i);
      continue;
    end;
    exit;
  end;
  Result := DefaultDateOrder; { default }
end;

//------------------------------------------------------------------------------

function IsFourDigitYear: Boolean;
begin
  Result := Pos('YYYY', AnsiUpperCase(ShortDateFormat)) > 0;
end;

//------------------------------------------------------------------------------

function MonthFromName(const S: string; MaxLen: Byte): Byte;
var
  ss : string;
  sm : string;
begin
  if Length(S) > 0 then begin
    ss := Copy(S, 1, MaxLen);
    for result := 1 to 12 do begin
      if (Length(LongMonthNames[result]) > 0) then begin
        sm := copy(LongMonthNames[result], 1, MaxLen);
        if AnsiCompareText(ss, sm) = 0 then exit;
      end;
    end;
  end;
  Result := 0;
end;

//------------------------------------------------------------------------------

procedure ScanBlanks(const S: string; var Pos: Integer);
var
  I: Integer;
begin
  I := Pos;
  while (I <= Length(S)) and (S[I] = ' ') do
    Inc(I);
  Pos := I;
end;

//------------------------------------------------------------------------------

function ScanNumber(const S: string; MaxLength: Integer; var Pos: Integer;
  var Number: Longint): Boolean;
var
  I: Integer;
  N: Word;
begin
  Result := False;
  ScanBlanks(S, Pos);
  I := Pos;
  N := 0;
  while (I <= Length(S)) and (Longint(I - Pos) < MaxLength) and
    (S[I] in ['0'..'9']) and (N < 1000) do
  begin
    N := N * 10 + (Ord(S[I]) - Ord('0'));
    Inc(I);
  end;
  if I > Pos then
  begin
    Pos := I;
    Number := N;
    Result := True;
  end;
end;

//------------------------------------------------------------------------------

function ScanChar(const S: string; var Pos: Integer; Ch: Char): Boolean;
begin
  Result := False;
  ScanBlanks(S, Pos);
  if (Pos <= Length(S)) and (S[Pos] = Ch) then
  begin
    Inc(Pos);
    Result := True;
  end;
end;

//------------------------------------------------------------------------------

procedure ScanToNumber(const S: string; var Pos: Integer);
begin
  while (Pos <= Length(S)) and not (S[Pos] in ['0'..'9']) do
  begin
    if S[Pos] in LeadBytes then
      Inc(Pos);
    Inc(Pos);
  end;
end;

//------------------------------------------------------------------------------

function ScanDate(const S, DateFormat: string; var Position: Integer;
  var Y, M, D: Integer): Boolean;
var
  DateOrder: TDateOrder;
  N1, N2, N3: Longint;
begin
  Result := False;
  Y := 0;
  M := 0;
  D := 0;
  DateOrder := GetDateOrder(DateFormat);
  if ShortDateFormat[1] = 'g' then { skip over prefix text }
    ScanToNumber(S, Position);
  if not (ScanNumber(S, MaxInt, Position, N1) and ScanChar(S, Position, DateSeparator{$IFDEF CLR}[1]{$ENDIF}) and
    ScanNumber(S, MaxInt, Position, N2)) then
    Exit;
  if ScanChar(S, Position, DateSeparator{$IFDEF CLR}[1]{$ENDIF}) then begin
    if not ScanNumber(S, MaxInt, Position, N3) then
      Exit;
    case DateOrder of
      doMDY : begin
                Y := N3;
                M := N1;
                D := N2;
              end;
      doDMY : begin
                Y := N3;
                M := N2;
                D := N1;
              end;
      doYMD : begin
                Y := N1;
                M := N2;
                D := N3;
              end;
    end;
    Y := ExpandYear(Y);
  end else begin
    Y := CurrentYear;
    if DateOrder = doDMY then
    begin
      D := N1;
      M := N2;
    end else begin
      M := N1;
      D := N2;
    end;
  end;
  ScanChar(S, Position, DateSeparator);
  ScanBlanks(S, Position);
  if SysLocale.FarEast and (Pos('ddd', ShortDateFormat) <> 0) then
  begin { ignore trailing text }
    if ShortTimeFormat[1] in ['0'..'9'] then { stop at time digit }
      ScanToNumber(S, Position)
    else { stop at time prefix }
      repeat
        while (Position <= Length(S)) and (S[Position] <> ' ') do
          Inc(Position);
        ScanBlanks(S, Position);
      until (Position > Length(S))
        or AnsiSameText(TimeAMString, Copy(S, Position, Length(TimeAMString)))
        or AnsiSameText(TimePMString, Copy(S, Position, Length(TimePMString)));
  end;
  Result := IsValidDate(Y, M, D) and (Position > Length(S));
end;

//------------------------------------------------------------------------------

function ScanDateStr(const Format, S: string; var D, M, Y: Integer): Boolean;
var
  Pos: Integer;
begin
  ExtractMask(Format, S, 'm', 3, M, -1, 0); { short month name? }
  if M = 0 then ExtractMask(Format, S, 'm', 1, M, -1, 0);
  ExtractMask(Format, S, 'd', 1, D, -1, 1);
  ExtractMask(Format, S, 'y', 1, Y, -1, CurrentYear);
  if M = -1 then M := CurrentMonth;
  Y := ExpandYear(Y);
  Result := IsValidDate(Y, M, D);
  if not Result then begin
    Pos := 1;
    Result := ScanDate(S, Format, Pos, Y, M, D);
  end;
end;

//------------------------------------------------------------------------------

function InternalStrToDate(const DateFormat,S:string; var Date:TDateTime):boolean;
var
  D, M, Y: Integer;
begin
  if S = '' then
  begin
    Date := NullDate;
    Result := True;
  end
  else
  begin
    Result := ScanDateStr(DateFormat, S, D, M, Y);
    if Result then
    try
      Date := EncodeDate(Y, M, D);
    except
      Result := False;
    end;
  end;
end;

//------------------------------------------------------------------------------

function StrToDateFmt(const DateFormat, S: string): TDateTime;
begin
  if not InternalStrToDate(DateFormat, S, Result) then
    raise EConvertError.CreateFmt('"%s" ist kein gültiges Datum.', [S]);
end;

//------------------------------------------------------------------------------

function StrToDateFmtDef(const DateFormat, S: string; Default: TDateTime): TDateTime;
begin
  if not InternalStrToDate(DateFormat, S, Result)
    then result := trunc(Default);
end;

//------------------------------------------------------------------------------

function ValidDate(ADate: TDateTime): Boolean;
var
  Year, Month, Day: Word;
begin
  try
    DecodeDate(ADate, Year, Month, Day);
    Result := IsValidDate(Year, Month, Day);
  except
    Result := False;
  end;
end;


//==============================================================================

initialization
  RegisteredHolidays := nil;

finalization
  UnregisterHolidays;

end.
