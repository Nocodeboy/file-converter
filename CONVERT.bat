@echo off
title File Converter
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "CONVERT.ps1"
