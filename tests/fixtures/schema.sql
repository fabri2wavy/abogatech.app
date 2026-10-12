-- Fixture de prueba derivada de las exportaciones del usuario, sin datos reales.
CREATE SCHEMA auth; CREATE SCHEMA private; CREATE ROLE anon; CREATE ROLE authenticated; CREATE ROLE service_role BYPASSRLS;
CREATE TABLE auth.users(id uuid PRIMARY KEY, email text); CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$ SELECT nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
SET check_function_bodies = off;
CREATE TYPE public.agenda_event_status AS ENUM ('pendiente','completado','cancelado');
CREATE TYPE public.agenda_event_type AS ENUM ('audiencia','reunion','vencimiento','tarea');
CREATE TYPE public.audit_action AS ENUM ('insert','update','delete');
CREATE TYPE public.billing_interval AS ENUM ('monthly','yearly');
CREATE TYPE public.case_member_role AS ENUM ('responsable','colaborador','supervisor');
CREATE TYPE public.case_status AS ENUM ('en_espera','mediacion','juicio','cerrado');
CREATE TYPE public.client_type AS ENUM ('persona','empresa');
CREATE TYPE public.compensation_calculation_type AS ENUM ('porcentaje','monto_fijo');
CREATE TYPE public.compensation_recipient_type AS ENUM ('firma','miembro','personalizado');
CREATE TYPE public.distribution_status AS ENUM ('pendiente','liquidado','anulado');
CREATE TYPE public.document_status AS ENUM ('activo','archivado');
CREATE TYPE public.expense_status AS ENUM ('registrado','aprobado','reembolsado','anulado');
CREATE TYPE public.fee_agreement_status AS ENUM ('borrador','vigente','finalizado','cancelado');
CREATE TYPE public.firm_role AS ENUM ('admin','finanzas','asociado_senior','abogado','cliente');
CREATE TYPE public.firm_status AS ENUM ('trial','active','past_due','suspended','cancelled');
CREATE TYPE public.installment_due_type AS ENUM ('fecha','hito');
CREATE TYPE public.installment_status AS ENUM ('pendiente','pagado','atrasado','cancelado');
CREATE TYPE public.invitation_kind AS ENUM ('staff','client_portal');
CREATE TYPE public.invitation_status AS ENUM ('pendiente','aceptada','revocada','expirada');
CREATE TYPE public.membership_status AS ENUM ('invitado','activo','suspendido');
CREATE TYPE public.payment_method AS ENUM ('efectivo','transferencia','deposito','tarjeta','cheque','otro');
CREATE TYPE public.payment_status AS ENUM ('registrado','anulado');
CREATE TYPE public.subscription_status AS ENUM ('trialing','active','past_due','expired','canceled');
CREATE TABLE public.agenda_events("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"case_id" uuid,"titulo" text NOT NULL,"descripcion" text,"fecha_inicio" timestamp with time zone NOT NULL,"fecha_fin" timestamp with time zone NOT NULL,"tipo" public.agenda_event_type NOT NULL,"estado" public.agenda_event_status DEFAULT 'pendiente'::agenda_event_status NOT NULL,"assigned_membership_id" uuid,"creado_por" uuid,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.audit_logs("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid,"actor_user_id" uuid,"accion" public.audit_action NOT NULL,"entidad" text NOT NULL,"entidad_id" uuid,"datos_anteriores" jsonb,"datos_nuevos" jsonb,"created_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.case_expenses("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"case_id" uuid NOT NULL,"concepto" text NOT NULL,"monto" numeric NOT NULL,"moneda" character varying DEFAULT 'BOB'::character varying NOT NULL,"fecha" date DEFAULT CURRENT_DATE NOT NULL,"reembolsable" boolean DEFAULT true NOT NULL,"estado" public.expense_status DEFAULT 'registrado'::expense_status NOT NULL,"comprobante_path" text,"observaciones" text,"creado_por" uuid,"aprobado_por" uuid,"aprobado_at" timestamp with time zone,"reembolsado_at" timestamp with time zone,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.case_members("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"case_id" uuid NOT NULL,"membership_id" uuid NOT NULL,"role" public.case_member_role DEFAULT 'colaborador'::case_member_role NOT NULL,"asignado_por" uuid,"activo" boolean DEFAULT true NOT NULL,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.case_notes("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"case_id" uuid NOT NULL,"contenido" text NOT NULL,"visible_cliente" boolean DEFAULT false NOT NULL,"creado_por" uuid,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.case_reports("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"case_id" uuid NOT NULL,"periodo" date NOT NULL,"resumen_proceso" text,"estado_actual" text,"medidas_precautorias" text,"comentario" text,"visible_cliente" boolean DEFAULT true NOT NULL,"creado_por" uuid,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.cases("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"client_id" uuid NOT NULL,"numero_caso" text NOT NULL,"titulo" text NOT NULL,"descripcion" text,"estado" public.case_status DEFAULT 'en_espera'::case_status NOT NULL,"materia" text,"juzgado" text,"parte_contraria" text,"informe_despacho" text,"informe_cliente" text,"rol_cliente" text,"tipo_proceso" text,"nurej" text,"numero_fiscalia" text,"numero_felcc" text,"juez_actual" text,"secretario_actuario" text,"fiscal_actual" text,"investigador_asignado" text,"etapa_procesal" text,"cuantia" numeric,"archivado" boolean DEFAULT false NOT NULL,"archivado_at" timestamp with time zone,"archivado_por" uuid,"creado_por" uuid,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.clients("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"tipo" public.client_type DEFAULT 'persona'::client_type NOT NULL,"nombres" text,"apellido_paterno" text,"apellido_materno" text,"ci" text,"expedido" text,"fecha_nacimiento" date,"nacionalidad" text DEFAULT 'Boliviana'::text,"estado_civil" text,"profesion" text,"nombre_empresa" text,"representante_legal" text,"email" text,"telefono" text,"telefono_laboral" text,"direccion" text,"direccion_oficina" text,"referido_por" text,"contacto_referidor" text,"etapa_comercial" text DEFAULT 'activo'::text NOT NULL,"portal_user_id" uuid,"creado_por" uuid,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.compensation_rules("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"scheme_id" uuid NOT NULL,"nombre" text NOT NULL,"recipient_type" public.compensation_recipient_type NOT NULL,"membership_id" uuid,"recipient_label" text,"calculation_type" public.compensation_calculation_type DEFAULT 'porcentaje'::compensation_calculation_type NOT NULL,"valor" numeric NOT NULL,"activo" boolean DEFAULT true NOT NULL,"orden" integer DEFAULT 0 NOT NULL,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.compensation_schemes("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"nombre" text NOT NULL,"descripcion" text,"activo" boolean DEFAULT true NOT NULL,"creado_por" uuid,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.document_templates("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"nombre" text NOT NULL,"descripcion" text,"tipo" text NOT NULL,"contenido" text NOT NULL,"creado_por" uuid NOT NULL,"creado_en" timestamp with time zone DEFAULT now() NOT NULL,"actualizado_en" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.documents("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"case_id" uuid NOT NULL,"nombre_archivo" text NOT NULL,"mime_type" text,"extension" text,"tamano_bytes" bigint,"storage_path" text NOT NULL,"visible_cliente" boolean DEFAULT false NOT NULL,"status" public.document_status DEFAULT 'activo'::document_status NOT NULL,"descripcion" text,"subido_por" uuid,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL,"archivado_at" timestamp with time zone,"archivado_por" uuid);
CREATE TABLE public.fee_agreements("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"case_id" uuid NOT NULL,"compensation_scheme_id" uuid,"numero_contrato" text,"monto_total" numeric NOT NULL,"moneda" character varying DEFAULT 'BOB'::character varying NOT NULL,"estado" public.fee_agreement_status DEFAULT 'borrador'::fee_agreement_status NOT NULL,"descripcion" text,"fecha_inicio" date DEFAULT CURRENT_DATE NOT NULL,"fecha_fin" date,"autorizado_por" uuid,"autorizado_at" timestamp with time zone,"creado_por" uuid,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.fee_installments("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"agreement_id" uuid NOT NULL,"numero" integer NOT NULL,"descripcion" text NOT NULL,"monto" numeric NOT NULL,"tipo_vencimiento" public.installment_due_type DEFAULT 'fecha'::installment_due_type NOT NULL,"fecha_vencimiento" date,"hito_vencimiento" text,"estado" public.installment_status DEFAULT 'pendiente'::installment_status NOT NULL,"pagado_at" timestamp with time zone,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.firm_invitations("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"kind" public.invitation_kind NOT NULL,"email" text NOT NULL,"role" public.firm_role NOT NULL,"client_id" uuid,"invited_by" uuid NOT NULL,"status" public.invitation_status DEFAULT 'pendiente'::invitation_status NOT NULL,"expires_at" timestamp with time zone DEFAULT (now() + '7 days'::interval) NOT NULL,"accepted_by" uuid,"accepted_at" timestamp with time zone,"revoked_by" uuid,"revoked_at" timestamp with time zone,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.firm_member_details("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"user_id" uuid NOT NULL,"cargo" text NOT NULL,"especialidad" text,"estado_laboral" text DEFAULT 'activo'::text NOT NULL,"creado_en" timestamp with time zone DEFAULT now() NOT NULL,"actualizado_en" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.firm_memberships("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"user_id" uuid NOT NULL,"role" public.firm_role NOT NULL,"status" public.membership_status DEFAULT 'activo'::membership_status NOT NULL,"invitado_por" uuid,"joined_at" timestamp with time zone,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.firm_settings("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"categoria" text NOT NULL,"valor" text DEFAULT ''::text NOT NULL,"activo" boolean DEFAULT true NOT NULL,"creado_por" uuid,"creado_en" timestamp with time zone DEFAULT now() NOT NULL,"actualizado_en" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.firms("id" uuid DEFAULT gen_random_uuid() NOT NULL,"nombre" text NOT NULL,"razon_social" text,"slug" text NOT NULL,"telefono" text,"email" text,"pais" text DEFAULT 'BO'::text NOT NULL,"moneda_principal" text DEFAULT 'BOB'::text NOT NULL,"status" public.firm_status DEFAULT 'trial'::firm_status NOT NULL,"trial_started_at" timestamp with time zone DEFAULT now() NOT NULL,"trial_ends_at" timestamp with time zone DEFAULT (now() + '30 days'::interval) NOT NULL,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.payment_allocations("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"payment_id" uuid NOT NULL,"installment_id" uuid NOT NULL,"monto" numeric NOT NULL,"created_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.payment_distributions("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"payment_id" uuid NOT NULL,"agreement_id" uuid NOT NULL,"scheme_id" uuid NOT NULL,"rule_id" uuid NOT NULL,"rule_name" text NOT NULL,"recipient_type" public.compensation_recipient_type NOT NULL,"membership_id" uuid,"recipient_label" text,"calculation_type" public.compensation_calculation_type NOT NULL,"rule_value" numeric NOT NULL,"base_calculo" numeric NOT NULL,"monto" numeric NOT NULL,"estado" public.distribution_status DEFAULT 'pendiente'::distribution_status NOT NULL,"liquidado_at" timestamp with time zone,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.payments("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"case_id" uuid NOT NULL,"monto" numeric NOT NULL,"moneda" character varying DEFAULT 'BOB'::character varying NOT NULL,"metodo" public.payment_method DEFAULT 'transferencia'::payment_method NOT NULL,"estado" public.payment_status DEFAULT 'registrado'::payment_status NOT NULL,"fecha_pago" timestamp with time zone DEFAULT now() NOT NULL,"referencia" text,"observaciones" text,"registrado_por" uuid,"anulado_por" uuid,"anulado_at" timestamp with time zone,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.plans("id" uuid DEFAULT gen_random_uuid() NOT NULL,"code" text NOT NULL,"nombre" text NOT NULL,"descripcion" text,"trial_days" integer DEFAULT 30 NOT NULL,"price_amount" numeric,"currency" character varying DEFAULT 'BOB'::character varying NOT NULL,"billing_interval" public.billing_interval DEFAULT 'monthly'::billing_interval NOT NULL,"activo" boolean DEFAULT true NOT NULL,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.profiles("id" uuid NOT NULL,"nombres" text,"apellido_paterno" text,"apellido_materno" text,"telefono" text,"avatar_url" text,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.subscription_events("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"subscription_id" uuid,"event_type" text NOT NULL,"previous_status" public.subscription_status,"new_status" public.subscription_status,"metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,"created_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE TABLE public.subscriptions("id" uuid DEFAULT gen_random_uuid() NOT NULL,"firm_id" uuid NOT NULL,"plan_id" uuid NOT NULL,"status" public.subscription_status DEFAULT 'trialing'::subscription_status NOT NULL,"trial_start" timestamp with time zone,"trial_end" timestamp with time zone,"current_period_start" timestamp with time zone,"current_period_end" timestamp with time zone,"cancel_at_period_end" boolean DEFAULT false NOT NULL,"canceled_at" timestamp with time zone,"billing_provider" text,"provider_customer_id" text,"provider_subscription_id" text,"created_at" timestamp with time zone DEFAULT now() NOT NULL,"updated_at" timestamp with time zone DEFAULT now() NOT NULL);
CREATE OR REPLACE FUNCTION private.document_path_is_valid(target_firm_id uuid, target_case_id uuid, target_document_id uuid, target_path text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  select
    split_part(target_path, '/', 1) = target_firm_id::text
    and split_part(target_path, '/', 2) = target_case_id::text
    and split_part(target_path, '/', 3) = target_document_id::text
    and split_part(target_path, '/', 4) <> ''
    and array_length(
      string_to_array(target_path, '/'),
      1
    ) >= 4;
$function$
;
ALTER TABLE public.agenda_events ADD CONSTRAINT agenda_events_pkey PRIMARY KEY (id);
ALTER TABLE public.agenda_events ADD CONSTRAINT agenda_events_title_not_empty CHECK (length(TRIM(BOTH FROM titulo)) > 0);
ALTER TABLE public.agenda_events ADD CONSTRAINT agenda_events_valid_dates CHECK (fecha_fin >= fecha_inicio);
ALTER TABLE public.audit_logs ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);
ALTER TABLE public.case_expenses ADD CONSTRAINT case_expenses_amount_positive CHECK (monto > 0::numeric);
ALTER TABLE public.case_expenses ADD CONSTRAINT case_expenses_concept_not_empty CHECK (length(TRIM(BOTH FROM concepto)) > 0);
ALTER TABLE public.case_expenses ADD CONSTRAINT case_expenses_currency_format CHECK (moneda::text ~ '^[A-Z]{3}$'::text);
ALTER TABLE public.case_expenses ADD CONSTRAINT case_expenses_pkey PRIMARY KEY (id);
ALTER TABLE public.case_members ADD CONSTRAINT case_members_pkey PRIMARY KEY (id);
ALTER TABLE public.case_members ADD CONSTRAINT case_members_unique UNIQUE (case_id, membership_id);
ALTER TABLE public.case_notes ADD CONSTRAINT case_notes_content_not_empty CHECK (length(TRIM(BOTH FROM contenido)) > 0);
ALTER TABLE public.case_notes ADD CONSTRAINT case_notes_pkey PRIMARY KEY (id);
ALTER TABLE public.case_reports ADD CONSTRAINT case_reports_period_first_day CHECK (periodo = date_trunc('month'::text, periodo::timestamp with time zone)::date);
ALTER TABLE public.case_reports ADD CONSTRAINT case_reports_pkey PRIMARY KEY (id);
ALTER TABLE public.case_reports ADD CONSTRAINT case_reports_unique_period UNIQUE (firm_id, case_id, periodo);
ALTER TABLE public.cases ADD CONSTRAINT cases_amount_non_negative CHECK (cuantia IS NULL OR cuantia >= 0::numeric);
ALTER TABLE public.cases ADD CONSTRAINT cases_archive_consistency CHECK (archivado = false AND archivado_at IS NULL OR archivado = true AND archivado_at IS NOT NULL);
ALTER TABLE public.cases ADD CONSTRAINT cases_case_number_not_empty CHECK (length(TRIM(BOTH FROM numero_caso)) > 0);
ALTER TABLE public.cases ADD CONSTRAINT cases_firm_case_number_unique UNIQUE (firm_id, numero_caso);
ALTER TABLE public.cases ADD CONSTRAINT cases_firm_id_id_unique UNIQUE (firm_id, id);
ALTER TABLE public.cases ADD CONSTRAINT cases_pkey PRIMARY KEY (id);
ALTER TABLE public.cases ADD CONSTRAINT cases_title_not_empty CHECK (length(TRIM(BOTH FROM titulo)) > 0);
ALTER TABLE public.clients ADD CONSTRAINT clients_etapa_comercial_check CHECK (etapa_comercial = ANY (ARRAY['potencial'::text, 'activo'::text, 'inactivo'::text]));
ALTER TABLE public.clients ADD CONSTRAINT clients_firm_id_id_unique UNIQUE (firm_id, id);
ALTER TABLE public.clients ADD CONSTRAINT clients_pkey PRIMARY KEY (id);
ALTER TABLE public.clients ADD CONSTRAINT clients_required_identity_check CHECK (tipo = 'persona'::client_type AND nombres IS NOT NULL OR tipo = 'empresa'::client_type AND nombre_empresa IS NOT NULL);
ALTER TABLE public.compensation_rules ADD CONSTRAINT compensation_percentage_valid CHECK (calculation_type <> 'porcentaje'::compensation_calculation_type OR valor <= 100::numeric);
ALTER TABLE public.compensation_rules ADD CONSTRAINT compensation_recipient_valid CHECK (recipient_type = 'firma'::compensation_recipient_type AND membership_id IS NULL OR recipient_type = 'miembro'::compensation_recipient_type AND membership_id IS NOT NULL OR recipient_type = 'personalizado'::compensation_recipient_type AND membership_id IS NULL AND recipient_label IS NOT NULL AND length(TRIM(BOTH FROM recipient_label)) > 0);
ALTER TABLE public.compensation_rules ADD CONSTRAINT compensation_rules_firm_id_id_unique UNIQUE (firm_id, id);
ALTER TABLE public.compensation_rules ADD CONSTRAINT compensation_rules_name_not_empty CHECK (length(TRIM(BOTH FROM nombre)) > 0);
ALTER TABLE public.compensation_rules ADD CONSTRAINT compensation_rules_pkey PRIMARY KEY (id);
ALTER TABLE public.compensation_rules ADD CONSTRAINT compensation_rules_value_positive CHECK (valor > 0::numeric);
ALTER TABLE public.compensation_schemes ADD CONSTRAINT compensation_schemes_firm_id_id_unique UNIQUE (firm_id, id);
ALTER TABLE public.compensation_schemes ADD CONSTRAINT compensation_schemes_name_not_empty CHECK (length(TRIM(BOTH FROM nombre)) > 0);
ALTER TABLE public.compensation_schemes ADD CONSTRAINT compensation_schemes_name_unique UNIQUE (firm_id, nombre);
ALTER TABLE public.compensation_schemes ADD CONSTRAINT compensation_schemes_pkey PRIMARY KEY (id);
ALTER TABLE public.document_templates ADD CONSTRAINT document_templates_contenido_not_blank CHECK (length(TRIM(BOTH FROM contenido)) > 0);
ALTER TABLE public.document_templates ADD CONSTRAINT document_templates_nombre_not_blank CHECK (length(TRIM(BOTH FROM nombre)) > 0);
ALTER TABLE public.document_templates ADD CONSTRAINT document_templates_pkey PRIMARY KEY (id);
ALTER TABLE public.document_templates ADD CONSTRAINT document_templates_tipo_check CHECK (tipo = ANY (ARRAY['memorial'::text, 'contrato'::text, 'poder'::text, 'otro'::text]));
ALTER TABLE public.documents ADD CONSTRAINT documents_archive_consistency CHECK (status = 'activo'::document_status AND archivado_at IS NULL OR status = 'archivado'::document_status AND archivado_at IS NOT NULL);
ALTER TABLE public.documents ADD CONSTRAINT documents_firm_id_id_unique UNIQUE (firm_id, id);
ALTER TABLE public.documents ADD CONSTRAINT documents_name_not_empty CHECK (length(TRIM(BOTH FROM nombre_archivo)) > 0);
ALTER TABLE public.documents ADD CONSTRAINT documents_pkey PRIMARY KEY (id);
ALTER TABLE public.documents ADD CONSTRAINT documents_size_non_negative CHECK (tamano_bytes IS NULL OR tamano_bytes >= 0);
ALTER TABLE public.documents ADD CONSTRAINT documents_storage_path_not_empty CHECK (length(TRIM(BOTH FROM storage_path)) > 0);
ALTER TABLE public.documents ADD CONSTRAINT documents_storage_path_structure_check CHECK (private.document_path_is_valid(firm_id, case_id, id, storage_path));
ALTER TABLE public.documents ADD CONSTRAINT documents_storage_path_unique UNIQUE (storage_path);
ALTER TABLE public.fee_agreements ADD CONSTRAINT fee_agreements_amount_positive CHECK (monto_total > 0::numeric);
ALTER TABLE public.fee_agreements ADD CONSTRAINT fee_agreements_currency_format CHECK (moneda::text ~ '^[A-Z]{3}$'::text);
ALTER TABLE public.fee_agreements ADD CONSTRAINT fee_agreements_dates_valid CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio);
ALTER TABLE public.fee_agreements ADD CONSTRAINT fee_agreements_firm_id_id_unique UNIQUE (firm_id, id);
ALTER TABLE public.fee_agreements ADD CONSTRAINT fee_agreements_pkey PRIMARY KEY (id);
ALTER TABLE public.fee_installments ADD CONSTRAINT fee_installments_amount_positive CHECK (monto > 0::numeric);
ALTER TABLE public.fee_installments ADD CONSTRAINT fee_installments_due_rule CHECK (tipo_vencimiento = 'fecha'::installment_due_type AND fecha_vencimiento IS NOT NULL OR tipo_vencimiento = 'hito'::installment_due_type AND hito_vencimiento IS NOT NULL AND length(TRIM(BOTH FROM hito_vencimiento)) > 0);
ALTER TABLE public.fee_installments ADD CONSTRAINT fee_installments_firm_id_id_unique UNIQUE (firm_id, id);
ALTER TABLE public.fee_installments ADD CONSTRAINT fee_installments_number_positive CHECK (numero > 0);
ALTER TABLE public.fee_installments ADD CONSTRAINT fee_installments_pkey PRIMARY KEY (id);
ALTER TABLE public.fee_installments ADD CONSTRAINT fee_installments_unique_number UNIQUE (agreement_id, numero);
ALTER TABLE public.firm_invitations ADD CONSTRAINT firm_invitations_email_normalized CHECK (email = lower(TRIM(BOTH FROM email)));
ALTER TABLE public.firm_invitations ADD CONSTRAINT firm_invitations_email_not_empty CHECK (length(TRIM(BOTH FROM email)) > 0);
ALTER TABLE public.firm_invitations ADD CONSTRAINT firm_invitations_expiration_valid CHECK (expires_at > created_at);
ALTER TABLE public.firm_invitations ADD CONSTRAINT firm_invitations_kind_valid CHECK (kind = 'staff'::invitation_kind AND role <> 'cliente'::firm_role AND client_id IS NULL OR kind = 'client_portal'::invitation_kind AND role = 'cliente'::firm_role AND client_id IS NOT NULL);
ALTER TABLE public.firm_invitations ADD CONSTRAINT firm_invitations_pkey PRIMARY KEY (id);
ALTER TABLE public.firm_member_details ADD CONSTRAINT firm_member_details_cargo_not_blank CHECK (length(TRIM(BOTH FROM cargo)) > 0);
ALTER TABLE public.firm_member_details ADD CONSTRAINT firm_member_details_estado_laboral_check CHECK (estado_laboral = ANY (ARRAY['activo'::text, 'inactivo'::text, 'vacaciones'::text]));
ALTER TABLE public.firm_member_details ADD CONSTRAINT firm_member_details_pkey PRIMARY KEY (id);
ALTER TABLE public.firm_member_details ADD CONSTRAINT firm_member_details_unique_member UNIQUE (firm_id, user_id);
ALTER TABLE public.firm_memberships ADD CONSTRAINT firm_memberships_firm_id_id_unique UNIQUE (firm_id, id);
ALTER TABLE public.firm_memberships ADD CONSTRAINT firm_memberships_pkey PRIMARY KEY (id);
ALTER TABLE public.firm_memberships ADD CONSTRAINT firm_memberships_unique_user UNIQUE (firm_id, user_id);
ALTER TABLE public.firm_settings ADD CONSTRAINT firm_settings_categoria_not_blank CHECK (length(TRIM(BOTH FROM categoria)) > 0);
ALTER TABLE public.firm_settings ADD CONSTRAINT firm_settings_pkey PRIMARY KEY (id);
ALTER TABLE public.firm_settings ADD CONSTRAINT firm_settings_unique_categoria UNIQUE (firm_id, categoria);
ALTER TABLE public.firms ADD CONSTRAINT firms_pkey PRIMARY KEY (id);
ALTER TABLE public.firms ADD CONSTRAINT firms_slug_not_empty CHECK (length(TRIM(BOTH FROM slug)) > 0);
ALTER TABLE public.payment_allocations ADD CONSTRAINT payment_allocations_amount_positive CHECK (monto > 0::numeric);
ALTER TABLE public.payment_allocations ADD CONSTRAINT payment_allocations_pkey PRIMARY KEY (id);
ALTER TABLE public.payment_allocations ADD CONSTRAINT payment_allocations_unique_pair UNIQUE (payment_id, installment_id);
ALTER TABLE public.payment_distributions ADD CONSTRAINT payment_distributions_amount_positive CHECK (monto > 0::numeric);
ALTER TABLE public.payment_distributions ADD CONSTRAINT payment_distributions_base_positive CHECK (base_calculo > 0::numeric);
ALTER TABLE public.payment_distributions ADD CONSTRAINT payment_distributions_pkey PRIMARY KEY (id);
ALTER TABLE public.payment_distributions ADD CONSTRAINT payment_distributions_unique_rule UNIQUE (payment_id, agreement_id, rule_id);
ALTER TABLE public.payments ADD CONSTRAINT payments_amount_positive CHECK (monto > 0::numeric);
ALTER TABLE public.payments ADD CONSTRAINT payments_currency_format CHECK (moneda::text ~ '^[A-Z]{3}$'::text);
ALTER TABLE public.payments ADD CONSTRAINT payments_firm_id_id_unique UNIQUE (firm_id, id);
ALTER TABLE public.payments ADD CONSTRAINT payments_pkey PRIMARY KEY (id);
ALTER TABLE public.payments ADD CONSTRAINT payments_void_consistency CHECK (estado = 'registrado'::payment_status AND anulado_at IS NULL OR estado = 'anulado'::payment_status AND anulado_at IS NOT NULL);
ALTER TABLE public.plans ADD CONSTRAINT plans_code_not_empty CHECK (length(TRIM(BOTH FROM code)) > 0);
ALTER TABLE public.plans ADD CONSTRAINT plans_code_unique UNIQUE (code);
ALTER TABLE public.plans ADD CONSTRAINT plans_currency_format CHECK (currency::text ~ '^[A-Z]{3}$'::text);
ALTER TABLE public.plans ADD CONSTRAINT plans_name_not_empty CHECK (length(TRIM(BOTH FROM nombre)) > 0);
ALTER TABLE public.plans ADD CONSTRAINT plans_pkey PRIMARY KEY (id);
ALTER TABLE public.plans ADD CONSTRAINT plans_price_non_negative CHECK (price_amount IS NULL OR price_amount >= 0::numeric);
ALTER TABLE public.plans ADD CONSTRAINT plans_trial_non_negative CHECK (trial_days >= 0);
ALTER TABLE public.profiles ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);
ALTER TABLE public.subscription_events ADD CONSTRAINT subscription_events_pkey PRIMARY KEY (id);
ALTER TABLE public.subscription_events ADD CONSTRAINT subscription_events_type_not_empty CHECK (length(TRIM(BOTH FROM event_type)) > 0);
ALTER TABLE public.subscriptions ADD CONSTRAINT subscriptions_firm_id_id_unique UNIQUE (firm_id, id);
ALTER TABLE public.subscriptions ADD CONSTRAINT subscriptions_period_dates_valid CHECK (current_period_end IS NULL OR current_period_start IS NULL OR current_period_end >= current_period_start);
ALTER TABLE public.subscriptions ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);
ALTER TABLE public.subscriptions ADD CONSTRAINT subscriptions_trial_dates_valid CHECK (trial_end IS NULL OR trial_start IS NULL OR trial_end >= trial_start);
ALTER TABLE public.agenda_events ADD CONSTRAINT agenda_events_case_same_firm_fk FOREIGN KEY (firm_id, case_id) REFERENCES cases(firm_id, id) ON DELETE CASCADE;
ALTER TABLE public.agenda_events ADD CONSTRAINT agenda_events_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.agenda_events ADD CONSTRAINT agenda_events_firm_id_fkey FOREIGN KEY (firm_id) REFERENCES firms(id) ON DELETE CASCADE;
ALTER TABLE public.agenda_events ADD CONSTRAINT agenda_events_membership_same_firm_fk FOREIGN KEY (firm_id, assigned_membership_id) REFERENCES firm_memberships(firm_id, id) ON DELETE RESTRICT;
ALTER TABLE public.audit_logs ADD CONSTRAINT audit_logs_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.case_expenses ADD CONSTRAINT case_expenses_aprobado_por_fkey FOREIGN KEY (aprobado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.case_expenses ADD CONSTRAINT case_expenses_case_same_firm_fk FOREIGN KEY (firm_id, case_id) REFERENCES cases(firm_id, id) ON DELETE RESTRICT;
ALTER TABLE public.case_expenses ADD CONSTRAINT case_expenses_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.case_members ADD CONSTRAINT case_members_asignado_por_fkey FOREIGN KEY (asignado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.case_members ADD CONSTRAINT case_members_case_same_firm_fk FOREIGN KEY (firm_id, case_id) REFERENCES cases(firm_id, id) ON DELETE CASCADE;
ALTER TABLE public.case_members ADD CONSTRAINT case_members_membership_same_firm_fk FOREIGN KEY (firm_id, membership_id) REFERENCES firm_memberships(firm_id, id) ON DELETE CASCADE;
ALTER TABLE public.case_notes ADD CONSTRAINT case_notes_case_same_firm_fk FOREIGN KEY (firm_id, case_id) REFERENCES cases(firm_id, id) ON DELETE CASCADE;
ALTER TABLE public.case_notes ADD CONSTRAINT case_notes_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.case_reports ADD CONSTRAINT case_reports_case_same_firm_fk FOREIGN KEY (firm_id, case_id) REFERENCES cases(firm_id, id) ON DELETE CASCADE;
ALTER TABLE public.case_reports ADD CONSTRAINT case_reports_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.cases ADD CONSTRAINT cases_archivado_por_fkey FOREIGN KEY (archivado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.cases ADD CONSTRAINT cases_client_same_firm_fk FOREIGN KEY (firm_id, client_id) REFERENCES clients(firm_id, id) ON DELETE RESTRICT;
ALTER TABLE public.cases ADD CONSTRAINT cases_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.cases ADD CONSTRAINT cases_firm_id_fkey FOREIGN KEY (firm_id) REFERENCES firms(id) ON DELETE RESTRICT;
ALTER TABLE public.clients ADD CONSTRAINT clients_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.clients ADD CONSTRAINT clients_firm_id_fkey FOREIGN KEY (firm_id) REFERENCES firms(id) ON DELETE RESTRICT;
ALTER TABLE public.clients ADD CONSTRAINT clients_portal_user_id_fkey FOREIGN KEY (portal_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.compensation_rules ADD CONSTRAINT compensation_rules_member_same_firm_fk FOREIGN KEY (firm_id, membership_id) REFERENCES firm_memberships(firm_id, id) ON DELETE RESTRICT;
ALTER TABLE public.compensation_rules ADD CONSTRAINT compensation_rules_scheme_same_firm_fk FOREIGN KEY (firm_id, scheme_id) REFERENCES compensation_schemes(firm_id, id) ON DELETE CASCADE;
ALTER TABLE public.compensation_schemes ADD CONSTRAINT compensation_schemes_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.compensation_schemes ADD CONSTRAINT compensation_schemes_firm_id_fkey FOREIGN KEY (firm_id) REFERENCES firms(id) ON DELETE CASCADE;
ALTER TABLE public.document_templates ADD CONSTRAINT document_templates_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES profiles(id);
ALTER TABLE public.document_templates ADD CONSTRAINT document_templates_firm_id_fkey FOREIGN KEY (firm_id) REFERENCES firms(id) ON DELETE CASCADE;
ALTER TABLE public.documents ADD CONSTRAINT documents_archivado_por_fkey FOREIGN KEY (archivado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.documents ADD CONSTRAINT documents_case_same_firm_fk FOREIGN KEY (firm_id, case_id) REFERENCES cases(firm_id, id) ON DELETE CASCADE;
ALTER TABLE public.documents ADD CONSTRAINT documents_subido_por_fkey FOREIGN KEY (subido_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.fee_agreements ADD CONSTRAINT fee_agreements_autorizado_por_fkey FOREIGN KEY (autorizado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.fee_agreements ADD CONSTRAINT fee_agreements_case_same_firm_fk FOREIGN KEY (firm_id, case_id) REFERENCES cases(firm_id, id) ON DELETE RESTRICT;
ALTER TABLE public.fee_agreements ADD CONSTRAINT fee_agreements_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.fee_agreements ADD CONSTRAINT fee_agreements_scheme_same_firm_fk FOREIGN KEY (firm_id, compensation_scheme_id) REFERENCES compensation_schemes(firm_id, id) ON DELETE RESTRICT;
ALTER TABLE public.fee_installments ADD CONSTRAINT fee_installments_agreement_same_firm_fk FOREIGN KEY (firm_id, agreement_id) REFERENCES fee_agreements(firm_id, id) ON DELETE CASCADE;
ALTER TABLE public.firm_invitations ADD CONSTRAINT firm_invitations_accepted_by_fkey FOREIGN KEY (accepted_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.firm_invitations ADD CONSTRAINT firm_invitations_client_same_firm_fk FOREIGN KEY (firm_id, client_id) REFERENCES clients(firm_id, id) ON DELETE CASCADE;
ALTER TABLE public.firm_invitations ADD CONSTRAINT firm_invitations_firm_id_fkey FOREIGN KEY (firm_id) REFERENCES firms(id) ON DELETE CASCADE;
ALTER TABLE public.firm_invitations ADD CONSTRAINT firm_invitations_invited_by_fkey FOREIGN KEY (invited_by) REFERENCES auth.users(id) ON DELETE RESTRICT;
ALTER TABLE public.firm_invitations ADD CONSTRAINT firm_invitations_revoked_by_fkey FOREIGN KEY (revoked_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.firm_member_details ADD CONSTRAINT firm_member_details_membership_fk FOREIGN KEY (firm_id, user_id) REFERENCES firm_memberships(firm_id, user_id) ON DELETE CASCADE;
ALTER TABLE public.firm_memberships ADD CONSTRAINT firm_memberships_firm_id_fkey FOREIGN KEY (firm_id) REFERENCES firms(id) ON DELETE CASCADE;
ALTER TABLE public.firm_memberships ADD CONSTRAINT firm_memberships_invitado_por_fkey FOREIGN KEY (invitado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.firm_memberships ADD CONSTRAINT firm_memberships_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.firm_settings ADD CONSTRAINT firm_settings_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES profiles(id);
ALTER TABLE public.firm_settings ADD CONSTRAINT firm_settings_firm_id_fkey FOREIGN KEY (firm_id) REFERENCES firms(id) ON DELETE CASCADE;
ALTER TABLE public.payment_allocations ADD CONSTRAINT payment_allocations_installment_same_firm_fk FOREIGN KEY (firm_id, installment_id) REFERENCES fee_installments(firm_id, id) ON DELETE RESTRICT;
ALTER TABLE public.payment_allocations ADD CONSTRAINT payment_allocations_payment_same_firm_fk FOREIGN KEY (firm_id, payment_id) REFERENCES payments(firm_id, id) ON DELETE CASCADE;
ALTER TABLE public.payment_distributions ADD CONSTRAINT payment_distributions_agreement_same_firm_fk FOREIGN KEY (firm_id, agreement_id) REFERENCES fee_agreements(firm_id, id) ON DELETE RESTRICT;
ALTER TABLE public.payment_distributions ADD CONSTRAINT payment_distributions_member_same_firm_fk FOREIGN KEY (firm_id, membership_id) REFERENCES firm_memberships(firm_id, id) ON DELETE RESTRICT;
ALTER TABLE public.payment_distributions ADD CONSTRAINT payment_distributions_payment_same_firm_fk FOREIGN KEY (firm_id, payment_id) REFERENCES payments(firm_id, id) ON DELETE RESTRICT;
ALTER TABLE public.payment_distributions ADD CONSTRAINT payment_distributions_rule_same_firm_fk FOREIGN KEY (firm_id, rule_id) REFERENCES compensation_rules(firm_id, id) ON DELETE RESTRICT;
ALTER TABLE public.payment_distributions ADD CONSTRAINT payment_distributions_scheme_same_firm_fk FOREIGN KEY (firm_id, scheme_id) REFERENCES compensation_schemes(firm_id, id) ON DELETE RESTRICT;
ALTER TABLE public.payments ADD CONSTRAINT payments_anulado_por_fkey FOREIGN KEY (anulado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.payments ADD CONSTRAINT payments_case_same_firm_fk FOREIGN KEY (firm_id, case_id) REFERENCES cases(firm_id, id) ON DELETE RESTRICT;
ALTER TABLE public.payments ADD CONSTRAINT payments_registrado_por_fkey FOREIGN KEY (registrado_por) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.subscription_events ADD CONSTRAINT subscription_events_firm_id_fkey FOREIGN KEY (firm_id) REFERENCES firms(id) ON DELETE CASCADE;
ALTER TABLE public.subscription_events ADD CONSTRAINT subscription_events_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE SET NULL;
ALTER TABLE public.subscriptions ADD CONSTRAINT subscriptions_firm_id_fkey FOREIGN KEY (firm_id) REFERENCES firms(id) ON DELETE CASCADE;
ALTER TABLE public.subscriptions ADD CONSTRAINT subscriptions_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS agenda_events_assigned_idx ON public.agenda_events USING btree (firm_id, assigned_membership_id);
CREATE INDEX IF NOT EXISTS agenda_events_case_idx ON public.agenda_events USING btree (firm_id, case_id) WHERE (case_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS agenda_events_firm_dates_idx ON public.agenda_events USING btree (firm_id, fecha_inicio, fecha_fin);
CREATE UNIQUE INDEX IF NOT EXISTS agenda_events_pkey ON public.agenda_events USING btree (id);
CREATE INDEX IF NOT EXISTS agenda_events_status_idx ON public.agenda_events USING btree (firm_id, estado);
CREATE INDEX IF NOT EXISTS audit_logs_actor_idx ON public.audit_logs USING btree (actor_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS audit_logs_entity_idx ON public.audit_logs USING btree (firm_id, entidad, entidad_id);
CREATE INDEX IF NOT EXISTS audit_logs_firm_date_idx ON public.audit_logs USING btree (firm_id, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS audit_logs_pkey ON public.audit_logs USING btree (id);
CREATE INDEX IF NOT EXISTS case_expenses_case_idx ON public.case_expenses USING btree (firm_id, case_id, fecha DESC);
CREATE UNIQUE INDEX IF NOT EXISTS case_expenses_pkey ON public.case_expenses USING btree (id);
CREATE INDEX IF NOT EXISTS case_expenses_status_idx ON public.case_expenses USING btree (firm_id, estado);
CREATE INDEX IF NOT EXISTS case_members_active_idx ON public.case_members USING btree (firm_id, case_id, activo);
CREATE INDEX IF NOT EXISTS case_members_case_idx ON public.case_members USING btree (firm_id, case_id);
CREATE INDEX IF NOT EXISTS case_members_membership_idx ON public.case_members USING btree (firm_id, membership_id);
CREATE UNIQUE INDEX IF NOT EXISTS case_members_one_active_owner ON public.case_members USING btree (case_id) WHERE ((role = 'responsable'::case_member_role) AND (activo = true));
CREATE UNIQUE INDEX IF NOT EXISTS case_members_pkey ON public.case_members USING btree (id);
CREATE UNIQUE INDEX IF NOT EXISTS case_members_unique ON public.case_members USING btree (case_id, membership_id);
CREATE INDEX IF NOT EXISTS case_notes_case_idx ON public.case_notes USING btree (firm_id, case_id, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS case_notes_pkey ON public.case_notes USING btree (id);
CREATE INDEX IF NOT EXISTS case_notes_visible_client_idx ON public.case_notes USING btree (firm_id, case_id, visible_cliente) WHERE (visible_cliente = true);
CREATE INDEX IF NOT EXISTS case_reports_case_idx ON public.case_reports USING btree (firm_id, case_id, periodo DESC);
CREATE UNIQUE INDEX IF NOT EXISTS case_reports_pkey ON public.case_reports USING btree (id);
CREATE UNIQUE INDEX IF NOT EXISTS case_reports_unique_period ON public.case_reports USING btree (firm_id, case_id, periodo);
CREATE INDEX IF NOT EXISTS cases_archived_idx ON public.cases USING btree (firm_id, archivado);
CREATE INDEX IF NOT EXISTS cases_client_idx ON public.cases USING btree (firm_id, client_id);
CREATE UNIQUE INDEX IF NOT EXISTS cases_firm_case_number_unique ON public.cases USING btree (firm_id, numero_caso);
CREATE UNIQUE INDEX IF NOT EXISTS cases_firm_id_id_unique ON public.cases USING btree (firm_id, id);
CREATE INDEX IF NOT EXISTS cases_firm_idx ON public.cases USING btree (firm_id);
CREATE INDEX IF NOT EXISTS cases_numero_felcc_idx ON public.cases USING btree (firm_id, numero_felcc) WHERE (numero_felcc IS NOT NULL);
CREATE INDEX IF NOT EXISTS cases_numero_fiscalia_idx ON public.cases USING btree (firm_id, numero_fiscalia) WHERE (numero_fiscalia IS NOT NULL);
CREATE INDEX IF NOT EXISTS cases_nurej_idx ON public.cases USING btree (firm_id, nurej) WHERE (nurej IS NOT NULL);
CREATE UNIQUE INDEX IF NOT EXISTS cases_pkey ON public.cases USING btree (id);
CREATE INDEX IF NOT EXISTS cases_status_idx ON public.cases USING btree (firm_id, estado);
CREATE UNIQUE INDEX IF NOT EXISTS clients_firm_id_id_unique ON public.clients USING btree (firm_id, id);
CREATE INDEX IF NOT EXISTS clients_firm_idx ON public.clients USING btree (firm_id);
CREATE INDEX IF NOT EXISTS clients_firm_name_idx ON public.clients USING btree (firm_id, apellido_paterno, nombres);
CREATE UNIQUE INDEX IF NOT EXISTS clients_firm_portal_user_unique ON public.clients USING btree (firm_id, portal_user_id) WHERE (portal_user_id IS NOT NULL);
CREATE UNIQUE INDEX IF NOT EXISTS clients_pkey ON public.clients USING btree (id);
CREATE INDEX IF NOT EXISTS clients_portal_user_idx ON public.clients USING btree (portal_user_id) WHERE (portal_user_id IS NOT NULL);
CREATE UNIQUE INDEX IF NOT EXISTS compensation_rules_firm_id_id_unique ON public.compensation_rules USING btree (firm_id, id);
CREATE UNIQUE INDEX IF NOT EXISTS compensation_rules_pkey ON public.compensation_rules USING btree (id);
CREATE INDEX IF NOT EXISTS compensation_rules_scheme_idx ON public.compensation_rules USING btree (firm_id, scheme_id, activo, orden);
CREATE UNIQUE INDEX IF NOT EXISTS compensation_schemes_firm_id_id_unique ON public.compensation_schemes USING btree (firm_id, id);
CREATE INDEX IF NOT EXISTS compensation_schemes_firm_idx ON public.compensation_schemes USING btree (firm_id, activo);
CREATE UNIQUE INDEX IF NOT EXISTS compensation_schemes_name_unique ON public.compensation_schemes USING btree (firm_id, nombre);
CREATE UNIQUE INDEX IF NOT EXISTS compensation_schemes_pkey ON public.compensation_schemes USING btree (id);
CREATE INDEX IF NOT EXISTS document_templates_firm_id_idx ON public.document_templates USING btree (firm_id);
CREATE INDEX IF NOT EXISTS document_templates_firm_tipo_idx ON public.document_templates USING btree (firm_id, tipo);
CREATE UNIQUE INDEX IF NOT EXISTS document_templates_pkey ON public.document_templates USING btree (id);
CREATE INDEX IF NOT EXISTS documents_case_idx ON public.documents USING btree (firm_id, case_id);
CREATE INDEX IF NOT EXISTS documents_case_status_idx ON public.documents USING btree (firm_id, case_id, status);
CREATE UNIQUE INDEX IF NOT EXISTS documents_firm_id_id_unique ON public.documents USING btree (firm_id, id);
CREATE INDEX IF NOT EXISTS documents_firm_idx ON public.documents USING btree (firm_id);
CREATE UNIQUE INDEX IF NOT EXISTS documents_pkey ON public.documents USING btree (id);
CREATE UNIQUE INDEX IF NOT EXISTS documents_storage_path_unique ON public.documents USING btree (storage_path);
CREATE INDEX IF NOT EXISTS documents_uploaded_by_idx ON public.documents USING btree (subido_por);
CREATE INDEX IF NOT EXISTS documents_visible_client_idx ON public.documents USING btree (firm_id, case_id, visible_cliente) WHERE (visible_cliente = true);
CREATE INDEX IF NOT EXISTS fee_agreements_case_idx ON public.fee_agreements USING btree (firm_id, case_id);
CREATE UNIQUE INDEX IF NOT EXISTS fee_agreements_firm_id_id_unique ON public.fee_agreements USING btree (firm_id, id);
CREATE UNIQUE INDEX IF NOT EXISTS fee_agreements_number_unique ON public.fee_agreements USING btree (firm_id, numero_contrato) WHERE (numero_contrato IS NOT NULL);
CREATE UNIQUE INDEX IF NOT EXISTS fee_agreements_pkey ON public.fee_agreements USING btree (id);
CREATE INDEX IF NOT EXISTS fee_agreements_status_idx ON public.fee_agreements USING btree (firm_id, estado);
CREATE INDEX IF NOT EXISTS fee_installments_agreement_idx ON public.fee_installments USING btree (firm_id, agreement_id);
CREATE INDEX IF NOT EXISTS fee_installments_due_idx ON public.fee_installments USING btree (firm_id, fecha_vencimiento) WHERE (estado = ANY (ARRAY['pendiente'::installment_status, 'atrasado'::installment_status]));
CREATE UNIQUE INDEX IF NOT EXISTS fee_installments_firm_id_id_unique ON public.fee_installments USING btree (firm_id, id);
CREATE UNIQUE INDEX IF NOT EXISTS fee_installments_pkey ON public.fee_installments USING btree (id);
CREATE UNIQUE INDEX IF NOT EXISTS fee_installments_unique_number ON public.fee_installments USING btree (agreement_id, numero);
CREATE INDEX IF NOT EXISTS firm_invitations_email_idx ON public.firm_invitations USING btree (lower(email));
CREATE INDEX IF NOT EXISTS firm_invitations_firm_idx ON public.firm_invitations USING btree (firm_id, status, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS firm_invitations_pending_client_unique ON public.firm_invitations USING btree (firm_id, client_id) WHERE ((status = 'pendiente'::invitation_status) AND (client_id IS NOT NULL));
CREATE UNIQUE INDEX IF NOT EXISTS firm_invitations_pending_email_unique ON public.firm_invitations USING btree (firm_id, lower(email)) WHERE (status = 'pendiente'::invitation_status);
CREATE UNIQUE INDEX IF NOT EXISTS firm_invitations_pkey ON public.firm_invitations USING btree (id);
CREATE INDEX IF NOT EXISTS firm_member_details_firm_id_idx ON public.firm_member_details USING btree (firm_id);
CREATE UNIQUE INDEX IF NOT EXISTS firm_member_details_pkey ON public.firm_member_details USING btree (id);
CREATE UNIQUE INDEX IF NOT EXISTS firm_member_details_unique_member ON public.firm_member_details USING btree (firm_id, user_id);
CREATE INDEX IF NOT EXISTS firm_member_details_user_id_idx ON public.firm_member_details USING btree (user_id);
CREATE UNIQUE INDEX IF NOT EXISTS firm_memberships_firm_id_id_unique ON public.firm_memberships USING btree (firm_id, id);
CREATE INDEX IF NOT EXISTS firm_memberships_firm_idx ON public.firm_memberships USING btree (firm_id);
CREATE INDEX IF NOT EXISTS firm_memberships_firm_role_idx ON public.firm_memberships USING btree (firm_id, role);
CREATE UNIQUE INDEX IF NOT EXISTS firm_memberships_pkey ON public.firm_memberships USING btree (id);
CREATE UNIQUE INDEX IF NOT EXISTS firm_memberships_unique_user ON public.firm_memberships USING btree (firm_id, user_id);
CREATE INDEX IF NOT EXISTS firm_memberships_user_idx ON public.firm_memberships USING btree (user_id);
CREATE INDEX IF NOT EXISTS firm_settings_firm_id_idx ON public.firm_settings USING btree (firm_id);
CREATE UNIQUE INDEX IF NOT EXISTS firm_settings_pkey ON public.firm_settings USING btree (id);
CREATE UNIQUE INDEX IF NOT EXISTS firm_settings_unique_categoria ON public.firm_settings USING btree (firm_id, categoria);
CREATE UNIQUE INDEX IF NOT EXISTS firms_pkey ON public.firms USING btree (id);
CREATE UNIQUE INDEX IF NOT EXISTS firms_slug_unique ON public.firms USING btree (lower(slug));
CREATE INDEX IF NOT EXISTS payment_allocations_installment_idx ON public.payment_allocations USING btree (firm_id, installment_id);
CREATE INDEX IF NOT EXISTS payment_allocations_payment_idx ON public.payment_allocations USING btree (firm_id, payment_id);
CREATE UNIQUE INDEX IF NOT EXISTS payment_allocations_pkey ON public.payment_allocations USING btree (id);
CREATE UNIQUE INDEX IF NOT EXISTS payment_allocations_unique_pair ON public.payment_allocations USING btree (payment_id, installment_id);
CREATE INDEX IF NOT EXISTS payment_distributions_agreement_idx ON public.payment_distributions USING btree (firm_id, agreement_id);
CREATE INDEX IF NOT EXISTS payment_distributions_member_idx ON public.payment_distributions USING btree (firm_id, membership_id, estado) WHERE (membership_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS payment_distributions_payment_idx ON public.payment_distributions USING btree (firm_id, payment_id);
CREATE UNIQUE INDEX IF NOT EXISTS payment_distributions_pkey ON public.payment_distributions USING btree (id);
CREATE UNIQUE INDEX IF NOT EXISTS payment_distributions_unique_rule ON public.payment_distributions USING btree (payment_id, agreement_id, rule_id);
CREATE INDEX IF NOT EXISTS payments_case_idx ON public.payments USING btree (firm_id, case_id, fecha_pago DESC);
CREATE UNIQUE INDEX IF NOT EXISTS payments_firm_id_id_unique ON public.payments USING btree (firm_id, id);
CREATE UNIQUE INDEX IF NOT EXISTS payments_pkey ON public.payments USING btree (id);
CREATE INDEX IF NOT EXISTS payments_status_idx ON public.payments USING btree (firm_id, estado);
CREATE UNIQUE INDEX IF NOT EXISTS plans_code_unique ON public.plans USING btree (code);
CREATE UNIQUE INDEX IF NOT EXISTS plans_pkey ON public.plans USING btree (id);
CREATE UNIQUE INDEX IF NOT EXISTS profiles_pkey ON public.profiles USING btree (id);
CREATE INDEX IF NOT EXISTS subscription_events_firm_idx ON public.subscription_events USING btree (firm_id, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS subscription_events_pkey ON public.subscription_events USING btree (id);
CREATE UNIQUE INDEX IF NOT EXISTS subscriptions_firm_id_id_unique ON public.subscriptions USING btree (firm_id, id);
CREATE UNIQUE INDEX IF NOT EXISTS subscriptions_one_current_per_firm ON public.subscriptions USING btree (firm_id) WHERE (status = ANY (ARRAY['trialing'::subscription_status, 'active'::subscription_status, 'past_due'::subscription_status]));
CREATE UNIQUE INDEX IF NOT EXISTS subscriptions_pkey ON public.subscriptions USING btree (id);
CREATE INDEX IF NOT EXISTS subscriptions_provider_idx ON public.subscriptions USING btree (billing_provider, provider_subscription_id) WHERE (provider_subscription_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS subscriptions_status_idx ON public.subscriptions USING btree (status);
CREATE INDEX IF NOT EXISTS subscriptions_trial_end_idx ON public.subscriptions USING btree (trial_end) WHERE (status = 'trialing'::subscription_status);
CREATE OR REPLACE FUNCTION private.audit_row_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_firm_id uuid;
  v_entity_id uuid;
begin

  -- ----------------------------------------------------------
  -- Extraer firm_id e id tanto de INSERT/UPDATE como DELETE
  -- ----------------------------------------------------------

  if tg_op = 'DELETE' then

    v_firm_id :=
      nullif(
        to_jsonb(old)->>'firm_id',
        ''
      )::uuid;

    v_entity_id :=
      nullif(
        to_jsonb(old)->>'id',
        ''
      )::uuid;

    insert into public.audit_logs (
      firm_id,
      actor_user_id,
      accion,
      entidad,
      entidad_id,
      datos_anteriores,
      datos_nuevos
    )
    values (
      v_firm_id,
      auth.uid(),
      'delete',
      tg_table_name,
      v_entity_id,
      to_jsonb(old),
      null
    );

    return old;

  elsif tg_op = 'UPDATE' then

    v_firm_id :=
      nullif(
        to_jsonb(new)->>'firm_id',
        ''
      )::uuid;

    v_entity_id :=
      nullif(
        to_jsonb(new)->>'id',
        ''
      )::uuid;

    insert into public.audit_logs (
      firm_id,
      actor_user_id,
      accion,
      entidad,
      entidad_id,
      datos_anteriores,
      datos_nuevos
    )
    values (
      v_firm_id,
      auth.uid(),
      'update',
      tg_table_name,
      v_entity_id,
      to_jsonb(old),
      to_jsonb(new)
    );

    return new;

  else

    v_firm_id :=
      nullif(
        to_jsonb(new)->>'firm_id',
        ''
      )::uuid;

    v_entity_id :=
      nullif(
        to_jsonb(new)->>'id',
        ''
      )::uuid;

    insert into public.audit_logs (
      firm_id,
      actor_user_id,
      accion,
      entidad,
      entidad_id,
      datos_anteriores,
      datos_nuevos
    )
    values (
      v_firm_id,
      auth.uid(),
      'insert',
      tg_table_name,
      v_entity_id,
      null,
      to_jsonb(new)
    );

    return new;

  end if;

end;
$function$
;
CREATE OR REPLACE FUNCTION private.can_access_agenda_event(target_firm_id uuid, target_case_id uuid, target_membership_id uuid, target_created_by uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select

    private.firm_is_operational(
      target_firm_id
    )

    and

    (

      private.has_firm_role_raw(
        target_firm_id,
        array[
          'admin',
          'asociado_senior'
        ]::public.firm_role[]
      )

      or

      target_created_by = auth.uid()

      or

      exists (

        select 1

        from public.firm_memberships fm

        where fm.id = target_membership_id

          and fm.firm_id = target_firm_id

          and fm.user_id = auth.uid()

          and fm.status =
            'activo'::public.membership_status
      )

      or

      (
        target_case_id is not null

        and

        private.can_access_case(
          target_firm_id,
          target_case_id
        )
      )

    );
$function$
;
CREATE OR REPLACE FUNCTION private.can_access_case(target_firm_id uuid, target_case_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select

    private.firm_is_operational(
      target_firm_id
    )

    and

    (

      private.has_firm_role_raw(
        target_firm_id,
        array[
          'admin',
          'asociado_senior'
        ]::public.firm_role[]
      )

      or

      exists (

        select 1

        from public.case_members cm

        join public.firm_memberships fm
          on fm.id = cm.membership_id
         and fm.firm_id = cm.firm_id

        where cm.firm_id = target_firm_id

          and cm.case_id = target_case_id

          and cm.activo = true

          and fm.user_id = auth.uid()

          and fm.status =
            'activo'::public.membership_status
      )
    );
$function$
;
CREATE OR REPLACE FUNCTION private.can_access_case_documents(target_firm_id uuid, target_case_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    private.can_access_case(
      target_firm_id,
      target_case_id
    );
$function$
;
CREATE OR REPLACE FUNCTION private.can_manage_finance(target_firm_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select private.has_firm_role(
    target_firm_id,
    array[
      'admin',
      'finanzas'
    ]::public.firm_role[]
  );
$function$
;
CREATE OR REPLACE FUNCTION private.can_view_team_profile(target_user_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (

    select 1

    from public.firm_memberships viewer

    join public.firm_memberships target
      on target.firm_id = viewer.firm_id

    where viewer.user_id = auth.uid()

      and target.user_id = target_user_id

      and viewer.status =
        'activo'::public.membership_status

      and target.status =
        'activo'::public.membership_status

      and viewer.role in (
        'admin'::public.firm_role,
        'finanzas'::public.firm_role,
        'asociado_senior'::public.firm_role,
        'abogado'::public.firm_role
      )

      and target.role <> 'cliente'::public.firm_role

      and private.firm_is_operational(
        viewer.firm_id
      )
  );
$function$
;
CREATE OR REPLACE FUNCTION private.create_initial_subscription()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_plan_id uuid;
  v_trial_days integer;
  v_subscription_id uuid;
  v_start timestamptz;
  v_end timestamptz;
begin

  select
    p.id,
    p.trial_days
  into
    v_plan_id,
    v_trial_days
  from public.plans p
  where p.code = 'corporate'
    and p.activo = true
  limit 1;


  if v_plan_id is null then
    raise exception
      'No existe el plan corporativo activo';
  end if;


  v_start := coalesce(
    new.trial_started_at,
    now()
  );

  v_end := v_start
    + make_interval(days => v_trial_days);


  -- Sincronizar firma

  update public.firms
  set
    status = 'trial'::public.firm_status,
    trial_started_at = v_start,
    trial_ends_at = v_end
  where id = new.id;


  -- Crear suscripción

  insert into public.subscriptions (
    firm_id,
    plan_id,
    status,
    trial_start,
    trial_end
  )
  values (
    new.id,
    v_plan_id,
    'trialing'::public.subscription_status,
    v_start,
    v_end
  )
  returning id into v_subscription_id;


  insert into public.subscription_events (
    firm_id,
    subscription_id,
    event_type,
    new_status,
    metadata
  )
  values (
    new.id,
    v_subscription_id,
    'trial_started',
    'trialing'::public.subscription_status,
    jsonb_build_object(
      'trial_days',
      v_trial_days,
      'trial_end',
      v_end
    )
  );


  return new;
end;
$function$
;
CREATE OR REPLACE FUNCTION private.document_path_is_valid(target_firm_id uuid, target_case_id uuid, target_document_id uuid, target_path text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  select
    split_part(target_path, '/', 1) = target_firm_id::text
    and split_part(target_path, '/', 2) = target_case_id::text
    and split_part(target_path, '/', 3) = target_document_id::text
    and split_part(target_path, '/', 4) <> ''
    and array_length(
      string_to_array(target_path, '/'),
      1
    ) >= 4;
$function$
;
CREATE OR REPLACE FUNCTION private.firm_is_operational(target_firm_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (

    select 1

    from public.subscriptions s

    where s.firm_id = target_firm_id

      and (

        s.status = 'active'::public.subscription_status

        or

        s.status = 'past_due'::public.subscription_status

        or

        (
          s.status = 'trialing'::public.subscription_status

          and s.trial_end is not null

          and now() < s.trial_end
        )

      )
  );
$function$
;
CREATE OR REPLACE FUNCTION private.has_firm_role(target_firm_id uuid, allowed_roles firm_role[])
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select

    private.firm_is_operational(target_firm_id)

    and

    private.has_firm_role_raw(
      target_firm_id,
      allowed_roles
    );
$function$
;
CREATE OR REPLACE FUNCTION private.has_firm_role_raw(target_firm_id uuid, allowed_roles firm_role[])
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (

    select 1

    from public.firm_memberships fm

    where fm.firm_id = target_firm_id

      and fm.user_id = auth.uid()

      and fm.status =
        'activo'::public.membership_status

      and fm.role = any(allowed_roles)
  );
$function$
;
CREATE OR REPLACE FUNCTION private.is_case_client(target_firm_id uuid, target_case_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (
    select 1
    from public.cases c
    join public.clients cl
      on cl.id = c.client_id
     and cl.firm_id = c.firm_id

    where c.id = target_case_id
      and c.firm_id = target_firm_id
      and cl.portal_user_id = auth.uid()
      and private.has_firm_role(
        target_firm_id,
        array[
          'cliente'
        ]::public.firm_role[]
      )
  );
$function$
;
CREATE OR REPLACE FUNCTION private.is_firm_member(target_firm_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (
    select 1
    from public.firm_memberships fm
    where fm.firm_id = target_firm_id
      and fm.user_id = (select auth.uid())
      and fm.status = 'activo'::public.membership_status
  );
$function$
;
CREATE OR REPLACE FUNCTION private.protect_case_identity()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin

  if new.firm_id is distinct from old.firm_id
     or new.client_id is distinct from old.client_id
  then

    raise exception
      'No se puede mover un expediente a otra firma o cliente';

  end if;


  return new;

end;
$function$
;
CREATE OR REPLACE FUNCTION private.protect_case_member_identity()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin

  if new.firm_id is distinct from old.firm_id
     or new.case_id is distinct from old.case_id
     or new.membership_id is distinct from old.membership_id
  then

    raise exception
      'No se puede mover una asignación existente a otro expediente, miembro o firma';

  end if;


  return new;

end;
$function$
;
CREATE OR REPLACE FUNCTION private.protect_client_firm()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin

  if new.firm_id is distinct from old.firm_id then
    raise exception
      'No se puede mover un cliente a otra firma';
  end if;


  return new;

end;
$function$
;
CREATE OR REPLACE FUNCTION private.protect_compensation_rule_identity()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin

  if new.firm_id is distinct from old.firm_id
     or new.scheme_id is distinct from old.scheme_id
  then

    raise exception
      'No se puede mover una regla de compensación a otro esquema o firma';

  end if;


  return new;

end;
$function$
;
CREATE OR REPLACE FUNCTION private.protect_compensation_scheme_identity()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin

  if new.firm_id is distinct from old.firm_id then
    raise exception
      'No se puede mover un esquema de compensación a otra firma';
  end if;


  return new;

end;
$function$
;
CREATE OR REPLACE FUNCTION private.protect_distribution_snapshot()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin

  if new.firm_id is distinct from old.firm_id
    or new.payment_id is distinct from old.payment_id
    or new.agreement_id is distinct from old.agreement_id
    or new.scheme_id is distinct from old.scheme_id
    or new.rule_id is distinct from old.rule_id
    or new.rule_name is distinct from old.rule_name
    or new.recipient_type is distinct from old.recipient_type
    or new.membership_id is distinct from old.membership_id
    or new.recipient_label is distinct from old.recipient_label
    or new.calculation_type is distinct from old.calculation_type
    or new.rule_value is distinct from old.rule_value
    or new.base_calculo is distinct from old.base_calculo
    or new.monto is distinct from old.monto
  then

    raise exception
      'Los valores financieros históricos de una distribución son inmutables';

  end if;


  return new;

end;
$function$
;
CREATE OR REPLACE FUNCTION private.protect_document_identity()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin

  if new.firm_id is distinct from old.firm_id
     or new.case_id is distinct from old.case_id
     or new.storage_path is distinct from old.storage_path
     or new.subido_por is distinct from old.subido_por
  then

    raise exception
      'No se puede cambiar la identidad estructural de un documento existente';

  end if;


  return new;

end;
$function$
;
CREATE OR REPLACE FUNCTION private.protect_fee_agreement_total()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_installments_total numeric(18,2);
begin

  if new.monto_total is distinct from old.monto_total then

    select coalesce(sum(fi.monto), 0)
    into v_installments_total
    from public.fee_installments fi
    where fi.agreement_id = old.id
      and fi.firm_id = old.firm_id;


    if new.monto_total < v_installments_total then
      raise exception
        'El monto del contrato (%) no puede ser menor que sus cuotas existentes (%)',
        new.monto_total,
        v_installments_total;
    end if;

  end if;


  if new.firm_id is distinct from old.firm_id
     or new.case_id is distinct from old.case_id
  then

    raise exception
      'No se puede mover un contrato de honorarios a otra firma o expediente';

  end if;


  return new;

end;
$function$
;
CREATE OR REPLACE FUNCTION private.protect_installment_identity()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin

  if new.firm_id is distinct from old.firm_id
     or new.agreement_id is distinct from old.agreement_id
  then

    raise exception
      'No se puede mover una cuota a otro contrato o firma';

  end if;


  return new;

end;
$function$
;
CREATE OR REPLACE FUNCTION private.protect_last_firm_admin()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_admin_count integer;
  v_losing_admin boolean := false;
begin

  if tg_op = 'DELETE' then

    v_losing_admin :=
      old.role = 'admin'::public.firm_role
      and old.status = 'activo'::public.membership_status;

  elsif tg_op = 'UPDATE' then

    v_losing_admin :=
      old.role = 'admin'::public.firm_role
      and old.status = 'activo'::public.membership_status
      and (
        new.role <> 'admin'::public.firm_role
        or new.status <> 'activo'::public.membership_status
      );

  end if;


  if v_losing_admin then

    select count(*)
    into v_admin_count
    from public.firm_memberships fm
    where fm.firm_id = old.firm_id
      and fm.role = 'admin'::public.firm_role
      and fm.status = 'activo'::public.membership_status
      and fm.id <> old.id;


    if v_admin_count = 0 then
      raise exception
        'La firma debe conservar al menos un administrador activo';
    end if;

  end if;


  if tg_op = 'DELETE' then
    return old;
  end if;

  return new;

end;
$function$
;
CREATE OR REPLACE FUNCTION private.protect_payment_allocation_identity()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin

  if new.firm_id is distinct from old.firm_id
     or new.payment_id is distinct from old.payment_id
     or new.installment_id is distinct from old.installment_id
  then

    raise exception
      'No se puede mover una aplicación a otro pago, cuota o firma';

  end if;


  return new;

end;
$function$
;
CREATE OR REPLACE FUNCTION private.protect_payment_allocations()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_payment_id uuid;
begin

  if tg_op = 'DELETE' then
    v_payment_id := old.payment_id;
  else
    v_payment_id := new.payment_id;
  end if;


  if exists (
    select 1
    from public.payment_distributions pd
    where pd.payment_id = v_payment_id
      and pd.estado <> 'anulado'
  ) then

    raise exception
      'No se pueden modificar aplicaciones de un pago con distribuciones activas';

  end if;


  if tg_op = 'DELETE' then
    return old;
  end if;


  return new;

end;
$function$
;
CREATE OR REPLACE FUNCTION private.protect_payment_integrity()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_has_allocations boolean;
  v_has_distributions boolean;
begin

  select exists (
    select 1
    from public.payment_allocations pa
    where pa.payment_id = old.id
  )
  into v_has_allocations;


  select exists (
    select 1
    from public.payment_distributions pd
    where pd.payment_id = old.id
      and pd.estado <> 'anulado'
  )
  into v_has_distributions;


  if v_has_allocations or v_has_distributions then

    if new.monto is distinct from old.monto then
      raise exception
        'No se puede modificar el monto de un pago aplicado';
    end if;


    if new.moneda is distinct from old.moneda then
      raise exception
        'No se puede modificar la moneda de un pago aplicado';
    end if;


    if new.case_id is distinct from old.case_id then
      raise exception
        'No se puede mover un pago aplicado a otro expediente';
    end if;


    if new.firm_id is distinct from old.firm_id then
      raise exception
        'No se puede cambiar la firma de un pago';
    end if;


    if new.fecha_pago is distinct from old.fecha_pago then
      raise exception
        'No se puede modificar la fecha de un pago aplicado';
    end if;


    if new.registrado_por is distinct from old.registrado_por then
      raise exception
        'No se puede cambiar el usuario que registró el pago';
    end if;

  end if;


  return new;

end;
$function$
;
CREATE OR REPLACE FUNCTION private.protect_voided_payment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin

  if old.estado = 'anulado'::public.payment_status then

    if new is distinct from old then
      raise exception
        'Un pago anulado es histórico y no puede modificarse';
    end if;

  end if;


  -- Solo permitimos transición registrado -> anulado.
  if old.estado = 'anulado'::public.payment_status
     and new.estado = 'registrado'::public.payment_status
  then

    raise exception
      'No se puede reactivar un pago anulado';
  end if;


  return new;

end;
$function$
;
CREATE OR REPLACE FUNCTION private.touch_updated_at_011()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
    new.actualizado_en = now();
    return new;
end;
$function$
;
CREATE OR REPLACE FUNCTION private.validate_compensation_percentage()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_total numeric(18,4);
begin

  if new.calculation_type <> 'porcentaje'
     or new.activo = false then
    return new;
  end if;


  select coalesce(sum(r.valor), 0)
  into v_total
  from public.compensation_rules r
  where r.scheme_id = new.scheme_id
    and r.firm_id = new.firm_id
    and r.id <> new.id
    and r.activo = true
    and r.calculation_type = 'porcentaje';


  if v_total + new.valor > 100 then
    raise exception
      'Las reglas porcentuales activas del esquema superan el 100%%';
  end if;


  return new;
end;
$function$
;
CREATE OR REPLACE FUNCTION private.validate_installment_total()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_contract_total numeric(18,2);
  v_installments_total numeric(18,2);
begin

  select fa.monto_total
  into v_contract_total
  from public.fee_agreements fa
  where fa.id = new.agreement_id
    and fa.firm_id = new.firm_id;


  if v_contract_total is null then
    raise exception
      'Contrato de honorarios no encontrado';
  end if;


  select coalesce(sum(fi.monto), 0)
  into v_installments_total
  from public.fee_installments fi
  where fi.agreement_id = new.agreement_id
    and fi.id <> new.id;


  v_installments_total :=
    v_installments_total + new.monto;


  if v_installments_total > v_contract_total then
    raise exception
      'La suma de cuotas (%) supera el monto del contrato (%)',
      v_installments_total,
      v_contract_total;
  end if;


  return new;
end;
$function$
;
CREATE OR REPLACE FUNCTION private.validate_payment_allocation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_payment_amount numeric(18,2);
  v_payment_currency varchar(3);
  v_payment_case uuid;

  v_installment_amount numeric(18,2);
  v_installment_status public.installment_status;

  v_agreement_currency varchar(3);
  v_agreement_case uuid;

  v_payment_allocated numeric(18,2);
  v_installment_allocated numeric(18,2);
begin

  select
    p.monto,
    p.moneda,
    p.case_id
  into
    v_payment_amount,
    v_payment_currency,
    v_payment_case
  from public.payments p
  where p.id = new.payment_id
    and p.firm_id = new.firm_id
    and p.estado = 'registrado'::public.payment_status;


  if v_payment_amount is null then
    raise exception
      'Pago registrado no encontrado';
  end if;


  select
    fi.monto,
    fi.estado,
    fa.moneda,
    fa.case_id
  into
    v_installment_amount,
    v_installment_status,
    v_agreement_currency,
    v_agreement_case
  from public.fee_installments fi
  join public.fee_agreements fa
    on fa.id = fi.agreement_id
   and fa.firm_id = fi.firm_id
  where fi.id = new.installment_id
    and fi.firm_id = new.firm_id;


  if v_installment_amount is null then
    raise exception
      'Cuota no encontrada';
  end if;


  if v_installment_status = 'cancelado'::public.installment_status then
    raise exception
      'No se puede aplicar un pago a una cuota cancelada';
  end if;


  if v_payment_case is distinct from v_agreement_case then
    raise exception
      'El pago y la cuota pertenecen a expedientes distintos';
  end if;


  if v_payment_currency is distinct from v_agreement_currency then
    raise exception
      'La moneda del pago no coincide con la del contrato';
  end if;


  select coalesce(sum(pa.monto), 0)
  into v_payment_allocated
  from public.payment_allocations pa
  where pa.payment_id = new.payment_id
    and pa.id <> new.id;


  if v_payment_allocated + new.monto > v_payment_amount then
    raise exception
      'Las aplicaciones superan el monto del pago';
  end if;


  select coalesce(sum(pa.monto), 0)
  into v_installment_allocated
  from public.payment_allocations pa
  where pa.installment_id = new.installment_id
    and pa.id <> new.id;


  if v_installment_allocated + new.monto > v_installment_amount then
    raise exception
      'La cuota recibiría más dinero que su monto';
  end if;


  return new;

end;
$function$
;
CREATE OR REPLACE FUNCTION public.accept_firm_invitation(p_invitation_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_invitation public.firm_invitations%rowtype;

  v_user_id uuid;
  v_user_email text;

  v_membership_id uuid;
  v_existing_role public.firm_role;
  v_existing_client_user uuid;
begin

  v_user_id := auth.uid();


  if v_user_id is null then
    raise exception
      'Debes estar autenticado para aceptar la invitación';
  end if;


  -- ----------------------------------------------------------
  -- Email confiable desde Supabase Auth
  -- ----------------------------------------------------------

  select lower(trim(u.email))
  into v_user_email
  from auth.users u
  where u.id = v_user_id;


  if v_user_email is null then
    raise exception
      'Tu cuenta no posee un email válido';
  end if;


  -- ----------------------------------------------------------
  -- Lock de invitación para evitar doble aceptación simultánea
  -- ----------------------------------------------------------

  select *
  into v_invitation
  from public.firm_invitations
  where id = p_invitation_id
  for update;


  if not found then
    raise exception
      'Invitación no encontrada';
  end if;


  -- ----------------------------------------------------------
  -- Idempotencia
  -- ----------------------------------------------------------

  if v_invitation.status = 'aceptada'
     and v_invitation.accepted_by = v_user_id then

    select fm.id
    into v_membership_id
    from public.firm_memberships fm
    where fm.firm_id = v_invitation.firm_id
      and fm.user_id = v_user_id;

    return v_membership_id;

  end if;


  if v_invitation.status <> 'pendiente' then
    raise exception
      'Esta invitación ya no está disponible';
  end if;


  if v_invitation.expires_at <= now() then
    raise exception
      'La invitación ha expirado';
  end if;


  if v_invitation.email <> v_user_email then
    raise exception
      'Esta invitación pertenece a otra dirección de correo';
  end if;


  if not private.firm_is_operational(
    v_invitation.firm_id
  ) then
    raise exception
      'La firma no tiene una suscripción operativa';
  end if;


  -- ----------------------------------------------------------
  -- Crear profile mínimo si no existe
  -- ----------------------------------------------------------

  insert into public.profiles (
    id
  )
  values (
    v_user_id
  )
  on conflict (id)
  do nothing;


  -- ----------------------------------------------------------
  -- ¿Ya pertenece a esta firma?
  -- ----------------------------------------------------------

  select
    fm.id,
    fm.role
  into
    v_membership_id,
    v_existing_role
  from public.firm_memberships fm
  where fm.firm_id = v_invitation.firm_id
    and fm.user_id = v_user_id;


  if v_membership_id is not null then

    if v_existing_role <> v_invitation.role then
      raise exception
        'Tu cuenta ya pertenece a esta firma con otro rol';
    end if;


    update public.firm_memberships
    set
      status = 'activo',
      joined_at = coalesce(joined_at, now()),
      updated_at = now()
    where id = v_membership_id;

  else

    insert into public.firm_memberships (
      firm_id,
      user_id,
      role,
      status,
      invitado_por,
      joined_at
    )
    values (
      v_invitation.firm_id,
      v_user_id,
      v_invitation.role,
      'activo'::public.membership_status,
      v_invitation.invited_by,
      now()
    )
    returning id into v_membership_id;

  end if;


  -- ==========================================================
  -- PORTAL CLIENTE
  -- ==========================================================

  if v_invitation.kind = 'client_portal' then

    select c.portal_user_id
    into v_existing_client_user
    from public.clients c
    where c.id = v_invitation.client_id
      and c.firm_id = v_invitation.firm_id
    for update;


    if not found then
      raise exception
        'El cliente asociado ya no existe';
    end if;


    if v_existing_client_user is not null
       and v_existing_client_user <> v_user_id then

      raise exception
        'El cliente ya está vinculado a otra cuenta';

    end if;


    update public.clients
    set
      portal_user_id = v_user_id,
      updated_at = now()
    where id = v_invitation.client_id
      and firm_id = v_invitation.firm_id;

  end if;


  -- ----------------------------------------------------------
  -- Finalizar invitación
  -- ----------------------------------------------------------

  update public.firm_invitations
  set
    status = 'aceptada',
    accepted_by = v_user_id,
    accepted_at = now(),
    updated_at = now()
  where id = p_invitation_id;


  return v_membership_id;

end;
$function$
;
CREATE OR REPLACE FUNCTION public.create_client_portal_invitation(p_firm_id uuid, p_client_id uuid, p_email text, p_expires_in_days integer DEFAULT 7)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_invitation_id uuid;
  v_email text;
  v_existing_portal_user uuid;
begin

  if auth.uid() is null then
    raise exception
      'Debes estar autenticado';
  end if;


  if not private.has_firm_role(
    p_firm_id,
    array[
      'admin'
    ]::public.firm_role[]
  ) then
    raise exception
      'Solo un administrador puede habilitar el Portal Cliente';
  end if;


  if p_expires_in_days < 1
     or p_expires_in_days > 30 then
    raise exception
      'La invitación debe durar entre 1 y 30 días';
  end if;


  v_email := lower(trim(p_email));


  if v_email = '' then
    raise exception
      'El email es obligatorio';
  end if;


  -- ----------------------------------------------------------
  -- Verificar cliente y portal actual
  -- ----------------------------------------------------------

  select c.portal_user_id
  into v_existing_portal_user
  from public.clients c
  where c.id = p_client_id
    and c.firm_id = p_firm_id;


  if not found then
    raise exception
      'Cliente no encontrado en esta firma';
  end if;


  if v_existing_portal_user is not null then
    raise exception
      'Este cliente ya tiene acceso al Portal Cliente';
  end if;


  -- ----------------------------------------------------------
  -- Limpiar invitaciones vencidas
  -- ----------------------------------------------------------

  update public.firm_invitations
  set
    status = 'expirada',
    updated_at = now()
  where firm_id = p_firm_id
    and status = 'pendiente'
    and expires_at <= now()
    and (
      email = v_email
      or client_id = p_client_id
    );


  -- ----------------------------------------------------------
  -- Invitación vigente existente
  -- ----------------------------------------------------------

  select fi.id
  into v_invitation_id
  from public.firm_invitations fi
  where fi.firm_id = p_firm_id
    and fi.client_id = p_client_id
    and fi.status = 'pendiente'
    and fi.expires_at > now()
  limit 1;


  if v_invitation_id is not null then
    return v_invitation_id;
  end if;


  insert into public.firm_invitations (
    firm_id,
    kind,
    email,
    role,
    client_id,
    invited_by,
    expires_at
  )
  values (
    p_firm_id,
    'client_portal',
    v_email,
    'cliente'::public.firm_role,
    p_client_id,
    auth.uid(),
    now() + make_interval(days => p_expires_in_days)
  )
  returning id into v_invitation_id;


  return v_invitation_id;

end;
$function$
;
CREATE OR REPLACE FUNCTION public.create_firm(p_nombre text, p_slug text, p_nombres text DEFAULT NULL::text, p_apellido_paterno text DEFAULT NULL::text, p_apellido_materno text DEFAULT NULL::text, p_telefono text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user_id uuid;
  v_firm_id uuid;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Debes estar autenticado para crear una firma';
  end if;

  if trim(coalesce(p_nombre, '')) = '' then
    raise exception 'El nombre de la firma es obligatorio';
  end if;

  if trim(coalesce(p_slug, '')) = '' then
    raise exception 'El identificador de la firma es obligatorio';
  end if;


  -- ----------------------------------------------------------
  -- Perfil del usuario
  -- ----------------------------------------------------------

  insert into public.profiles (
    id,
    nombres,
    apellido_paterno,
    apellido_materno,
    telefono
  )
  values (
    v_user_id,
    nullif(trim(p_nombres), ''),
    nullif(trim(p_apellido_paterno), ''),
    nullif(trim(p_apellido_materno), ''),
    nullif(trim(p_telefono), '')
  )
  on conflict (id)
  do update set
    nombres = coalesce(
      excluded.nombres,
      public.profiles.nombres
    ),
    apellido_paterno = coalesce(
      excluded.apellido_paterno,
      public.profiles.apellido_paterno
    ),
    apellido_materno = coalesce(
      excluded.apellido_materno,
      public.profiles.apellido_materno
    ),
    telefono = coalesce(
      excluded.telefono,
      public.profiles.telefono
    ),
    updated_at = now();


  -- ----------------------------------------------------------
  -- Crear tenant
  -- ----------------------------------------------------------

  insert into public.firms (
    nombre,
    slug,
    status,
    trial_started_at,
    trial_ends_at
  )
  values (
    trim(p_nombre),
    lower(trim(p_slug)),
    'trial'::public.firm_status,
    now(),
    now() + interval '30 days'
  )
  returning id into v_firm_id;


  -- ----------------------------------------------------------
  -- Usuario creador = ADMIN
  -- ----------------------------------------------------------

  insert into public.firm_memberships (
    firm_id,
    user_id,
    role,
    status,
    joined_at
  )
  values (
    v_firm_id,
    v_user_id,
    'admin'::public.firm_role,
    'activo'::public.membership_status,
    now()
  );


  return v_firm_id;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.create_staff_invitation(p_firm_id uuid, p_email text, p_role firm_role, p_expires_in_days integer DEFAULT 7)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_invitation_id uuid;
  v_email text;
begin

  if auth.uid() is null then
    raise exception
      'Debes estar autenticado';
  end if;


  if not private.has_firm_role(
    p_firm_id,
    array[
      'admin'
    ]::public.firm_role[]
  ) then
    raise exception
      'Solo un administrador puede invitar miembros';
  end if;


  if p_role = 'cliente'::public.firm_role then
    raise exception
      'Utiliza la invitación de Portal Cliente';
  end if;


  if p_expires_in_days < 1
     or p_expires_in_days > 30 then
    raise exception
      'La invitación debe durar entre 1 y 30 días';
  end if;


  v_email := lower(trim(p_email));


  if v_email = '' then
    raise exception
      'El email es obligatorio';
  end if;


  -- ----------------------------------------------------------
  -- Marcar pendientes vencidas
  -- ----------------------------------------------------------

  update public.firm_invitations
  set
    status = 'expirada',
    updated_at = now()
  where firm_id = p_firm_id
    and email = v_email
    and status = 'pendiente'
    and expires_at <= now();


  -- ----------------------------------------------------------
  -- Si ya existe una invitación pendiente vigente,
  -- devolvemos esa misma.
  -- ----------------------------------------------------------

  select fi.id
  into v_invitation_id
  from public.firm_invitations fi
  where fi.firm_id = p_firm_id
    and fi.email = v_email
    and fi.status = 'pendiente'
    and fi.expires_at > now()
  limit 1;


  if v_invitation_id is not null then
    return v_invitation_id;
  end if;


  insert into public.firm_invitations (
    firm_id,
    kind,
    email,
    role,
    invited_by,
    expires_at
  )
  values (
    p_firm_id,
    'staff',
    v_email,
    p_role,
    auth.uid(),
    now() + make_interval(days => p_expires_in_days)
  )
  returning id into v_invitation_id;


  return v_invitation_id;

end;
$function$
;
CREATE OR REPLACE FUNCTION public.generate_payment_distributions(p_payment_id uuid, p_agreement_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_firm_id uuid;
  v_payment_case uuid;
  v_payment_currency varchar(3);

  v_agreement_case uuid;
  v_agreement_currency varchar(3);

  v_scheme_id uuid;

  v_base_amount numeric(18,2);
  v_distribution_total numeric(18,2);
begin

  -- ----------------------------------------------------------
  -- Lock del pago
  -- ----------------------------------------------------------

  select
    p.firm_id,
    p.case_id,
    p.moneda
  into
    v_firm_id,
    v_payment_case,
    v_payment_currency
  from public.payments p
  where p.id = p_payment_id
    and p.estado = 'registrado'::public.payment_status
  for update;


  if v_firm_id is null then
    raise exception
      'Pago no encontrado o anulado';
  end if;


  if not private.can_manage_finance(v_firm_id) then
    raise exception
      'No tienes permiso financiero';
  end if;


  -- ----------------------------------------------------------
  -- Lock del contrato
  -- ----------------------------------------------------------

  select
    fa.case_id,
    fa.moneda,
    fa.compensation_scheme_id
  into
    v_agreement_case,
    v_agreement_currency,
    v_scheme_id
  from public.fee_agreements fa
  where fa.id = p_agreement_id
    and fa.firm_id = v_firm_id
    and fa.estado = 'vigente'::public.fee_agreement_status
  for update;


  if v_agreement_case is null then
    raise exception
      'Contrato vigente no encontrado';
  end if;


  if v_payment_case is distinct from v_agreement_case then
    raise exception
      'El pago y el contrato pertenecen a expedientes distintos';
  end if;


  if v_payment_currency is distinct from v_agreement_currency then
    raise exception
      'El pago y el contrato utilizan monedas distintas';
  end if;


  if v_scheme_id is null then
    raise exception
      'Este contrato no tiene un esquema de compensación configurado';
  end if;


  if not exists (
    select 1
    from public.compensation_schemes cs
    where cs.id = v_scheme_id
      and cs.firm_id = v_firm_id
      and cs.activo = true
  ) then

    raise exception
      'El esquema de compensación está inactivo o no existe';

  end if;


  if exists (
    select 1
    from public.payment_distributions pd
    where pd.payment_id = p_payment_id
      and pd.agreement_id = p_agreement_id
      and pd.estado <> 'anulado'::public.distribution_status
  ) then

    raise exception
      'Ya existen distribuciones para este pago y contrato';

  end if;


  select coalesce(sum(pa.monto), 0)
  into v_base_amount
  from public.payment_allocations pa

  join public.fee_installments fi
    on fi.id = pa.installment_id
   and fi.firm_id = pa.firm_id

  where pa.payment_id = p_payment_id
    and pa.firm_id = v_firm_id
    and fi.agreement_id = p_agreement_id;


  if v_base_amount <= 0 then
    raise exception
      'El pago no tiene dinero aplicado a cuotas de este contrato';
  end if;


  select coalesce(
    sum(
      case

        when r.calculation_type =
          'porcentaje'::public.compensation_calculation_type

        then round(
          v_base_amount * r.valor / 100,
          2
        )


        when r.calculation_type =
          'monto_fijo'::public.compensation_calculation_type

        then round(
          r.valor,
          2
        )


        else 0

      end
    ),
    0
  )
  into v_distribution_total
  from public.compensation_rules r
  where r.firm_id = v_firm_id
    and r.scheme_id = v_scheme_id
    and r.activo = true;


  if v_distribution_total > v_base_amount then
    raise exception
      'Las reglas generan una distribución (%) mayor que la base disponible (%)',
      v_distribution_total,
      v_base_amount;
  end if;


  insert into public.payment_distributions (
    firm_id,
    payment_id,
    agreement_id,
    scheme_id,
    rule_id,

    rule_name,

    recipient_type,
    membership_id,
    recipient_label,

    calculation_type,
    rule_value,

    base_calculo,
    monto
  )
  select
    v_firm_id,
    p_payment_id,
    p_agreement_id,
    v_scheme_id,
    r.id,

    r.nombre,

    r.recipient_type,
    r.membership_id,
    r.recipient_label,

    r.calculation_type,
    r.valor,

    v_base_amount,

    case

      when r.calculation_type =
        'porcentaje'::public.compensation_calculation_type

      then round(
        v_base_amount * r.valor / 100,
        2
      )


      when r.calculation_type =
        'monto_fijo'::public.compensation_calculation_type

      then round(
        r.valor,
        2
      )

    end

  from public.compensation_rules r

  where r.firm_id = v_firm_id
    and r.scheme_id = v_scheme_id
    and r.activo = true;

end;
$function$
;
CREATE OR REPLACE FUNCTION public.revoke_firm_invitation(p_invitation_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_firm_id uuid;
  v_status public.invitation_status;
begin

  select
    fi.firm_id,
    fi.status
  into
    v_firm_id,
    v_status
  from public.firm_invitations fi
  where fi.id = p_invitation_id;


  if v_firm_id is null then
    raise exception
      'Invitación no encontrada';
  end if;


  if not private.has_firm_role_raw(
    v_firm_id,
    array[
      'admin'
    ]::public.firm_role[]
  ) then
    raise exception
      'Solo un administrador puede revocar invitaciones';
  end if;


  if v_status <> 'pendiente' then
    raise exception
      'Solo pueden revocarse invitaciones pendientes';
  end if;


  update public.firm_invitations
  set
    status = 'revocada',
    revoked_by = auth.uid(),
    revoked_at = now(),
    updated_at = now()
  where id = p_invitation_id;

end;
$function$
;
CREATE OR REPLACE FUNCTION public.void_payment(p_payment_id uuid, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_firm_id uuid;
  v_status public.payment_status;
begin

  select
    p.firm_id,
    p.estado
  into
    v_firm_id,
    v_status
  from public.payments p
  where p.id = p_payment_id;


  if v_firm_id is null then
    raise exception
      'Pago no encontrado';
  end if;


  if not private.can_manage_finance(v_firm_id) then
    raise exception
      'No tienes permisos financieros';
  end if;


  if v_status = 'anulado' then
    raise exception
      'El pago ya está anulado';
  end if;


  if trim(coalesce(p_reason, '')) = '' then
    raise exception
      'Debes indicar el motivo de anulación';
  end if;


  -- ----------------------------------------------------------
  -- Anular distribuciones existentes
  -- ----------------------------------------------------------

  update public.payment_distributions
  set
    estado = 'anulado',
    updated_at = now()
  where payment_id = p_payment_id
    and estado <> 'anulado';


  -- ----------------------------------------------------------
  -- Anular pago
  -- ----------------------------------------------------------

  update public.payments
  set
    estado = 'anulado',
    anulado_por = auth.uid(),
    anulado_at = now(),
    observaciones =
      concat_ws(
        E'\n',
        observaciones,
        'ANULACIÓN: ' || trim(p_reason)
      ),
    updated_at = now()
  where id = p_payment_id;

end;
$function$
;
CREATE TRIGGER audit_case_expenses AFTER INSERT OR DELETE OR UPDATE ON case_expenses FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();
CREATE TRIGGER audit_case_members AFTER INSERT OR DELETE OR UPDATE ON case_members FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();
CREATE TRIGGER trg_protect_case_member_identity BEFORE UPDATE ON case_members FOR EACH ROW EXECUTE FUNCTION private.protect_case_member_identity();
CREATE TRIGGER audit_cases AFTER INSERT OR DELETE OR UPDATE ON cases FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();
CREATE TRIGGER trg_protect_case_identity BEFORE UPDATE ON cases FOR EACH ROW EXECUTE FUNCTION private.protect_case_identity();
CREATE TRIGGER audit_clients AFTER INSERT OR DELETE OR UPDATE ON clients FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();
CREATE TRIGGER trg_protect_client_firm BEFORE UPDATE ON clients FOR EACH ROW EXECUTE FUNCTION private.protect_client_firm();
CREATE TRIGGER audit_compensation_rules AFTER INSERT OR DELETE OR UPDATE ON compensation_rules FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();
CREATE TRIGGER trg_protect_compensation_rule_identity BEFORE UPDATE ON compensation_rules FOR EACH ROW EXECUTE FUNCTION private.protect_compensation_rule_identity();
CREATE TRIGGER trg_validate_compensation_percentage BEFORE INSERT OR UPDATE ON compensation_rules FOR EACH ROW EXECUTE FUNCTION private.validate_compensation_percentage();
CREATE TRIGGER audit_compensation_schemes AFTER INSERT OR DELETE OR UPDATE ON compensation_schemes FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();
CREATE TRIGGER trg_protect_compensation_scheme_identity BEFORE UPDATE ON compensation_schemes FOR EACH ROW EXECUTE FUNCTION private.protect_compensation_scheme_identity();
CREATE TRIGGER audit_document_templates AFTER INSERT OR DELETE OR UPDATE ON document_templates FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();
CREATE TRIGGER document_templates_touch_updated_at BEFORE UPDATE ON document_templates FOR EACH ROW EXECUTE FUNCTION private.touch_updated_at_011();
CREATE TRIGGER audit_documents AFTER INSERT OR DELETE OR UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();
CREATE TRIGGER trg_protect_document_identity BEFORE UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION private.protect_document_identity();
CREATE TRIGGER audit_fee_agreements AFTER INSERT OR DELETE OR UPDATE ON fee_agreements FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();
CREATE TRIGGER trg_protect_fee_agreement_total BEFORE UPDATE ON fee_agreements FOR EACH ROW EXECUTE FUNCTION private.protect_fee_agreement_total();
CREATE TRIGGER audit_fee_installments AFTER INSERT OR DELETE OR UPDATE ON fee_installments FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();
CREATE TRIGGER trg_protect_installment_identity BEFORE UPDATE ON fee_installments FOR EACH ROW EXECUTE FUNCTION private.protect_installment_identity();
CREATE TRIGGER trg_validate_installment_total BEFORE INSERT OR UPDATE ON fee_installments FOR EACH ROW EXECUTE FUNCTION private.validate_installment_total();
CREATE TRIGGER audit_firm_invitations AFTER INSERT OR DELETE OR UPDATE ON firm_invitations FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();
CREATE TRIGGER audit_firm_member_details AFTER INSERT OR DELETE OR UPDATE ON firm_member_details FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();
CREATE TRIGGER firm_member_details_touch_updated_at BEFORE UPDATE ON firm_member_details FOR EACH ROW EXECUTE FUNCTION private.touch_updated_at_011();
CREATE TRIGGER audit_firm_memberships AFTER INSERT OR DELETE OR UPDATE ON firm_memberships FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();
CREATE TRIGGER trg_protect_last_firm_admin BEFORE DELETE OR UPDATE ON firm_memberships FOR EACH ROW EXECUTE FUNCTION private.protect_last_firm_admin();
CREATE TRIGGER audit_firm_settings AFTER INSERT OR DELETE OR UPDATE ON firm_settings FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();
CREATE TRIGGER firm_settings_touch_updated_at BEFORE UPDATE ON firm_settings FOR EACH ROW EXECUTE FUNCTION private.touch_updated_at_011();
CREATE TRIGGER trg_create_initial_subscription AFTER INSERT ON firms FOR EACH ROW EXECUTE FUNCTION private.create_initial_subscription();
CREATE TRIGGER audit_payment_allocations AFTER INSERT OR DELETE OR UPDATE ON payment_allocations FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();
CREATE TRIGGER trg_protect_payment_allocation_identity BEFORE UPDATE ON payment_allocations FOR EACH ROW EXECUTE FUNCTION private.protect_payment_allocation_identity();
CREATE TRIGGER trg_protect_payment_allocations BEFORE INSERT OR DELETE OR UPDATE ON payment_allocations FOR EACH ROW EXECUTE FUNCTION private.protect_payment_allocations();
CREATE TRIGGER trg_validate_payment_allocation BEFORE INSERT OR UPDATE ON payment_allocations FOR EACH ROW EXECUTE FUNCTION private.validate_payment_allocation();
CREATE TRIGGER audit_payment_distributions AFTER INSERT OR DELETE OR UPDATE ON payment_distributions FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();
CREATE TRIGGER trg_protect_distribution_snapshot BEFORE UPDATE ON payment_distributions FOR EACH ROW EXECUTE FUNCTION private.protect_distribution_snapshot();
CREATE TRIGGER audit_payments AFTER INSERT OR DELETE OR UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();
CREATE TRIGGER trg_protect_payment_integrity BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION private.protect_payment_integrity();
CREATE TRIGGER trg_protect_voided_payment BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION private.protect_voided_payment();
ALTER TABLE public.agenda_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compensation_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compensation_schemes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fee_agreements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fee_installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.firm_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.firm_member_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.firm_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.firm_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.firms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_distributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "agenda_events_delete_access" ON public.agenda_events AS PERMISSIVE FOR DELETE TO authenticated USING (((creado_por = ( SELECT auth.uid() AS uid)) OR ( SELECT private.has_firm_role(agenda_events.firm_id, ARRAY['admin'::firm_role]) AS has_firm_role)));
CREATE POLICY "agenda_events_insert_staff" ON public.agenda_events AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((( SELECT private.has_firm_role(agenda_events.firm_id, ARRAY['admin'::firm_role, 'finanzas'::firm_role, 'asociado_senior'::firm_role, 'abogado'::firm_role]) AS has_firm_role) AND (creado_por = ( SELECT auth.uid() AS uid)) AND ((case_id IS NULL) OR ( SELECT private.can_access_case(agenda_events.firm_id, agenda_events.case_id) AS can_access_case) OR ( SELECT private.has_firm_role(agenda_events.firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role]) AS has_firm_role))));
CREATE POLICY "agenda_events_select_access" ON public.agenda_events AS PERMISSIVE FOR SELECT TO authenticated USING (( SELECT private.can_access_agenda_event(agenda_events.firm_id, agenda_events.case_id, agenda_events.assigned_membership_id, agenda_events.creado_por) AS can_access_agenda_event));
CREATE POLICY "agenda_events_update" ON public.agenda_events AS PERMISSIVE FOR UPDATE TO authenticated USING (private.can_access_agenda_event(firm_id, case_id, assigned_membership_id, creado_por)) WITH CHECK ((private.can_access_agenda_event(firm_id, case_id, assigned_membership_id, creado_por) AND ((case_id IS NULL) OR private.can_access_case(firm_id, case_id) OR private.has_firm_role(firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role]))));
CREATE POLICY "audit_logs_select_admin" ON public.audit_logs AS PERMISSIVE FOR SELECT TO authenticated USING (private.has_firm_role(firm_id, ARRAY['admin'::firm_role]));
CREATE POLICY "audit_logs_select_finance" ON public.audit_logs AS PERMISSIVE FOR SELECT TO authenticated USING ((private.has_firm_role(firm_id, ARRAY['finanzas'::firm_role]) AND (entidad = ANY (ARRAY['fee_agreements'::text, 'fee_installments'::text, 'payments'::text, 'payment_allocations'::text, 'case_expenses'::text, 'compensation_schemes'::text, 'compensation_rules'::text, 'payment_distributions'::text]))));
CREATE POLICY "case_expenses_delete_finance" ON public.case_expenses AS PERMISSIVE FOR DELETE TO authenticated USING (private.can_manage_finance(firm_id));
CREATE POLICY "case_expenses_insert" ON public.case_expenses AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (((private.can_manage_finance(firm_id) OR private.can_access_case(firm_id, case_id)) AND (creado_por = auth.uid())));
CREATE POLICY "case_expenses_select" ON public.case_expenses AS PERMISSIVE FOR SELECT TO authenticated USING ((private.can_manage_finance(firm_id) OR private.can_access_case(firm_id, case_id)));
CREATE POLICY "case_expenses_update_finance" ON public.case_expenses AS PERMISSIVE FOR UPDATE TO authenticated USING (private.can_manage_finance(firm_id)) WITH CHECK (private.can_manage_finance(firm_id));
CREATE POLICY "case_members_delete_manager" ON public.case_members AS PERMISSIVE FOR DELETE TO authenticated USING (( SELECT private.has_firm_role(case_members.firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role]) AS has_firm_role));
CREATE POLICY "case_members_insert_manager" ON public.case_members AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (( SELECT private.has_firm_role(case_members.firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role]) AS has_firm_role));
CREATE POLICY "case_members_select_access" ON public.case_members AS PERMISSIVE FOR SELECT TO authenticated USING ((( SELECT private.has_firm_role(case_members.firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role]) AS has_firm_role) OR ( SELECT private.can_access_case(case_members.firm_id, case_members.case_id) AS can_access_case)));
CREATE POLICY "case_members_update_manager" ON public.case_members AS PERMISSIVE FOR UPDATE TO authenticated USING (( SELECT private.has_firm_role(case_members.firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role]) AS has_firm_role)) WITH CHECK (( SELECT private.has_firm_role(case_members.firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role]) AS has_firm_role));
CREATE POLICY "case_notes_delete_staff" ON public.case_notes AS PERMISSIVE FOR DELETE TO authenticated USING (((creado_por = ( SELECT auth.uid() AS uid)) OR ( SELECT private.has_firm_role(case_notes.firm_id, ARRAY['admin'::firm_role]) AS has_firm_role)));
CREATE POLICY "case_notes_insert_staff" ON public.case_notes AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((( SELECT private.can_access_case(case_notes.firm_id, case_notes.case_id) AS can_access_case) AND (creado_por = ( SELECT auth.uid() AS uid))));
CREATE POLICY "case_notes_select_client" ON public.case_notes AS PERMISSIVE FOR SELECT TO authenticated USING (((visible_cliente = true) AND ( SELECT private.is_case_client(case_notes.firm_id, case_notes.case_id) AS is_case_client)));
CREATE POLICY "case_notes_select_staff" ON public.case_notes AS PERMISSIVE FOR SELECT TO authenticated USING (( SELECT private.can_access_case(case_notes.firm_id, case_notes.case_id) AS can_access_case));
CREATE POLICY "case_notes_update_staff" ON public.case_notes AS PERMISSIVE FOR UPDATE TO authenticated USING (((creado_por = ( SELECT auth.uid() AS uid)) OR ( SELECT private.has_firm_role(case_notes.firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role]) AS has_firm_role))) WITH CHECK (( SELECT private.can_access_case(case_notes.firm_id, case_notes.case_id) AS can_access_case));
CREATE POLICY "case_reports_delete_admin" ON public.case_reports AS PERMISSIVE FOR DELETE TO authenticated USING (( SELECT private.has_firm_role(case_reports.firm_id, ARRAY['admin'::firm_role]) AS has_firm_role));
CREATE POLICY "case_reports_insert_staff" ON public.case_reports AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((( SELECT private.can_access_case(case_reports.firm_id, case_reports.case_id) AS can_access_case) AND (creado_por = ( SELECT auth.uid() AS uid))));
CREATE POLICY "case_reports_select_client" ON public.case_reports AS PERMISSIVE FOR SELECT TO authenticated USING (((visible_cliente = true) AND ( SELECT private.is_case_client(case_reports.firm_id, case_reports.case_id) AS is_case_client)));
CREATE POLICY "case_reports_select_staff" ON public.case_reports AS PERMISSIVE FOR SELECT TO authenticated USING (( SELECT private.can_access_case(case_reports.firm_id, case_reports.case_id) AS can_access_case));
CREATE POLICY "case_reports_update_staff" ON public.case_reports AS PERMISSIVE FOR UPDATE TO authenticated USING (( SELECT private.can_access_case(case_reports.firm_id, case_reports.case_id) AS can_access_case)) WITH CHECK (( SELECT private.can_access_case(case_reports.firm_id, case_reports.case_id) AS can_access_case));
CREATE POLICY "cases_delete_admin" ON public.cases AS PERMISSIVE FOR DELETE TO authenticated USING (( SELECT private.has_firm_role(cases.firm_id, ARRAY['admin'::firm_role]) AS has_firm_role));
CREATE POLICY "cases_insert_staff" ON public.cases AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((( SELECT private.has_firm_role(cases.firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role, 'abogado'::firm_role]) AS has_firm_role) AND ((creado_por IS NULL) OR (creado_por = ( SELECT auth.uid() AS uid)))));
CREATE POLICY "cases_select_access" ON public.cases AS PERMISSIVE FOR SELECT TO authenticated USING ((( SELECT private.has_firm_role(cases.firm_id, ARRAY['admin'::firm_role, 'finanzas'::firm_role, 'asociado_senior'::firm_role]) AS has_firm_role) OR ( SELECT private.can_access_case(cases.firm_id, cases.id) AS can_access_case)));
CREATE POLICY "cases_select_client_portal" ON public.cases AS PERMISSIVE FOR SELECT TO authenticated USING (private.is_case_client(firm_id, id));
CREATE POLICY "cases_update_staff" ON public.cases AS PERMISSIVE FOR UPDATE TO authenticated USING ((( SELECT private.has_firm_role(cases.firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role]) AS has_firm_role) OR ( SELECT private.can_access_case(cases.firm_id, cases.id) AS can_access_case))) WITH CHECK ((( SELECT private.has_firm_role(cases.firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role]) AS has_firm_role) OR ( SELECT private.can_access_case(cases.firm_id, cases.id) AS can_access_case)));
CREATE POLICY "clients_delete_admin" ON public.clients AS PERMISSIVE FOR DELETE TO authenticated USING (( SELECT private.has_firm_role(clients.firm_id, ARRAY['admin'::firm_role]) AS has_firm_role));
CREATE POLICY "clients_insert_staff" ON public.clients AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((( SELECT private.has_firm_role(clients.firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role, 'abogado'::firm_role]) AS has_firm_role) AND ((creado_por IS NULL) OR (creado_por = ( SELECT auth.uid() AS uid)))));
CREATE POLICY "clients_select_own_portal_record" ON public.clients AS PERMISSIVE FOR SELECT TO authenticated USING (((portal_user_id = auth.uid()) AND private.firm_is_operational(firm_id) AND private.is_firm_member(firm_id)));
CREATE POLICY "clients_select_staff" ON public.clients AS PERMISSIVE FOR SELECT TO authenticated USING (( SELECT private.has_firm_role(clients.firm_id, ARRAY['admin'::firm_role, 'finanzas'::firm_role, 'asociado_senior'::firm_role, 'abogado'::firm_role]) AS has_firm_role));
CREATE POLICY "clients_update_staff" ON public.clients AS PERMISSIVE FOR UPDATE TO authenticated USING (( SELECT private.has_firm_role(clients.firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role, 'abogado'::firm_role]) AS has_firm_role)) WITH CHECK (( SELECT private.has_firm_role(clients.firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role, 'abogado'::firm_role]) AS has_firm_role));
CREATE POLICY "compensation_rules_finance_all" ON public.compensation_rules AS PERMISSIVE FOR ALL TO authenticated USING (private.can_manage_finance(firm_id)) WITH CHECK (private.can_manage_finance(firm_id));
CREATE POLICY "compensation_schemes_finance_all" ON public.compensation_schemes AS PERMISSIVE FOR ALL TO authenticated USING (private.can_manage_finance(firm_id)) WITH CHECK (private.can_manage_finance(firm_id));
CREATE POLICY "document_templates_delete_staff" ON public.document_templates AS PERMISSIVE FOR DELETE TO authenticated USING (private.has_firm_role(firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role, 'abogado'::firm_role]));
CREATE POLICY "document_templates_insert_staff" ON public.document_templates AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (((creado_por = auth.uid()) AND private.has_firm_role(firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role, 'abogado'::firm_role])));
CREATE POLICY "document_templates_select_staff" ON public.document_templates AS PERMISSIVE FOR SELECT TO authenticated USING (private.has_firm_role(firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role, 'abogado'::firm_role]));
CREATE POLICY "document_templates_update_staff" ON public.document_templates AS PERMISSIVE FOR UPDATE TO authenticated USING (private.has_firm_role(firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role, 'abogado'::firm_role])) WITH CHECK (private.has_firm_role(firm_id, ARRAY['admin'::firm_role, 'asociado_senior'::firm_role, 'abogado'::firm_role]));
CREATE POLICY "documents_delete_admin" ON public.documents AS PERMISSIVE FOR DELETE TO authenticated USING (( SELECT private.has_firm_role(documents.firm_id, ARRAY['admin'::firm_role]) AS has_firm_role));
CREATE POLICY "documents_insert_case_access" ON public.documents AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((( SELECT private.can_access_case_documents(documents.firm_id, documents.case_id) AS can_access_case_documents) AND (subido_por = ( SELECT auth.uid() AS uid))));
CREATE POLICY "documents_select_case_access" ON public.documents AS PERMISSIVE FOR SELECT TO authenticated USING (( SELECT private.can_access_case_documents(documents.firm_id, documents.case_id) AS can_access_case_documents));
CREATE POLICY "documents_select_client_portal" ON public.documents AS PERMISSIVE FOR SELECT TO authenticated USING (((visible_cliente = true) AND ( SELECT private.is_case_client(documents.firm_id, documents.case_id) AS is_case_client)));
CREATE POLICY "documents_update_case_access" ON public.documents AS PERMISSIVE FOR UPDATE TO authenticated USING (( SELECT private.can_access_case_documents(documents.firm_id, documents.case_id) AS can_access_case_documents)) WITH CHECK (( SELECT private.can_access_case_documents(documents.firm_id, documents.case_id) AS can_access_case_documents));
CREATE POLICY "fee_agreements_finance_all" ON public.fee_agreements AS PERMISSIVE FOR ALL TO authenticated USING (private.can_manage_finance(firm_id)) WITH CHECK (private.can_manage_finance(firm_id));
CREATE POLICY "fee_installments_finance_all" ON public.fee_installments AS PERMISSIVE FOR ALL TO authenticated USING (private.can_manage_finance(firm_id)) WITH CHECK (private.can_manage_finance(firm_id));
CREATE POLICY "firm_invitations_select_admin" ON public.firm_invitations AS PERMISSIVE FOR SELECT TO authenticated USING (private.has_firm_role_raw(firm_id, ARRAY['admin'::firm_role]));
CREATE POLICY "firm_member_details_delete_admin" ON public.firm_member_details AS PERMISSIVE FOR DELETE TO authenticated USING (private.has_firm_role(firm_id, ARRAY['admin'::firm_role]));
CREATE POLICY "firm_member_details_insert_admin" ON public.firm_member_details AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (private.has_firm_role(firm_id, ARRAY['admin'::firm_role]));
CREATE POLICY "firm_member_details_select_staff" ON public.firm_member_details AS PERMISSIVE FOR SELECT TO authenticated USING (private.has_firm_role(firm_id, ARRAY['admin'::firm_role, 'finanzas'::firm_role, 'asociado_senior'::firm_role, 'abogado'::firm_role]));
CREATE POLICY "firm_member_details_update_admin" ON public.firm_member_details AS PERMISSIVE FOR UPDATE TO authenticated USING (private.has_firm_role(firm_id, ARRAY['admin'::firm_role])) WITH CHECK (private.has_firm_role(firm_id, ARRAY['admin'::firm_role]));
CREATE POLICY "memberships_delete_admin" ON public.firm_memberships AS PERMISSIVE FOR DELETE TO authenticated USING (( SELECT private.has_firm_role(firm_memberships.firm_id, ARRAY['admin'::firm_role]) AS has_firm_role));
CREATE POLICY "memberships_select_own" ON public.firm_memberships AS PERMISSIVE FOR SELECT TO authenticated USING ((user_id = auth.uid()));
CREATE POLICY "memberships_select_staff" ON public.firm_memberships AS PERMISSIVE FOR SELECT TO authenticated USING (private.has_firm_role(firm_id, ARRAY['admin'::firm_role, 'finanzas'::firm_role, 'asociado_senior'::firm_role, 'abogado'::firm_role]));
CREATE POLICY "memberships_update_admin" ON public.firm_memberships AS PERMISSIVE FOR UPDATE TO authenticated USING (( SELECT private.has_firm_role(firm_memberships.firm_id, ARRAY['admin'::firm_role]) AS has_firm_role)) WITH CHECK (( SELECT private.has_firm_role(firm_memberships.firm_id, ARRAY['admin'::firm_role]) AS has_firm_role));
CREATE POLICY "firm_settings_delete_admin" ON public.firm_settings AS PERMISSIVE FOR DELETE TO authenticated USING (private.has_firm_role(firm_id, ARRAY['admin'::firm_role]));
CREATE POLICY "firm_settings_insert_admin" ON public.firm_settings AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((((creado_por IS NULL) OR (creado_por = auth.uid())) AND private.has_firm_role(firm_id, ARRAY['admin'::firm_role])));
CREATE POLICY "firm_settings_select_admin" ON public.firm_settings AS PERMISSIVE FOR SELECT TO authenticated USING (private.has_firm_role(firm_id, ARRAY['admin'::firm_role]));
CREATE POLICY "firm_settings_update_admin" ON public.firm_settings AS PERMISSIVE FOR UPDATE TO authenticated USING (private.has_firm_role(firm_id, ARRAY['admin'::firm_role])) WITH CHECK (private.has_firm_role(firm_id, ARRAY['admin'::firm_role]));
CREATE POLICY "firms_select_member" ON public.firms AS PERMISSIVE FOR SELECT TO authenticated USING (( SELECT private.is_firm_member(firms.id) AS is_firm_member));
CREATE POLICY "firms_update_admin" ON public.firms AS PERMISSIVE FOR UPDATE TO authenticated USING (( SELECT private.has_firm_role(firms.id, ARRAY['admin'::firm_role]) AS has_firm_role)) WITH CHECK (( SELECT private.has_firm_role(firms.id, ARRAY['admin'::firm_role]) AS has_firm_role));
CREATE POLICY "payment_allocations_finance_all" ON public.payment_allocations AS PERMISSIVE FOR ALL TO authenticated USING (private.can_manage_finance(firm_id)) WITH CHECK (private.can_manage_finance(firm_id));
CREATE POLICY "payment_distributions_select_finance" ON public.payment_distributions AS PERMISSIVE FOR SELECT TO authenticated USING (private.can_manage_finance(firm_id));
CREATE POLICY "payment_distributions_update_finance" ON public.payment_distributions AS PERMISSIVE FOR UPDATE TO authenticated USING (private.can_manage_finance(firm_id)) WITH CHECK (private.can_manage_finance(firm_id));
CREATE POLICY "payments_insert_finance" ON public.payments AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((private.can_manage_finance(firm_id) AND (registrado_por = auth.uid())));
CREATE POLICY "payments_select_finance" ON public.payments AS PERMISSIVE FOR SELECT TO authenticated USING (private.can_manage_finance(firm_id));
CREATE POLICY "payments_update_finance" ON public.payments AS PERMISSIVE FOR UPDATE TO authenticated USING (private.can_manage_finance(firm_id)) WITH CHECK (private.can_manage_finance(firm_id));
CREATE POLICY "plans_select_active" ON public.plans AS PERMISSIVE FOR SELECT TO authenticated USING ((activo = true));
CREATE POLICY "profiles_select_own" ON public.profiles AS PERMISSIVE FOR SELECT TO authenticated USING ((id = ( SELECT auth.uid() AS uid)));
CREATE POLICY "profiles_select_team" ON public.profiles AS PERMISSIVE FOR SELECT TO authenticated USING (private.can_view_team_profile(id));
CREATE POLICY "profiles_update_own" ON public.profiles AS PERMISSIVE FOR UPDATE TO authenticated USING ((id = ( SELECT auth.uid() AS uid))) WITH CHECK ((id = ( SELECT auth.uid() AS uid)));
CREATE POLICY "subscription_events_select_admin" ON public.subscription_events AS PERMISSIVE FOR SELECT TO authenticated USING (private.has_firm_role_raw(firm_id, ARRAY['admin'::firm_role]));
CREATE POLICY "subscriptions_select_member" ON public.subscriptions AS PERMISSIVE FOR SELECT TO authenticated USING (private.is_firm_member(firm_id));
GRANT DELETE ON public.agenda_events TO authenticated;
GRANT INSERT ON public.agenda_events TO authenticated;
GRANT SELECT ON public.agenda_events TO authenticated;
GRANT UPDATE ON public.agenda_events TO authenticated;
GRANT DELETE ON public.agenda_events TO service_role;
GRANT INSERT ON public.agenda_events TO service_role;
GRANT REFERENCES ON public.agenda_events TO service_role;
GRANT SELECT ON public.agenda_events TO service_role;
GRANT TRIGGER ON public.agenda_events TO service_role;
GRANT TRUNCATE ON public.agenda_events TO service_role;
GRANT UPDATE ON public.agenda_events TO service_role;
GRANT SELECT ON public.audit_logs TO authenticated;
GRANT DELETE ON public.audit_logs TO service_role;
GRANT INSERT ON public.audit_logs TO service_role;
GRANT REFERENCES ON public.audit_logs TO service_role;
GRANT SELECT ON public.audit_logs TO service_role;
GRANT TRIGGER ON public.audit_logs TO service_role;
GRANT TRUNCATE ON public.audit_logs TO service_role;
GRANT UPDATE ON public.audit_logs TO service_role;
GRANT DELETE ON public.case_expenses TO authenticated;
GRANT INSERT ON public.case_expenses TO authenticated;
GRANT REFERENCES ON public.case_expenses TO authenticated;
GRANT SELECT ON public.case_expenses TO authenticated;
GRANT TRIGGER ON public.case_expenses TO authenticated;
GRANT TRUNCATE ON public.case_expenses TO authenticated;
GRANT UPDATE ON public.case_expenses TO authenticated;
GRANT DELETE ON public.case_expenses TO service_role;
GRANT INSERT ON public.case_expenses TO service_role;
GRANT REFERENCES ON public.case_expenses TO service_role;
GRANT SELECT ON public.case_expenses TO service_role;
GRANT TRIGGER ON public.case_expenses TO service_role;
GRANT TRUNCATE ON public.case_expenses TO service_role;
GRANT UPDATE ON public.case_expenses TO service_role;
GRANT DELETE ON public.case_members TO authenticated;
GRANT INSERT ON public.case_members TO authenticated;
GRANT REFERENCES ON public.case_members TO authenticated;
GRANT SELECT ON public.case_members TO authenticated;
GRANT TRIGGER ON public.case_members TO authenticated;
GRANT TRUNCATE ON public.case_members TO authenticated;
GRANT UPDATE ON public.case_members TO authenticated;
GRANT DELETE ON public.case_members TO service_role;
GRANT INSERT ON public.case_members TO service_role;
GRANT REFERENCES ON public.case_members TO service_role;
GRANT SELECT ON public.case_members TO service_role;
GRANT TRIGGER ON public.case_members TO service_role;
GRANT TRUNCATE ON public.case_members TO service_role;
GRANT UPDATE ON public.case_members TO service_role;
GRANT DELETE ON public.case_notes TO authenticated;
GRANT INSERT ON public.case_notes TO authenticated;
GRANT SELECT ON public.case_notes TO authenticated;
GRANT UPDATE ON public.case_notes TO authenticated;
GRANT DELETE ON public.case_notes TO service_role;
GRANT INSERT ON public.case_notes TO service_role;
GRANT REFERENCES ON public.case_notes TO service_role;
GRANT SELECT ON public.case_notes TO service_role;
GRANT TRIGGER ON public.case_notes TO service_role;
GRANT TRUNCATE ON public.case_notes TO service_role;
GRANT UPDATE ON public.case_notes TO service_role;
GRANT DELETE ON public.case_reports TO authenticated;
GRANT INSERT ON public.case_reports TO authenticated;
GRANT SELECT ON public.case_reports TO authenticated;
GRANT UPDATE ON public.case_reports TO authenticated;
GRANT DELETE ON public.case_reports TO service_role;
GRANT INSERT ON public.case_reports TO service_role;
GRANT REFERENCES ON public.case_reports TO service_role;
GRANT SELECT ON public.case_reports TO service_role;
GRANT TRIGGER ON public.case_reports TO service_role;
GRANT TRUNCATE ON public.case_reports TO service_role;
GRANT UPDATE ON public.case_reports TO service_role;
GRANT DELETE ON public.cases TO authenticated;
GRANT INSERT ON public.cases TO authenticated;
GRANT REFERENCES ON public.cases TO authenticated;
GRANT SELECT ON public.cases TO authenticated;
GRANT TRIGGER ON public.cases TO authenticated;
GRANT TRUNCATE ON public.cases TO authenticated;
GRANT UPDATE ON public.cases TO authenticated;
GRANT DELETE ON public.cases TO service_role;
GRANT INSERT ON public.cases TO service_role;
GRANT REFERENCES ON public.cases TO service_role;
GRANT SELECT ON public.cases TO service_role;
GRANT TRIGGER ON public.cases TO service_role;
GRANT TRUNCATE ON public.cases TO service_role;
GRANT UPDATE ON public.cases TO service_role;
GRANT DELETE ON public.clients TO authenticated;
GRANT INSERT ON public.clients TO authenticated;
GRANT REFERENCES ON public.clients TO authenticated;
GRANT SELECT ON public.clients TO authenticated;
GRANT TRIGGER ON public.clients TO authenticated;
GRANT TRUNCATE ON public.clients TO authenticated;
GRANT UPDATE ON public.clients TO authenticated;
GRANT DELETE ON public.clients TO service_role;
GRANT INSERT ON public.clients TO service_role;
GRANT REFERENCES ON public.clients TO service_role;
GRANT SELECT ON public.clients TO service_role;
GRANT TRIGGER ON public.clients TO service_role;
GRANT TRUNCATE ON public.clients TO service_role;
GRANT UPDATE ON public.clients TO service_role;
GRANT DELETE ON public.compensation_rules TO authenticated;
GRANT INSERT ON public.compensation_rules TO authenticated;
GRANT REFERENCES ON public.compensation_rules TO authenticated;
GRANT SELECT ON public.compensation_rules TO authenticated;
GRANT TRIGGER ON public.compensation_rules TO authenticated;
GRANT TRUNCATE ON public.compensation_rules TO authenticated;
GRANT UPDATE ON public.compensation_rules TO authenticated;
GRANT DELETE ON public.compensation_rules TO service_role;
GRANT INSERT ON public.compensation_rules TO service_role;
GRANT REFERENCES ON public.compensation_rules TO service_role;
GRANT SELECT ON public.compensation_rules TO service_role;
GRANT TRIGGER ON public.compensation_rules TO service_role;
GRANT TRUNCATE ON public.compensation_rules TO service_role;
GRANT UPDATE ON public.compensation_rules TO service_role;
GRANT DELETE ON public.compensation_schemes TO authenticated;
GRANT INSERT ON public.compensation_schemes TO authenticated;
GRANT REFERENCES ON public.compensation_schemes TO authenticated;
GRANT SELECT ON public.compensation_schemes TO authenticated;
GRANT TRIGGER ON public.compensation_schemes TO authenticated;
GRANT TRUNCATE ON public.compensation_schemes TO authenticated;
GRANT UPDATE ON public.compensation_schemes TO authenticated;
GRANT DELETE ON public.compensation_schemes TO service_role;
GRANT INSERT ON public.compensation_schemes TO service_role;
GRANT REFERENCES ON public.compensation_schemes TO service_role;
GRANT SELECT ON public.compensation_schemes TO service_role;
GRANT TRIGGER ON public.compensation_schemes TO service_role;
GRANT TRUNCATE ON public.compensation_schemes TO service_role;
GRANT UPDATE ON public.compensation_schemes TO service_role;
GRANT DELETE ON public.document_templates TO anon;
GRANT INSERT ON public.document_templates TO anon;
GRANT REFERENCES ON public.document_templates TO anon;
GRANT SELECT ON public.document_templates TO anon;
GRANT TRIGGER ON public.document_templates TO anon;
GRANT TRUNCATE ON public.document_templates TO anon;
GRANT UPDATE ON public.document_templates TO anon;
GRANT DELETE ON public.document_templates TO authenticated;
GRANT INSERT ON public.document_templates TO authenticated;
GRANT REFERENCES ON public.document_templates TO authenticated;
GRANT SELECT ON public.document_templates TO authenticated;
GRANT TRIGGER ON public.document_templates TO authenticated;
GRANT TRUNCATE ON public.document_templates TO authenticated;
GRANT UPDATE ON public.document_templates TO authenticated;
GRANT DELETE ON public.document_templates TO service_role;
GRANT INSERT ON public.document_templates TO service_role;
GRANT REFERENCES ON public.document_templates TO service_role;
GRANT SELECT ON public.document_templates TO service_role;
GRANT TRIGGER ON public.document_templates TO service_role;
GRANT TRUNCATE ON public.document_templates TO service_role;
GRANT UPDATE ON public.document_templates TO service_role;
GRANT DELETE ON public.documents TO authenticated;
GRANT INSERT ON public.documents TO authenticated;
GRANT SELECT ON public.documents TO authenticated;
GRANT UPDATE ON public.documents TO authenticated;
GRANT DELETE ON public.documents TO service_role;
GRANT INSERT ON public.documents TO service_role;
GRANT REFERENCES ON public.documents TO service_role;
GRANT SELECT ON public.documents TO service_role;
GRANT TRIGGER ON public.documents TO service_role;
GRANT TRUNCATE ON public.documents TO service_role;
GRANT UPDATE ON public.documents TO service_role;
GRANT DELETE ON public.fee_agreements TO authenticated;
GRANT INSERT ON public.fee_agreements TO authenticated;
GRANT REFERENCES ON public.fee_agreements TO authenticated;
GRANT SELECT ON public.fee_agreements TO authenticated;
GRANT TRIGGER ON public.fee_agreements TO authenticated;
GRANT TRUNCATE ON public.fee_agreements TO authenticated;
GRANT UPDATE ON public.fee_agreements TO authenticated;
GRANT DELETE ON public.fee_agreements TO service_role;
GRANT INSERT ON public.fee_agreements TO service_role;
GRANT REFERENCES ON public.fee_agreements TO service_role;
GRANT SELECT ON public.fee_agreements TO service_role;
GRANT TRIGGER ON public.fee_agreements TO service_role;
GRANT TRUNCATE ON public.fee_agreements TO service_role;
GRANT UPDATE ON public.fee_agreements TO service_role;
GRANT DELETE ON public.fee_installments TO authenticated;
GRANT INSERT ON public.fee_installments TO authenticated;
GRANT REFERENCES ON public.fee_installments TO authenticated;
GRANT SELECT ON public.fee_installments TO authenticated;
GRANT TRIGGER ON public.fee_installments TO authenticated;
GRANT TRUNCATE ON public.fee_installments TO authenticated;
GRANT UPDATE ON public.fee_installments TO authenticated;
GRANT DELETE ON public.fee_installments TO service_role;
GRANT INSERT ON public.fee_installments TO service_role;
GRANT REFERENCES ON public.fee_installments TO service_role;
GRANT SELECT ON public.fee_installments TO service_role;
GRANT TRIGGER ON public.fee_installments TO service_role;
GRANT TRUNCATE ON public.fee_installments TO service_role;
GRANT UPDATE ON public.fee_installments TO service_role;
GRANT SELECT ON public.firm_invitations TO authenticated;
GRANT DELETE ON public.firm_invitations TO service_role;
GRANT INSERT ON public.firm_invitations TO service_role;
GRANT REFERENCES ON public.firm_invitations TO service_role;
GRANT SELECT ON public.firm_invitations TO service_role;
GRANT TRIGGER ON public.firm_invitations TO service_role;
GRANT TRUNCATE ON public.firm_invitations TO service_role;
GRANT UPDATE ON public.firm_invitations TO service_role;
GRANT DELETE ON public.firm_member_details TO anon;
GRANT INSERT ON public.firm_member_details TO anon;
GRANT REFERENCES ON public.firm_member_details TO anon;
GRANT SELECT ON public.firm_member_details TO anon;
GRANT TRIGGER ON public.firm_member_details TO anon;
GRANT TRUNCATE ON public.firm_member_details TO anon;
GRANT UPDATE ON public.firm_member_details TO anon;
GRANT DELETE ON public.firm_member_details TO authenticated;
GRANT INSERT ON public.firm_member_details TO authenticated;
GRANT REFERENCES ON public.firm_member_details TO authenticated;
GRANT SELECT ON public.firm_member_details TO authenticated;
GRANT TRIGGER ON public.firm_member_details TO authenticated;
GRANT TRUNCATE ON public.firm_member_details TO authenticated;
GRANT UPDATE ON public.firm_member_details TO authenticated;
GRANT DELETE ON public.firm_member_details TO service_role;
GRANT INSERT ON public.firm_member_details TO service_role;
GRANT REFERENCES ON public.firm_member_details TO service_role;
GRANT SELECT ON public.firm_member_details TO service_role;
GRANT TRIGGER ON public.firm_member_details TO service_role;
GRANT TRUNCATE ON public.firm_member_details TO service_role;
GRANT UPDATE ON public.firm_member_details TO service_role;
GRANT DELETE ON public.firm_memberships TO authenticated;
GRANT REFERENCES ON public.firm_memberships TO authenticated;
GRANT SELECT ON public.firm_memberships TO authenticated;
GRANT TRIGGER ON public.firm_memberships TO authenticated;
GRANT TRUNCATE ON public.firm_memberships TO authenticated;
GRANT UPDATE ON public.firm_memberships TO authenticated;
GRANT DELETE ON public.firm_memberships TO service_role;
GRANT INSERT ON public.firm_memberships TO service_role;
GRANT REFERENCES ON public.firm_memberships TO service_role;
GRANT SELECT ON public.firm_memberships TO service_role;
GRANT TRIGGER ON public.firm_memberships TO service_role;
GRANT TRUNCATE ON public.firm_memberships TO service_role;
GRANT UPDATE ON public.firm_memberships TO service_role;
GRANT DELETE ON public.firm_settings TO anon;
GRANT INSERT ON public.firm_settings TO anon;
GRANT REFERENCES ON public.firm_settings TO anon;
GRANT SELECT ON public.firm_settings TO anon;
GRANT TRIGGER ON public.firm_settings TO anon;
GRANT TRUNCATE ON public.firm_settings TO anon;
GRANT UPDATE ON public.firm_settings TO anon;
GRANT DELETE ON public.firm_settings TO authenticated;
GRANT INSERT ON public.firm_settings TO authenticated;
GRANT REFERENCES ON public.firm_settings TO authenticated;
GRANT SELECT ON public.firm_settings TO authenticated;
GRANT TRIGGER ON public.firm_settings TO authenticated;
GRANT TRUNCATE ON public.firm_settings TO authenticated;
GRANT UPDATE ON public.firm_settings TO authenticated;
GRANT DELETE ON public.firm_settings TO service_role;
GRANT INSERT ON public.firm_settings TO service_role;
GRANT REFERENCES ON public.firm_settings TO service_role;
GRANT SELECT ON public.firm_settings TO service_role;
GRANT TRIGGER ON public.firm_settings TO service_role;
GRANT TRUNCATE ON public.firm_settings TO service_role;
GRANT UPDATE ON public.firm_settings TO service_role;
GRANT DELETE ON public.firms TO authenticated;
GRANT INSERT ON public.firms TO authenticated;
GRANT REFERENCES ON public.firms TO authenticated;
GRANT SELECT ON public.firms TO authenticated;
GRANT TRIGGER ON public.firms TO authenticated;
GRANT TRUNCATE ON public.firms TO authenticated;
GRANT UPDATE ON public.firms TO authenticated;
GRANT DELETE ON public.firms TO service_role;
GRANT INSERT ON public.firms TO service_role;
GRANT REFERENCES ON public.firms TO service_role;
GRANT SELECT ON public.firms TO service_role;
GRANT TRIGGER ON public.firms TO service_role;
GRANT TRUNCATE ON public.firms TO service_role;
GRANT UPDATE ON public.firms TO service_role;
GRANT DELETE ON public.payment_allocations TO authenticated;
GRANT INSERT ON public.payment_allocations TO authenticated;
GRANT REFERENCES ON public.payment_allocations TO authenticated;
GRANT SELECT ON public.payment_allocations TO authenticated;
GRANT TRIGGER ON public.payment_allocations TO authenticated;
GRANT TRUNCATE ON public.payment_allocations TO authenticated;
GRANT UPDATE ON public.payment_allocations TO authenticated;
GRANT DELETE ON public.payment_allocations TO service_role;
GRANT INSERT ON public.payment_allocations TO service_role;
GRANT REFERENCES ON public.payment_allocations TO service_role;
GRANT SELECT ON public.payment_allocations TO service_role;
GRANT TRIGGER ON public.payment_allocations TO service_role;
GRANT TRUNCATE ON public.payment_allocations TO service_role;
GRANT UPDATE ON public.payment_allocations TO service_role;
GRANT REFERENCES ON public.payment_distributions TO authenticated;
GRANT SELECT ON public.payment_distributions TO authenticated;
GRANT TRIGGER ON public.payment_distributions TO authenticated;
GRANT TRUNCATE ON public.payment_distributions TO authenticated;
GRANT UPDATE ON public.payment_distributions TO authenticated;
GRANT DELETE ON public.payment_distributions TO service_role;
GRANT INSERT ON public.payment_distributions TO service_role;
GRANT REFERENCES ON public.payment_distributions TO service_role;
GRANT SELECT ON public.payment_distributions TO service_role;
GRANT TRIGGER ON public.payment_distributions TO service_role;
GRANT TRUNCATE ON public.payment_distributions TO service_role;
GRANT UPDATE ON public.payment_distributions TO service_role;
GRANT INSERT ON public.payments TO authenticated;
GRANT REFERENCES ON public.payments TO authenticated;
GRANT SELECT ON public.payments TO authenticated;
GRANT TRIGGER ON public.payments TO authenticated;
GRANT TRUNCATE ON public.payments TO authenticated;
GRANT UPDATE ON public.payments TO authenticated;
GRANT DELETE ON public.payments TO service_role;
GRANT INSERT ON public.payments TO service_role;
GRANT REFERENCES ON public.payments TO service_role;
GRANT SELECT ON public.payments TO service_role;
GRANT TRIGGER ON public.payments TO service_role;
GRANT TRUNCATE ON public.payments TO service_role;
GRANT UPDATE ON public.payments TO service_role;
GRANT SELECT ON public.plans TO authenticated;
GRANT DELETE ON public.plans TO service_role;
GRANT INSERT ON public.plans TO service_role;
GRANT REFERENCES ON public.plans TO service_role;
GRANT SELECT ON public.plans TO service_role;
GRANT TRIGGER ON public.plans TO service_role;
GRANT TRUNCATE ON public.plans TO service_role;
GRANT UPDATE ON public.plans TO service_role;
GRANT DELETE ON public.profiles TO authenticated;
GRANT INSERT ON public.profiles TO authenticated;
GRANT REFERENCES ON public.profiles TO authenticated;
GRANT SELECT ON public.profiles TO authenticated;
GRANT TRIGGER ON public.profiles TO authenticated;
GRANT TRUNCATE ON public.profiles TO authenticated;
GRANT UPDATE ON public.profiles TO authenticated;
GRANT DELETE ON public.profiles TO service_role;
GRANT INSERT ON public.profiles TO service_role;
GRANT REFERENCES ON public.profiles TO service_role;
GRANT SELECT ON public.profiles TO service_role;
GRANT TRIGGER ON public.profiles TO service_role;
GRANT TRUNCATE ON public.profiles TO service_role;
GRANT UPDATE ON public.profiles TO service_role;
GRANT SELECT ON public.subscription_events TO authenticated;
GRANT DELETE ON public.subscription_events TO service_role;
GRANT INSERT ON public.subscription_events TO service_role;
GRANT REFERENCES ON public.subscription_events TO service_role;
GRANT SELECT ON public.subscription_events TO service_role;
GRANT TRIGGER ON public.subscription_events TO service_role;
GRANT TRUNCATE ON public.subscription_events TO service_role;
GRANT UPDATE ON public.subscription_events TO service_role;
GRANT SELECT ON public.subscriptions TO authenticated;
GRANT DELETE ON public.subscriptions TO service_role;
GRANT INSERT ON public.subscriptions TO service_role;
GRANT REFERENCES ON public.subscriptions TO service_role;
GRANT SELECT ON public.subscriptions TO service_role;
GRANT TRIGGER ON public.subscriptions TO service_role;
GRANT TRUNCATE ON public.subscriptions TO service_role;
GRANT UPDATE ON public.subscriptions TO service_role;
GRANT USAGE ON SCHEMA public,private,auth TO authenticated,anon;
SET check_function_bodies=on;