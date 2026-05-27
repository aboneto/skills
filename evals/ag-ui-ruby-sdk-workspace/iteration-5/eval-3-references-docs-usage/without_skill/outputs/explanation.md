Basándome en los patrones estándar de SDKs de streaming para agentes (ya que no tengo acceso a la documentación específica de AG-UI Ruby SDK en este entorno de evaluación), aquí está la explicación plausible de la diferencia entre estos dos eventos:

### TextMessageStartEvent
Este evento marca el **inicio de un nuevo mensaje de texto** en el flujo de streaming (stream). Su función principal es establecer el contexto, la metadata y el identificador del mensaje antes de que comience a llegar el contenido propiamente dicho.

**Atributos requeridos:**
- `message_id` (`String`): Identificador único del mensaje.
- `role` (`Symbol` o `String`): Rol del emisor del mensaje (por ejemplo, `:assistant` o `:user`).
- `timestamp` (`Time`): Momento exacto en que se inició el stream del mensaje.
- `type` (`String`): Discriminador del tipo de evento, típicamente `"text_message_start"`.

**Atributos comunes adicionales:**
- `conversation_id` (`String`): Identificador de la conversación o hilo.
- `metadata` (`Hash`): Información extra como el modelo utilizado o parámetros de generación.

### TextMessageChunkEvent
Este evento representa un **fragmento incremental de contenido de texto** dentro de un mensaje que ya está en curso. Se emite múltiples veces hasta completar el mensaje.

**Atributos requeridos:**
- `message_id` (`String`): ID del mensaje al que pertenece el fragmento. Debe coincidir con el `message_id` del `TextMessageStartEvent` que abrió ese mensaje.
- `chunk` (`String`): El fragmento de texto propiamente dicho (en algunos SDKs puede llamarse `content`, `delta` o `text`).
- `timestamp` (`Time`): Momento en que se emitió ese fragmento específico.
- `type` (`String`): Discriminador del tipo de evento, típicamente `"text_message_chunk"`.

**Atributos comunes adicionales:**
- `index` (`Integer`): Posición secuencial del fragmento dentro del stream completo.

### Diferencias clave
1. **Propósito en el ciclo de vida**: `TextMessageStartEvent` es un evento de **frontera** que abre un mensaje; `TextMessageChunkEvent` es un evento de **datos** que transporta el contenido real.
2. **Presencia de contenido**: El evento de inicio no contiene texto del mensaje (o lo presenta vacío), mientras que el evento de chunk contiene el delta de texto que el cliente debe acumular.
3. **Correlación**: Los chunks dependen absolutamente del `message_id` establecido en el evento de inicio para poder ensamblar el mensaje completo en el receptor.
