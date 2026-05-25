% rrxiv.cls -- rrxiv paper class v0.3
%
% Provides a LaTeX class for rrxiv submissions. Extends `article` with
% semantic environments that the rrxiv parser extracts into the Canonical
% Intermediate Representation (CIR) without requiring post-hoc OCR.
%
% v0.3 (2026-05-25): visible page-stamp footer. Every page now carries
% the canonical paper id, version, license, build date, and page number
% in a small footer rule. Lets a reader holding a printed PDF know which
% rrxiv revision they're looking at — important when multiple versions
% of the same paper are in circulation. Override the build date with
% \rrxivbuilddate{YYYY-MM-DD} for deterministic builds.
%
% v0.2 (RRP-0002): edge marker delimiter changed from `:` to `|` to
% disambiguate edges whose source/target IDs themselves contain colons
% (which the canonical <paper_id>:claim:<label> convention guarantees).
% Parsers that recognise the v0.1 format continue to work; the rrxiv
% reference parser emits a DeprecationWarning when it sees one.
%
% License: MIT.

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{rrxiv}[2026/05/25 v0.5 rrxiv paper class]

% Pass options to article
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax
\LoadClass[11pt]{article}

% ---- Required packages ----
\RequirePackage[a4paper, margin=1in]{geometry}
\RequirePackage[utf8]{inputenc}
\RequirePackage[T1]{fontenc}
\RequirePackage{amsmath, amsthm, amssymb, mathtools}
\RequirePackage{graphicx}
% `float` provides the [H] placement specifier used by figure/table
% environments that must appear inline (e.g. mid-proof TikZ diagrams).
\RequirePackage{float}
\RequirePackage{xcolor}
% TikZ + the `calc` library covers geometric figures (coordinate
% arithmetic like $(A)!0.5!(B)$ for midpoints). Loading at the class
% level so paper authors don't have to repeat the boilerplate.
\RequirePackage{tikz}
\usetikzlibrary{calc}
\RequirePackage{enumitem}
\RequirePackage[numbers]{natbib}
\RequirePackage{booktabs}
\RequirePackage{authblk}
\RequirePackage[colorlinks=true,
                linkcolor=blue!50!black,
                citecolor=blue!50!black,
                urlcolor=blue!50!black]{hyperref}
\RequirePackage{fancyhdr}
\RequirePackage{lastpage}

