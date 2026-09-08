import { getCollection } from 'astro:content';

export async function getPublishedCourses() {
  const all = await getCollection('oferta');
  return all
    .filter((entry) => entry.data.estado === 'publicado' || entry.data.estado === 'archivado')
    .sort((a,b) => b.data.prioridad - a.data.prioridad ||
      a.data.fecha_inicio.localeCompare(b.data.fecha_inicio));
}

export function yearOf(date: string) {
  return Number(date.slice(0,4));
}

export function money(value?: number, currency='MXN') {
  if (value === undefined) return '';
  return new Intl.NumberFormat('es-MX', { style:'currency', currency }).format(value);
}
