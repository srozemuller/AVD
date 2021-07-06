param (
$sysprep,
$arg
)
Start-Process -FilePath $sysprep -ArgumentList $arg
