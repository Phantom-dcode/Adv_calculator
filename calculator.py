"""
╔══════════════════════════════════════════════════════════════════╗
║  NOVA CALCX  ─  Phantom Calc                                     ║
║  Python + Tkinter  |  Full Scientific Calculator                 ║
║  Fixed: filename, engine bugs, Flask API wrapper                 ║
╚══════════════════════════════════════════════════════════════════╝

RUN (desktop):   python calculator.py
RUN (API only):  python calculator.py --api
"""
import sys
import tkinter as tk
import math
import random
import re

# ─────────────────────────────────────────────────────────────────
# COLOUR PALETTE
# ─────────────────────────────────────────────────────────────────
C = {
    "bg":        "#0A0A1A",
    "bg_mid":    "#0F0F2E",
    "disp_bg":   "#070715",
    "disp_text": "#E8F4FD",
    "disp_sub":  "#7EB8DA",
    "cyan":      "#00E5FF",
    "purple":    "#BF00FF",
    "pink":      "#FF006E",
    "green":     "#00FF9F",
    "gold":      "#FFD700",
    "btn_num":   "#1A1A3E",
    "btn_num_h": "#2A2A5E",
    "btn_op":    "#0D2B4E",
    "btn_op_h":  "#1A4A7A",
    "btn_func":  "#1E0A3E",
    "btn_func_h":"#3A1A6E",
    "btn_eq":    "#003366",
    "btn_eq_h":  "#0055AA",
    "btn_clr":   "#3D0000",
    "btn_clr_h": "#660000",
    "btn_mem":   "#0A1A2A",
    "btn_mem_h": "#1A3A5A",
    "text_dim":  "#8899BB",
    "white":     "#FFFFFF",
}

