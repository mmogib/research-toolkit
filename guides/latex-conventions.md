# LaTeX Conventions

Mohammed's LaTeX writing style and conventions for mathematics research papers.

## Document Class & Packages

### Standard Setup
```latex
\documentclass[12pt]{article}
\usepackage[utf8]{inputenc}
\usepackage{amsmath,amssymb,amsthm}
\usepackage{mathtools}           % \DeclarePairedDelimiter, etc.
\usepackage[style=numeric,sorting=nyt,backend=biber]{biblatex}
\usepackage{authblk}             % Author affiliations
\usepackage{hyperref}
\usepackage{cleveref}            % \cref for smart cross-references
\usepackage{algorithm,algpseudocode}
\usepackage{booktabs}            % Professional tables
\usepackage{siunitx}             % \num{1.23e-4} for scientific notation
```

### Bibliography
- **Biblatex + Biber** (not BibTeX)
- References managed via Zotero — never add entries manually
- `\addbibresource{references.bib}`
- `\printbibliography` at end

### Reference Papers (`refs/`)
- Store downloaded PDFs of cited papers in `refs/`
- Claude can read these with the Read tool when needed (verify formulas, check proofs, understand referenced algorithms)
- Workflow: Claude asks Mohammed to download a specific paper into `refs/`, then reads it directly
- File naming: use the bib key or a descriptive name (e.g., `ChenYangZhao2023.pdf`, `Gerth_Weidner_1990.pdf`)

## Theorem Environments

### Shared Counter
All theorem-like environments share one counter:
```latex
\newtheorem{theorem}{Theorem}[section]
\newtheorem{lemma}[theorem]{Lemma}
\newtheorem{proposition}[theorem]{Proposition}
\newtheorem{corollary}[theorem]{Corollary}
\newtheorem{assumption}[theorem]{Assumption}

\theoremstyle{definition}
\newtheorem{definition}[theorem]{Definition}
\newtheorem{example}[theorem]{Example}
\newtheorem{problem}{Problem}        % Separate counter for test problems

\theoremstyle{remark}
\newtheorem{remark}[theorem]{Remark}
```

This produces: Theorem 3.1, Lemma 3.2, Proposition 3.3 (sequential within section).

### Labels
```latex
\begin{theorem}\label{thm:main_convergence}
\begin{lemma}\label{lem:usc_dini}
\begin{proposition}\label{prop:stationarity}
\begin{assumption}\label{ass:A1}
\begin{problem}\label{prob:MOP1}
```

## Math Notation

### Operators (always via \DeclareMathOperator)
```latex
\DeclareMathOperator{\dom}{dom}
\DeclareMathOperator{\epi}{epi}
\DeclareMathOperator{\cone}{cone}
\DeclareMathOperator{\conv}{conv}
\DeclareMathOperator{\Int}{int}
\DeclareMathOperator{\cl}{cl}
\DeclareMathOperator{\bd}{bd}
\DeclareMathOperator{\argmin}{arg\,min}
\DeclareMathOperator{\argmax}{arg\,max}
```

### Standard Symbols
| Concept | Symbol | LaTeX |
|---------|--------|-------|
| Real numbers | R^n | `\mathbb{R}^n` |
| Nonneg orthant | R^m_+ | `\mathbb{R}^m_+` |
| Inner product | <x,y> | `\langle x, y \rangle` |
| Norm | \|x\| | `\|x\|` or `\lVert x \rVert` |
| Partial order | ≤_C | `\preceq_C` or `\leq_C` |
| Strict order | <_C | `\prec_C` |
| Subset | ⊆ | `\subseteq` (never `\subset` for non-strict) |
| Cone | C | `C` (upright, not italic for named cones) |
| Ordering cone | C | Context-dependent |
| Jacobian | JF(x) | `JF(x)` |
| Dini derivative | D^+F(x;d) | `D^+F(x;d)` |
| Clarke subdiff | ∂_C f(x) | `\partial_C f(x)` |
| Scalarization | φ | `\varphi` |

### Equation Labels
```latex
\begin{equation}\label{eq:vop}        % Main problem
\begin{equation}\label{eq:subproblem}  % Subproblem
\begin{equation}\label{eq:linesearch}  % Line search condition
\begin{equation}\label{eq:reference}   % Reference update
```

Use `\eqref{eq:vop}` (parenthesized) for equation references.

## Writing Style

