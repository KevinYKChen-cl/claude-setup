@echo off
rem Open the Scotty beads board; see scotty.ps1.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scotty.ps1" %*
