# Optimize

Fecha: 2026-04-30

Alcance: oportunidades de optimizacion verificadas por lectura directa de codigo. La prioridad esta en evitar bloqueo del event loop, reducir asignaciones innecesarias, eliminar esperas artificiales y bajar el costo de streams y logs.

## Alta prioridad

- [ ] Evitar I/O sincronico en `maxi_framework/lib/src/win_unix_socket/implementation/win_unix_server_socket.dart`
  - Ubicacion: linea 111 y linea 213.
  - Oportunidad: se usan `existsSync()` y `deleteSync()` para limpiar el archivo del socket.
  - Impacto: estas llamadas bloquean el isolate principal. En servidores o inicializaciones concurrentes eso introduce latencia evitable.
  - Recomendacion: usar `await f.exists()` y `await f.delete()` o mover el cleanup a una ruta asincrona controlada.

- [ ] Reemplazar la espera fija en `maxi_framework/lib/src/win_unix_socket/implementation/win_unix_server_socket.dart`
  - Ubicacion: linea 201.
  - Oportunidad: `await Future.delayed(const Duration(milliseconds: 50));` se usa para esperar que el isolate procese el cierre.
  - Impacto: agrega latencia fija aunque el cierre ya haya terminado, y sigue siendo fragil si en algun entorno 50 ms no alcanzan.
  - Recomendacion: usar una señal explicita de cierre con `Completer`, mensaje de confirmacion desde el isolate o cierre coordinado del `ReceivePort`.

- [ ] Evitar escrituras bloqueantes en `maxi_framework/lib/src/utils/hexadecimal_utilities.dart`
  - Ubicacion: linea 149 y linea 157.
  - Oportunidad: `writeAsStringSync()` se llama dos veces al generar archivos de debugging.
  - Impacto: bloquea el event loop y fragmenta la escritura en dos operaciones cuando podria hacerse en una sola.
  - Recomendacion: construir el contenido completo y escribirlo una sola vez con `writeAsString`, o usar `openWrite()` si el volumen puede crecer.

- [ ] Sustituir esperas artificiales usadas como “yield” en `maxi_framework` y `maxi_thread`
  - Ubicacion: por ejemplo `maxi_framework/lib/src/extensions/result_extensions.dart`, linea 204; `maxi_framework/lib/src/channels/channel.dart`, linea 17; `maxi_framework/lib/src/synchronizers/mutex.dart`, linea 75; `maxi_thread/lib/src/isolate/channels/isolate_origin_channel.dart`, linea 35.
  - Oportunidad: hay muchos `Future.delayed(Duration.zero)` para ceder el control.
  - Impacto: cada uno crea trabajo adicional en el scheduler y complica razonar sobre el orden real de ejecucion.
  - Recomendacion: eliminarlos cuando no sean necesarios o reemplazarlos por `scheduleMicrotask` solo cuando el orden de microtareas sea el requisito real.

- [ ] Revisar el uso masivo de `StreamController.broadcast()`
  - Ubicacion: por ejemplo `maxi_framework/lib/src/channels/master_channel.dart`, linea 28 y linea 95; `maxi_framework/lib/src/channels/bidirectional_channel.dart`, linea 26 y linea 90; `maxi_thread/lib/src/shared/shared_service.dart`, linea 26; `maxi_flutter_framework/lib/src/android_service/android_service_port.dart`, linea 27.
  - Oportunidad: se crean muchos controllers broadcast por defecto.
  - Impacto: los broadcast streams suelen tener mas costo y semantica mas compleja que un stream simple. Si la mayoria de estos canales tienen un solo consumidor, se esta pagando sobrecosto innecesario.
  - Recomendacion: usar single-subscription por defecto y dejar `broadcast()` solo en los casos donde realmente hay varios listeners simultaneos.

## Prioridad media

- [ ] Evitar copias temporales para desechar clientes en `maxi_framework/lib/src/win_unix_socket/native_build_win_unix_socket_server.dart`
  - Ubicacion: linea 79.
  - Oportunidad: `_clients.toList().lambda((x) => x.dispose());` crea una lista intermedia solo para iterar.
  - Impacto: asignacion extra y cierre indirecto en un camino de cleanup que puede repetirse con muchos clientes.
  - Recomendacion: iterar sobre una copia controlada solo si es estrictamente necesario por mutacion concurrente; si no, usar un `for` directo o un `while (_clients.isNotEmpty)`.

- [ ] Reducir asignaciones y cierres en `maxi_framework/lib/src/lifecycle/lifecycle_scope.dart`
  - Ubicacion: linea 50 a linea 105, y linea 192 a linea 197.
  - Oportunidad: el discard usa muchas llamadas a `lambda(...)`, wrappers de `volatileFunction(...)` y varias listas de bookkeeping.
  - Impacto: el cleanup acumula closures, excepciones encapsuladas y listas auxiliares, lo que aumenta costo justo en rutas de descarte masivo.
  - Recomendacion: reemplazar `lambda(...)` por loops directos en caminos internos y reservar wrappers pesados solo para operaciones que realmente puedan fallar de forma interesante.