% ---- rrxiv metadata commands ----
% These are extracted by the rrxiv parser into CIR top-level fields.
\newcommand{\rrxivid}[1]{\def\@rrxivid{#1}}
\newcommand{\rrxivversion}[1]{\def\@rrxivversion{#1}}
\newcommand{\rrxivprotocolversion}[1]{\def\@rrxivprotocolversion{#1}}
\newcommand{\rrxivlicense}[1]{\def\@rrxivlicense{#1}}
\newcommand{\rrxivtopics}[1]{\def\@rrxivtopics{#1}}
% Build-date stamp shown in the page footer. Defaults to \today in ISO
% format; override with \rrxivbuilddate{2026-05-25} to get a deterministic
% timestamp (useful in CI so the PDF is reproducible across rebuilds).
\newcommand{\rrxivbuilddate}[1]{\def\@rrxivbuilddate{#1}}

% Defaults
\rrxivid{TBD}
\rrxivversion{v1}
\rrxivprotocolversion{0.1.0}
\rrxivlicense{CC-BY-4.0}
\rrxivtopics{}
\rrxivbuilddate{\the\year-\ifnum\month<10 0\fi\the\month-\ifnum\day<10 0\fi\the\day}

% ---- Page-stamp footer (v0.3) ----
% Every page carries the canonical paper id, version, license, build
% date, and page-count in a small footer rule. Style picks:
%   - footnotesize so it never competes with the body text
%   - typewriter (\texttt) on the id so rrxiv:YYYY.MM.NNNNN reads as
%     an identifier, not prose
%   - thin rule above the footer so it's clearly metadata, not content
\pagestyle{fancy}
\fancyhf{}
\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0.4pt}
\fancyfoot[L]{\footnotesize\texttt{\@rrxivid} \textperiodcentered\ \@rrxivversion}
\fancyfoot[C]{\footnotesize\thepage\ /\ \pageref{LastPage}}
\fancyfoot[R]{\footnotesize\@rrxivlicense\ \textperiodcentered\ \@rrxivbuilddate}
% \maketitle redefines page 1 to use the `plain` pagestyle, which would
% strip our footer from the title page (the most-shared page). Override
% `plain` so the stamp survives \maketitle.
\fancypagestyle{plain}{%
  \fancyhf{}%
  \renewcommand{\headrulewidth}{0pt}%
  \renewcommand{\footrulewidth}{0.4pt}%
  \fancyfoot[L]{\footnotesize\texttt{\@rrxivid} \textperiodcentered\ \@rrxivversion}%
  \fancyfoot[C]{\footnotesize\thepage\ /\ \pageref{LastPage}}%
  \fancyfoot[R]{\footnotesize\@rrxivlicense\ \textperiodcentered\ \@rrxivbuilddate}%
}

% ---- Sidecar log channel ----
% The rrxiv parser reads structured metadata from a `.rrxiv.aux` channel
% emitted via \write. This lets us extract claim content without re-parsing
% TeX after the fact. The sidecar uses a simple line-based format:
% RRXIV:<kind>:<label>:<json-escaped-content>
%
% v0.1: emit on \begin{...} and \end{...} for tracked environments.
% v0.2: capture content body. For now the parser falls back to source scan.
\newwrite\rrxiv@sidecar
\AtBeginDocument{%
  \immediate\openout\rrxiv@sidecar=\jobname.rrxiv.aux\relax
  \immediate\write\rrxiv@sidecar{RRXIV:meta:id:\@rrxivid}%
  \immediate\write\rrxiv@sidecar{RRXIV:meta:version:\@rrxivversion}%
  \immediate\write\rrxiv@sidecar{RRXIV:meta:protocol:\@rrxivprotocolversion}%
  \immediate\write\rrxiv@sidecar{RRXIV:meta:license:\@rrxivlicense}%
  \immediate\write\rrxiv@sidecar{RRXIV:meta:topics:\@rrxivtopics}%
}
\AtEndDocument{\immediate\closeout\rrxiv@sidecar}

\newcommand{\rrxiv@emit}[2]{%
  \immediate\write\rrxiv@sidecar{RRXIV:#1:\@currentlabel}%
}

% ---- Theorem-like environments (visual style) ----
\theoremstyle{definition}
\newtheorem{rrxiv@claim}{Claim}
\newtheorem{rrxiv@evidence}{Evidence}
\newtheorem{rrxiv@observation}{Observation}
\newtheorem{rrxiv@remark}{Remark}
\newtheorem{rrxiv@scope}{Scope}
\newtheorem{rrxiv@openquestion}{Open Question}

% ---- Public semantic environments ----
% Each takes an optional title. Each emits a sidecar marker on \begin so the
% parser can locate it in the source. Claims, in particular, get a stable
% local label that the CIR uses for the claim ID (paper_id:label).

\newenvironment{claim}[1][]{%
  \begin{rrxiv@claim}[#1]%
  \rrxiv@emit{claim}{begin}%
}{%
  \end{rrxiv@claim}%
}

\newenvironment{evidence}[1][]{%
  \begin{rrxiv@evidence}[#1]%
  \rrxiv@emit{evidence}{begin}%
}{%
  \end{rrxiv@evidence}%
}

\newenvironment{observation}[1][]{%
  \begin{rrxiv@observation}[#1]%
  \rrxiv@emit{observation}{begin}%
}{%
  \end{rrxiv@observation}%
}

\newenvironment{rrxivremark}[1][]{%
  \begin{rrxiv@remark}[#1]%
  \rrxiv@emit{remark}{begin}%
}{%
  \end{rrxiv@remark}%
}

\newenvironment{scope}[1][]{%
  \begin{rrxiv@scope}[#1]%
  \rrxiv@emit{scope}{begin}%
}{%
  \end{rrxiv@scope}%
}

\newenvironment{openquestion}[1][]{%
  \begin{rrxiv@openquestion}[#1]%
  \rrxiv@emit{openquestion}{begin}%
}{%
  \end{rrxiv@openquestion}%
}

% ---- Inline edge declarations ----
% These declare typed edges between claims without producing visual output.
% They emit sidecar markers only.

% v0.2: edge marker uses `|` between src and dst (RRP-0002).
\newcommand{\dependson}[2]{\immediate\write\rrxiv@sidecar{RRXIV:edge:depends_on:#1|#2}}
\newcommand{\contradicts}[2]{\immediate\write\rrxiv@sidecar{RRXIV:edge:contradicts:#1|#2}}
\newcommand{\extendsclaim}[2]{\immediate\write\rrxiv@sidecar{RRXIV:edge:extends:#1|#2}}
\newcommand{\supports}[2]{\immediate\write\rrxiv@sidecar{RRXIV:edge:supports:#1|#2}}

% ---- Convenience macros consistent with common math notation ----
\newcommand{\R}{\mathbb{R}}
\newcommand{\N}{\mathbb{N}}
\newcommand{\Z}{\mathbb{Z}}
\newcommand{\E}{\mathbb{E}}
\newcommand{\Prob}{\mathbb{P}}
\newcommand{\1}{\mathbf{1}}

% ---- Done ----
\endinput
