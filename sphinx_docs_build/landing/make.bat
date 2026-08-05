@ECHO OFF

pushd %~dp0

REM Command file for the Sphinx landing page

if "%SPHINXBUILD%" == "" (
	set SPHINXBUILD=sphinx-build
)
set SOURCEDIR=source
set OUTPUTDIR=../../docs
set DOCTREEDIR=.doctrees

%SPHINXBUILD% >NUL 2>NUL
if errorlevel 9009 (
	echo.
	echo.The 'sphinx-build' command was not found. Make sure Sphinx is installed.
	echo.If you don't have Sphinx installed, visit https://www.sphinx-doc.org/
	exit /b 1
)

if "%1" == "" goto html
if "%1" == "html" goto html

:html
%SPHINXBUILD% -b html -d %DOCTREEDIR% %SPHINXOPTS% %SOURCEDIR% %OUTPUTDIR%
goto end

:end
popd