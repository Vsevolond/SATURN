import Testing
@testable import saturn

@Test func example() async throws {
    let spec = """
    %tokens
        NUMBER  = [0-9]+
        ID      = [a-zA-Z_][a-zA-Z0-9_]*
        PLUS    = "+"
        MINUS   = "-"
        STAR    = "*"
        DIV     = "/"
        LPAREN  = "("
        RPAREN  = ")"
        ASSIGN  = "="
        SEMICOL = ";"
        PRINT   = "print"
        VAR     = "var"
     
    %types
        Env
     
    %attributes
        NUMBER.lexval : int;
        ID.name       : string;
        Program.env   : Env (inherited);
        Statement.env : Env (inherited);
        Expr.val      : int;
     
    %methods
        Env  createEnv();
        Env  setVar(Env, string, int);
        int  getVar(Env, string);
        int  add(int, int);
        int  sub(int, int);
        int  mul(int, int);
        int  div(int, int);
        void print(int);
        Env  seq(Env, Env[]);
        Env  varDecl(Env, string, int);
        Env  assign(Env, string, int);
        Env  printStmt(Env, int);
     
    %grammar
        Program = Statement %rep ( SEMICOL Statement )
            { $0.env = seq(createEnv(), $2.env); }
        
        Statement = VAR ID ASSIGN Expr / varDecl
                  | ID ASSIGN Expr     / assign
                  | PRINT Expr         / printStmt
        
        Expr = Expr PLUS Term  { $0.val = add($1.val, $3.val); }
             | Expr MINUS Term { $0.val = sub($1.val, $3.val); }
             | Term            { $0.val = $1.val; }
        
        Term = Term STAR Factor { $0.val = mul($1.val, $3.val); }
             | Term DIV Factor  { $0.val = div($1.val, $3.val); }
             | Factor           { $0.val = $1.val; }
        
        Factor = NUMBER             { $0.val = $1.lexval; }
               | ID                 { $0.val = getVar($0.env, $1.name); }
               | LPAREN Expr RPAREN { $0.val = $2.val; }
     
    %axiom 
        Program
    """
}
