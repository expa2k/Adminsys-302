#Ruta donde guardas los scripts
. .\funcionescorreo.ps1



$running = $true
while($running){
    Write-Host "Configuracion de servidor de correo, Selecciona una opcion [1-5]"
    Write-Host "[1] Instalar mercury"
    Write-Host "[2] Configurar usuarios"
    Write-Host "[3] Instalar squirrelmail"
    Write-Host "[4] Salir"
    $opc = Read-Host "Opcion:"
    switch($opc){
        '1'{
            InstalarMercury
        }
        '2'{
            Write-Host "Abre la ventana de Mercury Ve a Configuration -> Magae Local Users -> Add y ahi creas el usuario"
        }
        '3'{
            instalarsquirrel
        }
        '4'{
            Write-Host "Saliendo..."
            $running = false
        }
    }

}

