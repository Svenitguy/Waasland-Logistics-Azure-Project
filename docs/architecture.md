# 🏛️ Technische Architectuur & Design Specificaties

Dit document bevat de gedetailleerde technische architectuur van de **Waasland Logistics & Cloud Services (WLCS)** Azure-omgeving, ontworpen volgens de best practices van het **Microsoft Cloud Adoption Framework (CAF)** en het **Well-Architected Framework (WAF)**.

---

## 1. Cloud Governance & Beheershiërarchie (CAF)
Om enterprise-isolatie en schaalbaarheid te garanderen, is er gekozen voor een **Multi-Subscription Model** aangestuurd via **Azure Management Groups**.

* **WLCS-Platform-Prod (Subscription)** ➔ Huisvest gedeelde transitdiensten (Hub VNet, Private DNS Zones).
* **WLCS-Logistics-Dev (Subscription)** ➔ Volledig geïsoleerde sandbox voor applicatie-ontwikkeling (Spoke VNet, Storage, VM's).

---

## 2. Identity & Access Management (RBAC)
Toegang is strikt ingericht volgens het principe van **Least Privilege** en gebaseerd op **Microsoft Entra ID**-groepen. 

*   `sec-wlcs-network-admins` ➔ Network Contributor op de Platform-MG.
*   `sec-wlcs-sys-admins` ➔ Virtual Machine Contributor op de Workloads-MG.

### 🤖 Identiteit- & Kostenautomatisering
Voor de simulatie van 150 medewerkers is een geautomatiseerde DevOps-workaround via de **Microsoft Graph PowerShell SDK** (`scripts/sync-entra-users.ps1`) gebouwd. Groepen zijn ingesteld op `Assigned` in plaats van dynamische licenties (Entra ID P1/P2 vereiste) om licentiekosten in de opstartfase te elimineren (WAF Cost Optimization).

---

## 3. Netwerk Architectuur (Hub-Spoke Topologie)

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
┌────────────────────────────────────────┐
│         Logistics Spoke VNet           │ (10.1.0.0/20)
│  - Web-Subnet     (10.1.1.0/24)        │
│  - App-Subnet     (10.1.2.0/24)        │ ──┐ (Private Connection)
│  - DB-Subnet 🔒   (10.1.3.0/24)        │   │
└────────────────────────────────────────┘   ▼
                                       ┌──────────────────────────────┐
                                       │    Private Endpoint Layer    │
                                       │  [pe-st-logistics-file-dev]  │
                                       └─────────────┬────────────────┘
                                                     │ (Microsoft Backbone)
                                                     ▼
                                       ┌──────────────────────────────┐
                                       │    Secure Azure Storage      │
                                       │  [stwlcslogisticsdev...]     │
                                       └──────────────────────────────┘
```

### 🛰️ Netwerksegmentatie & Terraform Modules
*   **Hub VNet (`vnet-wlcs-hub-prod-001`)**: Range `10.0.0.0/20`. Gereserveerd voor transitdiensten.
*   **Spoke VNet (`vnet-wlcs-logistics-dev-001`)**: Range `10.1.0.0/20`.
    *   *Micro-segmentatie (NSG)*: Het database-subnet (`10.1.3.0/24`) blokkeert via een NSG (`nsg-logistics-db-dev`) al het inkomend verkeer (`Deny-All-Other-Inbound`), met uitzondering van MS SQL-verkeer (poort 1433) afkomstig van het applicatiesubnet.

---

## 4. Gecentraliseerde & Beveiligde Opslag Architectuur (WAF Security)

Binnen Fase 3 is een ontkoppelde opslaginfrastructuur gerealiseerd via de Terraform-module `modules/storage`. Deze is specifiek ontworpen voor de veilige opslag van logistieke documenten (vrachtbrieven en pakbonnen).

### 🔒 Enterprise Protection Matrix
Toegang tot de data is op vier lagen gecodeerd en beveiligd conform de **Zero Trust**-architectuur van het Well-Architected Framework:

1. **Storage Compartimentering:** Het Azure Storage Account is geconfigureerd met `Standard_LRS` voor kostenefficiënte lokale redundantie. TLS 1.2 is hard afgedwongen en `allow_nested_items_to_be_public` staat op `false`.
2. **Netwerk Firewall Isolation:** De `network_rules` zijn ingesteld op `default_action = "Deny"`. Alleen vertrouwde Microsoft-services hebben een bypass. De publieke data-ingang is hiermee volledig gesloten.
3. **Private Endpoint Inrichting:** Er is een **Azure Private Endpoint** (`pe-st-logistics-file-dev-001`) geplaatst binnen het applicatiesubnet (`10.1.2.0/24`). Verkeer van de applicatieservers naar de fileshare verloopt via een intern IP-adres binnen het VNet. De data reist uitsluitend over de private backbone van Microsoft en omzeilt het openbare internet.
4. **Private DNS Resolutie:** Er is een centrale **Private DNS Zone** (`privatelink.file.core.windows.net`) uitgerold in de platform-laag en via een `virtual_network_link` gekoppeld aan het Spoke VNet. Dit garandeert dat interne applicatieaanroepen naar de storage URL automatisch en naadloos worden omgezet naar het private IP-adres van het endpoint.

---

## 5. Deployment & State Management (IaC & CI/CD)

### 🔒 Remote State Backend & State Isolation
De Terraform state wordt opgeslagen in een Azure Blob Storage Container (`tfstate`) binnen `rg-wlcs-tfstate-prod-001`. Er is gekozen voor strikte **State Isolation** door het project op te splitsen in twee onafhankelijke lagen om wildgroei aan kosten te voorkomen:
* `01_base` ➔ Huisvest de permanente netwerkbasis en de opslagmodule.
* `02_addons` ➔ Huisvest de tijdelijke, kostbare add-on schil (**Azure Bastion Basic SKU**).

### 🚀 CI/CD GitHub Actions Pipeline & FinOps Controls
De uitrol-pipeline (`terraform-deploy.yml`) maakt gebruik van passwordless OIDC-authenticatie gekoppeld aan een stabiele Azure `development` omgevingsreferentie.

* **FinOps Gate:** Bij een reguliere code-push worden speculatieve plannen gemaakt. Job 3 (`apply_base`) vereist een handmatige goedkeuring via de GitHub UI om de core-basis bij te werken. Job 4 (`apply_addons`) wordt dankzij een custom `workflow_dispatch` conditie standaard op **SKIP** gezet, waardoor Azure Bastion-kosten op nul blijven staan.
* **On-Demand Activation:** De engineer kan via de "Run workflow" knop in GitHub de addons handmatig starten voor tijdelijk beheer via RDP/SSH over HTTPS.
* **Geautomatiseerde Nachtwacht:** Een parallelle destroy-pipeline (`terraform-destroy.yml`) start elke werkdag om 17:00 UTC via een **cron-job** om uitsluitend de `02_addons`-stack te vernietigen, wat resulteert in een **kostenbesparing van ruim 70%** op de Bastion host!
