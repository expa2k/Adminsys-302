#!/bin/bash

source ./ftpfunciones.sh


menu_principal() {
    while true; do
        show_menu
        read -r opcion
        case $opcion in
            1) 
                while true; do
                    read -p "Ingresa el nombre del usuario: " nombreUsuario
                    if userValid "$nombreUsuario"; then
                        break
                    fi
                    echo "usuario no valido, ingrese uno valido por favor."
                done
                
                while true; do
                    read -p "Ingrese el grupo (reprobados/recursadores): " nombreGrupo
                    if [[ "$nombreGrupo" == "reprobados" || "$nombreGrupo" == "recursadores" ]]; then
                        break
                    fi
                    echo "Grupo inválido. Use 'reprobados' o 'recursadores'"
                done
                
                createUser "$nombreUsuario" "$nombreGrupo"
                ;;
            2) 
                clear
                read -p "Ingrese el nombre del usuario: " nombreUsuario
                if ! id "$nombreUsuario" >/dev/null 2>&1; then
                    echo "Error: El usuario $nombreUsuario no existe"
                    continue
                fi
                grupoActual=$(groups "$nombreUsuario" | grep -o -E "reprobados|recursadores" | head -1)
                echo "Grupo actual: $grupoActual"
                
                while true; do
                    read -p "Ingrese el nuevo grupo (reprobados/recursadores): " nuevoGrupo
                    if [[ "$nuevoGrupo" == "reprobados" || "$nuevoGrupo" == "recursadores" ]]; then
                        if [[ "$grupoActual" == "$nuevoGrupo" ]]; then
                            echo "El usuario ya pertenece a ese grupo"
                        else
                            if changeUserGroup "$nombreUsuario" "$nuevoGrupo"; then
                                echo "Cambio de grupo realizado "
                            else
                                echo "Error al cambiar de grupo"
                            fi
                        fi
                        break
                    else
                        echo "Grupo inválido. Use 'reprobados' o 'recursadores'"
                    fi
                done
                ;;
            3) 
                read -p "Ingrese el nombre del usuario a eliminar: " nombreUsuario
                read -p "¿Está seguro de eliminar al usuario '$nombreUsuario'? (s/n): " confirmar
                if [[ "$confirmar" == "s" ]]; then
                    deleteUser "$nombreUsuario"
                fi
                ;;
            4)
                echo "Saliendo"
                exit 0
                ;;
            *)
                echo "Opción inválida"
                ;;
        esac
    done
}
main
menu_principal