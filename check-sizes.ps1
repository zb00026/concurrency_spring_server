$dirs = @(
  'C:\Users\1\.gradle\caches\modules-2',
  'C:\Users\1\.gradle\caches\8.10.2',
  'C:\Users\1\.gradle\wrapper\dists'
)
foreach ($d in $dirs) {
  $sum = (Get-ChildItem -Recurse -File $d | Measure-Object -Property Length -Sum).Sum
  "{0}  {1:N0} MB" -f $d, ($sum / 1MB)
}
