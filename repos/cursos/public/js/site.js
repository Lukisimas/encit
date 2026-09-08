(() => {
  const TZ = 'America/Mexico_City';

  // Obtiene YYYY-MM-DD en la zona de Ciudad de México sin depender de la zona del visitante.
  function todayMX() {
    const parts = new Intl.DateTimeFormat('en-CA', {
      timeZone: TZ, year:'numeric', month:'2-digit', day:'2-digit'
    }).formatToParts(new Date());
    const v = Object.fromEntries(parts.map(p => [p.type,p.value]));
    return `${v.year}-${v.month}-${v.day}`;
  }

  const today=todayMX();
  const isPublished = el => today >= el.dataset.publishFrom && today <= el.dataset.publishUntil && today <= el.dataset.end;
  const isCurrent = el => today <= el.dataset.end;
  const isHistory = el => today > el.dataset.end;

  document.querySelectorAll('[data-carousel] [data-course]').forEach(el => el.hidden=!isPublished(el));
  const carouselVisible=[...document.querySelectorAll('[data-carousel] [data-course]')].some(el=>!el.hidden);
  document.querySelectorAll('[data-carousel-empty]').forEach(el=>el.hidden=carouselVisible);

  document.querySelectorAll('[data-current-catalog] [data-course]').forEach(el=>el.hidden=!isCurrent(el));
  document.querySelectorAll('[data-history-catalog] [data-course]').forEach(el=>{
    const container=el.closest('[data-history-catalog]');
    const year=container?.dataset.historyYear;
    el.hidden=!(isHistory(el) && (!year || el.dataset.year===year));
  });

  document.querySelectorAll('[data-temporal-status]').forEach(status=>{
    const hero=status.closest('[data-start][data-end]');
    if(!hero) return;
    const start=hero.dataset.start, end=hero.dataset.end;
    if(today < start) status.textContent='Próximamente';
    else if(today <= end) status.textContent='En curso';
    else status.textContent='Actividad concluida';
    const enroll=hero.querySelector('[data-enrollment]');
    if(enroll && today > end) enroll.hidden=true;
  });
})();
