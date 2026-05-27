## Diferencia entre `TextMessageStartEvent` y `TextMessageChunkEvent`

### `TextMessageStartEvent`
- Marca el **inicio** de un stream de mensajes de texto.
- Requiere solo **un atributo obligatorio**: `message_id` (String).
- Se usa en el patrón **granular** junto con `TextMessageContentEvent` y `TextMessageEndEvent` para tener control fino sobre cada parte del mensaje.

### `TextMessageChunkEvent`
- Es un evento de **conveniencia** que agrupa `message_id`, `role` y `delta` en un solo evento.
- **Ningún atributo es obligatorio** (todos son opcionales: `message_id`, `role`, `delta`, `timestamp`, `raw_event`).
- Simplifica la API a costa de perder control granular — algunos clientes lo expanden automáticamente a Start/Content/End internamente.

### Resumen de atributos requeridos

| Evento | Atributos obligatorios |
|---|---|
| `TextMessageStartEvent` | `message_id` (String) |
| `TextMessageChunkEvent` | Ninguno (todos opcionales) |

La principal diferencia: `StartEvent` exige `message_id` y es parte del flujo granular de 3 eventos (Start → Content* → End), mientras que `ChunkEvent` es un todo-en-uno sin atributos obligatorios que sacrifica control por simplicidad.
