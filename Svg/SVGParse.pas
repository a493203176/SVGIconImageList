{******************************************************************}
{ Parse of SVG property values                                     }
{                                                                  }
{ home page : http://www.mwcs.de                                   }
{ email     : martin.walter@mwcs.de                                }
{                                                                  }
{ date      : 05-04-2008                                           }
{                                                                  }
{ Use of this file is permitted for commercial and non-commercial  }
{ use, as long as the author is credited.                          }
{ This file (c) 2005, 2008 Martin Walter                           }
{                                                                  }
{ Thanks to:                                                       }
{ Kiriakos Vlahos (fixed GetFactor)                                }
{ Kiriakos Vlahos (Added parse length in percent)                  }
{                                                                  }
{ This Software is distributed on an "AS IS" basis, WITHOUT        }
{ WARRANTY OF ANY KIND, either express or implied.                 }
{                                                                  }
{ *****************************************************************}

unit SVGParse;

interface

uses
  System.Types,
  System.Classes,
  SVGTypes;

function ParseAngle(const Angle: string): TFloat;

function ParseByte(const S: string): Byte;

function ParsePercent(const S: string): TFloat;

function ParseInteger(const S: string): Integer;

function ParseLength(const S: string): TFloat; overload;
function ParseLength(const S: string; var IsPercent: Boolean): TFloat; overload;

function ParseUnit(const S: string): TSVGUnit;

function GetFactor(const SVGUnit: TSVGUnit): TFloat;

function ParseDRect(const S: string): TRectF;

function ParseURI(const URI: string): string;

function ParseTransform(const ATransform: string): TAffineMatrix;

implementation

uses
  System.SysUtils, System.Math, System.StrUtils,
  SVGCommon;

function ParseAngle(const Angle: string): TFloat;
var
  D: TFloat;
  C: Integer;
  S: string;
begin
  if Angle <> '' then
  begin
    S := Angle;
    C := Pos('deg', S);
    if C <> 0 then
    begin
      S := LeftStr(S, C - 1);
      if TryStrToTFloat(S, D) then
        Result := DegToRad(D)
      else
        Result := 0;
      Exit;
    end;

    C := Pos('rad', S);
    if C <> 0 then
    begin
      TryStrToTFloat(S, Result);
      Exit;
    end;

    C := Pos('grad', S);
    if C <> 0 then
    begin
      S := LeftStr(S, C - 1);
      if TryStrToTFloat(S, D) then
        Result := GradToRad(D)
      else
        Result := 0;
      Exit;
    end;

    if TryStrToTFloat(S, D) then
      Result := DegToRad(D)
    else
      Result := 0;
  end else
    Result := 0;
end;

function ParseByte(const S: string): Byte;
begin
  Result := ParseInteger(S);
end;

function ParsePercent(const S: string): TFloat;
begin
  Result := -1;
  if S = '' then
    Exit;

  if S[Length(S)] = '%' then
    Result := StrToTFloat(LeftStr(S, Length(S) - 1)) / 100
  else
    Result := StrToTFloat(S);
end;

function ParseInteger(const S: string): Integer;
begin
  Result := StrToInt(S);
end;

function ParseLength(const S: string): TFloat;
Var
  IsPercent: Boolean;
begin
   Result := ParseLength(S, IsPercent);
end;

function ParseLength(const S: string; var IsPercent: Boolean): TFloat; overload;
var
  U: string;
  SVGUnit: TSVGUnit;
  Factor: TFloat;
begin
  SVGUnit := ParseUnit(S);
  IsPercent := SVGUnit = suPercent;
  if SVGUnit = suPercent then
    U := Copy(S, Length(S), 1)
  else
    if SVGUnit <> suNone then
      U := Copy(S, Length(S) - 1, 2);

  Factor := GetFactor(SVGUnit);
  if U = 'px' then
    Result := StrToTFloat(Copy(S, 1, Length(S) - 2))
  else
  if U = 'pt' then
    Result := StrToTFloat(Copy(S, 1, Length(S) - 2)) * Factor
  else
  if U = 'pc' then
    Result := StrToTFloat(Copy(S, 1, Length(S) - 2)) * Factor
  else
  if U = 'mm' then
    Result := StrToTFloat(Copy(S, 1, Length(S) - 2)) * Factor
  else
  if U = 'cm' then
    Result := StrToTFloat(Copy(S, 1, Length(S) - 2)) * Factor
  else
  if U = 'in' then
    Result := StrToTFloat(Copy(S, 1, Length(S) - 2)) * Factor
  else
  if U = '%' then
    Result := StrToTFloat(Copy(S, 1, Length(S) - 1)) * Factor
  else
    Result := StrToTFloat(S);
end;

function ParseUnit(const S: string): TSVGUnit;
begin
  Result := suNone;

  if Copy(S, Length(S) - 1, 2) = 'px' then
  begin
    Result := suPx;
    Exit;
  end;

  if Copy(S, Length(S) - 1, 2) = 'pt' then
  begin
    Result := suPt;
    Exit;
  end;

  if Copy(S, Length(S) - 1, 2) = 'pc' then
  begin
    Result := suPC;
    Exit;
  end;

  if Copy(S, Length(S) - 1, 2) = 'mm' then
  begin
    Result := suMM;
    Exit;
  end;

  if Copy(S, Length(S) - 1, 2) = 'cm' then
  begin
    Result := suCM;
    Exit;
  end;

  if Copy(S, Length(S) - 1, 2) = 'in' then
  begin
    Result := suIN;
    Exit;
  end;

  if Copy(S, Length(S) - 1, 2) = 'em' then
  begin
    Result := suEM;
    Exit;
  end;

  if Copy(S, Length(S) - 1, 2) = 'ex' then
  begin
    Result := suEX;
    Exit;
  end;

  if Copy(S, Length(S), 1) = '%' then
  begin
    Result := suPercent;
    Exit;
  end;
end;

function GetFactor(const SVGUnit: TSVGUnit): TFloat;
begin
  case SVGUnit of
    suPX: Result := 1;
    suPT: Result := 1.3333;     // 96 / 72
    suPC: Result := 16;         // 1pc = 12 pt
    suMM: Result := 3.77952756; //  96 / 25.4
    suCM: Result := 37.7952756; // 10 mm
    suIN: Result := 96;         // 96 px per inch
    suEM: Result := 16;         // 1 -> font size    12pt = 16 px
    suEX: Result := 16;         // 1 -> font height
    suPercent: Result := 1/100;
    else
      Result := 1;
  end;
end;

function GetValues(const S: string; const Delimiter: Char): TStrings;
var
  C: Integer;
begin
  Result := TStringList.Create;
  Result.Delimiter := Delimiter;
  Result.DelimitedText := S;

  for C := Result.Count - 1 downto 0 do
  begin
    if Result[C] = '' then
    begin
      Result.Delete(C);
    end;
  end;
end;

function ParseDRect(const S: string): TRectF;
var
  SL: TStrings;
begin
  FillChar(Result, SizeOf(Result), 0);

  SL := GetValues(Trim(S), ' ');

  try
    if SL.Count = 4 then
    begin
      Result.Left := ParseLength(SL[0]);
      Result.Top := ParseLength(SL[1]);
      Result.Width := ParseLength(SL[2]);
      Result.Height := ParseLength(SL[3]);
    end;
  finally
    SL.Free;
  end;
end;

function ParseURI(const URI: string): string;
var
  S: string;
begin
  Result := '';
  if URI <> '' then
  begin
    S := Trim(URI);
    if (Copy(S, 1, 5) = 'url(#') and (S[Length(S)] = ')') then
      Result := Copy(S, 6, Length(S) - 6);
  end;
end;

function GetMatrix(const S: string): TAffineMatrix;
var
  SL: TStrings;
begin
  Result := TAffineMatrix.Identity;
  SL := GetValues(S, ',');
  try
    if SL.Count = 6 then
    begin
      Result.m11 := StrToTFloat(SL[0]);
      Result.m12 := StrToTFloat(SL[1]);
      Result.m21 := StrToTFloat(SL[2]);
      Result.m22 := StrToTFloat(SL[3]);
      Result.dx := StrToTFloat(SL[4]);
      Result.dy := StrToTFloat(SL[5]);
    end;
  finally
    SL.Free;
  end;
end;

function GetTranslate(const S: string): TAffineMatrix;
var
  SL: TStrings;
begin
  FillChar(Result, SizeOf(Result), 0);
  SL := GetValues(S, ',');
  try
    if SL.Count = 1 then
      SL.Add('0');

    if SL.Count = 2 then
    begin
      Result := TAffineMatrix.CreateTranslation(StrToTFloat(SL[0]), StrToTFloat(SL[1]));
    end;
  finally
    SL.Free;
  end;
end;

function GetScale(const S: string): TAffineMatrix;
var
  SL: TStrings;
begin
  FillChar(Result, SizeOf(Result), 0);
  SL := GetValues(S, ',');
  try
    if SL.Count = 1 then
      SL.Add(SL[0]);
    if SL.Count = 2 then
    begin
      Result := TAffineMatrix.CreateScaling(StrToTFloat(SL[0]), StrToTFloat(SL[1]));
    end;
  finally
    SL.Free;
  end;
end;

function GetRotation(const S: string): TAffineMatrix;
var
  SL: TStrings;
  X, Y, Angle: TFloat;
begin
  X := 0;
  Y := 0;
  Angle := 0;
  SL := GetValues(S, ',');
  try
    if SL.Count > 0 then
    begin
      Angle := ParseAngle(SL[0]);

      if SL.Count = 3 then
      begin
        X := StrToTFloat(SL[1]);
        Y := StrToTFloat(SL[2]);
      end else
      begin
        X := 0;
        Y := 0;
      end;
    end;
  finally
    SL.Free;
  end;

  Result := TAffineMatrix.CreateTranslation(X, Y);
  Result := TAffineMatrix.CreateRotation(Angle) * Result;
  Result := TAffineMatrix.CreateTranslation(-X, -Y) * Result;
end;

function GetSkewX(const S: string): TAffineMatrix;
var
  SL: TStrings;
begin
  FillChar(Result, SizeOf(Result), 0);

  SL := GetValues(S, ',');
  try
    if SL.Count = 1 then
    begin
      Result := TAffineMatrix.Identity;
      Result.m21 := Tan(StrToTFloat(SL[0]));
    end;
  finally
    SL.Free;
  end;
end;

function GetSkewY(const S: string): TAffineMatrix;
var
  SL: TStrings;
begin
  FillChar(Result, SizeOf(Result), 0);

  SL := GetValues(S, ',');
  try
    if SL.Count = 1 then
    begin
      Result := TAffineMatrix.Identity;
      Result.m12 := Tan(StrToTFloat(SL[0]));
    end;
  finally
    SL.Free;
  end;
end;

function ParseTransform(const ATransform: string): TAffineMatrix;
var
  Start: Integer;
  Stop: Integer;
  TType: string;
  Values: string;
  S: string;
  M: TAffineMatrix;
begin
  FillChar(Result, SizeOf(Result), 0);

  S := Trim(ATransform);

  while S <> '' do
  begin
    Start := Pos('(', S);
    Stop := Pos(')', S);
    if (Start = 0) or (Stop = 0) then
      Exit;
    TType := Trim(Copy(S, 1, Start - 1));
    Values := Trim(Copy(S, Start + 1, Stop - Start - 1));
    Values := StringReplace(Values, ' ', ',', [rfReplaceAll]);

    if TType = 'matrix' then
    begin
      M := GetMatrix(Values);
    end
    else if TType = 'translate' then
    begin
      M := GetTranslate(Values);
    end
    else if TType = 'scale' then
    begin
      M := GetScale(Values);
    end
    else if TType = 'rotate' then
    begin
      M := GetRotation(Values);
    end
    else if TType = 'skewX' then
    begin
      M := GetSkewX(Values);
    end
    else if TType = 'skewY' then
    begin
      M := GetSkewY(Values);
    end;

    if not M.IsEmpty then
    begin
      if Result.IsEmpty then
        Result := M
      else
        Result := M * Result;
    end;

    S := Trim(Copy(S, Stop + 1, Length(S)));
  end;
end;

end.
