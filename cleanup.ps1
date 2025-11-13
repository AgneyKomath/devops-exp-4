# stop app if app.pid exists
if (Test-Path "app.pid") {
  $appPid = Get-Content "app.pid" -ErrorAction SilentlyContinue
  if ($appPid) {
    try { Stop-Process -Id $appPid -Force -ErrorAction SilentlyContinue } catch {}
  }
  Remove-Item "app.pid" -ErrorAction SilentlyContinue
}
