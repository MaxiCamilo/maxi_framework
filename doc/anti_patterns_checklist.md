# Checklist de anti patrones y codigo sucio

Fecha: 2026-04-30

Alcance: revision estatica de los proyectos del workspace. Esta lista prioriza problemas verificados por lectura directa de codigo y, cuando aplica, por errores del analizador.

## Criticos

- [ ] Propagar el error real en `disco_total_label/lib/src/server_connectors/create_transaction.dart`
  - Ubicacion: linea 20 y linea 21.
  - Problema: si `ObtainTotals` falla, el metodo devuelve `result.asResultValue()` en lugar de devolver el error.
  - Por que esta mal: convierte un fallo de infraestructura o negocio en un falso exito con un resultado vacio. Eso oculta el problema, rompe la trazabilidad del flujo y puede dejar al llamador tomando decisiones con datos incompletos.
  - Sugerencia: devolver `totalScaleResult.cast()` o propagar el `NegativeResult` correspondiente. Revisar tambien la logica final del metodo porque en la linea 32 vuelve a devolver un resultado vacio sin usar `determinateTotal` ni los campos `pluCommand`, `batchCode` y `boxCode`.

- [ ] Corregir el orden de inicializacion en `maxi_framework/lib/src/win_unix_socket/native_build_win_unix_socket_server.dart`
  - Ubicacion: linea 91 y linea 101.
  - Problema: `_subscription = _socket.stream.listen(...)` se crea antes de inicializar `_receiverController = StreamController<Uint8List>()`.
  - Por que esta mal: si el stream emite de forma inmediata, el callback intenta usar un campo `late` todavia no inicializado y puede terminar en `LateInitializationError`.
  - Sugerencia: crear primero `_receiverController` y despues registrar la suscripcion. Si el constructor puede fallar a mitad de camino, envolver la inicializacion con una secuencia segura o un `try/finally`.

- [ ] Reparar la deriva de API que rompe `maxi_flutter_widgets`
  - Ubicacion: `maxi_flutter_widgets/lib/src/fields/controllers/standar_field_controll.dart`, linea 29 y linea 73.
  - Problema: `onDispose` tiene una firma incompatible con la interfaz esperada y se llama `.select(...)` sobre un `Result`, metodo que ya no existe en la API actual.
  - Por que esta mal: el paquete no compila. Esto ya no es una cuestion de estilo sino una rotura de contrato entre capas del framework.
  - Sugerencia: alinear el controlador con la API vigente de `Disposable` y `Result`. Sustituir `.select(...)` por el helper correcto actual y adaptar `onDispose` al tipo real esperado.

- [ ] Reparar el uso de `heart.lifecycleScope` en `maxi_flutter_widgets/lib/src/fields/text_form.dart`
  - Ubicacion: linea 62 y linea 64.
  - Problema: el widget usa `heart.lifecycleScope` aunque el tipo actual de `heart` ya no expone ese getter.
  - Por que esta mal: el archivo no compila y deja evidencia de que el paquete no fue migrado junto con el framework base.
  - Sugerencia: revisar la API actual de `ReactiveState` y `LifeCoordinator`, y migrar el acceso a la forma vigente de registrar objetos y disposables.

- [ ] Reparar la deriva de API en `maxi_flutter_framework/lib/src/android_service/android_service_connector.dart`
  - Ubicacion: linea 88, linea 93 y linea 129.
  - Problema: se usa `.select(...)` sobre `Result`, se accede `state.index` sin asegurar nulabilidad y se invoca `toFutureResult()` sobre `onDispose` aunque la API actual no lo soporta.
  - Por que esta mal: combina errores de compilacion con supuestos invalidos sobre nulabilidad y ciclo de vida.
  - Sugerencia: migrar este conector a la API actual del framework y revalidar el flujo de parada del servicio con tests o una prueba manual controlada.

## Alta prioridad

