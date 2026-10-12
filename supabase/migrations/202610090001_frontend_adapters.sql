-- Aplicar primero en una copia de desarrollo. No altera tablas ni los datos existentes.
begin;
CREATE OR REPLACE FUNCTION public.app_save_case(p_firm_id uuid, p_id uuid, p_fields jsonb, p_assignee uuid, p_set_assignee boolean)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v public.cases; incoming public.cases; member_id uuid; privileged boolean;
BEGIN
  IF auth.uid() IS NULL OR NOT private.has_firm_role(p_firm_id, ARRAY['admin','asociado_senior','abogado']::public.firm_role[]) THEN RAISE EXCEPTION 'Acceso denegado'; END IF;
  privileged := private.has_firm_role(p_firm_id, ARRAY['admin','asociado_senior']::public.firm_role[]);
  incoming := jsonb_populate_record(NULL::public.cases, p_fields);
  IF p_set_assignee AND p_assignee IS NOT NULL THEN
    SELECT id INTO member_id FROM public.firm_memberships WHERE firm_id=p_firm_id AND user_id=p_assignee AND status='activo' AND role <> 'cliente';
    IF member_id IS NULL THEN RAISE EXCEPTION 'Responsable ajeno al equipo activo'; END IF;
  END IF;
  IF p_id IS NULL THEN
    IF NOT privileged AND (p_assignee IS DISTINCT FROM auth.uid()) THEN RAISE EXCEPTION 'Un abogado debe asignarse a sí mismo al crear un expediente'; END IF;
    IF NOT EXISTS(SELECT 1 FROM public.clients WHERE firm_id=p_firm_id AND id=incoming.client_id) THEN RAISE EXCEPTION 'Cliente ajeno a la firma'; END IF;
    INSERT INTO public.cases (firm_id,client_id,creado_por,numero_caso,titulo,materia,juzgado,parte_contraria,informe_despacho,informe_cliente,rol_cliente,tipo_proceso,nurej,numero_fiscalia,numero_felcc,juez_actual,secretario_actuario,fiscal_actual,investigador_asignado,etapa_procesal,cuantia,estado)
    VALUES (p_firm_id,incoming.client_id,auth.uid(),incoming.numero_caso,incoming.titulo,incoming.materia,incoming.juzgado,incoming.parte_contraria,incoming.informe_despacho,incoming.informe_cliente,incoming.rol_cliente,incoming.tipo_proceso,incoming.nurej,incoming.numero_fiscalia,incoming.numero_felcc,incoming.juez_actual,incoming.secretario_actuario,incoming.fiscal_actual,incoming.investigador_asignado,incoming.etapa_procesal,incoming.cuantia,coalesce(incoming.estado,'en_espera'::public.case_status)) RETURNING * INTO v;
  ELSE
    SELECT * INTO v FROM public.cases WHERE id=p_id AND firm_id=p_firm_id FOR UPDATE;
    IF NOT FOUND OR NOT private.can_access_case(p_firm_id,p_id) THEN RAISE EXCEPTION 'Expediente no accesible'; END IF;
    IF p_fields ? 'client_id' AND incoming.client_id IS DISTINCT FROM v.client_id THEN RAISE EXCEPTION 'No se puede cambiar el cliente del expediente'; END IF;
    IF p_set_assignee AND NOT privileged THEN
      IF NOT EXISTS(SELECT 1 FROM public.case_members WHERE firm_id=p_firm_id AND case_id=p_id AND membership_id=member_id AND role='responsable' AND activo) THEN
        RAISE EXCEPTION 'Solo administración o un asociado senior puede reasignar';
      END IF;
      p_set_assignee := false;
    END IF;
    UPDATE public.cases SET numero_caso=CASE WHEN p_fields ? 'numero_caso' THEN incoming.numero_caso ELSE v.numero_caso END,titulo=CASE WHEN p_fields ? 'titulo' THEN incoming.titulo ELSE v.titulo END,materia=CASE WHEN p_fields ? 'materia' THEN incoming.materia ELSE v.materia END,juzgado=CASE WHEN p_fields ? 'juzgado' THEN incoming.juzgado ELSE v.juzgado END,parte_contraria=CASE WHEN p_fields ? 'parte_contraria' THEN incoming.parte_contraria ELSE v.parte_contraria END,informe_despacho=CASE WHEN p_fields ? 'informe_despacho' THEN incoming.informe_despacho ELSE v.informe_despacho END,informe_cliente=CASE WHEN p_fields ? 'informe_cliente' THEN incoming.informe_cliente ELSE v.informe_cliente END,rol_cliente=CASE WHEN p_fields ? 'rol_cliente' THEN incoming.rol_cliente ELSE v.rol_cliente END,tipo_proceso=CASE WHEN p_fields ? 'tipo_proceso' THEN incoming.tipo_proceso ELSE v.tipo_proceso END,nurej=CASE WHEN p_fields ? 'nurej' THEN incoming.nurej ELSE v.nurej END,numero_fiscalia=CASE WHEN p_fields ? 'numero_fiscalia' THEN incoming.numero_fiscalia ELSE v.numero_fiscalia END,numero_felcc=CASE WHEN p_fields ? 'numero_felcc' THEN incoming.numero_felcc ELSE v.numero_felcc END,juez_actual=CASE WHEN p_fields ? 'juez_actual' THEN incoming.juez_actual ELSE v.juez_actual END,secretario_actuario=CASE WHEN p_fields ? 'secretario_actuario' THEN incoming.secretario_actuario ELSE v.secretario_actuario END,fiscal_actual=CASE WHEN p_fields ? 'fiscal_actual' THEN incoming.fiscal_actual ELSE v.fiscal_actual END,investigador_asignado=CASE WHEN p_fields ? 'investigador_asignado' THEN incoming.investigador_asignado ELSE v.investigador_asignado END,etapa_procesal=CASE WHEN p_fields ? 'etapa_procesal' THEN incoming.etapa_procesal ELSE v.etapa_procesal END,cuantia=CASE WHEN p_fields ? 'cuantia' THEN incoming.cuantia ELSE v.cuantia END,estado=CASE WHEN p_fields ? 'estado' THEN incoming.estado ELSE v.estado END, updated_at=now() WHERE id=p_id AND firm_id=p_firm_id RETURNING * INTO v;
  END IF;
  IF p_set_assignee THEN
    UPDATE public.case_members SET role='colaborador' WHERE firm_id=p_firm_id AND case_id=v.id AND role='responsable' AND activo=true;
    IF member_id IS NOT NULL THEN
      INSERT INTO public.case_members(firm_id,case_id,membership_id,role,asignado_por,activo)
      VALUES(p_firm_id,v.id,member_id,'responsable',auth.uid(),true)
      ON CONFLICT(case_id,membership_id) DO UPDATE SET role='responsable',activo=true,asignado_por=auth.uid();
    END IF;
  END IF;
  RETURN to_jsonb(v);
