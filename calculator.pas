Program Calc;

uses GraphABC, Events;

type
  PointT = class
  public
    x, y: Integer;
    
    constructor Create(x_, y_: Integer);
    begin
      x := x_;
      y := y_;
    end;
  end;

  SizeT = class
  public
    width, height: Integer;
    
    constructor Create(w, h: Integer);
    begin
      width := w;
      height := h;
    end;
  end;

  RectangleT = class
  public
    position: PointT;
    size: SizeT;
    
    constructor Create(pos: PointT; sz: SizeT);
    begin
      position := pos;
      size := sz;
    end;
  end;

  UIElementT = class
  public
    rect: RectangleT;
    
    constructor Create(rect_: RectangleT);
    begin
      rect := rect_;
    end;
    
    procedure Draw; virtual;
    begin
      rectangle(10, 10, 50, 50);
    end;
    
    procedure OnClick; virtual;
    begin
    end;
    
    procedure AfterClick; virtual;
    begin
    end;
    
    function IsPointerOnElement(pt: PointT): Boolean;
    begin
      var dpt: PointT := new PointT(rect.position.X + rect.size.width, 
                                    rect.position.Y + rect.size.height);
      
      IsPointerOnElement := (rect.position.X <= pt.X) and (dpt.X >= pt.X) and 
                            (rect.position.Y <= pt.Y) and (dpt.Y >= pt.Y);
    end;
  end;

  TextFieldT = class(UIElementT)
  public
    text: String;
    
    constructor Create(rect_: RectangleT; txt: String);
    begin
      inherited Create(rect_);
      text := txt;
    end;
    
    procedure Draw; override;
    begin
      var dpt: PointT := new PointT(rect.position.x + rect.size.width,
                                    rect.position.y + rect.size.height);
      
      SetBrushColor(clWhite);
      FillRectangle(rect.position.x, rect.position.y, dpt.x, dpt.y);
      
      TextOut(rect.position.x + 3, 
              rect.position.y + Round((rect.size.height - TextHeight(text))/2), 
              text);
    end;
  end;

  ButtonT = class(UIElementT)
  private
    isPressed: Boolean;
    
    procedure DrawPressedButton;
    begin
      var dpt: PointT := new PointT(rect.position.x + rect.size.width,
                                    rect.position.y + rect.size.height);
      
      SetBrushColor(clGray);
      FillRectangle(rect.position.x, rect.position.y, dpt.x, dpt.y);
    end;

    procedure DrawUnpressedButton;
    begin
      var dpt: PointT := new PointT(rect.position.x + rect.size.width,
                                    rect.position.y + rect.size.height);      

      SetBrushColor(clWhite);
      FillRectangle(rect.position.x, rect.position.y, dpt.x, dpt.y);
    end;
    
    procedure DrawText;
    begin
      TextOut(rect.position.x + Round((rect.size.width - TextWidth(text)) / 2), 
              rect.position.y + Round((rect.size.height - TextHeight(text)) / 2), 
              text);
    end;
    
  public
    text: String;
    Action: procedure;
    
    constructor Create(rect_: RectangleT; txt: String; act: procedure);
    begin
      inherited Create(rect_);
      isPressed := false;
      text := txt;
      Action := act;
    end;
    
    procedure Draw; override;
    begin
      if isPressed then DrawPressedButton else DrawUnpressedButton;
      
      DrawText;
    end;
    
    procedure OnClick; override;
    begin
      isPressed := true;
      Action;
    end;
    
    procedure AfterClick; override;
    begin
      isPressed := false;
    end;    
  end;

  UIT = class
  private
    elements: array of UIElementT;

  public
    constructor Create;
    begin
      LockDrawing;
      elements := new UIElementT[0];
      OnMouseDown := OnClick;
      OnMouseUp := AfterClick;
      
      SetFontName('Arial');
      SetFontStyle(fsBold);
      SetFontSize(12);
    end;
    
    procedure AddElement(e: UIElementT);
    begin
      SetLength(elements, elements.Length+1);
      elements[elements.Length-1] := e;
    end;
    
    procedure Update;
    begin
      window.Clear(clLightGray);
      
      for var i := 0 to elements.Length-1 do
        elements[i].Draw;
      
      Redraw;
    end;
    
    procedure OnClick(x, y, mb: Integer);
    begin
      for var i := 0 to elements.Length-1 do
        if elements[i].IsPointerOnElement(new PointT(x, y)) then 
          elements[i].OnClick;
        
      Update;
    end;
    
    procedure AfterClick(x, y, mb: Integer);
    begin
      for var i := 0 to elements.Length-1 do
        if elements[i].IsPointerOnElement(new PointT(x, y)) then 
          elements[i].AfterClick;
        
      Update;
    end;
  end;

  CalculatorT = class
  public
    ui: UIT;
    exp: TextFieldT;
    first: Real;
    op: function(f, s: Real): Real;
    hasSecondNum: Boolean;
  
    function CreateProc(p: procedure): procedure;
    begin
      CreateProc := p;
    end;

    procedure Equals;
    begin
      if hasSecondNum then
      begin
        exp.text := op(first, exp.text.ToInteger).ToString;
        hasSecondNum := false;
      end;
    end;
    
    procedure Plus;
    begin
      if exp.text[1].IsDigit = false then Exit;
      if hasSecondNum then Equals;
      first := exp.text.ToReal;
      exp.text := '+';
      hasSecondNum := true;
      op := (f, s: Real) -> f + s;      
    end;
    
    procedure Minus;
    begin
      if exp.text[1].IsDigit = false then Exit;
      if hasSecondNum then Equals;
      first := exp.text.ToReal;
      exp.text := '-';
      hasSecondNum := true;
      op := (f, s: Real) -> f - s;      
    end;
    
    procedure Multiply;
    begin
      if exp.text[1].IsDigit = false then Exit;
      if hasSecondNum then Equals;
      first := exp.text.ToReal;
      exp.text := '*';
      hasSecondNum := true;
      op := (f, s: Real) -> f * s;      
    end;
  
    procedure Divide;
    begin
      if exp.text[1].IsDigit = false then Exit;
      if hasSecondNum then Equals;
      first := exp.text.ToReal;
      exp.text := '-';
      hasSecondNum := true;
      op := (f, s: Real) -> f - s;      
    end;
    
    procedure InputDigit(d: String);
    begin
      if (exp.text.Length <> 0) and exp.text[1].IsDigit then 
        exp.text += d
      else
      begin
        exp.text := d
      end;      
    end;

    procedure Clear;
    begin
      hasSecondNum := false;
      first := 0;
      exp.text := '';      
    end;
    
    procedure ChangeSign;
    begin
      if (exp.text.Length <> 0) and (exp.text[1].IsDigit or 
         (exp.text[1] = '-')) then
        exp.text := (-exp.text.ToReal).ToString;      
    end;
  
    procedure Pow;
    begin
      if exp.text[1].IsDigit = false then Exit;
      first := exp.text.ToReal;
      if hasSecondNum then Equals;
      exp.text := '^';
      hasSecondNum := true;
      op := (f, s: Real) -> power(f, s);            
    end;
  
    procedure BackSpace;
    begin
      if exp.text.Length <> 0 then 
        exp.text := exp.text.Remove(exp.text.Length-1, 1);
    end;
        
    constructor Create;
    begin
      var buttonSize: SizeT := new SizeT(77, 52);
      var space: SizeT := new SizeT(2, 2);
      var textFieldSize: SizeT := 
        new SizeT(buttonSize.width*4 + space.width*3, 50);
      
      window.IsFixedSize := true;
      window.SetSize(textFieldSize.width + space.width*2,
                     buttonSize.height*5 + space.height*7 + textFieldSize.height);
      window.Title := 'Калькулятор';
      
      ui := new UIT;
      exp := new TextFieldT(
               new RectangleT(
                 new PointT(space.width, space.height), 
                 textFieldSize
               ), 
               ''
             );
      hasSecondNum := false;
      
      var buttons: array [1..20] of String := (
        'C',   '^', '←', '+',
        '1',   '2', '3',  '-',
        '4',   '5', '6',  '*',
        '7',   '8', '9',  '/',
        '+/-', '0', '.',  '='
      );
      var buttonsActions: array [1..20] of ()->() := (
        self.Clear, Self.Pow, BackSpace, Plus,
        CreateProc(() -> InputDigit('1')), 
        CreateProc(() -> InputDigit('2')),
        CreateProc(() -> InputDigit('3')),
        Minus,
        CreateProc(() -> InputDigit('4')),
        CreateProc(() -> InputDigit('5')),
        CreateProc(() -> InputDigit('6')),
        Multiply,
        CreateProc(() -> InputDigit('7')),
        CreateProc(() -> InputDigit('8')),
        CreateProc(() -> InputDigit('9')),
        Divide,
        ChangeSign, 
        CreateProc(() -> InputDigit('0')), 
        CreateProc(() -> InputDigit('.')),
        Equals
      );
            
      ui.AddElement(exp);
      
      for var i := 1 to 5 do
      begin
        for var j := 1 to 4 do
        begin
          ui.AddElement(
            new ButtonT(
              new RectangleT(
                new PointT(
                  space.width + (j-1)*(buttonSize.width + space.width),
                  exp.rect.size.height + exp.rect.position.y + space.height +
                    (i-1)*(buttonSize.height + space.height)
                ),
                buttonSize
              ),
              buttons[(i-1)*4 + j],
              buttonsActions[(i-1)*4 + j]
            )
          );
        end;
      end;
      
      ui.Update;
    end;
  end;

begin
  new CalculatorT;
end.