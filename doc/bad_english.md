# Bad English in Names

Fecha: 2026-04-30

Alcance: nombres de archivos, clases, metodos, constantes o variables donde el ingles es incorrecto, esta mal escrito o suena claramente no idiomatico. La idea es dejar un mapa de renombres recomendados antes de hacer una limpieza global.

## Renombres recomendados

- [ ] `standar_field_controll.dart` y `StandarFieldControll`
  - Ubicacion: `maxi_flutter_widgets/lib/src/fields/controllers/standar_field_controll.dart`, linea 7.
  - Problema: `standar` y `controll` estan mal escritos.
  - Sugerencia: archivo `standard_field_controller.dart`; clase `StandardFieldController`.
  - Motivo: ademas de corregir el ingles, el nombre encaja mejor con la carpeta `controllers` y con `TextFormController` y `NumberFormController`.

- [ ] `FormalContractVertial`
  - Ubicacion: `maxi_flutter_widgets/lib/src/containers/formal_contract_vertial.dart`, linea 5.
  - Problema: `Vertial` deberia ser `Vertical`.
  - Sugerencia: archivo `formal_contract_vertical.dart`; clase `FormalContractVertical`.
  - Motivo: es un typo directo y el propio archivo ya usa `ContractVertically`, lo que confirma la forma correcta.

- [ ] `FileAnalizer` y `file_analizer.dart`
  - Ubicacion: `maxi_reflection_constructor/lib/src/analyzer/file_analizer.dart`, linea 11 y linea 21.
  - Problema: `Analizer` deberia ser `Analyzer`.
  - Sugerencia: archivo `file_analyzer.dart`; tipos `FileAnalyzer` y `FileAnalyzerResult`.
  - Motivo: es la grafia correcta en ingles tecnico y alinea el nombre con el paquete `analyzer` que el archivo ya importa.

- [ ] `FileReflectorWritter` y `file_reflector_writter.dart`
  - Ubicacion: `maxi_reflection_constructor/lib/src/writers/file_reflector_writter.dart`, linea 8, linea 18 y linea 28.
  - Problema: `Writter` deberia ser `Writer`.
  - Sugerencia: archivo `file_reflector_writer.dart`; tipos `FileReflectorWriter` y `FileReflectorWriterResult`.
  - Motivo: typo claro y repetido en varios puntos del paquete.

- [ ] `realSeacher`
  - Ubicacion: `maxi_reflection_constructor/lib/src/generators/reflector_builder.dart`, linea 30.
  - Problema: `Seacher` deberia ser `Searcher`.
  - Sugerencia: `realSearcher`.
  - Motivo: variable local, facil de renombrar, mejora lectura inmediata.

- [ ] `_buildSteamOnThread` y `_buildSteamEntOnThread`
  - Ubicacion: `maxi_thread/lib/src/extensions/stream_skill_extension.dart`, linea 15, linea 46, linea 95 y linea 128.
  - Problema: `Steam` deberia ser `Stream`.
  - Sugerencia: `_buildStreamOnThread` y `_buildStreamEntityOnThread`.
  - Motivo: evita confundir el concepto de streams con la palabra `Steam` y mejora la legibilidad del stack trace y de los logs.

- [ ] `contructor`, `_contructors` e `invokeContructor`
  - Ubicacion: aparecen en el modulo de reflexion, por ejemplo en `maxi_reflection/lib/src/entities/reflected_entity_implementation.dart`, linea 89.
  - Problema: `contructor` y `contructors` deberian ser `constructor` y `constructors`.
  - Sugerencia: `ReflectedMethodType.constructor`, `_constructors`, `invokeConstructor`.
  - Motivo: es un typo repetido que termina formando parte del API del modulo.

- [ ] `anotations`
  - Ubicacion: muy extendido en `maxi_reflection`, por ejemplo en `maxi_reflection/lib/src/entities/reflected_entity_implementation.dart`, linea 40.
  - Problema: `anotations` deberia ser `annotations`.
  - Sugerencia: renombrar a `annotations` en propiedades, parametros y helpers.
  - Motivo: es probablemente el typo mas repetido del workspace y afecta clases base, utilidades y codigo generado.

- [ ] `runInternalFuncionality`
  - Ubicacion: muy extendido en varios paquetes, por ejemplo en `disco_total_label/lib/src/server_connectors/create_transaction.dart`, linea 16, y en `maxi_framework/lib/src/functionalities/functionality.dart`, linea 19.
  - Problema: `Funcionality` deberia ser `Functionality`.
  - Sugerencia: `runInternalFunctionality`.
  - Motivo: el typo aparece en una API muy central. Si se corrige, conviene hacerlo como una migracion coordinada porque impacta a casi todo el monorepo.