# ─────────────────────────────────────────────────────────────────
# CALCULATION ENGINE   (bug-fixed)
# ─────────────────────────────────────────────────────────────────
class Engine:
    def __init__(self):
        self.memory     = 0.0
        self.angle_mode = "DEG"
        self.history    = []
        self._reset()

    def _reset(self):
        self.current  = "0"
        self.expr     = ""
        self.operand1 = None
        self.operator = None
        self.new_num  = True

    # ── angle helpers ──────────────────────────────────────────
    def _rad(self, x):
        if self.angle_mode == "DEG":  return math.radians(x)
        if self.angle_mode == "GRAD": return x * math.pi / 200
        return x

    def _inv_angle(self, x):
        if self.angle_mode == "DEG":  return math.degrees(x)
        if self.angle_mode == "GRAD": return x * 200 / math.pi
        return x

    # ── format number ──────────────────────────────────────────
    def fmt(self, v):
        if isinstance(v, complex):
            r, i = v.real, v.imag
            sgn  = "+" if i >= 0 else "-"
            return f"{self._n(r)} {sgn} {self._n(abs(i))}i"
        return self._n(v)

    def _n(self, v):
        if math.isnan(v):  return "NaN"
        if math.isinf(v):  return "∞" if v > 0 else "-∞"
        if v == int(v) and abs(v) < 1e15:
            return str(int(v))
        if abs(v) >= 1e12 or (abs(v) < 1e-6 and v != 0):
            return f"{v:.6e}"
        return f"{v:.10g}"

    # ── public entry ───────────────────────────────────────────
    def press(self, k):
        """Returns (kind, display_value, sub_text)."""
        try:
            return self._h(k)
        except ZeroDivisionError:
            self._reset()
            return "error", "÷ by Zero", ""
        except (ValueError, OverflowError) as ex:
            self._reset()
            return "error", "Math Error", str(ex)[:24]
        except Exception as ex:
            self._reset()
            return "error", "Error", str(ex)[:24]

    def _h(self, k):
        # ── Clear / Back ─────────────────────────────────────
        if k == "AC":
            self._reset()
            return "display", "0", ""

        if k == "C":
            self.current = "0"; self.new_num = True
            return "display", "0", self.expr

        if k == "⌫":
            if not self.new_num:
                self.current = self.current[:-1] or "0"
                if self.current == "-":
                    self.current = "0"
            return "display", self.current, self.expr

        # ── Memory ───────────────────────────────────────────
        if k == "MC":
            self.memory = 0.0
            return "display", self.current, "M cleared"
        if k == "MR":
            self.current = self.fmt(self.memory)
            self.new_num = False
            return "display", self.current, f"MR = {self.fmt(self.memory)}"
        if k == "M+":
            self.memory += float(self.current)
            return "display", self.current, f"M = {self.fmt(self.memory)}"
        if k == "M-":
            self.memory -= float(self.current)
            return "display", self.current, f"M = {self.fmt(self.memory)}"
        if k == "MS":
            self.memory = float(self.current)
            return "display", self.current, f"MS = {self.fmt(self.memory)}"

        # ── Angle mode ───────────────────────────────────────
        if k in ("DEG", "RAD", "GRAD"):
            self.angle_mode = k
            return "mode", self.current, k

        # ── Constants ────────────────────────────────────────
        consts = {
            "π":    math.pi,
            "e":    math.e,
            "φ":    (1 + math.sqrt(5)) / 2,
            "Rand": random.random(),
        }
        if k in consts:
            self.current = self.fmt(consts[k])
            self.new_num = False
            return "display", self.current, k

        # ── Digits & decimal point ────────────────────────────
        if k.isdigit() or k == ".":
            if self.new_num:
                self.current = "0." if k == "." else k
                self.new_num = False
            else:
                if k == "." and "." in self.current:
                    return "display", self.current, self.expr
                if self.current == "0" and k != ".":
                    self.current = k
                else:
                    self.current += k
            return "display", self.current, self.expr

        # ── Unary functions ──────────────────────────────────
        UNARY = {
            "x²":   lambda x: x ** 2,
            "x³":   lambda x: x ** 3,
            "√":    math.sqrt,
            "∛":    lambda x: math.copysign(abs(x) ** (1/3), x),
            "1/x":  lambda x: 1 / x,
            "x!":   lambda x: float(math.factorial(int(x))),
            "±":    lambda x: -x,
            "%":    lambda x: x / 100,
            "sin":  lambda x: math.sin(self._rad(x)),
            "cos":  lambda x: math.cos(self._rad(x)),
            "tan":  lambda x: math.tan(self._rad(x)),
            "sin⁻¹":lambda x: self._inv_angle(math.asin(x)),
            "cos⁻¹":lambda x: self._inv_angle(math.acos(x)),
            "tan⁻¹":lambda x: self._inv_angle(math.atan(x)),
            "sinh": math.sinh,
            "cosh": math.cosh,
            "tanh": math.tanh,
            "ln":   math.log,
            "log":  math.log10,
            "log₂": math.log2,
            "eˣ":   math.exp,
            "10ˣ":  lambda x: 10 ** x,
            "2ˣ":   lambda x: 2 ** x,
            "abs":  abs,
            "ceil": math.ceil,
            "floor":math.floor,
        }
        if k in UNARY:
            x = float(self.current)
            r = UNARY[k](x)
            self.expr    = f"{k}({self._n(x)}) ="
            self.current = self.fmt(r)
            self.new_num = True
            self.history.append(f"{self.expr} {self.current}")
            if len(self.history) > 50:
                self.history = self.history[-50:]
            return "display", self.current, self.expr

        # ── Binary operators ─────────────────────────────────
        BINARY_OPS = {"+", "−", "-", "×", "÷", "^", "xⁿ", "ˣ√y", "mod", "nCr", "nPr"}
        if k in BINARY_OPS:
            v = float(self.current)
            if self.operand1 is not None and not self.new_num:
                # Chain: apply pending operation first
                r = self._bin(self.operand1, self.operator, v)
                self.current  = self.fmt(r)
                self.operand1 = r
            else:
                self.operand1 = v
            self.operator = k
            self.expr     = f"{self.fmt(self.operand1)} {k}"
            self.new_num  = True
            return "display", self.current, self.expr

        # ── Equals ───────────────────────────────────────────
        if k == "=":
            if self.operand1 is not None and self.operator is not None:
                v2  = float(self.current)
                r   = self._bin(self.operand1, self.operator, v2)
                exp = f"{self.fmt(self.operand1)} {self.operator} {self.fmt(v2)} ="
                self.history.append(f"{exp} {self.fmt(r)}")
                if len(self.history) > 50:
                    self.history = self.history[-50:]
                self.current  = self.fmt(r)
                self.expr     = exp
                self.operand1 = None
                self.operator = None
                self.new_num  = True
                return "result", self.current, exp
            return "display", self.current, self.expr

        return "display", self.current, self.expr

    def _bin(self, a, op, b):
        ops = {
            "+":    lambda x, y: x + y,
            "−":    lambda x, y: x - y,
            "-":    lambda x, y: x - y,
            "×":    lambda x, y: x * y,
            "÷":    lambda x, y: x / y,
            "^":    lambda x, y: x ** y,
            "xⁿ":   lambda x, y: x ** y,
            "ˣ√y":  lambda x, y: y ** (1 / x),
            "mod":  lambda x, y: x % y,
            "nCr":  lambda x, y: float(math.comb(int(x), int(y))),
            "nPr":  lambda x, y: float(math.perm(int(x), int(y))),
        }
        if op not in ops:
            raise ValueError(f"Unknown operator: {op}")
        return ops[op](a, b)

    # ── REST API evaluate (for Flask wrapper) ─────────────────
    def evaluate_expr(self, expression: str):
        """Evaluate a raw expression string. Returns (result_str, error_str)."""
        # Simple safe-eval approach for the API
        safe_ns = {
            "__builtins__": {},
            "sin":  lambda x: math.sin(self._rad(x)),
            "cos":  lambda x: math.cos(self._rad(x)),
            "tan":  lambda x: math.tan(self._rad(x)),
            "asin": lambda x: self._inv_angle(math.asin(x)),
            "acos": lambda x: self._inv_angle(math.acos(x)),
            "atan": lambda x: self._inv_angle(math.atan(x)),
            "sinh": math.sinh, "cosh": math.cosh, "tanh": math.tanh,
            "log":  math.log10, "log2": math.log2, "ln": math.log,
            "exp":  math.exp,   "sqrt": math.sqrt,
            "factorial": math.factorial, "abs": abs,
            "ceil": math.ceil, "floor": math.floor,
            "pi": math.pi, "e": math.e,
        }
        expr = (expression
                .replace("×", "*").replace("÷", "/")
                .replace("−", "-").replace("²", "**2")
                .replace("³", "**3").replace("^", "**")
                .replace("π", str(math.pi)))
        try:
            result = eval(expr, safe_ns)          # noqa: S307
            return self.fmt(float(result)), None
        except ZeroDivisionError:
            return None, "Division by zero"
        except Exception as ex:
            return None, str(ex)