- [ ] Eliminar excepciones tragadas en `maxi_framework/lib/src/win_unix_socket/implementation/win_unix_server_socket.dart`
  - Ubicacion: linea 214.
  - Problema: el cleanup del archivo de socket hace `catch (_) {}` y descarta cualquier error.
  - Por que esta mal: si falla el borrado del socket, se pierde diagnostico y pueden quedar archivos huerfanos que rompan conexiones futuras.
  - Sugerencia: registrar el error con contexto o devolver un resultado controlado. Si el fallo es tolerable, al menos dejar trazabilidad.

- [ ] Reemplazar codigo magico en `maxi_framework/lib/src/win_unix_socket/implementation/win_unix_server_socket.dart`
  - Ubicacion: linea 49.
  - Problema: se usa el valor `10004` directamente para distinguir `WSAEINTR`.
  - Por que esta mal: los codigos magicos reducen legibilidad y facilitan errores al mantener FFI o puertos entre plataformas.
  - Sugerencia: extraer una constante con nombre semantico, idealmente junto al resto de constantes de WinSock.

- [ ] Revisar el uso inseguro de `late` en `disco_total_label/lib/src/scale_interaction/commands/command_downloading_totals.dart`
  - Ubicacion: linea 17, linea 18, linea 19 y linea 25.
  - Problema: `lastContext`, `latePluCommand` y `lateAppConfig` son `late`, y su asignacion depende de una condicion operacional antes de que `initialize()` use esos valores.
  - Por que esta mal: si cambia el orden de ejecucion o hay una reentrada no contemplada, aparece un fallo en runtime en vez de un error controlado.
  - Sugerencia: pasar dependencias por constructor o por el metodo de inicializacion, o bien modelarlas como nullable con validacion explicita antes de usarlas.

- [ ] Completar o aislar la implementacion parcial de `maxi_flutter_framework/lib/src/app_managers/flutter_service_manager.dart`
  - Ubicacion: lineas 62 a 103.
  - Problema: metodos clave de una implementacion productiva terminan en `TODO` y `throw UnimplementedError()`.
  - Por que esta mal: la clase aparenta estar lista para uso real, pero varios caminos funcionales explotan en runtime.
  - Sugerencia: o se completa la implementacion o se restringe su exposicion publica mientras siga incompleta. Como minimo, documentar explicitamente las capacidades no soportadas.

- [ ] Completar los stubs de reflexion y serializacion en `maxi_reflection`
  - Ubicacion: `maxi_reflection/lib/src/entities/reflected_entity_implementation.dart`, linea 292 y linea 293; `maxi_reflection/lib/src/types/locals/errors/reflected_local_error_data.dart`, linea 53, linea 54, linea 59 y linea 60.
  - Problema: existen rutas centrales de clonacion, serializacion y construccion de reflectores que terminan en `UnimplementedError`.
  - Por que esta mal: el modulo de reflexion queda parcialmente funcional y falla justo en caminos que parecen nucleares para el framework.
  - Sugerencia: definir primero el contrato esperado de cada metodo y cubrirlo con tests. Si todavia no se va a soportar, ocultar esos caminos o fallar con un `NegativeResult` mas explicito.

- [ ] Completar el administrador de estructura en `maxi_sqlite/lib/src/enginer/sqlite_transaction.dart`
  - Ubicacion: linea 71 y linea 72.
  - Problema: `buildStructureManager()` no esta implementado.
  - Por que esta mal: una transaccion expone una interfaz que promete operaciones de estructura, pero en runtime falla con `UnimplementedError`.
  - Sugerencia: implementar el adaptador real o devolver un objeto no soportado claramente tipado. Evitar exponer una transaccion incompleta como si fuera compatible con toda la interfaz `SqlTransaction`.

