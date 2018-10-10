unit wdcTools;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TSortedList = class(TList)
  private
    FDuplicates : boolean;
    FSorted : boolean;
    procedure SetSorted(Value:boolean);
  public
    constructor Create;
    function  Add(Item:Pointer) : integer; virtual;
    procedure AddReplace(Item:Pointer);
    function  Compare(Key1,Key2:pointer) : integer; virtual; abstract;
    function  IndexOf(Item:Pointer) : integer; virtual;
    function  KeyOf(Item:Pointer) : pointer; virtual;
    function  Search(Key:Pointer; var Index:integer) : boolean;
    property  Duplicates : boolean read FDuplicates write FDuplicates default true;
    property  Sorted : boolean read FSorted write SetSorted default true;
  end;

  TIntegerList = class(TSortedList)
  private
    function  GetValue(index:integer) : NativeInt;
    procedure SetValue(index:Integer; value:NativeInt);
  public
    constructor Create; overload;
    constructor Create(ADuplicates,ASorted: Boolean); overload;
    function  Add(value:NativeInt) : integer; reintroduce;
    function  Compare(Key1,Key2: Pointer): Integer; override;
    function  First: NativeInt;
    function  IndexOf(value:NativeInt) : integer; reintroduce;
    procedure Insert(index:Integer; value:NativeInt);
    function  Last: NativeInt;
    function  Remove(value:NativeInt) : integer;
    property  Values[index:integer] : NativeInt read GetValue write SetValue; default;
    property  Duplicates default true;
    property  Sorted default false;
  end;

implementation

uses
  Math;

//------------------------------------------------------------------------------
//    TSortedList
//------------------------------------------------------------------------------

constructor TSortedList.Create;
begin
  inherited Create;
  FDuplicates := true;
  FSorted := true;
end;

//------------------------------------------------------------------------------

function TSortedList.Add(Item: Pointer) : integer;
begin
  if FSorted then begin
    if not Search(KeyOf(Item), result) or Duplicates
      then Insert(result, Item);
  end else
    result := inherited Add(Item);
end;

//------------------------------------------------------------------------------

procedure TSortedList.AddReplace(Item: Pointer);
var
  Index: integer;
begin
  if Search(KeyOf(Item), Index) then Delete(Index);
  Add(Item);
end;

//------------------------------------------------------------------------------

function TSortedList.IndexOf(Item:Pointer) : integer;
var
  i: integer;
begin
  result := -1;
  if FSorted then begin
    if Search(KeyOf(Item), i) then begin
      if Duplicates then
        while (i < Count) and (Item <> Items[i]) do inc(i);
      if i < Count then result := i;
    end;
  end else
    Search(KeyOf(Item), result);
end;

//------------------------------------------------------------------------------

function TSortedList.KeyOf(Item:Pointer) : Pointer;
begin
  result := Item;
end;

//------------------------------------------------------------------------------

function TSortedList.Search(Key:Pointer; var Index:integer) : boolean;
var
  L, H, i, C: integer;
begin
  result := false;
  if FSorted then begin
    L := 0;
    H := Count - 1;
    while L <= H do begin
      i := (L + H) shr 1;
      C := Compare(KeyOf(Items[i]), Key);
      if C < 0
        then L := i + 1
      else begin
        H := i - 1;
        if C = 0 then begin
          result := true;
          if not Duplicates then L := i;
        end;
      end;
    end;
    Index := L;
  end else begin
    for i:=Count-1 downto 0 do
      if Compare(KeyOf(Items[i]), Key)=0 then begin
        Index := i;
        result := true;
        exit;
      end;
    Index := -1;
  end;
end;

//------------------------------------------------------------------------------

var
  L : TSortedList;

function SortCompare(item1,item2:pointer) : integer;
begin
  result := L.Compare(item1,item2);
end;

procedure TSortedList.SetSorted(value:boolean);
begin
  if value <> FSorted then begin
    FSorted := value;
    if FSorted then begin
      L := Self;
      Sort(@SortCompare);
    end;
  end;
end;

//------------------------------------------------------------------------------
//  TIntegerList;
//------------------------------------------------------------------------------

constructor TIntegerList.Create;
begin
  inherited Create;
  FDuplicates := true;
  FSorted := false;
end;

//------------------------------------------------------------------------------

constructor TIntegerList.Create(ADuplicates, ASorted: Boolean);
begin
  inherited Create;
  FDuplicates := ADuplicates;
  FSorted := ASorted;
end;

//------------------------------------------------------------------------------

function TIntegerList.Add(value:NativeInt) : integer;
begin
  result := inherited Add(pointer(value));
end;

//------------------------------------------------------------------------------

function TIntegerList.Compare(Key1, Key2: Pointer): Integer;
begin
  result := CompareValue(NativeInt(Key1), NativeInt(Key2));
end;

//------------------------------------------------------------------------------

function TIntegerList.First : NativeInt;
begin
  result := GetValue(0);
end;

//------------------------------------------------------------------------------

function TIntegerList.GetValue(index:integer) : NativeInt;
begin
  result := NativeInt(Items[index]);
end;

//------------------------------------------------------------------------------

function TIntegerList.IndexOf(value:NativeInt) : integer;
begin
  result := inherited IndexOf(pointer(value));
end;

//------------------------------------------------------------------------------

procedure TIntegerList.Insert(index:Integer; value:NativeInt);
begin
  inherited Insert(index, pointer(value));
end;

//------------------------------------------------------------------------------

function TIntegerList.Last: NativeInt;
begin
  result := GetValue(Count-1);
end;

//------------------------------------------------------------------------------

function TIntegerList.Remove(value:NativeInt) : integer;
begin
  result := inherited Remove(pointer(value));
end;

//------------------------------------------------------------------------------

procedure TIntegerList.SetValue(index:Integer; value:NativeInt);
begin
  Items[index] := pointer(value);
end;


end.

