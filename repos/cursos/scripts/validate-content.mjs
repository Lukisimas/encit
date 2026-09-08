import fs from 'node:fs';
import path from 'node:path';
const base='src/data/oferta';
const allowedPalettes=new Set(['tierra','oceano','bosque','volcan','mineral','atmosfera']);
const allowedTypes=new Set(['Curso','Diplomado','Taller','Seminario']);
let errors=[];
for (const dir of fs.readdirSync(base,{withFileTypes:true}).filter(d=>d.isDirectory())) {
  const file=path.join(base,dir.name,'curso.json');
  if(!fs.existsSync(file)){errors.push(`${dir.name}: falta curso.json`);continue;}
  let d; try{d=JSON.parse(fs.readFileSync(file,'utf8'));}catch(e){errors.push(`${dir.name}: JSON inválido ${e.message}`);continue;}
  if(d.slug!==dir.name) errors.push(`${dir.name}: slug debe coincidir con nombre de carpeta`);
  if(!allowedPalettes.has(d.paleta)) errors.push(`${dir.name}: paleta inválida`);
  if(!allowedTypes.has(d.tipo)) errors.push(`${dir.name}: tipo inválido`);
  for(const k of ['publicar_desde','publicar_hasta','fecha_inicio','fecha_fin']) {
    if(!/^\d{4}-\d{2}-\d{2}$/.test(d[k]||'')) errors.push(`${dir.name}: ${k} debe ser YYYY-MM-DD`);
  }
  if(d.publicar_desde>d.publicar_hasta) errors.push(`${dir.name}: ventana de publicación invertida`);
  if(d.fecha_inicio>d.fecha_fin) errors.push(`${dir.name}: fechas académicas invertidas`);
  if(d.programa && !fs.existsSync(path.join(base,dir.name,'programa.pdf'))) errors.push(`${dir.name}: programa declarado pero falta programa.pdf`);
}
if(errors.length){console.error(errors.join('\n'));process.exit(1);}
console.log('Contenido válido');