END $$;
REVOKE ALL ON FUNCTION public.app_save_case(uuid,uuid,jsonb,uuid,boolean) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.app_save_case(uuid,uuid,jsonb,uuid,boolean) TO authenticated;

CREATE OR REPLACE FUNCTION public.app_save_member(p_firm_id uuid, p_user_id uuid, p_fields jsonb, p_create boolean)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE m public.firm_memberships; p public.profiles; d public.firm_member_details; new_role public.firm_role;
BEGIN
  IF auth.uid() IS NULL OR NOT private.has_firm_role(p_firm_id,ARRAY['admin']::public.firm_role[]) THEN RAISE EXCEPTION 'Solo el administrador de la firma'; END IF;
  -- Serializar modificaciones del equipo, incluida la protección del último admin.
  PERFORM 1 FROM public.firms WHERE id=p_firm_id FOR UPDATE;
  SELECT * INTO m FROM public.firm_memberships WHERE firm_id=p_firm_id AND user_id=p_user_id FOR UPDATE;
  IF NOT p_create AND m.id IS NULL THEN RAISE EXCEPTION 'Miembro ajeno a la firma'; END IF;
  IF p_create AND EXISTS(SELECT 1 FROM public.firm_memberships WHERE user_id=p_user_id) THEN RAISE EXCEPTION 'Para usuarios existentes utiliza una invitación'; END IF;
  new_role := coalesce((p_fields->>'role')::public.firm_role,m.role);
  IF new_role IS NULL OR new_role='cliente' THEN RAISE EXCEPTION 'Rol de equipo inválido'; END IF;
  SELECT * INTO p FROM public.profiles WHERE id=p_user_id;
  IF p.id IS NOT NULL AND p_user_id<>auth.uid() AND EXISTS(SELECT 1 FROM public.firm_memberships WHERE user_id=p_user_id AND firm_id<>p_firm_id)
     AND ((p_fields ? 'nombres' AND (p_fields->>'nombres') IS DISTINCT FROM p.nombres)
       OR (p_fields ? 'apellido_paterno' AND (p_fields->>'apellido_paterno') IS DISTINCT FROM p.apellido_paterno)
       OR (p_fields ? 'apellido_materno' AND (p_fields->>'apellido_materno') IS DISTINCT FROM p.apellido_materno)
       OR (p_fields ? 'telefono' AND (p_fields->>'telefono') IS DISTINCT FROM p.telefono))
  THEN RAISE EXCEPTION 'El perfil es compartido; el usuario debe editar sus datos personales'; END IF;
  INSERT INTO public.profiles(id,nombres,apellido_paterno,apellido_materno,telefono)
  VALUES(p_user_id,p_fields->>'nombres',p_fields->>'apellido_paterno',p_fields->>'apellido_materno',p_fields->>'telefono')
  ON CONFLICT(id) DO UPDATE SET
    nombres=CASE WHEN p_fields ? 'nombres' THEN excluded.nombres ELSE profiles.nombres END,
    apellido_paterno=CASE WHEN p_fields ? 'apellido_paterno' THEN excluded.apellido_paterno ELSE profiles.apellido_paterno END,
    apellido_materno=CASE WHEN p_fields ? 'apellido_materno' THEN excluded.apellido_materno ELSE profiles.apellido_materno END,
    telefono=CASE WHEN p_fields ? 'telefono' THEN excluded.telefono ELSE profiles.telefono END,updated_at=now();
  IF p_create THEN
    INSERT INTO public.firm_memberships(firm_id,user_id,role,status,joined_at,invitado_por)
    VALUES(p_firm_id,p_user_id,new_role,'activo',now(),auth.uid()) RETURNING * INTO m;
  ELSE
    UPDATE public.firm_memberships SET role=new_role,updated_at=now() WHERE id=m.id;
  END IF;
  SELECT * INTO d FROM public.firm_member_details WHERE firm_id=p_firm_id AND user_id=p_user_id;
  INSERT INTO public.firm_member_details(firm_id,user_id,cargo,especialidad,estado_laboral)
  VALUES(p_firm_id,p_user_id,coalesce(p_fields->>'cargo',d.cargo),CASE WHEN p_fields ? 'especialidad' THEN p_fields->>'especialidad' ELSE d.especialidad END,coalesce(p_fields->>'estado_laboral',d.estado_laboral,'activo'))
  ON CONFLICT(firm_id,user_id) DO UPDATE SET cargo=excluded.cargo,especialidad=excluded.especialidad,estado_laboral=excluded.estado_laboral,actualizado_en=now();
  RETURN m.id;
