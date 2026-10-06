// Luck'In : fonction « push » (Supabase › Edge Functions)
// - kind "cron"  : appelée toutes les 15 min par la base. Envoie les rappels (réveil, soir, bilan du dimanche)
//                  à l'heure choisie par chacun, seulement si le rituel n'est pas encore fait,
//                  et les rappels d'entretien (Carrière) : 2 jours avant et la veille à 19:00, le matin même à 08:00.
// - kind "test"  : l'utilisateur connecté s'envoie une notification de test.
// - kind "cheer" : encourager un ami du même groupe (une fois par jour et par ami).
// Secrets à définir dans Edge Functions › Secrets : VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, CRON_SECRET.
// SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY sont fournis automatiquement par Supabase, côté serveur uniquement.
import webpush from "npm:web-push@3.6.7";
import { createClient } from "npm:@supabase/supabase-js@2";

const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
const VAPID = {
  subject: "https://brisco-ops.github.io/luckin/",
  publicKey: Deno.env.get("VAPID_PUBLIC_KEY")!,
  privateKey: Deno.env.get("VAPID_PRIVATE_KEY")!,
};
const CRON_SECRET = Deno.env.get("CRON_SECRET") || "";
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (o: unknown, status = 200) => new Response(JSON.stringify(o), { status, headers: { ...CORS, "Content-Type": "application/json" } });

type Sub = { endpoint: string; user_id: string; p256dh: string; auth: string; tz: string; prefs: Record<string, unknown>; last_sent: Record<string, string> };

async function sendTo(sub: Sub, msg: { title: string; body: string; tag?: string; url?: string }) {
  const d = webpush.generateRequestDetails(
    { endpoint: sub.endpoint, keys: { p256dh: sub.p256dh, auth: sub.auth } },
    JSON.stringify(msg),
    { vapidDetails: VAPID, TTL: 4 * 3600, urgency: "normal" },
  );
  const r = await fetch(d.endpoint, { method: "POST", headers: d.headers as Record<string, string>, body: d.body });
  if (r.status === 404 || r.status === 410) await sb.from("push_subs").delete().eq("endpoint", sub.endpoint); // abonnement expiré
  return r.ok;
}
async function sendToUser(userId: string, msg: { title: string; body: string; tag?: string; url?: string }) {
  const { data } = await sb.from("push_subs").select("*").eq("user_id", userId);
  let n = 0;
  for (const s of (data || []) as Sub[]) if (await sendTo(s, msg).catch(() => false)) n++;
  return n;
}

