-- Solo modifica la duración de NUEVAS pruebas. Las suscripciones existentes conservan sus fechas.
begin;
UPDATE public.plans SET trial_days=7,updated_at=now() WHERE code='corporate' AND activo=true;
ALTER TABLE public.plans ALTER COLUMN trial_days SET DEFAULT 7;
ALTER TABLE public.firms ALTER COLUMN trial_ends_at SET DEFAULT (now()+interval '7 days');
-- create_initial_subscription recalcula las fechas desde plans.trial_days al insertar firms.
commit;