END $$;
REVOKE ALL ON FUNCTION public.app_save_member(uuid,uuid,jsonb,boolean) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.app_save_member(uuid,uuid,jsonb,boolean) TO authenticated;

CREATE OR REPLACE FUNCTION public.app_create_agreement(p_firm_id uuid,p_data jsonb,p_installments jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE a public.fee_agreements; i public.fee_installments; q jsonb; total numeric; n integer:=0;
  scheme uuid; member uuid; entry record; payment_id uuid; paid jsonb:='{}'; fund numeric; sum_rules numeric; currency text; net_pct numeric; principal uuid; gross numeric;
BEGIN
  IF auth.uid() IS NULL OR NOT private.can_manage_finance(p_firm_id) THEN RAISE EXCEPTION 'Acceso financiero denegado'; END IF;
  PERFORM 1 FROM public.cases WHERE id=(p_data->>'expedienteId')::uuid AND firm_id=p_firm_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Expediente ajeno a la firma'; END IF;
  IF EXISTS(SELECT 1 FROM public.fee_agreements WHERE firm_id=p_firm_id AND case_id=(p_data->>'expedienteId')::uuid AND estado<>'cancelado') THEN RAISE EXCEPTION 'Este expediente ya tiene contrato'; END IF;
  total := (p_data->>'montoTotal')::numeric;
  IF total IS NULL OR total<=0 OR total<>round(total,2) OR jsonb_typeof(p_installments)<>'array' OR jsonb_array_length(p_installments)=0 THEN RAISE EXCEPTION 'Contrato o cuotas inválidos'; END IF;
  IF (SELECT sum((value->>'monto')::numeric) FROM jsonb_array_elements(p_installments)) IS DISTINCT FROM total THEN RAISE EXCEPTION 'Las cuotas deben sumar exactamente el contrato'; END IF;
  currency := CASE p_data->>'moneda' WHEN 'BS' THEN 'BOB' WHEN 'USD' THEN 'USD' ELSE NULL END;
  IF currency IS NULL THEN RAISE EXCEPTION 'Moneda no admitida'; END IF;
  -- Preservar la calculadora existente: 28.5% de deducciones + fondo, reparto sobre el neto.
  -- Estos porcentajes proceden del frontend; no constituyen una validación tributaria.
  fund := coalesce((p_data->>'porcentajeFondo')::numeric,0);
  IF fund<0 OR fund>71.5 THEN RAISE EXCEPTION 'El fondo deja una base de reparto negativa'; END IF;
  net_pct := 71.5-fund;
  IF jsonb_typeof(coalesce(p_data->'distribucionAbogados','[]'))<>'array' THEN RAISE EXCEPTION 'Distribución inválida'; END IF;
  sum_rules := 0;
  INSERT INTO public.compensation_schemes(firm_id,nombre,descripcion,creado_por)
  VALUES(p_firm_id,'Distribución del contrato','Calculadora heredada: deducciones 28.5%; reparto del neto',auth.uid()) RETURNING id INTO scheme;
  INSERT INTO public.compensation_rules(firm_id,scheme_id,nombre,recipient_type,recipient_label,calculation_type,valor)
  VALUES(p_firm_id,scheme,'Deducciones calculadora','personalizado','Deducciones calculadora heredada','porcentaje',28.5);
  IF fund>0 THEN INSERT INTO public.compensation_rules(firm_id,scheme_id,nombre,recipient_type,calculation_type,valor) VALUES(p_firm_id,scheme,'Firma','firma','porcentaje',fund); END IF;
  FOR entry IN SELECT value->>'abogadoId' AS key, value->>'porcentaje' AS value FROM jsonb_array_elements(coalesce(p_data->'distribucionAbogados','[]')) LOOP
    IF entry.value IS NULL OR entry.value::numeric<0 THEN RAISE EXCEPTION 'Porcentaje inválido'; END IF;
    sum_rules:=sum_rules+entry.value::numeric;
    IF sum_rules>100 THEN RAISE EXCEPTION 'La distribución supera 100 por ciento'; END IF;
    gross:=net_pct*entry.value::numeric/100;
    IF gross=0 THEN CONTINUE; END IF;
    SELECT id INTO member FROM public.firm_memberships WHERE firm_id=p_firm_id AND user_id=entry.key::uuid AND status='activo' AND role<>'cliente';
    IF member IS NULL THEN RAISE EXCEPTION 'Beneficiario ajeno al equipo'; END IF;
    INSERT INTO public.compensation_rules(firm_id,scheme_id,nombre,recipient_type,membership_id,calculation_type,valor)
    VALUES(p_firm_id,scheme,'Miembro','miembro',member,'porcentaje',gross);
  END LOOP;
  IF sum_rules<100 AND net_pct>0 THEN
    SELECT cm.membership_id INTO principal FROM public.case_members cm JOIN public.firm_memberships fm ON fm.id=cm.membership_id AND fm.firm_id=cm.firm_id
    WHERE cm.firm_id=p_firm_id AND cm.case_id=(p_data->>'expedienteId')::uuid AND cm.activo AND cm.role='responsable' AND fm.status='activo' AND fm.role<>'cliente' LIMIT 1;
    IF principal IS NULL THEN RAISE EXCEPTION 'Asigna un responsable al expediente para recibir el remanente'; END IF;
    INSERT INTO public.compensation_rules(firm_id,scheme_id,nombre,recipient_type,membership_id,calculation_type,valor)
    VALUES(p_firm_id,scheme,'Remanente responsable','miembro',principal,'porcentaje',net_pct*(100-sum_rules)/100);
  END IF;
  INSERT INTO public.fee_agreements(firm_id,case_id,compensation_scheme_id,monto_total,moneda,estado,creado_por,autorizado_por,autorizado_at)
  VALUES(p_firm_id,(p_data->>'expedienteId')::uuid,scheme,total,currency,coalesce((p_data->>'estadoContrato')::public.fee_agreement_status,'vigente'),auth.uid(),CASE WHEN (p_data->>'autorizadoAdministracion')::boolean THEN auth.uid() END,CASE WHEN (p_data->>'autorizadoAdministracion')::boolean THEN now() END) RETURNING * INTO a;
  FOR q IN SELECT value FROM jsonb_array_elements(p_installments) LOOP
    n:=n+1;
    IF (q->>'monto')::numeric<=0 OR (q->>'monto')::numeric<>round((q->>'monto')::numeric,2) THEN RAISE EXCEPTION 'Cuota inválida'; END IF;
    INSERT INTO public.fee_installments(firm_id,agreement_id,numero,descripcion,monto,tipo_vencimiento,fecha_vencimiento,hito_vencimiento,estado)
    VALUES(p_firm_id,a.id,n,q->>'descripcion',(q->>'monto')::numeric,coalesce((q->>'tipoVencimiento')::public.installment_due_type,'fecha'),nullif(q->>'fechaVencimiento','')::date,nullif(q->>'hitoVencimiento',''),CASE WHEN q->>'estado'='pagado' THEN 'pendiente'::public.installment_status ELSE coalesce((q->>'estado')::public.installment_status,'pendiente') END) RETURNING * INTO i;
    IF q->>'estado'='pagado' THEN
      INSERT INTO public.payments(firm_id,case_id,monto,moneda,metodo,fecha_pago,registrado_por,observaciones)
      VALUES(p_firm_id,a.case_id,i.monto,currency,'otro',coalesce(nullif(q->>'fechaPago','')::timestamptz,now()),auth.uid(),'Pago inicial declarado al crear el contrato') RETURNING id INTO payment_id;
      INSERT INTO public.payment_allocations(firm_id,payment_id,installment_id,monto) VALUES(p_firm_id,payment_id,i.id,i.monto);
      UPDATE public.fee_installments SET estado='pagado',pagado_at=coalesce(nullif(q->>'fechaPago','')::timestamptz,now()) WHERE id=i.id;
      paid:=paid || jsonb_build_object(i.id::text,i.monto);
      IF scheme IS NOT NULL THEN PERFORM public.generate_payment_distributions(payment_id,a.id); END IF;
    END IF;
  END LOOP;
  RETURN jsonb_build_object('agreement',to_jsonb(a),'installments',(SELECT jsonb_agg(to_jsonb(fi) ORDER BY numero) FROM public.fee_installments fi WHERE fi.agreement_id=a.id AND fi.firm_id=p_firm_id),'paid',paid);
END $$;
REVOKE ALL ON FUNCTION public.app_create_agreement(uuid,jsonb,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.app_create_agreement(uuid,jsonb,jsonb) TO authenticated;
commit;
