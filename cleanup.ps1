# stop app if app.pid exists
if (Test-Path "app.pid") {
  $pid = Get-Content "app.pid" -ErrorAction SilentlyContinue
  if ($pid) {
    try { Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue } catch {}
  }
  Remove-Item "app.pid" -ErrorAction SilentlyContinue
}
