import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { PGlite } from "@electric-sql/pglite";
const sql = (p) => readFileSync(new URL(p, import.meta.url), "utf8");
test("RPC: aislamiento, vencimiento, transacciones y compatibilidad con el esquema exportado", async () => {
  const db = new PGlite();
  try {
    await db.exec(sql("./fixtures/schema.sql"));
    await db.exec(
      sql("../supabase/migrations/202610090001_frontend_adapters.sql"),
    );
    const admin = "10000000-0000-0000-0000-000000000001";
    const outsider = "10000000-0000-0000-0000-000000000002";
    const lawyer = "10000000-0000-0000-0000-000000000003";
    await db.query(
      "INSERT INTO auth.users(id,email) VALUES ($1,$4),($2,$5),($3,$6)",
      [
        admin,
        outsider,
        lawyer,
        "admin@test.invalid",
        "outside@test.invalid",
        "lawyer@test.invalid",
      ],
    );
    await db.exec(
      "INSERT INTO public.plans(code,nombre,trial_days) VALUES('corporate','Corporativo',30)",
    );
    const login = async (id) => {
      await db.query("SELECT set_config('request.jwt.claim.sub',$1,false)", [
        id,
      ]);
      await db.exec("SET ROLE authenticated");
    };
    await login(admin);
    const {
      rows: [{ id: firm }],
    } = await db.query("SELECT public.create_firm('A','a') AS id");
    await db.exec("RESET ROLE");
    await db.exec(
      sql("../supabase/migrations/202610090002_trial_seven_days.sql"),
    );
    const oldTrial = await db.query(
      "SELECT extract(epoch FROM trial_end-trial_start)/86400 AS days FROM subscriptions WHERE firm_id=$1",
      [firm],
    );
    assert.equal(Number(oldTrial.rows[0].days), 30);
    await login(outsider);
    const {
      rows: [{ id: other }],
    } = await db.query("SELECT public.create_firm('B','b') AS id");
    const newTrial = await db.query(
      "SELECT extract(epoch FROM trial_end-trial_start)/86400 AS days FROM subscriptions WHERE firm_id=$1",
      [other],
    );
    assert.equal(Number(newTrial.rows[0].days), 7);
    await login(admin);
    const client = (
      await db.query(
        "INSERT INTO public.clients(firm_id,nombres,creado_por) VALUES($1,'Cliente ficticio',$2) RETURNING id",
        [firm, admin],
      )
    ).rows[0].id;
    const callCase = (f, fields, user = admin, id = null) =>
      db.query("SELECT public.app_save_case($1,$2,$3,$4,true) AS result", [
        f,
        id,
        fields,
        user,
      ]);
    const fields = {
      client_id: client,
      numero_caso: "A-1",
      titulo: "Caso de prueba",
    };
    const c = (await callCase(firm, fields)).rows[0].result;
    assert.equal(c.firm_id, firm);
    await assert.rejects(callCase(other, fields), /Acceso denegado/);
    await assert.rejects(
      callCase(firm, { ...fields, numero_caso: "A-2" }, outsider),
      /ajeno/,
    );
    const before = (await db.query("SELECT count(*) AS n FROM cases")).rows[0]
      .n;
    await assert.rejects(
      callCase(firm, { ...fields, numero_caso: "A-3", client_id: outsider }),
      /Cliente ajeno/,
    );
    assert.equal(
      (await db.query("SELECT count(*) AS n FROM cases")).rows[0].n,
      before,
    );
    const member = {
      nombres: "Abogada",
      apellido_paterno: "Prueba",
      cargo: "Abogada",
      role: "abogado",
    };
    await db.query("SELECT public.app_save_member($1,$2,$3,true)", [
      firm,
      lawyer,
      member,
    ]);
    const agreement = {
      expedienteId: c.id,
      montoTotal: 100,
      moneda: "BS",
      estadoContrato: "vigente",
      porcentajeFondo: 10,
      distribucionAbogados: [{ abogadoId: lawyer, porcentaje: "50" }],
    };
    const installments = [
      {
        descripcion: "Primera",
        monto: 40,
        tipoVencimiento: "fecha",
        fechaVencimiento: "2030-01-01",
        estado: "pagado",
      },
      {
        descripcion: "Segunda",
        monto: 60,
        tipoVencimiento: "hito",
        hitoVencimiento: "Sentencia",
        estado: "pendiente",
      },
    ];
    await assert.rejects(
      db.query("SELECT app_create_agreement($1,$2,$3)", [
        firm,
        agreement,
        [{ ...installments[0], monto: 99 }],
      ]),
      /sumar/,
    );
    assert.equal(
      (await db.query("SELECT count(*) AS n FROM fee_agreements")).rows[0].n,
      0,
    );
    await assert.rejects(
      db.query("SELECT app_create_agreement($1,$2,$3)", [
        firm,
        agreement,
        [installments[0], { ...installments[1], hitoVencimiento: "" }],
      ]),
    );
    assert.equal(
      (await db.query("SELECT count(*) AS n FROM fee_agreements")).rows[0].n,
      0,
    );
    assert.equal(
      (await db.query("SELECT count(*) AS n FROM payments")).rows[0].n,
      0,
    );
    const result = (
      await db.query("SELECT app_create_agreement($1,$2,$3) AS r", [
        firm,
        agreement,
        installments,
      ])
    ).rows[0].r;
    assert.equal(result.agreement.moneda, "BOB");
    assert.equal(result.installments.length, 2);
    assert.equal(Object.values(result.paid)[0], 40);
    assert.equal(
      Number(
        (await db.query("SELECT sum(valor) AS total FROM compensation_rules"))
          .rows[0].total,
      ),
      100,
    );
    await assert.rejects(
      db.query("SELECT app_create_agreement($1,$2,$3)", [
        firm,
        agreement,
        installments,
      ]),
      /ya tiene/,
    );
    await login(outsider);
    assert.equal(
      (await db.query("SELECT id FROM cases WHERE firm_id=$1", [firm])).rows
        .length,
      0,
    );
    await assert.rejects(
      db.query("SELECT app_save_member($1,$2,$3,false)", [
        firm,
        lawyer,
        member,
      ]),
      /administrador/,
    );
    await db.exec("RESET ROLE");
    await db.query(
      "UPDATE subscriptions SET trial_start=now()-interval '8 days', trial_end=now()-interval '1 second' WHERE firm_id=$1",
      [firm],
    );
    await login(admin);
    await assert.rejects(
      callCase(firm, { ...fields, numero_caso: "VENCIDO" }),
      /Acceso denegado/,
    );
    assert.equal(
      (await db.query("SELECT id FROM cases WHERE firm_id=$1", [firm])).rows
        .length,
      0,
    );
  } finally {
    await db.close();
  }
});
