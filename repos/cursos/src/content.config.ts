import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const oferta = defineCollection({
  loader: glob({ pattern: '**/curso.json', base: './src/data/oferta' }),
  schema: z.object({
    slug: z.string().min(2),
    tipo: z.enum(['Curso','Diplomado','Taller','Seminario']),
    titulo: z.string().min(4),
    subtitulo: z.string().optional().default(''),
    paleta: z.enum(['tierra','oceano','bosque','volcan','mineral','atmosfera']),
    estado: z.enum(['borrador','publicado','cancelado','archivado']),
    publicar_desde: z.string(),
    publicar_hasta: z.string(),
    fecha_inicio: z.string(),
    fecha_fin: z.string(),
    modalidad: z.enum(['Presencial','En línea','Híbrida']),
    duracion_horas: z.number().positive(),
    horario: z.string(),
    descripcion_corta: z.string().max(260),
    descripcion: z.string(),
    objetivo: z.string(),
    dirigido_a: z.string(),
    requisitos: z.array(z.string()).default([]),
    temario: z.array(z.object({
      titulo: z.string(),
      descripcion: z.string().optional().default('')
    })).min(1),
    costos: z.object({
      general: z.number().nonnegative().optional(),
      comunidad_unam: z.number().nonnegative().optional(),
      moneda: z.string().default('MXN')
    }).optional(),
    responsable: z.object({
      nombre: z.string(),
      semblanza: z.string().optional().default('')
    }),
    inscripcion_url: z.string().url().optional().or(z.literal('')),
    programa: z.string().optional().default(''),
    prioridad: z.number().int().default(0)
  })
});

export const collections = { oferta };