- [ ] `formated`
  - Ubicacion: `maxi_framework/lib/src/language/cache_oration.dart`, linea 5; `maxi_framework/lib/src/language/oration.dart`, linea 101.
  - Problema: `formated` deberia ser `formatted`.
  - Sugerencia: `formatted`.
  - Motivo: typo simple y muy facil de corregir.

- [ ] `_notifyChangeCotroller`
  - Ubicacion: `maxi_framework/lib/src/values/remote_object.dart`, linea 16.
  - Problema: `Cotroller` deberia ser `Controller`.
  - Sugerencia: `_notifyChangeController`.
  - Motivo: typo localizado, bajo riesgo de renombre.

- [ ] `_unifiedStreamControlers`
  - Ubicacion: `maxi_framework/lib/src/lifecycle/lifecycle_scope.dart`, linea 14.
  - Problema: `Controlers` deberia ser `Controllers`.
  - Sugerencia: `_unifiedStreamControllers`.
  - Motivo: typo repetido varias veces dentro del mismo archivo.

- [ ] `kStopedService`
  - Ubicacion: `maxi_flutter_framework/lib/src/android_service/android_service_connector.dart`, linea 29; usado tambien en `maxi_flutter_framework/lib/src/android_service/android_service_port.dart`, linea 59.
  - Problema: `Stoped` deberia ser `Stopped`.
  - Sugerencia: `kStoppedService` y string `'mx.stoppedService'`.
  - Motivo: el typo aparece en una constante publica y en el nombre del canal/evento.

- [ ] `ScaleProductDescount`
  - Ubicacion: `citek_app_framework/lib/src/business/scale_article.dart`, linea 30.
  - Problema: `Descount` deberia ser `Discount`.
  - Sugerencia: `ScaleProductDiscount`.
  - Motivo: typo visible en enum, adapters proto, codigo generado y tests. Conviene corregirlo de forma coordinada porque es parte del modelo de dominio.

- [ ] `whenUnkownTypeValue`
  - Ubicacion: `maxi_flutter_widgets/lib/src/fields/controllers/standar_field_controll.dart`, linea 110; override en `number_form_controller.dart`, linea 46.
  - Problema: `Unkown` deberia ser `Unknown`.
  - Sugerencia: `whenUnknownTypeValue`.
  - Motivo: typo simple en un metodo protegido.

- [ ] `determinateTotal`
  - Ubicacion: `disco_total_label/lib/src/server_connectors/create_transaction.dart`, linea 24.
  - Problema: `determinate` no es la palabra natural en este contexto.
  - Sugerencia: `matchingTotal`, `selectedTotal` o `targetTotal`.
  - Motivo: aunque no es un typo tan mecanico como otros, el nombre actual suena poco idiomatico y comunica peor la intencion.

## Casos mas discutibles pero recomendables

- [ ] `itWasDiscarded`
  - Ubicacion: muy extendido en `maxi_framework`.
  - Problema: no es un ingles natural para una propiedad booleana.
  - Sugerencia: `wasDiscarded` o, si expresa estado actual, `isDiscarded`.
  - Motivo: la forma actual se entiende, pero suena traducida literalmente.

- [ ] `itsCanAcceptType`
  - Ubicacion: `maxi_flutter_widgets/lib/src/fields/controllers/standar_field_controll.dart`, linea 35.
  - Problema: construccion gramatical incorrecta.
  - Sugerencia: `canAcceptType`.
  - Motivo: mejora mucho la legibilidad del API.

- [ ] `movil`
  - Ubicacion: aparece como propiedad en algunos managers Flutter.
  - Problema: no es ingles sino espanol.
  - Sugerencia: `isMobile`.
  - Motivo: si el API va en ingles, conviene no mezclar idiomas en nombres publicos.

## Estrategia sugerida de renombre

- [ ] Hacer primero renombres locales y de bajo impacto.
  - Ejemplos: `formated`, `_notifyChangeCotroller`, `_unifiedStreamControlers`, `realSeacher`, `whenUnkownTypeValue`.

- [ ] Despues hacer renombres de archivos y clases con soporte del lenguaje.
  - Ejemplos: `StandarFieldControll`, `FormalContractVertial`, `FileAnalizer`, `FileReflectorWritter`.

- [ ] Dejar para una migracion coordinada los nombres que forman parte del API compartido.
  - Ejemplos: `runInternalFuncionality`, `anotations`, `ScaleProductDescount`, `contructor`.
  - Motivo: esos cambios afectan varios paquetes y, en algunos casos, codigo generado.
