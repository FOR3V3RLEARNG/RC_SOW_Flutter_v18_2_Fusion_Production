const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function response(status: number, payload: unknown) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function parseCsvLine(line: string) {
  const values: string[] = [];
  let value = "";
  let quoted = false;
  for (let index = 0; index < line.length; index += 1) {
    const character = line[index];
    if (character === '"') {
      if (quoted && line[index + 1] === '"') {
        value += '"';
        index += 1;
      } else {
        quoted = !quoted;
      }
    } else if (character === "," && !quoted) {
      values.push(value.trim());
      value = "";
    } else {
      value += character;
    }
  }
  values.push(value.trim());
  return values;
}

function normalize(value: string) {
  return value.trim().toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_|_$/g, "");
}

function buildMappings(headers: string[], sample: string[]) {
  const targets: Record<string, { aliases: string[]; required: boolean }> = {
    "House code": { aliases: ["house_code", "housecode", "code", "shelter_id"], required: true },
    "Beneficiary name": { aliases: ["beneficiary", "beneficiary_name", "head_of_household", "family_name"], required: true },
    Parish: { aliases: ["parish", "location_parish", "district", "region_code"], required: true },
    Cluster: { aliases: ["cluster", "cluster_id", "sector_group", "camp_id"], required: false },
    "GPS coordinates": { aliases: ["gps", "gps_string", "lat_long", "coordinates"], required: false },
    "Assessment date": { aliases: ["assessment_date", "date", "created_at"], required: false },
  };
  return Object.entries(targets).map(([systemField, definition]) => {
    const index = headers.findIndex((header) => definition.aliases.includes(normalize(header)));
    return {
      system_field: systemField,
      source_column: index < 0 ? "" : headers[index],
      sample_value: index < 0 ? "—" : String(sample[index] ?? "—"),
      confidence: index < 0 ? 0 : 0.92,
      required: definition.required,
    };
  });
}

async function profileFor(request: Request) {
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
    `${supabaseUrl}/rest/v1/profiles?id=eq.${encodeURIComponent(user.id)}&active=eq.true&select=id,assigned_parishes`,
    { headers: { Authorization: authorization, apikey: anonKey } },
  );
  if (!profileResponse.ok) return null;
  const profiles = await profileResponse.json();
  return Array.isArray(profiles) && profiles.length === 1
    ? { user, profile: profiles[0], authorization, supabaseUrl, anonKey }
    : null;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") return response(405, { error: "POST required" });

  try {
    const session = await profileFor(request);
    if (!session) return response(401, { error: "Approved RC SOW account required" });
    const body = await request.json();
    const fileName = String(body.file_name ?? "").trim();
    const contentBase64 = String(body.content_base64 ?? "");
    if (!fileName || !contentBase64) {
      return response(400, { error: "file_name and content_base64 are required" });
    }
    if (contentBase64.length * 0.75 > 15 * 1024 * 1024) {
      return response(413, { error: "Legacy source exceeds the 15 MB preview limit" });
    }

    const extension = fileName.split(".").pop()?.toLowerCase();
    const text = new TextDecoder().decode(Uint8Array.from(atob(contentBase64), (character) => character.charCodeAt(0)));
    let rows: Array<Record<string, unknown>> = [];
    let headers: string[] = [];
    let sample: string[] = [];
    const warnings: string[] = [
      "Potential duplicate house codes and beneficiaries require review before activation.",
    ];

    if (extension === "csv") {
      const values = text.split(/\r?\n/).filter((line) => line.trim()).map(parseCsvLine);
      headers = values[0] ?? [];
      sample = values[1] ?? [];
      rows = values.slice(1, 1001).map((row) => Object.fromEntries(headers.map((header, index) => [header, row[index] ?? ""])));
      if (values.length > 1001) warnings.push("Preview is limited to the first 1,000 data rows.");
    } else if (extension === "json") {
      const decoded = JSON.parse(text);
      rows = (Array.isArray(decoded) ? decoded : [decoded])
        .filter((row) => row && typeof row === "object")
        .slice(0, 1000);
      headers = rows.length ? Object.keys(rows[0]) : [];
      sample = headers.map((header) => String(rows[0]?.[header] ?? ""));
    } else {
      warnings.push("XLSX, XLS and PDF sources require the organization’s document parser. Export CSV for immediate mapping.");
    }

    const mappings = buildMappings(headers, sample);
    const assignedParishes = Array.isArray(session.profile.assigned_parishes)
      ? session.profile.assigned_parishes
      : [];
    const parish = String(assignedParishes[0] ?? "");
    if (!parish) return response(403, { error: "No assigned parish is available" });

    const insertResponse = await fetch(
      `${session.supabaseUrl}/rest/v1/legacy_import_batches?select=id`,
      {
        method: "POST",
        headers: {
          Authorization: session.authorization,
          apikey: session.anonKey,
          "Content-Type": "application/json",
          Prefer: "return=representation",
        },
        body: JSON.stringify({
          parish,
          file_name: fileName,
          row_count: rows.length,
          mappings,
          warnings,
          staged_payload: rows,
          status: "mapping",
          created_by: session.user.id,
        }),
      },
    );
    if (!insertResponse.ok) return response(400, { error: "Could not stage import preview" });
    const inserted = await insertResponse.json();
    return response(200, {
      id: inserted[0].id,
      row_count: rows.length,
      mappings,
      warnings,
    });
  } catch (error) {
    return response(400, {
      error: error instanceof Error ? error.message : "Legacy preview failed",
    });
  }
});
