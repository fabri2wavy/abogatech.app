import { NextResponse } from "next/server";
import { serverContext } from "@/infrastructure/backend/server";
import { requireRole } from "@/infrastructure/backend/context";

export const runtime = "nodejs";

export async function POST(request: Request) {
  let session;
  try {
    session = await serverContext();
    requireRole(session.ctx, ["admin", "asociado_senior", "abogado"]);
  } catch {
    return NextResponse.json(
      { error: "Sesión, firma o suscripción sin acceso al asistente." },
      { status: 403 },
    );
  }
  try {
    const { db: supabase, ctx } = session;
    const abogadoId = ctx.userId;
    const { pregunta, archivo } = await request.json();
    const apiKey = process.env.GROQ_API_KEY;

    if (!apiKey) {
      console.error("Falta configurar GROQ_API_KEY en el servidor.");
      return NextResponse.json(
        { error: "El asistente no está configurado." },
        { status: 503 },
      );
    }

    if (
      typeof abogadoId !== "string" ||
      !abogadoId.trim() ||
      (pregunta != null && typeof pregunta !== "string") ||
      (archivo != null && typeof archivo !== "string") ||
      (!pregunta?.trim() && !archivo)
    ) {
      return NextResponse.json(
        { error: "Envía una consulta o un PDF y el ID del abogado." },
        { status: 400 },
      );
    }

    let textoDocumento = "";
    if (archivo) {
      if (archivo.length > 7_000_000) {
        return NextResponse.json(
          { error: "El PDF supera el límite de 5 MB." },
          { status: 413 },
        );
      }
      const buffer = Buffer.from(archivo, "base64");
      if (buffer.subarray(0, 5).toString() !== "%PDF-") {
        return NextResponse.json(
          { error: "El archivo adjunto no es un PDF válido." },
          { status: 400 },
        );
      }
      const { PDFParse } = await import("pdf-parse");
      const parser = new PDFParse({ data: buffer });
      try {
        const documento = await parser.getText({ pageJoiner: "" });
        textoDocumento = documento.text.trim();
      } catch {
        return NextResponse.json(
          {
            error:
              "No se pudo leer el PDF. Comprueba que no esté dañado ni protegido con contraseña.",
          },
          { status: 422 },
        );
      } finally {
        await parser.destroy();
      }
      if (!textoDocumento) {
        return NextResponse.json(
          {
            error:
              "El PDF no contiene texto extraíble. Si es un escaneo, conviértelo con OCR antes de adjuntarlo.",
          },
          { status: 422 },
        );
      }
      if (textoDocumento.length > 100_000) {
        return NextResponse.json(
          {
            error:
              "El documento es demasiado extenso. Adjunta solo las páginas que quieras analizar.",
          },
          { status: 413 },
        );
      }
    }

    console.log("🔍 Buscando datos en Supabase para el ID:", abogadoId);

    const { data: perfilAbogado, error: errorPerfil } = await supabase
      .from("profiles")
      .select("nombres, apellido_paterno")
      .eq("id", abogadoId)
      .single();

    if (errorPerfil)
      console.error("Error al buscar perfil:", errorPerfil.message);

    const nombreDoctor = perfilAbogado
      ? `${perfilAbogado.nombres} ${perfilAbogado.apellido_paterno}`
      : "Abogado";
    console.log("Identidad confirmada:", nombreDoctor);

    const { data: misExpedientes, error: errorExpedientes } = await supabase
      .from("cases")
      .select(
        `
        numero_caso,
        titulo,
        estado,
        cliente:clients!cases_client_same_firm_fk (nombres, apellido_paterno)
      `,
      )
      .eq("firm_id", ctx.firmId)
      .limit(10);

    if (errorExpedientes)
      console.error("Error al buscar expedientes:", errorExpedientes.message);
    console.log(`Expedientes encontrados: ${misExpedientes?.length || 0}`);

    const systemPrompt = `
      Eres el asistente de inteligencia artificial de ABOGATECH, una plataforma de gestión legal.
      
      CONTEXTO CRÍTICO:
      Estás hablando en privado con el Dr. ${nombreDoctor}. 
      
      REGLA DE SALUDO: 
      Si el usuario te dice "Hola", "Buenos días", o cualquier saludo inicial, TU PRIMERA FRASE DEBE SER: "Hola Doctor ${nombreDoctor}." 
      
      BASE DE DATOS EN TIEMPO REAL:
      Estos son los expedientes que el Dr. ${nombreDoctor} puede consultar en su firma activa:
      ${JSON.stringify(misExpedientes || [])}
      
      INSTRUCCIONES MULTIMODALES:
      Si el usuario adjunta un documento, prioriza el análisis de ese texto legal.
    `;

    const response = await fetch(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: process.env.GROQ_MODEL || "openai/gpt-oss-120b",
          messages: [
            { role: "system", content: systemPrompt },
            {
              role: "user",
              content:
                (pregunta?.trim() || "Analiza el documento adjunto.") +
                (textoDocumento
                  ? `\n\nTexto del PDF adjunto:\n${textoDocumento}`
                  : ""),
            },
          ],
        }),
        signal: AbortSignal.timeout(60_000),
      },
    );

    if (!response.ok) {
      console.error("Groq rechazó la solicitud. Estado HTTP:", response.status);
      return NextResponse.json(
        {
          error:
            response.status === 429
              ? "Se alcanzó el límite de solicitudes de Groq. Intenta nuevamente en unos momentos."
              : "No se pudo obtener una respuesta de Groq. Revisa la clave y el modelo configurados en el servidor.",
        },
        { status: response.status === 429 ? 429 : 502 },
      );
    }

    const completion = await response.json();
    const respuesta = completion.choices?.[0]?.message?.content;
    if (typeof respuesta !== "string" || !respuesta.trim()) {
      return NextResponse.json(
        { error: "Groq devolvió una respuesta vacía." },
        { status: 502 },
      );
    }
    return NextResponse.json({ respuesta });
  } catch (error) {
    console.error("Falla crítica en el endpoint:", error);
    return NextResponse.json(
      { error: "Fallo el procesamiento." },
      { status: 500 },
    );
  }
}
