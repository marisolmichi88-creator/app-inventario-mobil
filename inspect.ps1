$svg = [System.IO.File]::ReadAllText("c:\Users\MARI\app-inventario-mobil\assets\icon.svg")
$clean = $svg -replace 'base64,[^"]{100,}', 'base64,...TRUNCATED...'
Write-Output $clean
