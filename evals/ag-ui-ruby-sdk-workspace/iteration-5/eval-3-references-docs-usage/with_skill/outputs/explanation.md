Basándome en la documentación del SDK AG-UI Ruby, estas son las diferencias entre ambos eventos:

## Diferencia principal

- **`TextMessageStartEvent`**: Señala explícitamente el **inicio** de un stream de mensaje de texto.
- **`TextMessageChunkEvent`**: Es un **evento de conveniencia** que representa un fragmento de mensaje; algunos clientes lo expanden automáticamente en los eventos Start/Content/End.

## Atributos requeridos

### TextMessageStartEvent
El único atributo estrictamente obligatorio es:
- **`message_id`** (`String`): ID único que debe reutilizarse para los eventos Content y End del mismo mensaje.

### TextMessageChunkEvent
Según la tabla de propiedades, **ningún atributo está marcado como obligatorio** en el esquema. Sin embargo:
- **`message_id`** (`String|nil`): Aunque el tipo permite `nil`, la documentación especifica que es **requerido en el primer chunk** de un mensaje.

## Atributos adicionales (opcionales)

| Atributo | TextMessageStartEvent | TextMessageChunkEvent |
|---|---|---|
| `role` | Opcional. Default: `"assistant"`. Válidos: `"developer"`, `"system"`, `"assistant"`, `"user"` | Opcional (`String|nil`). Debe ser uno de los valores de rol válidos |
| `delta` | No tiene | Opcional (`String|nil`). Contiene el fragmento de texto |
| `timestamp` | Opcional (`Time\|nil`) | Opcional (`Time\|nil`) |
| `raw_event` | Opcional (`Object\|nil`) | Opcional (`Object\|nil`) |

En resumen: `TextMessageStartEvent` requiere obligatoriamente un `message_id` para iniciar el stream, mientras que `TextMessageChunkEvent` no tiene campos estrictamente obligatorios en su esquema, pero necesita `message_id` en el primer chunk para identificar a qué mensaje pertenece, y añade el campo `delta` para transportar el contenido textual.