# ─────────────────────────────────────────────────────────────────
# ANIMATED 3-D BUTTON
# ─────────────────────────────────────────────────────────────────
class Btn(tk.Canvas):
    STYLE = {
        "num":   (C["btn_num"],  C["btn_num_h"],  "#05052A", C["cyan"],   C["white"]),
        "op":    (C["btn_op"],   C["btn_op_h"],   "#050E1F", C["cyan"],   C["cyan"]),
        "func":  (C["btn_func"], C["btn_func_h"], "#0A051A", C["purple"], C["purple"]),
        "eq":    (C["btn_eq"],   C["btn_eq_h"],   "#001122", C["cyan"],   C["green"]),
        "clear": (C["btn_clr"],  C["btn_clr_h"],  "#1A0000", C["pink"],   C["pink"]),
        "mem":   (C["btn_mem"],  C["btn_mem_h"],  "#030A12", C["gold"],   C["gold"]),
    }

    def __init__(self, parent, text, cmd, style="num", w=68, h=52, **kw):
        super().__init__(parent, width=w, height=h,
                         highlightthickness=0, bd=0, bg=C["bg"], **kw)
        self.txt  = text
        self.cmd  = cmd
        self.s    = style
        self.W    = w
        self.H    = h
        self.hover = False
        self.down  = False

        face, face_h, shadow, glow, fg = self.STYLE.get(style, self.STYLE["num"])
        self.face = face; self.face_h = face_h; self.shadow = shadow
        self.glow = glow; self.fg = fg

        self._draw()
        self.bind("<Enter>",          self._enter)
        self.bind("<Leave>",          self._leave)
        self.bind("<ButtonPress-1>",  self._press_btn)
        self.bind("<ButtonRelease-1>",self._release_btn)

    def _rr(self, x1, y1, x2, y2, r, **kw):
        pts = [x1+r, y1,  x2-r, y1,  x2, y1,    x2, y1+r,
               x2, y2-r,  x2, y2,    x2-r, y2,  x1+r, y2,
               x1, y2,    x1, y2-r,  x1, y1+r,  x1, y1,  x1+r, y1]
        return self.create_polygon(pts, smooth=True, **kw)

    def _draw(self):
        self.delete("all")
        w, h = self.W, self.H
        d  = 0 if self.down else 4
        fc = self.face_h if self.hover else self.face

        # Shadow layer
        if d:
            self._rr(d, d, w, h, 12, fill=self.shadow)

        # Face
        self._rr(0, 0, w-d, h-d, 12, fill=fc)

        # Glow border on hover
        if self.hover or self.down:
            self._rr(0, 0, w-d, h-d, 12, fill="", outline=self.glow, width=2)

        # Top specular
        self._rr(2, 2, w-d-2, (h-d)//4+2, 8, fill="#FFFFFF0A")

        # Label
        cx  = (w-d)/2 + (d*0.6 if self.down else 0)
        cy  = (h-d)/2 + (d*0.6 if self.down else 0)
        fs  = max(9, min(16, 32 - len(self.txt)*2))
        col = self.glow if self.hover else self.fg

        self.create_text(cx, cy, text=self.txt, fill=col,
                         font=("Segoe UI", fs, "bold"), anchor="center")

    def _enter(self, _=None):  self.hover = True;  self._draw()
    def _leave(self, _=None):  self.hover = False; self.down = False; self._draw()

    def _press_btn(self, _=None):
        self.down = True
        self._draw()

    def _release_btn(self, _=None):
        self.down = False
        self._draw()
        if self.cmd:
            self.cmd(self.txt)
        self._ripple()

    def _ripple(self):
        cx, cy = self.W // 2, self.H // 2
        o = self.create_oval(cx-2, cy-2, cx+2, cy+2,
                              outline=self.glow, width=2)
        def ex(r=2):
            self.coords(o, cx-r, cy-r, cx+r, cy+r)
            if r < min(self.W, self.H)//2 + 5:
                self.after(18, lambda: ex(r+4))
            else:
                self.delete(o)
        ex()


# ─────────────────────────────────────────────────────────────────
# DISPLAY
# ─────────────────────────────────────────────────────────────────
class Display(tk.Canvas):
    def __init__(self, parent, w, h):
        super().__init__(parent, width=w, height=h,
                         highlightthickness=0, bd=0, bg=C["bg"])
        self.W = w; self.H = h
        self.main = "0"; self.sub = ""
        self.mode = "DEG"; self.mem = ""
        self._sy  = 0
        self._pts = []
        self._draw()
        self._scan()

    def update_display(self, main, sub, mode, mem):
        self.main = main; self.sub  = sub
        self.mode = mode; self.mem  = mem
        self._burst()
        self._draw()

    def _draw(self):
        self.delete("all")
        w, h = self.W, self.H

        # Gradient background
        for i in range(h):
            t = i / h
            rv = int(7 + t*5); gv = int(7 + t*5); bv = int(21 + t*15)
            self.create_line(0, i, w, i, fill=f"#{rv:02x}{gv:02x}{bv:02x}")

        # Glow borders
        for thick, alpha in [(3, "11"), (2, "22"), (1, "44")]:
            self.create_rectangle(thick, thick, w-thick, h-thick,
                                  outline=f"#00E5FF{alpha}", width=1)

        # Corner ticks
        sz = 8
        for cx, cy, dx, dy in [(0,0,1,1),(w,0,-1,1),(0,h,1,-1),(w,h,-1,-1)]:
            self.create_line(cx, cy, cx+dx*sz, cy,      fill=C["cyan"], width=2)
            self.create_line(cx, cy, cx,       cy+dy*sz, fill=C["cyan"], width=2)

        # Memory label
        if self.mem:
            self.create_text(10, 12, text=self.mem,
                             fill=C["gold"], font=("Consolas", 9, "bold"),
                             anchor="w")

        # Mode badge
        bc = {"DEG":"#004488","RAD":"#440088","GRAD":"#004400"}.get(self.mode, "#004488")
        self.create_rectangle(w-52, 5, w-6, 21, fill=bc, outline=C["cyan"])
        self.create_text(w-29, 13, text=self.mode,
                         fill=C["cyan"], font=("Consolas", 9, "bold"))

        # Expression sub-line
        self.create_text(w-10, 34, text=self.sub,
                         fill=C["disp_sub"], font=("Consolas", 12), anchor="e")

        # Main number
        fs = max(18, min(40, 40 - max(0, len(self.main)-7)*2))
        self.create_text(w-10, h-16, text=self.main,
                         fill=C["disp_text"],
                         font=("Consolas", fs, "bold"), anchor="se")

        # Cursor blink
        self.create_rectangle(w-12, h-10, w-8, h-8, fill=C["cyan"])

        # Scan-line
        self.create_line(0, self._sy % h, w, self._sy % h,
                         fill="#FFFFFF09", width=2)

        # Particles
        for px, py, pc, pr in self._pts:
            if pr > 0:
                self.create_oval(px-pr, py-pr, px+pr, py+pr,
                                 fill=pc, outline="")

    def _scan(self):
        self._sy += 3
        self._draw()
        self.after(40, self._scan)

    def _burst(self):
        cols = [C["cyan"], C["purple"], C["green"], C["pink"]]
        for _ in range(6):
            self._pts.append([
                random.randint(10, self.W-10),
                random.randint(10, self.H-10),
                random.choice(cols),
                random.uniform(1.5, 3.5),
            ])
        self._fade(0)

    def _fade(self, step):
        if step > 10:
            self._pts.clear(); return
        self._pts = [[px, py, pc, max(0, pr-0.35)]
                     for px, py, pc, pr in self._pts]
        self.after(45, lambda: self._fade(step+1))


# ─────────────────────────────────────────────────────────────────
# HISTORY WINDOW
# ─────────────────────────────────────────────────────────────────
class HistWin(tk.Toplevel):
    def __init__(self, root, hist):
        super().__init__(root)
        self.title("History")
        self.configure(bg=C["bg"])
        self.geometry("380x520")
        self.resizable(False, False)

        tk.Label(self, text="📋  CALCULATION HISTORY",
                 bg=C["bg"], fg=C["cyan"],
                 font=("Consolas", 13, "bold")).pack(pady=10)

        frm = tk.Frame(self, bg=C["bg_mid"])
        frm.pack(fill="both", expand=True, padx=10, pady=4)

        sb = tk.Scrollbar(frm, bg=C["bg"])
        sb.pack(side="right", fill="y")

        lb = tk.Listbox(frm, bg=C["bg_mid"], fg=C["disp_text"],
                        font=("Consolas", 11),
                        selectbackground=C["cyan"]+"44",
                        selectforeground=C["cyan"],
                        yscrollcommand=sb.set, bd=0, highlightthickness=0)
        lb.pack(fill="both", expand=True)
        sb.config(command=lb.yview)

        for h in reversed(hist[-50:]):
            lb.insert("end", " " + h)

        tk.Button(self, text="✕  Close",
                  bg=C["btn_clr"], fg=C["pink"],
                  font=("Segoe UI", 11, "bold"),
                  relief="flat", bd=0, cursor="hand2",
                  command=self.destroy,
                  padx=14, pady=6).pack(pady=10)


# ─────────────────────────────────────────────────────────────────
# STAR-FIELD CANVAS
# ─────────────────────────────────────────────────────────────────
class Stars(tk.Canvas):
    def __init__(self, parent, w, h):
        super().__init__(parent, width=w, height=h,
                         highlightthickness=0, bd=0, bg=C["bg"])
        self.W = w; self.H = h; self._t = 0
        self.stars = [
            (random.randint(0, w), random.randint(0, h),
             random.uniform(0.3, 1.5), random.uniform(0, 6.28))
            for _ in range(140)
        ]
        self._anim()

    def _anim(self):
        self.delete("all")
        self._t += 0.03
        for x, y, r, ph in self.stars:
            a  = 0.4 + 0.6 * math.sin(self._t + ph)
            v  = int(a * 210)
            col = f"#{v:02x}{v:02x}{min(255, v+30):02x}"
            self.create_oval(x-r, y-r, x+r, y+r, fill=col, outline="")
        self.after(55, self._anim)


# ─────────────────────────────────────────────────────────────────
# MAIN APP
# ─────────────────────────────────────────────────────────────────
class PhantomCalc:
    SCI = [
        [("MC","mem"),  ("MR","mem"),  ("M+","mem"),  ("M-","mem"),  ("MS","mem")],
        [("DEG","func"),("RAD","func"),("π","func"),   ("e","func"),  ("φ","func")],
        [("x²","func"), ("x³","func"), ("xⁿ","op"),   ("√","func"),  ("∛","func")],
        [("sin","func"),("cos","func"),("tan","func"), ("sin⁻¹","func"),("cos⁻¹","func")],
        [("tan⁻¹","func"),("sinh","func"),("cosh","func"),("tanh","func"),("1/x","func")],
        [("ln","func"), ("log","func"),("log₂","func"),("eˣ","func"),("10ˣ","func")],
        [("x!","func"), ("mod","op"),  ("nCr","func"), ("nPr","func"),("Rand","func")],
        [("abs","func"),("ceil","func"),("floor","func"),("ˣ√y","op"),("2ˣ","func")],
    ]
    BASIC = [
        [("AC","clear"), ("⌫","clear"), ("%","func"),  ("÷","op")],
        [("7","num"),    ("8","num"),   ("9","num"),   ("×","op")],
        [("4","num"),    ("5","num"),   ("6","num"),   ("−","op")],
        [("1","num"),    ("2","num"),   ("3","num"),   ("+","op")],
        [("±","func"),   ("0","num"),   (".","num"),   ("=","eq")],
    ]

    def __init__(self, root):
        self.root = root
        self.eng  = Engine()
        self._sci = True
        self._setup()
        self._ui()

    def _setup(self):
        self.root.title("NOVA CALCX  ◈  3D Holographic")
        self.root.configure(bg=C["bg"])
        self.root.resizable(False, False)
        W, H = 528, 870
        x = (self.root.winfo_screenwidth()  - W) // 2
        y = (self.root.winfo_screenheight() - H) // 2
        self.root.geometry(f"{W}x{H}+{x}+{y}")

    def _ui(self):
        Stars(self.root, 528, 870).place(x=0, y=0)

        # ── Title bar ────────────────────────────────────────
        tb = tk.Frame(self.root, bg=C["bg"])
        tb.place(x=0, y=0, width=528, height=46)

        tk.Label(tb, text="◈  NOVA CALCX",
                 bg=C["bg"], fg=C["cyan"],
                 font=("Consolas", 14, "bold")).pack(side="left", padx=14, pady=8)

        hist_lbl = tk.Label(tb, text="📋",
                             bg=C["bg"], fg=C["gold"],
                             font=("Segoe UI", 15), cursor="hand2")
        hist_lbl.pack(side="right", padx=6)
        hist_lbl.bind("<Button-1>", self._hist)

        self.mode_lbl = tk.Label(tb, text="⊟ BASIC",
                                  bg=C["btn_func"], fg=C["purple"],
                                  font=("Consolas", 10, "bold"),
                                  cursor="hand2", padx=8, pady=4)
        self.mode_lbl.pack(side="right", padx=4, pady=6)
        self.mode_lbl.bind("<Button-1>", self._toggle)

        # ── Display ──────────────────────────────────────────
        self.disp = Display(self.root, 508, 112)
        self.disp.place(x=10, y=52)

        # ── Scientific pad ───────────────────────────────────
        self.sci_fr = tk.Frame(self.root, bg=C["bg"])
        self.sci_fr.place(x=10, y=174)
        self._mk_pad(self.sci_fr, self.SCI, bw=97, bh=46)

        # ── Basic pad ────────────────────────────────────────
        self.bas_fr = tk.Frame(self.root, bg=C["bg"])
        self.bas_fr.place(x=10, y=594)
        self._mk_pad(self.bas_fr, self.BASIC, bw=120, bh=54)

        # ── Watermark ────────────────────────────────────────
        tk.Label(self.root,
                 text="Phantom ✦  KPR Institute of Engineering & Technology",
                 bg=C["bg"], fg=C["text_dim"],
                 font=("Consolas", 7)).place(x=0, y=852, width=528)

        self._bind_keys()

    def _mk_pad(self, fr, layout, bw, bh):
        for w in fr.winfo_children():
            w.destroy()
        for r, row in enumerate(layout):
            for cc, (lbl, sty) in enumerate(row):
                Btn(fr, lbl, self._press, style=sty, w=bw, h=bh).grid(
                    row=r, column=cc, padx=2, pady=2)

    def _press(self, k):
        kind, main, sub = self.eng.press(k)
        mem = f"M = {self.eng.fmt(self.eng.memory)}" if self.eng.memory else ""
        self.disp.update_display(main, sub, self.eng.angle_mode, mem)

    def _toggle(self, _=None):
        if self._sci:
            self._sci = False
            self.mode_lbl.config(text="⊞ SCI")
            self.sci_fr.place_forget()
            self.bas_fr.place(x=10, y=174)
        else:
            self._sci = True
            self.mode_lbl.config(text="⊟ BASIC")
            self.sci_fr.place(x=10, y=174)
            self.bas_fr.place(x=10, y=594)

    def _hist(self, _=None):
        HistWin(self.root, self.eng.history)

    def _bind_keys(self):
        km = {
            "0":"0","1":"1","2":"2","3":"3","4":"4",
            "5":"5","6":"6","7":"7","8":"8","9":"9",
            "plus":"+", "minus":"−", "asterisk":"×", "slash":"÷",
            "Return":"=", "KP_Enter":"=", "equal":"=",
            "BackSpace":"⌫", "Delete":"AC", "period":".",
            "percent":"%", "parenleft":"(", "parenright":")",
        }
        for ev, k in km.items():
            self.root.bind(f"<{ev}>", lambda e, val=k: self._press(val))


# ─────────────────────────────────────────────────────────────────
# FLASK API WRAPPER  (used by Docker / Render / Railway)
# ─────────────────────────────────────────────────────────────────
def create_flask_app():
    """Returns a Flask WSGI app that wraps the Engine."""
    try:
        from flask import Flask, request, jsonify, send_from_directory
        import os
    except ImportError:
        print("Flask not installed. Install with: pip install flask")
        sys.exit(1)

    flask_app = Flask(__name__)
    engine    = Engine()

    @flask_app.route("/health")
    def health():
        return jsonify({"status": "ok", "service": "nova-calcx"})

    @flask_app.route("/calc", methods=["POST"])
    def calc():
        data = request.get_json(silent=True) or {}
        expr = data.get("expression", "")
        if not expr:
            return jsonify({"error": "No expression provided"}), 400
        result, err = engine.evaluate_expr(expr)
        if err:
            return jsonify({"error": err}), 422
        return jsonify({"result": result, "expression": expr})

    @flask_app.route("/press", methods=["POST"])
    def press_key():
        data = request.get_json(silent=True) or {}
        key  = data.get("key", "")
        if not key:
            return jsonify({"error": "No key provided"}), 400
        kind, main, sub = engine.press(key)
        return jsonify({
            "kind":   kind,
            "value":  main,
            "sub":    sub,
            "mode":   engine.angle_mode,
            "memory": engine.memory,
        })

    @flask_app.route("/", defaults={"path": ""})
    @flask_app.route("/<path:path>")
    def serve_web(path):
        web_dir = os.path.join(os.path.dirname(__file__), "public", "web")
        if os.path.exists(os.path.join(web_dir, path)) and path:
            return send_from_directory(web_dir, path)
        return send_from_directory(web_dir, "index.html")

    return flask_app


# ─────────────────────────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────────────────────────
def main():
    root = tk.Tk()
    try:
        from ctypes import windll
        windll.shcore.SetProcessDpiAwareness(1)
    except Exception:
        pass
    PhantomCalc(root)
    root.mainloop()


# This is what gunicorn uses: gunicorn calculator:app
app = create_flask_app() if "--api" not in sys.argv else None

if __name__ == "__main__":
    if "--api" in sys.argv:
        # Headless API mode (no display needed)
        flask_app = create_flask_app()
        port = int(sys.argv[sys.argv.index("--port")+1]) if "--port" in sys.argv else 8000
        flask_app.run(host="0.0.0.0", port=port, debug=False)
    else:
        main()
