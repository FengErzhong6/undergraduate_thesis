@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ------------------------------------------------
rem            LaTeX Automated Compiler
rem                <By Huangrui Mo>
rem Windows wrapper adapted for TeX Live 2024.
rem ------------------------------------------------

rem Prefer the local Windows TeX Live 2024 installation when it exists.
set "TEXLIVE_BIN=D:\texlive\2024\bin\windows"
if exist "%TEXLIVE_BIN%\xelatex.exe" set "PATH=%TEXLIVE_BIN%;%PATH%"

rem ------------------------------------------------
rem ->> Preprocessing
rem ------------------------------------------------
if "%~1"=="" goto :usage
if not "%~3"=="" goto :usage

set "Mode=%~1"

if "%~2"=="" (
    if exist "Thesis.tex" (
        set "SourceFile=Thesis.tex"
    ) else (
        set "SourceFile="
        for %%F in (*.tex) do (
            if not defined SourceFile set "SourceFile=%%~nxF"
        )
    )
) else (
    set "SourceFile=%~2"
)

if not defined SourceFile (
    echo No .tex file found.
    exit /b 1
)

for %%F in ("!SourceFile!") do set "FileName=%%~nF"

if /i not "!Mode:l=!"=="!Mode!" (
    set "TexCompiler=lualatex"
) else if /i not "!Mode:p=!"=="!Mode!" (
    set "TexCompiler=pdflatex"
) else (
    set "TexCompiler=xelatex"
)

if /i not "!Mode:a=!"=="!Mode!" (
    set "BibCompiler=bibtex"
) else if /i not "!Mode:b=!"=="!Mode!" (
    set "BibCompiler=biber"
) else (
    set "BibCompiler="
)

where "!TexCompiler!" >nul 2>nul
if errorlevel 1 (
    echo !TexCompiler! was not found. Check TeX Live path: %TEXLIVE_BIN%
    exit /b 1
)

if defined BibCompiler (
    where "!BibCompiler!" >nul 2>nul
    if errorlevel 1 (
        echo !BibCompiler! was not found. Check TeX Live path: %TEXLIVE_BIN%
        exit /b 1
    )
)

set "Tmp=Tmp"
set "Tex=Tex"
if not exist "%Tmp%\%Tex%" mkdir "%Tmp%\%Tex%"

rem Add project subdirectories to TeX search paths.
set "TEXINPUTS=.//;%TEXINPUTS%"
set "BIBINPUTS=.//;%BIBINPUTS%"
set "BSTINPUTS=.//;%BSTINPUTS%"

rem ------------------------------------------------
rem ->> Compiling
rem ------------------------------------------------
"!TexCompiler!" -synctex=1 -output-directory="%Tmp%" "!SourceFile!" || exit /b 1

if defined BibCompiler (
    rem LaTeX writes included aux files as Tex/*.aux; BibTeX/Biber needs them under Tmp/.
    if exist "%Tmp%\!FileName!.aux" (
        set "ARTX_TMP=%Tmp%"
        set "ARTX_FILE=!FileName!"
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$aux = Join-Path $env:ARTX_TMP ($env:ARTX_FILE + '.aux'); $prefix = $env:ARTX_TMP.Replace('\', '/') + '/'; $text = [IO.File]::ReadAllText($aux); $text = $text.Replace('\@input{', '\@input{' + $prefix); [IO.File]::WriteAllText($aux, $text, [System.Text.UTF8Encoding]::new($false))" || exit /b 1
    )
    "!BibCompiler!" "%Tmp%\!FileName!" || exit /b 1
    "!TexCompiler!" -synctex=1 -output-directory="%Tmp%" "!SourceFile!" || exit /b 1
    "!TexCompiler!" -synctex=1 -output-directory="%Tmp%" "!SourceFile!" || exit /b 1
)

rem ------------------------------------------------
rem ->> Postprocessing
rem ------------------------------------------------
echo ------------------------------------------------
echo !TexCompiler! !BibCompiler! !FileName!.tex finished...
echo ------------------------------------------------
exit /b 0

:usage
echo ------------------------------------------------
echo Usage: %~nx0 ^<l^|p^|x^>[^<a^|b^>] [filename]
echo TeX engine parameters: l=lualatex, p=pdflatex, x=xelatex
echo Bib engine parameters: none, a=bibtex, b=biber
echo Example: %~nx0 xa Thesis.tex
echo ------------------------------------------------
exit /b 1
