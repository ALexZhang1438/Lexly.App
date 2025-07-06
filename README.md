# 📱 LEXLY - Asistente Legal Inteligente

LEXLY es una app iOS que actúa como un asistente legal especializado en **temas fiscales y laborales de España**. Utiliza inteligencia artificial para **explicar textos legales complejos de forma sencilla**, combinando procesamiento de lenguaje natural y visión por computador.

---

## 🎯 Propósito

Brindar asesoramiento legal accesible y comprensible para cualquier persona, con especial atención a temas fiscales y laborales del entorno español.

---

## 🔧 Funcionalidades Principales

### 💬 Chat Inteligente con IA
- Conversaciones contextuales usando la API de Asistentes de OpenAI.
- Especialización en fiscalidad y derecho laboral en España.
- Respuestas en tiempo real, adaptadas al contexto.

### 📷 Análisis de Imágenes
- Reconocimiento de documentos legales mediante GPT-4o.
- Resumen automático del contenido visual.
- Integración con el asistente para mantener el flujo conversacional.

### 🌍 Soporte Multiidioma
- Español (idioma principal), Chino (mandarín) e Inglés.
- Cambio dinámico de idioma durante la conversación.
- Saludos y respuestas personalizadas por idioma.

### 🛡️ Seguridad y Control
- **Rate Limiting**: 10 mensajes/minuto, mínimo 2 segundos entre mensajes.
- Filtros contra contenido inapropiado y validación de entrada.
- Manejo robusto de errores con mensajes claros.

---

## 🏗️ Arquitectura Técnica

### 🔐 Configuración y Seguridad
- `Secret.swift`: Almacena claves API de forma segura.
- `Config.swift`: Contiene parámetros globales (límites, modelos, URLs).

### 🤖 Servicios de IA
- `OpenAIAssistantService.swift`: Lógica para interacción textual.
- `Services.swift`: Análisis y compresión de imágenes.

### 🧠 Lógica de Negocio
- `ChatViewModel.swift`: Coordina el estado y lógica del chat.
- `Models.swift`: Estructuras de datos usadas por toda la app.

### 💡 Interfaz de Usuario
- `ContentView.swift`: Entrada principal de la app.
- `MessageBubbles.swift`: Mensajes estilo burbuja.
- `ImagePicker.swift`: Integración para subir imágenes.

---

## 🔄 Flujo de Funcionamiento

### Mensajes de Texto
1. Validación de contenido y límites.
2. Envío al asistente de OpenAI.
3. Procesamiento y respuesta.
4. Visualización en UI estilo chat.

### Imágenes
1. Selección por parte del usuario.
2. Análisis visual con GPT-4o.
3. Generación de resumen.
4. Envío del contexto al asistente.
5. Respuesta adaptada al contenido legal.

---

## 🎨 UX/UI Destacadas

- Diseño responsive adaptable a distintos dispositivos.
- Chat tipo burbujas con animaciones suaves.
- Ocultación automática del teclado al recibir respuestas.
- Cambio de idioma con transiciones animadas.
- Indicadores de carga durante procesos.

---

## 🔐 Seguridad y Privacidad

- Claves API gestionadas fuera del repositorio (`.gitignore`).
- Validación de entradas para prevenir abusos o contenido malicioso.
- Aviso legal claro: herramienta de ayuda, no reemplazo de asesoría profesional.

---

## 📊 Métricas y Límites

- **10 mensajes/minuto** y **100 mensajes/día**.
- **2 segundos** mínimo entre mensajes.
- **2000 caracteres** por mensaje / **5000 caracteres** por respuesta.
- **Modelos utilizados**:
  - GPT-3.5-turbo (texto)
  - GPT-4o (imágenes)
  - Asistente personalizado de OpenAI

---

## 📌 Casos de Uso

1. 🧾 Explicación de documentos legales (contratos, reglamentos).
2. 💰 Dudas sobre obligaciones fiscales.
3. ⚖️ Aclaración de derechos y deberes laborales.
4. 📋 Asistencia con formularios oficiales.
5. 🔍 Consultas legales rápidas.

---

## 🚀 Estado Actual

✅ App funcional y lista para pruebas y despliegue:
- Chat con IA operativo  
- Procesamiento de imágenes funcional  
- Soporte multiidioma  
- Seguridad y control de uso implementado  
- Interfaz cuidada y accesible

---

## 🛠️ Requisitos Técnicos

- Xcode 15+
- iOS 16.0+
- Swift + SwiftUI
- API Key de OpenAI

---

## 📬 Contacto

¿Comentarios o sugerencias? Puedes abrir un issue o contribuir al proyecto mediante pull requests.

---

