# practiquescloud

Repositori de pràctiques del mòdul **OPT: Cloud Computing** (ASIX2, INS Provençana).

Cada pràctica té la seva pròpia carpeta amb el codi d'Infraestructura com a Codi
(Terraform), els diagrames de topologia i la documentació del desplegament.

## Pràctiques

| Pràctica | Contingut | Enllaç |
|---|---|---|
| Pt1.4 — Exercici 1 | 2 instàncies EC2 `t3.micro` amb Amazon Linux 2023 a `us-east-1` | [`pt1-4-ex1/`](pt1-4-ex1/) |

## Requisits

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5
- Credencials d'AWS amb permisos per crear els recursos de cada pràctica
- (Opcional) AWS CLI per verificar els recursos desplegats

## Ús general

```bash
git clone https://github.com/Josueinsti123/practiquescloud.git
cd practiquescloud/<practica>
terraform init
terraform plan
terraform apply
# ... proves ...
terraform destroy
```

Cada carpeta conté un `README.md` amb el procediment detallat, la topologia i les
instruccions d'execució.

## Autor

**Josué Córdova** — ASIX2, INS Provençana · Curs 2026-2027
