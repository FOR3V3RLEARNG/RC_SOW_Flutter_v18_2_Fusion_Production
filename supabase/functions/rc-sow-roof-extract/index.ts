const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type ExtractedRoof = {
  roof_type: "Gable" | "Hip" | "Shed / Mono" | "Flat" | "Intersecting" | "Custom";
  length_ft: number;
  width_ft: number;
  wall_height_ft: number;
  pitch_rise_per_12: number;
  confidence: number;
  nodes: Array<{ x: number; y: number }>;
  measurements: Array<{
    label: string;
    value: number;
    unit: string;
    confidence: number;
  }>;
};

function response(status: number, payload: unknown) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function extensionMime(fileName: string) {
  const extension = fileName.split(".").pop()?.toLowerCase();
  if (extension === "png") return "image/png";
  if (extension === "webp") return "image/webp";
  if (extension === "pdf") return "application/pdf";
  return "image/jpeg";
}

async function requireActiveUser(request: Request) {
  const authorization = request.headers.get("Authorization");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!authorization || !supabaseUrl || !anonKey) return null;

  const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: { Authorization: authorization, apikey: anonKey },
  });
  if (!userResponse.ok) return null;
  const user = await userResponse.json();

  const profileResponse = await fetch(
    `${supabaseUrl}/rest/v1/profiles?id=eq.${encodeURIComponent(user.id)}&active=eq.true&select=id`,
    { headers: { Authorization: authorization, apikey: anonKey } },
  );
  if (!profileResponse.ok) return null;
  const profiles = await profileResponse.json();
  return Array.isArray(profiles) && profiles.length === 1 ? user : null;
}

function extractOutputText(payload: Record<string, unknown>) {
  if (typeof payload.output_text === "string") return payload.output_text;
  const output = Array.isArray(payload.output) ? payload.output : [];
  for (const item of output) {
    if (!item || typeof item !== "object") continue;
    const content = Array.isArray((item as { content?: unknown }).content)
      ? (item as { content: unknown[] }).content
      : [];
    for (const part of content) {
      if (
        part &&
        typeof part === "object" &&
        (part as { type?: unknown }).type === "output_text" &&
        typeof (part as { text?: unknown }).text === "string"
      ) {
        return (part as { text: string }).text;
      }
    }
  }
  throw new Error("The vision provider returned no structured text.");
}

