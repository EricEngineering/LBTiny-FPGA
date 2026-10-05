@echo off
setlocal

set VIVADO_BIN=C:\Xilinx\Vivado\2024.2\bin
set XVLOG=%VIVADO_BIN%\xvlog.bat
set XELAB=%VIVADO_BIN%\xelab.bat
set XSIM=%VIVADO_BIN%\xsim.bat

set BUILD_DIR=build

:: get the testbench file name
set testbench=%1

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

echo.
echo ===== Compiling Verilog =====
pushd "%BUILD_DIR%"

:: Iterate over all src files and compile the verilog
for /R "..\src\" %%f in (*) do (
    call "%XVLOG%" -sv %%f
    if errorlevel 1 (
        popd
        goto failed
    )
)
:: Compile the testbench
call "%XVLOG%" -sv "..\tb\%testbench%.v"
if errorlevel 1 (
    popd
    goto failed
)

echo.
echo ===== Elaborating =====
call "%XELAB%" %testbench% -s sim -debug typical
if errorlevel 1 (
    popd
    goto failed
)

echo.
echo ===== Running simulation =====
call "%XSIM%" sim -tclbatch ../wave.tcl
if errorlevel 1 (
    popd
    goto failed
)

popd

echo.
echo ===== Simulation succeeded =====

if exist "%BUILD_DIR%\sim.wdb" (
    echo Closing old XSim GUI if open...
    taskkill /IM xsim.exe /F >nul 2>&1

    echo Opening waveform viewer...

	if exist sim.wcfg (
		echo Loading saved waveform config...
		start "" cmd /c "cd /d %CD%\%BUILD_DIR% && call "%XSIM%" --gui sim.wdb -view ..\sim.wcfg"
	) else (
		echo No waveform config found, opening default view...
		start "" cmd /c "cd /d %CD%\%BUILD_DIR% && call "%XSIM%" --gui sim.wdb"
	)

    exit /b 0
) else (
    echo ERROR: %BUILD_DIR%\sim.wdb not found!
    exit /b 1
)

:failed
echo.
echo Simulation FAILED.
exit /b 1