- [ ] Revisar si `LocalPointer.notifyChange` necesita broadcast en `maxi_framework/lib/src/values/remote_object.dart`
  - Ubicacion: linea 21.
  - Oportunidad: el stream se crea como broadcast siempre.
  - Impacto: si la mayoria de los `LocalPointer` tienen un unico listener, hay un costo innecesario por instancia.
  - Recomendacion: usar stream simple, o reemplazarlo por un primitivo mas barato si solo se notifica cambio local y de baja frecuencia.

- [ ] Bajar el costo del logging de errores en `maxi_framework/lib/src/extensions/result_extensions.dart`
  - Ubicacion: linea 204 a linea 210.
  - Oportunidad: `logIfFails()` arma un bloque multilinea grande con `StackTrace.current` en cada fallo.
  - Impacto: genera strings grandes y stack traces nuevos incluso cuando el error ya trae contexto suficiente.
  - Recomendacion: registrar menos texto por defecto, reutilizar el stack trace original cuando exista y dejar el modo verboso detras de un flag de debug.

- [ ] Acelerar copias de directorios en `maxi_framework/lib/src/app_managers/native_dart/directories/native_folder_operator.dart`
  - Ubicacion: linea 64 a linea 118.
  - Oportunidad: la copia de archivos, carpetas y links se hace completamente secuencial.
  - Impacto: para arboles grandes la latencia total escala linealmente aunque muchas operaciones de I/O podrian solaparse.
  - Recomendacion: usar concurrencia acotada, por ejemplo un pool pequeño de tareas, manteniendo cancelacion y control de errores.

- [ ] Reducir clones repetidos de colecciones en `maxi_framework/lib/src/values/disposable_list.dart`
  - Ubicacion: linea 155, linea 167, linea 180, linea 205, linea 212, linea 270, linea 278 y linea 286.
  - Oportunidad: el tipo hace varios `toList()` y clones para operar sobre subconjuntos.
  - Impacto: aumenta asignaciones y presion de GC en estructuras que potencialmente se usan mucho.
  - Recomendacion: mantener version iterable cuando se pueda, o clonar solo en metodos donde la mutacion concurrente realmente lo exige.

- [ ] Reducir materializacion de listas en `maxi_framework/lib/src/values/table_result.dart`
  - Ubicacion: linea 60 y linea 163.
  - Oportunidad: se usa `_values.map(...).toList()` para cada consulta de columna.
  - Impacto: si el consumidor solo itera una vez o filtra despues, se materializa memoria innecesaria.
  - Recomendacion: ofrecer versiones `Iterable` o cachear resultados si esas columnas se consultan muchas veces.

## Prioridad baja pero recomendable

- [ ] Revisar el costo de `split('/').map(...).toList()` en referencias de archivos
  - Ubicacion: `maxi_framework/lib/src/files/directory_reference.dart`, linea 17; `maxi_framework/lib/src/files/folder_reference.dart`, linea 61; `maxi_framework/lib/src/files/file_reference.dart`, linea 59.
  - Oportunidad: cada parseo de ruta crea varias colecciones intermedias.
  - Impacto: no suele ser critico, pero si estas referencias se construyen mucho, hay costo evitable.
  - Recomendacion: considerar parseo mas directo o helpers compartidos que minimicen asignaciones.

- [ ] Revisar el costo de `bytes.reversed.toList()` en `maxi_framework/lib/src/utils/hexadecimal_utilities.dart`
  - Ubicacion: linea 83.
  - Oportunidad: invertir una lista con `.reversed.toList()` crea una coleccion completa nueva.
  - Impacto: para buffers grandes o muy frecuentes, suma asignaciones evitables.
  - Recomendacion: invertir in place cuando el contrato lo permita, o documentar que el costo es aceptable si el volumen es pequeno.

- [ ] Evitar logging/printing directo en caminos productivos cuando pueda apagarse por nivel
  - Ubicacion: varios `main.dart` y conectores de `citek_scale_api`, `citek_scale_receptor` y `disco_total_label`, ademas de logs extensos en `maxi_framework` y `maxi_thread`.
  - Impacto: aunque no siempre es un cuello de botella, el logging frecuente con interpolacion de strings y stack traces puede convertirse en costo real bajo carga.
  - Recomendacion: centralizar logging y no construir mensajes caros cuando el nivel actual no los va a emitir.

## Estrategia sugerida

- [ ] Corregir primero los bloqueos del event loop.
  - Prioridad: I/O sincronico y `Future.delayed(Duration.zero)` / delays fijos.

- [ ] Luego revisar primitivas de comunicacion.
  - Prioridad: `broadcast()` por defecto, `StreamController` innecesarios y logs caros.

- [ ] Finalmente optimizar asignaciones internas.
  - Prioridad: clones con `toList()`, materializacion de colecciones y wrappers internos de cleanup.
