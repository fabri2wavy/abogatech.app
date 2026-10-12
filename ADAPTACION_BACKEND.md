# Adaptación de ABOGATECH a la base multifirma

Esta rama adapta el código de `abogatech-app` al esquema suministrado el 9 de octubre de 2026. Se conserva el diseño. Las modificaciones de `FinanzasTab.tsx` corresponden a importes abonados parcialmente y al estado cancelado, no a una redistribución visual.

## Instalación

1. Usar un proyecto de desarrollo que contenga el esquema actual completo (tablas, enums, funciones privadas, políticas y triggers). El archivo `tests/fixtures/schema.sql` es exclusivo de pruebas locales: **no ejecutarlo en Supabase**.
2. Revisar y aplicar `supabase/migrations/202610090001_frontend_adapters.sql`. Añade tres RPC transaccionales: guardar expediente con responsable, guardar un miembro y crear contrato con cuotas/pagos iniciales/distribución. No renombra ni reemplaza las tablas existentes.
3. Aplicar `202610090002_trial_seven_days.sql` si se quieren pruebas de siete días desde la creación de la firma. Cambia el plan `corporate` y los valores predeterminados; no recorta suscripciones existentes. El trigger existente sigue sincronizando las fechas.
4. Configurar las variables indicadas en `.env.example` en el entorno del servidor. La clave privada se utiliza exclusivamente para administrar cuentas Auth y obtener correos del equipo, después de validar al administrador y su firma. No colocarla en una variable `NEXT_PUBLIC_*`.
5. Ejecutar `npm ci`, `npm test`, `npm run typecheck`, `npm run build` y `npm run dev`.
6. Iniciar sesión con usuarios que tengan `profiles`, una membresía activa y una suscripción operativa en el proyecto de desarrollo. Confirmar los flujos con dos firmas y usuarios de diferentes roles antes de publicar.

No se aplicaron migraciones en una base remota ni se publicó el sitio.

## Contratos de datos

- `domain/types/database.ts` contiene las filas y enums del esquema exportado. Las entidades de presentación conservan los nombres que consumen las pantallas.
- Los repositorios consultan por `firm_id` y usan la sesión de Supabase, manteniendo RLS. El rol proviene de `firm_memberships`, nunca de un valor de respaldo de administrador.
- Crear un cliente escribe `clients`. No crea una cuenta Auth ni cambia contraseñas al convertirlo a activo. Las invitaciones al portal se ofrecen mediante `firmaActions.ts`.
- Los documentos usan `firma/caso/documento/archivo`. Se crean los metadatos antes del upload, y se borra el archivo antes de borrar los metadatos, de acuerdo con las políticas exportadas.
- La auditoría de las tablas cubiertas por los triggers se consulta desde `audit_logs`; se quitaron las escrituras manuales que duplicaban eventos o que no estaban permitidas por RLS. No se agregaron triggers a las tablas que carecían de ellos.
- La eliminación de un miembro suspende su membresía; conserva su cuenta y su historial en otras firmas.
- El asistente resuelve el usuario desde la sesión y consulta expedientes permitidos de la firma activa con RLS. No acepta el ID del navegador como autoridad ni consulta con `service_role`.

## Selección de firma y suscripción

Si la cuenta tiene una sola membresía activa, se utiliza esa firma. Si tiene varias, se exige una selección explícita para evitar mezclar datos. `GET /api/firma` lista sus firmas; `POST /api/firma` con JSON `{"firmId":"UUID"}` selecciona una, validando la membresía. La cookie de selección no concede permisos y se verifica en cada contexto. No se añadió un selector visual porque el alcance preserva las pantallas existentes.

El vencimiento se comprueba en los repositorios y acciones. `past_due` mantiene acceso, tal como hace la función exportada `firm_is_operational`. La suspensión comercial se controla por `subscriptions`; cambiar únicamente `firms.status` no equivale a suspender. La aplicación no cambia estas reglas de negocio existentes.

Las acciones para invitar y aceptar miembros/usuarios del portal crean o consumen invitaciones de la base. No envían correos; su entrega e interfaz se integrarán por separado.

La función existente `create_firm` sigue siendo autoservicio para usuarios autenticados. Esta adaptación no inventa un rol de administrador global ni agrega un panel visual de altas de firmas. Restringir las altas exclusivamente al propietario de la plataforma requiere definir esa identidad y sus permisos.

## Finanzas

- BOB se presenta como `BS` en la interfaz antigua; USD se conserva.
- El saldo pagado procede de `payment_allocations` y pagos registrados. Los pagos anulados no se contabilizan.
- Se mantiene la calculadora existente: deducciones de 28.5%, fondo de oficina y reparto del neto. Se guardan como reglas; el remanente va al responsable del expediente. Esto conserva la fórmula del frontend y **no valida su tratamiento tributario**. Los comprobantes conservan las fórmulas y conversión preexistentes.
- Los contratos con cuotas inválidas revierten toda la operación. Las cuotas declaradas pagadas al crear un contrato generan pagos y aplicaciones explícitas, con método `otro` y una observación de origen.
- La pantalla de estado de cuenta solo representa un contrato. Ante varios contratos no cancelados, devuelve un error explícito en lugar de elegir uno arbitrariamente. Los totales globales con varias monedas también devuelven error; no se suman BOB y USD sin un criterio de conversión.
- Las nuevas funciones no implementan una pantalla de cobros posteriores. El repositorio original tampoco la ofrecía; la base mantiene sus funciones de anulación y distribución existentes.

## Diferencias que requieren una decisión de producto

El formulario antiguo contiene campos que no existen en la base suministrada: área de especialidad/NIT/abogado de contacto del cliente, historial de juzgados, oficios solicitados y medidas previas al remate. La adaptación rechaza valores no vacíos en los campos detectados, para evitar aparentar que se guardaron. No se agregaron columnas ni se escondieron controles.

Las políticas RLS y permisos preexistentes no constituyen una auditoría completa: por ejemplo, algunas políticas de borrado permiten al creador actuar sin consultar directamente el vencimiento. Los repositorios sí lo comprueban, pero un bloqueo comercial absoluto contra clientes directos requiere revisar también esas políticas. No se alteraron indiscriminadamente los permisos existentes.

## Verificación

`npm test` ejecuta pruebas de contexto/finanzas y una base PostgreSQL local mediante PGlite. La fixture deriva de las exportaciones, no contiene clientes ni usuarios reales. Se prueban creación de casos, separación entre firmas, altas de miembros, contratos/pagos/distribución, reversión ante fallo de cuotas y bloqueo por vencimiento. PGlite no reproduce el servicio HTTP de Supabase Auth/Storage ni los envíos externos del asistente: esos flujos requieren validación en el proyecto de desarrollo.