function buildDocument(houseCode: string, fileName: string, roof: ExtractedRoof) {
  const sourceNodes = roof.nodes.length >= 3
    ? roof.nodes
    : [
      { x: 0, y: 0 },
      { x: 1, y: 0 },
      { x: 1, y: 1 },
      { x: 0, y: 1 },
    ];
  const nodes = sourceNodes.map((node, index) => ({
    id: `ai-main-n${index + 1}`,
    x: 190 + Math.max(0, Math.min(1, node.x)) * 420,
    y: 180 + Math.max(0, Math.min(1, node.y)) * 280,
  }));
  const centerY = nodes.reduce((sum, node) => sum + node.y, 0) / nodes.length;
  const minX = Math.min(...nodes.map((node) => node.x));
  const maxX = Math.max(...nodes.map((node) => node.x));
  return {
    houseCode,
    selectedSectionId: "ai-main",
    snapEnabled: true,
    source: "Image-assisted proposal",
    sourceFileName: fileName,
    aiConfidence: roof.confidence,
    updatedAt: new Date().toISOString(),
    sections: [{
      id: "ai-main",
      name: "AI proposal • Main roof",
      structure: "Main house",
      roofType: roof.roof_type,
      nodes,
      lines: [{
        id: "ai-main-ridge",
        kind: "ridge",
        start: { id: "ai-main-rs", x: minX + 25, y: centerY },
        end: { id: "ai-main-re", x: maxX - 25, y: centerY },
        label: "Proposed ridge",
      }],
      lengthFt: roof.length_ft,
      widthFt: roof.width_ft,
      wallHeightFt: roof.wall_height_ft,
      pitchRisePer12: roof.pitch_rise_per_12,
      rotationDegrees: 0,
      drainAngleDegrees: 180,
      drainEnabled: true,
      locked: false,
    }],
  };
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") return response(405, { error: "POST required" });

  try {
    if (!await requireActiveUser(request)) {
      return response(401, { error: "Approved RC SOW account required" });
    }
    const body = await request.json();
    const houseCode = String(body.house_code ?? "").trim().toUpperCase();
    const fileName = String(body.file_name ?? "").trim();
    const contentBase64 = String(body.content_base64 ?? "");
    if (!houseCode || !fileName || !contentBase64) {
      return response(400, { error: "house_code, file_name and content_base64 are required" });
    }
    if (contentBase64.length * 0.75 > 12 * 1024 * 1024) {
      return response(413, { error: "Drawing source exceeds the 12 MB review limit" });
    }

    const apiKey = Deno.env.get("OPENAI_API_KEY");
    const model = Deno.env.get("OPENAI_VISION_MODEL");
    if (!apiKey || !model) {
      return response(503, {
        error: "Organization-approved vision provider is not configured",
      });
    }

    const mime = extensionMime(fileName);
    const filePart = mime === "application/pdf"
      ? {
        type: "input_file",
        filename: fileName,
        file_data: `data:${mime};base64,${contentBase64}`,
      }
      : {
        type: "input_image",
        image_url: `data:${mime};base64,${contentBase64}`,
        detail: "high",
      };
    const providerResponse = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        store: false,
        input: [{
          role: "user",
          content: [
            {
              type: "input_text",
              text:
                "Extract a cautious 2D roof-plan proposal from this field sketch. Coordinates must be normalized from 0 to 1. Never claim unmarked dimensions as verified. Lower confidence for estimates, illegible values, perspective distortion, or ambiguous geometry. Return only the requested schema.",
            },
            filePart,
          ],
        }],
        text: {
          format: {
            type: "json_schema",
            name: "rc_sow_roof_proposal",
            strict: true,
            schema: {
              type: "object",
              additionalProperties: false,
              required: [
                "roof_type",
                "length_ft",
                "width_ft",
                "wall_height_ft",
                "pitch_rise_per_12",
                "confidence",
                "nodes",
                "measurements",
              ],
              properties: {
                roof_type: {
                  type: "string",
                  enum: ["Gable", "Hip", "Shed / Mono", "Flat", "Intersecting", "Custom"],
                },
                length_ft: { type: "number", minimum: 0, maximum: 200 },
                width_ft: { type: "number", minimum: 0, maximum: 200 },
                wall_height_ft: { type: "number", minimum: 0, maximum: 40 },
                pitch_rise_per_12: { type: "number", minimum: 0, maximum: 24 },
                confidence: { type: "number", minimum: 0, maximum: 1 },
                nodes: {
                  type: "array",
                  minItems: 3,
                  maxItems: 24,
                  items: {
                    type: "object",
                    additionalProperties: false,
                    required: ["x", "y"],
                    properties: {
                      x: { type: "number", minimum: 0, maximum: 1 },
                      y: { type: "number", minimum: 0, maximum: 1 },
                    },
                  },
                },
                measurements: {
                  type: "array",
                  maxItems: 30,
                  items: {
                    type: "object",
                    additionalProperties: false,
                    required: ["label", "value", "unit", "confidence"],
                    properties: {
                      label: { type: "string" },
                      value: { type: "number" },
                      unit: { type: "string" },
                      confidence: { type: "number", minimum: 0, maximum: 1 },
                    },
                  },
                },
              },
            },
          },
        },
      }),
    });
    if (!providerResponse.ok) {
      return response(502, { error: "Vision extraction provider failed" });
    }
    const providerPayload = await providerResponse.json();
    const roof = JSON.parse(extractOutputText(providerPayload)) as ExtractedRoof;
    return response(200, {
      document: buildDocument(houseCode, fileName, roof),
      measurements: roof.measurements,
      overall_confidence: roof.confidence,
      engine_label: "RC SOW secure image review",
    });
  } catch (error) {
    return response(400, {
      error: error instanceof Error ? error.message : "Roof extraction failed",
    });
  }
});