### General Principles
- Direct, concise sentences. No filler.
- Present tense for mathematical statements ("Theorem 3.1 shows that...")
- Past tense for experimental observations ("The algorithm converged in 57 iterations")
- Avoid: "it is worth noting that", "it should be mentioned that", "we remark that" — just state the fact
- Avoid: "robust", "crucial", "comprehensive", "fundamental", "notably", "streamline", "leverage"
- No named-paragraphs with bold labels (e.g., avoid "**Convergence.** The algorithm...")
- No excessive bold in body text

### Proof Style
- Start with the key idea, not notation setup
- Cite assumptions explicitly: "By (A3), F is Clarke regular"
- Label cases: "Case (i):", "Case (ii):" (not bold)
- End with \qed or \qedhere

### Lists Before Displays
When a display equation or list follows, end the preceding sentence with a colon:
```latex
The following statements hold:
\begin{enumerate}
    \item ...
\end{enumerate}
```

### Referencing
- Theorems: "Theorem~\ref{thm:main}" or "\cref{thm:main}"
- Equations: "\eqref{eq:vop}" (parenthesized automatically)
- Sections: "Section~\ref{sec:convergence}"
- Figures: "Figure~\ref{fig:convergence}"
- Tables: "Table~\ref{tab:results}"
- Problems: "Problem~\ref{prob:MOP1}"

Use `~` (non-breaking space) before `\ref` and `\eqref`.

## Tables

### Style
```latex
\begin{table}[t]
\centering
\caption{Multi-start results for 48 test problems.}\label{tab:results}
\begin{tabular}{lrrrrrr}
\toprule
Problem & $n$ & $m$ & Success & Med.\ iters & Med.\ $|v|$ & Time (s) \\
\midrule
MOP1 & 2 & 2 & 51/51 & 12 & \num{3.2e-7} & 0.01 \\
...
\bottomrule
\end{tabular}
\end{table}
```

- Use `booktabs` (`\toprule`, `\midrule`, `\bottomrule`) — no vertical lines
- Use `\num{}` from `siunitx` for scientific notation
- Bold best values if comparing methods
- Captions go above tables, below figures

## Figures

### Placement
```latex
\begin{figure}[t]
\centering
\includegraphics[width=\textwidth]{imgs/fig_convergence.pdf}
\caption{Convergence history of $|v(x_k)|$ for three problems under four $\eta_{\max}$ levels.}\label{fig:convergence}
\end{figure}
```

- PDF format for vector graphics (generated by Plots.jl with PGFPlotsX)
- `width=\textwidth` for full-width, `width=0.48\textwidth` for side-by-side
- Captions are self-contained (reader understands without main text)

## Algorithm Environment

```latex
\begin{algorithm}[t]
\caption{Conditional Gradient Method for VOP}\label{alg:condg}
\begin{algorithmic}[1]
\Require $x_0 \in K$, parameters $\sigma_1, \delta, \eta_{\max}, \varepsilon$
\Ensure Approximate stationary point $x^*$
\State Set $\Gamma_0 \gets F(x_0)$, $k \gets 0$
\While{$|v(x_k)| > \varepsilon$ and $k < k_{\max}$}
    \State Solve subproblem: $s_k \gets \argmin_{s \in K} \varphi(D^+F(x_k; s - x_k))$
    \State Set $d_k \gets s_k - x_k$, $v_k \gets \varphi(D^+F(x_k; d_k))$
    \State Find step size $\tau_k$ via nonmonotone line search
    \State Update $x_{k+1} \gets x_k + \tau_k d_k$
    \State Update $\Gamma_{k+1} \gets \eta_{k+1} \Gamma_k + (1 - \eta_{k+1}) F(x_{k+1})$
    \State $k \gets k + 1$
\EndWhile
\end{algorithmic}
\end{algorithm}
```

## Section Structure

### Typical Paper Structure
```
1. Introduction (motivation, contributions)
2. Preliminaries (notation, background, standing definitions)
3. [Theory section — framework, scalarization, etc.]
4. [Algorithm section — method, subproblem, line search]
5. Convergence Analysis (main theorems)
6. Numerical Experiments
   6.1 Test problems
   6.2 Parameter selection
   6.3 Main results
   6.4 Ablation / sensitivity
   6.5 Applications (optional)
   6.6 Extensions (optional)
7. Conclusion
```

### Section Labels
```latex
\section{Introduction}\label{sec:intro}
\section{Preliminaries}\label{sec:prelim}
\section{Numerical Experiments}\label{sec:experiments}
\subsection{Test Problems}\label{SS:problems}
```
