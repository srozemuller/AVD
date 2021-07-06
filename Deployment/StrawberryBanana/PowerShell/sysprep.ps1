$sysprep = 'C:\Windows\System32\Sysprep\Sysprep.exe'
$arg = '/generalize /oobe /shutdown /quiet /mode:vm'
Start-Process -FilePath $sysprep -ArgumentList $arg