# 🏛️ Technische Architectuur & Design Specificaties

Dit document bevat de gedetailleerde technische architectuur van de **Waasland Logistics & Cloud Services (WLCS)** Azure-omgeving. Deze architectuur is ontworpen volgens de best practices van het **Microsoft Cloud Adoption Framework (CAF)** en het **Well-Architected Framework (WAF)**.

---

## 1. Cloud Governance & Beheershiërarchie (CAF)

Om enterprise-isolatie en schaalbaarheid te garanderen, is er gekozen voor een **Multi-Subscription Model** aangestuurd via **Azure Management Groups**. Dit voorkomt "resource wildgroei" en zorgt voor een strikte scheiding van kosten en verantwoordelijkheden.

### 🏢 Management Group Structuur
- **Tenant Root Group**: Overkoepelende ankerplaats voor globale policies.
  └── **WLCS-Root-MG**: De hoofdmap van de organisatie waar bedrijfsbrede governance wordt afgedwongen.
       ├── **WLCS-Platform-MG**: Bestemd voor gedeelde, centrale IT-infrastructuur.
       │    └── `WLCS-Platform-Prod` (Subscription)
       └── **WLCS-Workloads-MG**: Bestemd voor de daadwerkelijke bedrijfsapplicaties.
            ├── **WLCS-Prod-MG**: Productie-omgevingen (Toekomstig).
            └── **WLCS-NonProd-MG**: Test-, acceptatie- en ontwikkelomgevingen.
                 └── `WLCS-Logistics-Dev` (Subscription)

---

## 2. Identity & Access Management (RBAC)

Toegang tot de resources is strikt ingericht volgens het principe van **Least Privilege** en gebaseerd op **Microsoft Entra ID**-groepen. Er worden geen directe rechten aan individuele gebruikers toegewezen.

| Groepsnaam | Azure RBAC Rol | Bereik (Scope) | Doel |
| :--- | :--- | :--- | :--- |
| `sec-wlcs-security-auditors` | Security Reader | `WLCS-Root-MG` | Compliance en security audits over de hele tenant. |
| `sec-wlcs-network-admins` | Network Contributor | `WLCS-Platform-MG` | Beheer van de centrale netwerkhub (ExpressRoute/VPN/Firewall). |
| `sec-wlcs-sys-admins` | Virtual Machine Contributor | `WLCS-Workloads-MG` | Beheer van computing workloads (VM's, Scale Sets). |

### 🤖 Identiteit- & Kostenautomatisering
Voor de simulatie van 150 medewerkers is gekozen voor een geautomatiseerde DevOps-workaround via de **Microsoft Graph PowerShell SDK** (`scripts/sync-entra-users.ps1`). 
- **WAF Cost Optimization**: Groepen zijn ingesteld op `Assigned` (Toegewezen) in plaats van dynamische licenties (Entra ID P1/P2 vereiste) om onnodige licentiekosten in de opstartfase te elimineren.
- Het script synchroniseert gebruikers op basis van afdelingsmetadata naar de respectievelijke `dept-wlcs-` groepen.

---

## 3. Netwerk Architectuur (Hub-Spoke Topologie)

Het netwerk is ontworpen als een **Hub-and-Spoke** netwerktopologie om centrale controle te combineren met isolatie van workloads.

```text
[ Central Internet / On-Prem ]
│
▼
┌───────────────────┐
│  Platform Hub VNet│ (10.0.0.0/20)
│  - GatewaySubnet  │
│  - FirewallSubnet │
└─────────┬─────────┘
▲
│ (Bidirectionele VNet Peering)
▼
┌───────────────────┐
│Logistics Spoke VNet│ (10.1.0.0/20)
│  - Web-Subnet     │
│  - App-Subnet     │
│  - DB-Subnet 🔒   │ (Geïsoleerd via NSG poort 1433)
└───────────────────┘
```

### 🛰️ Netwerksegmentatie & Terraform Modules
De netwerkinfrastructuur is modulair opgebouwd in Terraform (`terraform/modules/network`).
*   **Hub VNet (`vnet-wlcs-hub-prod-001`)**: Gedeplooide IP-range `10.0.0.0/20`. Gereserveerd voor centrale transitdiensten.
*   **Spoke VNet (`vnet-wlcs-logistics-dev-001`)**: Gedeplooide IP-range `10.1.0.0/20`.
    *   *Micro-segmentatie*: Het database-subnet (`10.1.3.0/24`) is voorzien van een Network Security Group (`nsg-logistics-db-dev`).
    *   *Inbound Security*: De NSG blokkeert al het inkomend verkeer (`Deny-All-Other-Inbound`), met uitzondering van SQL-verkeer (poort 1433) dat specifiek afkomstig is van het applicatiesubnet.

---

## 4. Cloud Governance & Compliance Policies

Op het niveau van de `WLCS-Root-MG` zijn strikte **Azure Policies** afgedwongen om wildgroei en security-breken proactief te voorkomen (Deny effect):
1.  **Geografische Restricte**: Resources mogen *enkel* in de Azure regio `northeurope` (Ierland) worden aangemaakt. Dit minimaliseert cross-region data transfer kosten en latency.
2.  **Verplichte Tagging**: Elke resource *moet* voorzien zijn van de tags `Environment`, `Project`, en `Owner`. Dit garandeert sluitende kostentoewijzing (Cost Center tracking).
3.  **Regulatory Compliance**: Het **ISO/IEC 27001:2022** framework is gekoppeld in `Audit`-modus om continue monitoring op de Europese security baseline te waarborgen.

---

## 5. Deployment & State Management (IaC & CI/CD)

### 🔒 Remote State Backend
De Terraform state wordt niet lokaal bewaard, maar centraal en veilig opgeslagen in een **Azure Blob Storage Container** (`tfstate`) binnen de Resource Group `rg-wlcs-tfstate-prod-001`.
*   Toegang is beveiligd via RBAC met de rol `Storage Blob Data Owner`.
*   State locking voorkomt *concurrency*-conflicten tijdens gelijktijdige runs.

### 🚀 CI/CD GitHub Actions Pipeline
De pipeline (`.github/workflows/terraform-deploy.yml`) is opgedeeld in drie geautomatiseerde fases om menselijke fouten uit te sluiten:

1.  **Code Validation & Security (Shift-Left Security)**:
    *   `terraform fmt -check` en `terraform validate` controleren de syntax.
    *   **Trivy Security** scant de code op hardcoded secrets en misconfiguraties *voordat* er infrastructuur wordt aangemaakt.
2.  **Terraform Security Plan**:
    *   Genereert het infrastructuurplan via OIDC (OpenID Connect) authenticatie. Dit is passwordless en elimineert het risico van rondslingerende Azure Client Secrets op GitHub.
3.  **Azure Infrastructure Apply**:
    *   **Gated Deployment**: Deze fase vereist een handmatige goedkeuring (*Environment Approval*) in GitHub om te garanderen dat er nooit ongecontroleerd wijzigingen naar Azure gepusht worden.