function localNow(tz: string) {
  let parts: Record<string, string> = {};
  try {
    parts = Object.fromEntries(new Intl.DateTimeFormat("en-CA", { timeZone: tz, year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit", hourCycle: "h23", weekday: "short" })
      .formatToParts(new Date()).map((p) => [p.type, p.value]));
  } catch { return localNow("Europe/Paris"); }
  return { day: `${parts.year}-${parts.month}-${parts.day}`, min: +parts.hour * 60 + +parts.minute, sunday: parts.weekday === "Sun" };
}
const toMin = (t: unknown) => { const m = String(t || "").match(/^(\d{1,2}):(\d{2})/); return m ? +m[1] * 60 + +m[2] : null; };
const MSG: Record<string, { title: string; body: string }> = {
  morning: { title: "Réveil", body: "1 minute : poids, sommeil et ton rituel du matin." },
  evening: { title: "Ta soirée", body: "1 minute pour clôturer ta journée." },
  weekly: { title: "Bilan du dimanche", body: "Mensurations et bilan de ta semaine." },
};

// Rappels d'entretien : lus dans le journal synchronisé (user_data.data.jobs)
const IV_EVE = 19 * 60, IV_MORN = 8 * 60;
const IV_KIND: Record<string, string> = { tel: "téléphone", visio: "visio", place: "sur place" };
const shiftDay = (d: string, n: number) => { const x = new Date(d + "T12:00:00Z"); x.setUTCDate(x.getUTCDate() + n); return x.toISOString().slice(0, 10); };
const longDay = (d: string) => new Date(d + "T12:00:00Z").toLocaleDateString("fr-FR", { weekday: "long", day: "numeric", month: "long", timeZone: "UTC" });
const inWin = (min: number, t: number) => min >= t && min < t + 20;
type Iv = { date?: string; time?: string; kind?: string };
type Job = { id: string; company?: string; role?: string; status?: string; interviews?: Iv[] };
const jobsCache = new Map<string, Job[]>();
async function jobsOf(userId: string) {
  if (!jobsCache.has(userId)) {
    const { data } = await sb.from("user_data").select("data").eq("user_id", userId).maybeSingle();
    const jobs = ((data?.data as { jobs?: Job[] } | null)?.jobs || []).filter((j) => j.status === "envoyee" || j.status === "entretien");
    jobsCache.set(userId, jobs);
  }
  return jobsCache.get(userId)!;
}
function ivMessages(jobs: Job[], now: { day: string; min: number }) {
  const out: { key: string; title: string; body: string }[] = [];
  for (const j of jobs) for (const iv of j.interviews || []) {
    if (!iv.date) continue;
    const who = [j.company, j.role].filter(Boolean).join(" · ") || "Entretien";
    const how = [iv.time ? "à " + iv.time : "", iv.kind && IV_KIND[iv.kind] ? "(" + IV_KIND[iv.kind] + ")" : ""].filter(Boolean).join(" ");
    const key = `iv:${j.id}:${iv.date}:${iv.time || ""}`;
    if (inWin(now.min, IV_EVE) && shiftDay(now.day, 2) === iv.date)
      out.push({ key: key + ":j2", title: "Entretien dans 2 jours", body: `${who}, ${longDay(iv.date)} ${how}. Prends le temps de te préparer.`.replace(" .", ".") });
    if (inWin(now.min, IV_EVE) && shiftDay(now.day, 1) === iv.date)
      out.push({ key: key + ":j1", title: "Entretien demain", body: `${who}, ${how}.`.replace(", .", ".") });
    const ivMin = toMin(iv.time);
    if (inWin(now.min, IV_MORN) && now.day === iv.date && (ivMin == null || ivMin >= IV_MORN + 60))
      out.push({ key: key + ":j0", title: "Entretien aujourd’hui", body: `${who}, ${how}. Bonne chance !`.replace(", .", ".") });
  }
  return out;
}

async function runCron() {
  jobsCache.clear(); // l'instance peut rester chaude entre deux appels : on relit toujours le journal
  const { data: subs } = await sb.from("push_subs").select("*");
  let sent = 0;
  for (const s of (subs || []) as Sub[]) {
    const p = s.prefs || {};
    if (!p.on) continue;
    const now = localNow(s.tz || "Europe/Paris");
    const last = { ...(s.last_sent || {}) };
    let changed = false;
    for (const kind of ["morning", "evening", "weekly"]) {
      const t = toMin(p[kind]);
      if (t == null || last[kind] === now.day) continue;
      if (kind === "weekly" && !now.sunday) continue;
      if (now.min < t || now.min >= t + 20) continue; // fenêtre de 20 min, la tâche tourne toutes les 15 min
      last[kind] = now.day; changed = true;
      if (kind !== "weekly") {
        const { data: sh } = await sb.from("daily_share").select("morning,evening").eq("user_id", s.user_id).eq("day", now.day).maybeSingle();
        if (sh && (sh as Record<string, boolean>)[kind]) continue; // déjà fait : pas de rappel
      }
      if (await sendTo(s, { ...MSG[kind], tag: kind, url: "./" }).catch(() => false)) sent++;
    }
    if (p.iv !== false && (inWin(now.min, IV_EVE) || inWin(now.min, IV_MORN))) {
      for (const m of ivMessages(await jobsOf(s.user_id), now)) {
        if (last[m.key]) continue;
        last[m.key] = now.day; changed = true;
        if (await sendTo(s, { title: m.title, body: m.body, tag: m.key, url: "./" }).catch(() => false)) sent++;
      }
      const old = shiftDay(now.day, -7); // on oublie les rappels d'entretien de plus d'une semaine
      for (const k of Object.keys(last)) if (k.startsWith("iv:") && last[k] < old) { delete last[k]; changed = true; }
    }
    if (changed) await sb.from("push_subs").update({ last_sent: last }).eq("endpoint", s.endpoint);
  }
  return json({ ok: true, sent });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const body = await req.json().catch(() => ({}));

  if (body.kind === "cron") {
    if (!CRON_SECRET || req.headers.get("x-cron-secret") !== CRON_SECRET) return json({ error: "forbidden" }, 401);
    return runCron();
  }

  // Appels depuis l'app : on vérifie l'utilisateur connecté
  const jwt = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
  const { data: u } = await sb.auth.getUser(jwt);
  const me = u?.user;
  if (!me) return json({ error: "Connecte-toi d’abord." }, 401);

  if (body.kind === "test") {
    const n = await sendToUser(me.id, { title: "Luck’In", body: "Les notifications fonctionnent.", tag: "test" });
    return json({ ok: true, sent: n });
  }

  if (body.kind === "cheer") {
    const to = String(body.to || "");
    if (!to || to === me.id) return json({ error: "Destinataire invalide." }, 400);
    const { data: mine } = await sb.from("group_members").select("group_id").eq("user_id", me.id);
    const ids = (mine || []).map((x) => x.group_id);
    const { data: common } = ids.length ? await sb.from("group_members").select("group_id").eq("user_id", to).in("group_id", ids) : { data: [] };
    if (!common || !common.length) return json({ error: "Vous n’êtes pas dans le même groupe." }, 403);
    const day = localNow("Europe/Paris").day;
    const ins = await sb.from("cheers").insert({ from_id: me.id, to_id: to, day });
    if (ins.error) return json({ error: "Déjà encouragé aujourd’hui.", already: true }, 409);
    const { data: prof } = await sb.from("profiles").select("name").eq("id", me.id).maybeSingle();
    const name = (prof?.name || "Un ami").trim();
    const n = await sendToUser(to, { title: `🔥 ${name} t’encourage`, body: "Continue, tu es sur la bonne voie.", tag: "cheer-" + me.id, url: "./" });
    return json({ ok: true, sent: n });
  }

  return json({ error: "Requête inconnue." }, 400);
});
