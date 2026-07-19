// Free, no-key job board API: https://www.arbeitnow.com/api/job-board-api
const ARBEITNOW_URL = "https://www.arbeitnow.com/api/job-board-api";

function stripHtml(html) {
  return html
    .replace(/<[^>]*>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/\s+/g, " ")
    .trim();
}

// A naive .slice(0, n) can land inside a surrogate pair (e.g. an emoji),
// leaving a dangling unpaired high surrogate — that's invalid UTF-16 and
// breaks JSON encoding once it reaches PostgREST ("invalid input syntax for
// type json"). Trim one more char off if the cut landed mid-pair.
export function truncateSafely(text, maxLength) {
  if (text.length <= maxLength) return text;
  let cut = text.slice(0, maxLength);
  const lastCode = cut.charCodeAt(cut.length - 1);
  if (lastCode >= 0xd800 && lastCode <= 0xdbff) cut = cut.slice(0, -1);
  return cut;
}

export async function fetchArbeitnowJobs() {
  const res = await fetch(ARBEITNOW_URL, { signal: AbortSignal.timeout(10_000) });
  if (!res.ok) throw new Error(`Arbeitnow API returned ${res.status}`);
  const body = await res.json();
  const jobs = Array.isArray(body?.data) ? body.data : [];

  return jobs.map((job) => ({
    source: "arbeitnow",
    external_id: job.slug,
    title: job.title,
    company_name: job.company_name,
    location: job.location || null,
    remote: Boolean(job.remote),
    description: truncateSafely(stripHtml(job.description || ""), 4000),
    apply_url: job.url,
    tags: Array.isArray(job.tags) ? job.tags : [],
    job_types: Array.isArray(job.job_types) ? job.job_types : [],
    posted_at: job.created_at ? new Date(job.created_at * 1000).toISOString() : null,
  }));
}
