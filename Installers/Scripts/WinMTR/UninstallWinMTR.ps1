$TargetDirectory = "C:\Tools\WinMTR"

if (Test-Path -LiteralPath $TargetDirectory) {
  Remove-Item -LiteralPath $TargetDirectory -Recurse -Force
}

exit 0