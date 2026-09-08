import fs from 'node:fs';
import path from 'node:path';
const src='src/data/oferta', dest='public/programas';
fs.mkdirSync(dest,{recursive:true});
for(const dir of fs.readdirSync(src,{withFileTypes:true}).filter(d=>d.isDirectory())){
 const json=JSON.parse(fs.readFileSync(path.join(src,dir.name,'curso.json'),'utf8'));
 const pdf=path.join(src,dir.name,'programa.pdf');
 if(fs.existsSync(pdf)){
   const out=`/programas/${dir.name}.pdf`;
   fs.copyFileSync(pdf,path.join(dest,`${dir.name}.pdf`));
   if(json.programa!==out) {
     console.warn(`${dir.name}: configure "programa": "${out}" para enlazarlo.`);
   }
 }
}
