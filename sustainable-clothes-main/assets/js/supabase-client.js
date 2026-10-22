let cfg;
try { cfg = await import('./config.js'); } catch { cfg = null; }
export const BASE_PATH = (() => { const p=location.pathname; const i=p.indexOf('/p/'); if(i>=0)return p.slice(0,i+1); return p.slice(0,p.lastIndexOf('/')+1) || '/'; })();
export const configured = Boolean(cfg && cfg.SUPABASE_URL?.startsWith('https://') && !cfg.SUPABASE_URL.includes('YOUR_PROJECT') && cfg.SUPABASE_ANON_KEY && !cfg.SUPABASE_ANON_KEY.includes('YOUR_PUBLIC'));
export let supabase = null;
if (configured) {
  try {
    const { createClient } = await import('https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.49.1/+esm');
    supabase = createClient(cfg.SUPABASE_URL,cfg.SUPABASE_ANON_KEY);
  } catch {
    // Public passport will render its visibly labeled sample fallback offline.
  }
}
export const publicUrl = slug => location.origin+BASE_PATH+'p/'+encodeURIComponent(slug);