- [ ] Completar la inicializacion de base de datos en `disco_total_label/lib/src/database/create_tables_on_database.dart`
  - Ubicacion: linea 6 y linea 7.
  - Problema: `performInitialize()` es un stub.
  - Por que esta mal: el nombre de la clase indica una responsabilidad critica de arranque, pero hoy cualquier uso termina en excepcion.
  - Sugerencia: implementar la creacion real de tablas o retirar la clase del flujo hasta que exista una version funcional.

## Media prioridad

- [ ] Eliminar residuos de depuracion en `maxi_thread/lib/src/isolate/connections/isolate_task_sender.dart`
  - Ubicacion: linea 113.
  - Problema: aparece `log('mmmmm')` dentro de un camino operacional.
  - Por que esta mal: no comunica ninguna intencion tecnica y contamina los logs del sistema.
  - Sugerencia: eliminarlo o reemplazarlo por un mensaje estructurado que describa el estado anomalo real.

- [ ] Limpiar nombres inconsistentes en `maxi_framework`
  - Ubicacion: `maxi_framework/lib/src/app_managers/native_dart/directories/native_folder_operator.dart`, linea 58; `maxi_framework/lib/src/utils/hexadecimal_utilities.dart`, linea 146; `maxi_framework/lib/src/extensions/iteraton_extensions.dart`, linea 4 y linea 52.
  - Problema: aparecen nombres como `newPatch`, `archvio`, `funcion` y `filtre`.
  - Por que esta mal: empeora la legibilidad, aumenta el costo cognitivo y transmite poca disciplina en APIs que probablemente otros paquetes consumen.
  - Sugerencia: normalizar nombres a una sola convencion idiomatica. Si la base va a usar ingles, mantenerla consistente en todo el API publico y privado.

- [ ] Corregir nombres historicos mal escritos en `maxi_thread` y `maxi_reflection`
  - Ubicacion: `maxi_thread/lib/src/extensions/stream_skill_extension.dart`, linea 15 y linea 46; `maxi_reflection/lib/src/entities/reflected_entity_implementation.dart`, linea 292; otras referencias relacionadas a `contructor` aparecen en el modulo de reflexion.
  - Problema: hay nombres como `_buildSteamOnThread`, `contructor` y derivados.
  - Por que esta mal: estos errores terminan propagandose por la API, la documentacion y el codigo generado, lo que hace mas cara cualquier futura limpieza.
  - Sugerencia: planificar una pasada de renombre semantico con soporte del lenguaje para no romper referencias.

- [ ] Reducir ruido y codigo comentado en `maxi_framework/test/maxi_framework_test.dart`
  - Ubicacion: varias lineas, incluyendo 17, 39, 51 y bloques comentados dentro del archivo.
  - Problema: hay `print()` de depuracion y bloques grandes de codigo comentado.
  - Por que esta mal: dificulta entender la intencion del test y ensucia la salida de CI o de ejecucion local.
  - Sugerencia: eliminar `print()` innecesarios, convertir el codigo comentado en tests reales o borrarlo si ya no aporta.

## Observaciones generales

- [ ] Hay una señal transversal de deriva entre paquetes base y paquetes consumidores.
  - Problema: varios errores de `maxi_flutter_widgets` y `maxi_flutter_framework` no parecen defectos aislados, sino sintomas de cambios de API en `maxi_framework` que no se propagaron de forma consistente.
  - Por que esta mal: cuando la base evoluciona sin una migracion coordinada, los consumidores quedan compilando a medias y la deuda se multiplica.
  - Sugerencia: definir una estrategia de compatibilidad. Puede ser una migracion completa por version, una capa de adaptacion temporal o una lista de breaking changes con validacion automatica en todos los paquetes.

- [ ] Hay demasiados `UnimplementedError` en rutas potencialmente productivas.
  - Problema: no estan limitados a prototipos o clases internas de laboratorio.
  - Por que esta mal: desplaza los errores desde compilacion hacia runtime.
  - Sugerencia: mover esos casos a contratos mas honestos, feature flags, clases abstractas reales o resultados negativos controlados mientras no exista implementacion.
