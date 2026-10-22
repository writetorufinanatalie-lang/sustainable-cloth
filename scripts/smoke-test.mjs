// Verifies public read and write restrictions against the configured Supabase project.
import {createClient} from '@supabase/supabase-js';
import {SUPABASE_URL,SUPABASE_ANON_KEY} from '../assets/js/config.js';
if(SUPABASE_URL.includes('YOUR_PROJECT')||SUPABASE_ANON_KEY.includes('YOUR_PUBLIC'))throw new Error('Configure assets/js/config.js first');
const db=createClient(SUPABASE_URL,SUPABASE_ANON_KEY,{auth:{persistSession:false}});
const slug=process.argv[2]||'field-notes-tee-04';
const {data:visible,error}=await db.from('products').select('id,slug').eq('slug',slug);
if(error||!visible?.length)throw new Error('Anon could not read published product: '+(error?.message||'no row'));
const id=visible[0].id;
const {error:insertError}=await db.from('products').insert({brand_id:'10000000-0000-4000-8000-000000000001',slug:'anon-write-must-fail',name:'Must not insert',is_published:true});
if(!insertError)throw new Error('SECURITY FAILURE: anon inserted a product');
const {error:updateError}=await db.from('products').update({name:'Must not update'}).eq('id',id);
if(!updateError)throw new Error('SECURITY FAILURE: anon updated a product');
const {data:hidden,error:hiddenErr}=await db.from('products').select('id').eq('is_published',false);
if(hiddenErr)throw hiddenErr;
if(hidden?.length)throw new Error('SECURITY FAILURE: anon read an unpublished fixture');
console.log('PASS: anon reads published data; insert/update denied; unpublished fixture is not visible.');

