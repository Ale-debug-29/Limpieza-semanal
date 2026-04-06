# Limpieza-semanal

Este es un pequeño script con adicion de una tarea programada para que nos limmpie los archivos temporales cada lunes a las 3:00 y que se ejecute automaticamente como una tarea programada de Windows para ello debemos seguri las siguientes instrucciones.

1. En el equipo donde quieras instalarlo, descarga "Instalar-LimpiezaSemanal.ps1"
2. Ejecútalo como Administrador — hace todo solo
Listo, cada lunes a las 03:00 se ejecuta automáticamente aunque no haya nadie conectado, porque corre como SYSTEM

Un detalle importante: la tarea corre como SYSTEM en lugar de como tu usuario, lo que significa que tiene permisos máximos y funciona aunque el equipo esté en la pantalla de login sin ningún usuario conectado.
