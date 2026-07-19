# OpenAPI 3.1 skeleton — distilled reference

Bundled starting skeleton for `stdd-plan`'s `api.yml` (S-16). API shape lives
**only** in `api.yml` — copy this skeleton as a starting point, then fill it
in from the approved `spec.md`; never redefine the shape a second time in
`design-be.md`/`design-fe.md`.

```yaml
openapi: 3.1.0
info:
  title: <Change name> API
  version: 0.1.0
paths:
  /webhooks/{id}/deliveries:
    get:
      summary: List delivery attempts for a webhook
      operationId: listDeliveries
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/DeliveryList'
components:
  schemas:
    DeliveryList:
      type: object
      properties:
        deliveries:
          type: array
          items:
            $ref: '#/components/schemas/Delivery'
    Delivery:
      type: object
      required: [id, status, attempt]
      properties:
        id:
          type: string
          format: uuid
        status:
          type: string
          enum: [pending, failed, delivered]
        attempt:
          type: integer
```

## Notes

- `components` is optional under OpenAPI 3.1 (no `paths` object is required
  to reference it) — omit the section entirely for a contract with no
  reusable schemas, rather than leaving an empty stub.
- If no lint tool (e.g. `redocly`) is available in the environment, the
  degraded structural check (S-16) only verifies: YAML parses, `openapi`
  version field exists, `paths` exists with required fields, and
  `components` (if present) is structurally valid — it does NOT validate
  full JSON Schema correctness the way a real linter would. Say so plainly
  in the plan report when this degraded path is taken.
