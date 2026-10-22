import QRCode from 'qrcode';
import { mkdir } from 'node:fs/promises';
const url=process.argv[2];
if(!url||!/^https?:\/\//.test(url)){console.error('Usage: npm run qr -- https://your-site/p/field-notes-tee-04');process.exit(1)}
await mkdir('qr',{recursive:true});
const opts={errorCorrectionLevel:'H',margin:4,width:1200,color:{dark:'#172b26',light:'#ffffff'}};
await QRCode.toFile('qr/field-notes-tee-04.png',url,{...opts,type:'png'});
await QRCode.toFile('qr/field-notes-tee-04.svg',url,{...opts,type:'svg'});
console.log('Wrote QR PNG and SVG for '+url);
