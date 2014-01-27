@echo off
set THEDIR=%CD%

echo Info: Run the script from cygwin "$HOME" folder
echo Info: with elevated permissions (for mklink call)
echo Info: Directories will be junctions, files - simlinks
echo Info: MSys "$HOME" folder is a fine target as well,
echo Info: but you must change "cyghome" to something else
echo.

if "%~1"=="" (
	echo Error - please give USERNAME
	echo Usage: mklinks.bat USERNAME
	goto end
)

echo :: Working in %CD%..
echo.

@rem Directories inside Users/%1
FOR %%i IN (Documents Desktop Pictures Dropbox Downloads) DO (
	if NOT EXIST %%i (
		mklink /J %%i C:\Users\%1\%%i
	) else (
		echo %%i already existed
	)
)

echo.

@rem The Users/%1 dir
if NOT EXIST %1 (
	mklink /J %1 C:\Users\%1
) else (
	echo %1 already existed
)

echo.

@rem Files
if NOT EXIST .gitconfig (
	mklink .gitconfig C:\Users\%1\.gitconfig
) else (
	echo .gitconfig already existed
)

echo.

@rem Outside cygwin's root
cd C:\Users\%1
echo :: Working in %CD%..
echo.

if NOT EXIST cyghome (
	mklink /J cyghome "%THEDIR%"
) else (
	echo cyghome already existed
)

@rem Return to starting directory
cd %THEDIR%

:end
echo.
cd %THEDIR%

