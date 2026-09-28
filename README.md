# Waasland Logistics & Cloud Services (WLCS) - Azure Cloud Enterprise Project

Welkom bij het cloud-infrastructuurproject voor **Waasland Logistics & Cloud Services**. In dit project bouw ik een volledige enterprise-omgeving op van A tot Z binnen Microsoft Azure, strikt conform de richtlijnen van het **Microsoft Cloud Adoption Framework (CAF)** en het **Well-Architected Framework (WAF)**.

## Project Status & Voortgang
- [x] **Fase 1: Governance & Fundering** (Voltooid)
- [ ] **Fase 2: Core Netwerkinfrastructuur** (Hub-Spoke)
- [ ] **Fase 3: Compute, Storage & Bedrijfsapplicatie**
- [ ] **Fase 4: WAF Optimalisatie (Security, Monitoring & Budget)**
- [ ] **Fase 5: Infrastructure as Code (IaC) Vertaling**

---

## Fase 1: Governance & Beheershiërarchie (CAF)

Als eerste stap heb ik een robuuste beheerstructuur opgezet met behulp van **Azure Management Groups**. Dit zorgt voor een strikte scheiding tussen centrale platform-diensten en de daadwerkelijke applicatieworkloads.

### Ontworpen Hiërarchie (Management Groups & Subscriptions):
- **Tenant Root Group** (Overkoepelende Azure container)
  └── **WLCS-Root-MG** (Hoofdmap van de organisatie)
       ├── **WLCS-Platform-MG** (Gedeelde core-infrastructuur)
       │    └── 🟡 *Subscription: WLCS-Platform-Prod* (Centrale netwerkhub, DNS, logging & security)
       └── **WLCS-Workloads-MG** (Bedrijfsapplicaties & workloads)
            ├── **WLCS-Prod-MG** (Live productieomgevingen)
            │    └── ⚪ *(Toekomstig abonnement: WLCS-Logistics-Prod)*
            └── **WLCS-NonProd-MG** (Test-, acceptatie- en ontwikkelomgevingen)
                 └── 🟡 *Subscription: WLCS-Logistics-Dev* (Geïsoleerde sandbox voor applicatie-ontwikkeling)

### Architectuur Bewijs (Portal Implementatie)
Hieronder zie je de daadwerkelijke implementatie van deze hiërarchie binnen mijn Azure Tenant:

![WLCS Beheergroepen Hiërarchie](docs/screenshots/01-fase1-management-groups.png)

### Multi-Subscription & Omgevingsisolatie (CAF Best Practice)
Om te voldoen aan de strikte isolatierichtlijnen van het Cloud Adoption Framework (CAF), is er gekozen voor een multi-subscription model onder één centraal factureringsaccount. De abonnementen zijn als volgt verdeeld en gekoppeld aan de governance-hiërarchie:

- **WLCS-Platform-Prod** ➔ Gekoppeld aan `WLCS-Platform-MG` (Huisvest de centrale netwerkhub en gedeelde IT-services).
- **WLCS-Logistics-Dev** ➔ Gekoppeld aan `WLCS-NonProd-MG` (Geïsoleerde sandbox-omgeving voor de ontwikkeling en test van de logistieke applicaties).

![Enterprise Abonnementen Structuur](docs/screenshots/02-fase1-subscriptions-mapped.png)

---

## Identity & Access Management (RBAC & Least Privilege)
Om te voldoen aan de WAF-pijler **Security**, is toegang tot de cloudinfrastructuur strikt ingericht op basis van groepsidentiteiten (Microsoft Entra ID) en Role-Based Access Control (RBAC). Gebruikers krijgen nooit rechtstreeks rechten, maar worden lid gemaakt van functionele beveiligingsgroepen.

### Ingerichte RBAC-structuur:
- **sec-wlcs-network-admins** ➔ Heeft de rol `Network Contributor` (Inzender voor netwerken) op de `WLCS-Platform-MG`. Zij beheren uitsluitend de netwerkinfrastructuur.
- **sec-wlcs-sys-admins** ➔ Heeft de rol `Virtual Machine Contributor` (Inzender voor virtuele machines) op de `WLCS-Workloads-MG`. Zij beheren computing workloads.
- **sec-wlcs-security-auditors** ➔ Heeft de rol `Security Reader` (Beveiligingslezer) op de `WLCS-Root-MG` voor compliance-audits.

![Azure RBAC Toewijzing](docs/screenshots/06-fase1-rbac-assigned.png)

### Geautomatiseerde Groepsynchronisatie (WAF Cost Optimization & Operational Excellence)
Voor een realistische simulatie zijn **150 unieke Belgische medewerkers** via een bulk-import toegevoegd. Hoewel het CAF *Dynamic Groups* adviseert, vereist dit een Microsoft Entra ID P1-licentie per gebruiker. Om onnodige licentiekosten in deze opstartfase te elimineren (WAF Cost Optimization), is er gekozen voor een geautomatiseerde **DevOps-workaround**.

De afdelingsgroepen (`dept-wlcs-`) zijn ingesteld op het type `Toegewezen (Assigned)`. Vervolgens is de sortering volledig geautomatiseerd met een PowerShell-script (`scripts/sync-entra-users.ps1`) via de **Microsoft Graph PowerShell SDK**. Dit script leest de afdelings metadata uit en wijst gebruikers foutloos toe.

![PowerShell Console Output](docs/screenshots/08-fase1-powershell-output.png)

Het resultaat is een enterprise-waardige, gevulde mappenstructuur met unieke gebruikers:

![Entra ID Groepsleden Overzicht](docs/screenshots/07-fase1-group-members.png)

---

## Azure Policy & Cloud Governance (WAF Security & Operational Excellence)

Om wildgroei aan resources te voorkomen en kosten helder te alloceren, is er op het niveau van de `WLCS-Root-MG` een strikt governance-beleid afgedwongen met Azure Policy.

### 1. Proactieve Handhaving (Deny-fase)
De volgende policies zijn met het effect `Standaard (Deny)` geactiveerd:
- **WLCS - Toegestane locaties**: Garandeert dat alle resources binnen de primaire Azure-regio worden uitgerold om latency en cross-regio kosten te voorkomen.
- **WLCS - Vereis Tag: Environment / Project / Owner**: Verplicht het labelen van alle resources voor cost management en operational excellence.

![WLCS Azure Policy Overzicht](docs/screenshots/04-fase1-policy-assignments.png)

### 2. Regulatory Compliance & Europese Security Baseline (Audit-fase)
Als Europese KMO moet Waasland Logistics voldoen aan de GDPR. Hiervoor is het **ISO/IEC 27001:2022 Regulatory Compliance**-initiatief (58 regels) toegewezen in `Audit-modus` om continu de security-compliance te monitoren.

![WLCS Compliance Dashboard](docs/screenshots/05-fase1-compliance-dashboard.png)
