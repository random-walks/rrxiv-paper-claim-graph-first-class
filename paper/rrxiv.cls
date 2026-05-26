% rrxiv.cls -- rrxiv paper class v0.7
%
% Provides a LaTeX class for rrxiv submissions. Extends `article` with
% semantic environments that the rrxiv parser extracts into the Canonical
% Intermediate Representation (CIR) without requiring post-hoc OCR.
%
% v0.7 (2026-05-26, RRP-0026): \rrxivauthor gains four new keys for the
% gold-standard agent attribution shape — `model-name`, `model-vendor`,
% `model-series`, `model-version`, `model-release-pin`. The previous
% `model-slug` key (v0.6, RRP-0025) is kept as a deprecated alias for
% `model-release-pin` so existing papers don't break. Agent authors
% SHOULD set Name to the full marketing identifier ("Claude Opus 4.7"),
% with model-name matching it for the single-model case.
%
% v0.6 (2026-05-26, RRP-0021 + RRP-0025): new \rrxivauthor macro for
% structured author records with role/ORCID/agent-handle/provenance keys.
% Authors call \rrxivauthor[k=v,...]{Name} for each author; the macro
% emits a pipe-separated RRXIV:author:<n>|... line to the sidecar in
% declaration order, and falls through to authblk's \author{} so the
% rendered title block stays visual. Plain \author{...} continues to
% work as a fallback.
%
% v0.5 (2026-05-25): \RequirePackage{tikz} + \usetikzlibrary{calc} at
% class level so geometric figures don't need preamble boilerplate.
%
% v0.4 (2026-05-25): \RequirePackage{float} for [H] figure placement.
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
\ProvidesClass{rrxiv}[2026/05/26 v0.7 rrxiv paper class]

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
\RequirePackage{keyval}     % for \rrxivauthor[k=v,...]{Name} (v0.6)
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
% v0.6: open the sidecar at class-load time so preamble macros
% (like \rrxivauthor) can write to it before \begin{document}. The
% RRXIV:meta:* lines still emit at \AtBeginDocument because they need
% the metadata commands to have run.
\immediate\openout\rrxiv@sidecar=\jobname.rrxiv.aux\relax
\AtBeginDocument{%
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

% ---- Structured author records (v0.6, RRP-0021 + RRP-0025) ----
%
% \rrxivauthor[k=v,...]{Display Name}
%
% Accepted keys (all optional except the positional Name):
%   orcid                  ORCID iD (0000-XXXX-XXXX-XXXX form)
%   role                   author | coauthor | translator | editor | encoder | agent
%   handle                 agent handle (e.g. `agent:claude-opus-4.7`); implies is-agent=true
%   is-agent               true|false (default false)
%   affiliation            free-form institution
%   email                  contact email
%   model-slug             RRP-0025 vendor model identifier (lowercased, hyphens)
%   model-family           RRP-0025 coarse family (`claude`, `gpt`, `gemini`, ...)
%   model-release-date     YYYY-MM-DD
%   inference-environment  free-form (`Claude Code CLI`, etc.)
%
% Emits one pipe-separated line per call to the sidecar:
%   RRXIV:author:<n>|name=...|orcid=...|role=...|...
% Empty fields are still emitted as `key=`; the parser strips them.
%
% Falls through to authblk's \author{Name} so the visible title block
% still renders. Authors who prefer the plain \author{X \and Y \and Z}
% form can use that instead — the parser then falls back to merging
% rrxiv-meta.json's authors[] array onto the parsed names by name-match.
\newcounter{rrxiv@author@count}
\setcounter{rrxiv@author@count}{0}

\define@key{rrxiv@author}{orcid}{\def\rrxiv@author@orcid{#1}}
\define@key{rrxiv@author}{role}{\def\rrxiv@author@role{#1}}
\define@key{rrxiv@author}{handle}{\def\rrxiv@author@handle{#1}}
\define@key{rrxiv@author}{is-agent}{\def\rrxiv@author@isagent{#1}}
\define@key{rrxiv@author}{affiliation}{\def\rrxiv@author@affiliation{#1}}
\define@key{rrxiv@author}{email}{\def\rrxiv@author@email{#1}}
% v0.7: model-name + vendor + series + version + release-pin are the
% RRP-0026 fields. model-slug is kept as a deprecated alias for
% release-pin so v0.6 papers don't break.
\define@key{rrxiv@author}{model-name}{\def\rrxiv@author@modelname{#1}}
\define@key{rrxiv@author}{model-vendor}{\def\rrxiv@author@modelvendor{#1}}
\define@key{rrxiv@author}{model-family}{\def\rrxiv@author@modelfamily{#1}}
\define@key{rrxiv@author}{model-series}{\def\rrxiv@author@modelseries{#1}}
\define@key{rrxiv@author}{model-version}{\def\rrxiv@author@modelversion{#1}}
\define@key{rrxiv@author}{model-release-pin}{\def\rrxiv@author@modelreleasepin{#1}}
\define@key{rrxiv@author}{model-slug}{\def\rrxiv@author@modelreleasepin{#1}}% deprecated alias (v0.6)
\define@key{rrxiv@author}{model-release-date}{\def\rrxiv@author@modelrelease{#1}}
\define@key{rrxiv@author}{inference-environment}{\def\rrxiv@author@infenv{#1}}

\newcommand{\rrxivauthor}[2][]{%
  % Reset all keys to empty before each call so prior \rrxivauthor's
  % keys don't leak into this one.
  \def\rrxiv@author@orcid{}%
  \def\rrxiv@author@role{}%
  \def\rrxiv@author@handle{}%
  \def\rrxiv@author@isagent{}%
  \def\rrxiv@author@affiliation{}%
  \def\rrxiv@author@email{}%
  \def\rrxiv@author@modelname{}%
  \def\rrxiv@author@modelvendor{}%
  \def\rrxiv@author@modelfamily{}%
  \def\rrxiv@author@modelseries{}%
  \def\rrxiv@author@modelversion{}%
  \def\rrxiv@author@modelreleasepin{}%
  \def\rrxiv@author@modelrelease{}%
  \def\rrxiv@author@infenv{}%
  \setkeys{rrxiv@author}{#1}%
  \stepcounter{rrxiv@author@count}%
  \immediate\write\rrxiv@sidecar{%
RRXIV:author:\arabic{rrxiv@author@count}|name=#2|orcid=\rrxiv@author@orcid|role=\rrxiv@author@role|handle=\rrxiv@author@handle|is_agent=\rrxiv@author@isagent|affiliation=\rrxiv@author@affiliation|email=\rrxiv@author@email|model_name=\rrxiv@author@modelname|model_vendor=\rrxiv@author@modelvendor|model_family=\rrxiv@author@modelfamily|model_series=\rrxiv@author@modelseries|model_version=\rrxiv@author@modelversion|model_release_pin=\rrxiv@author@modelreleasepin|model_release_date=\rrxiv@author@modelrelease|inference_environment=\rrxiv@author@infenv%
  }%
  % Render via authblk's \author so the visible title block still has
  % the name. authblk handles repeated \author{} calls correctly.
  \author{#2}%
}

% ---- Convenience macros consistent with common math notation ----
\newcommand{\R}{\mathbb{R}}
\newcommand{\N}{\mathbb{N}}
\newcommand{\Z}{\mathbb{Z}}
\newcommand{\E}{\mathbb{E}}
\newcommand{\Prob}{\mathbb{P}}
\newcommand{\1}{\mathbf{1}}

% ---- Done ----
\endinput
