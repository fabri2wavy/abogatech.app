import { test } from "node:test";
import assert from "node:assert/strict";
import {
  subscriptionIsOperational,
  selectMembership,
} from "../infrastructure/backend/context";
import {
  paidByInstallment,
  mapInstallment,
  assertSingleCurrency,
} from "../infrastructure/backend/finance";
import type { Rows } from "../domain/types/database";
test("vencimiento exacto y past_due coinciden con la política exportada", () => {
  const now = Date.parse("2026-10-12T12:00:00Z");
  assert.equal(
    subscriptionIsOperational(
      { status: "trialing", trial_end: "2026-10-12T12:00:00Z" },
      now,
    ),
    false,
  );
  assert.equal(
    subscriptionIsOperational(
      { status: "trialing", trial_end: "2026-10-12T12:00:01Z" },
      now,
    ),
    true,
  );
  assert.equal(
    subscriptionIsOperational({ status: "trialing", trial_end: null }, now),
    false,
  );
  assert.equal(
    subscriptionIsOperational({ status: "past_due", trial_end: null }, now),
    true,
  );
  assert.equal(
    subscriptionIsOperational({ status: "expired", trial_end: null }, now),
    false,
  );
});
test("la selección no inventa membresías ni elige otra firma silenciosamente", () => {
  const a = { firm_id: "A", status: "activo" } as Rows["firm_memberships"];
  const b = { firm_id: "B", status: "activo" } as Rows["firm_memberships"];
  assert.equal(selectMembership([a]).firm_id, "A");
  assert.throws(() => selectMembership([a, b]));
  assert.throws(() => selectMembership([a], "B"));
  assert.throws(() => selectMembership([{ ...a, status: "suspendido" }], "A"));
  assert.equal(selectMembership([a, b], "B").firm_id, "B");
});
test("abonos parciales y pagos anulados no se cuentan como cuotas enteras pagadas", () => {
  const payments = [
    { id: "p1", estado: "registrado" },
    { id: "p2", estado: "anulado" },
  ] as Rows["payments"][];
  const allocations = [
    { payment_id: "p1", installment_id: "i1", monto: 25 },
    { payment_id: "p2", installment_id: "i1", monto: 75 },
  ] as Rows["payment_allocations"][];
  const totals = paidByInstallment(payments, allocations);
  const row = {
    id: "i1",
    monto: 100,
    estado: "pendiente",
    fecha_vencimiento: "2000-01-01",
  } as Rows["fee_installments"];
  const mapped = mapInstallment(row, totals.get("i1")!);
  assert.equal(mapped.montoPagado, 25);
  assert.equal(mapped.saldoPendiente, 75);
  assert.equal(mapped.estado, "atrasado");
  assert.throws(() => assertSingleCurrency(["BOB", "USD"]));
});
