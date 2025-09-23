# ruff: noqa: F403, F405
from sympy import *
from latex2sympy2 import latex2sympy as parse_latex

def parse_equation(latex_str: str):
    """
    Parse a LaTeX string into either a SymPy expression or Eq.
    Splits on '=' that is not inside curly braces.
    """
    depth = 0
    eq_index = None

    # latex_str = latex_str.replace("&", "")
    latex_str = latex_str.replace(r"\log", r"\ln")

    for i, ch in enumerate(latex_str):
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth = max(depth - 1, 0)
        elif ch == "=" and depth == 0:
            eq_index = i
            break  # first top-level '='

    if eq_index is None:
        # no top-level '=', parse as expression
        return parse_latex(latex_str)

    left_str = latex_str[:eq_index]
    right_str = latex_str[eq_index + 1:]
    left_expr = parse_latex(left_str.strip())
    right_expr = parse_latex(right_str.strip())
    return Eq(left_expr, right_expr)

def diff_equation(latex_str: str, var: str):
    """
    Parse a LaTeX string into either a SymPy expression or Eq.
    Splits on '=' that is not inside curly braces.
    """
    depth = 0
    eq_index = None

    latex_str = latex_str.replace("&", "")
    var = parse_latex(var)

    for i, ch in enumerate(latex_str):
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth = max(depth - 1, 0)
        elif ch == "=" and depth == 0:
            eq_index = i
            break  # first top-level '='

    if eq_index is None:
        # no top-level '=', parse as expression
        expr = parse_latex(latex_str)
        return diff(expr, var)

    left_str = latex_str[:eq_index]
    right_str = latex_str[eq_index + 1:]
    left_expr = parse_latex(left_str.strip())
    right_expr = parse_latex(right_str.strip())
    left_diff = diff(left_expr, var)
    right_diff = diff(right_expr, var)
    return Eq(left_diff, right_diff)

if __name__ == "__main__":
    latex = "x^{2} =& 2x"
    latex = "x^{2}"
    diff = diff_equation(latex, "x")
    print(f"Diff {latex} : {diff}")
    
