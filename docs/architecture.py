#!/usr/bin/env python3
"""Generate the platform architecture diagram using official Google Cloud icons.

This uses the ``diagrams`` library (https://diagrams.mingrammer.com), which
bundles the official Google Cloud Platform icon set (plus Argo CD, GitHub, and
Kubernetes icons) and renders through Graphviz (``dot``) under the hood. It
mirrors the Terraform-provisioned platform: GKE, Argo CD GitOps, External
Secrets Operator, ExternalDNS, cert-manager (DNS-01), Crossplane (GCP
providers), Cloud SQL, Artifact Registry, Secret Manager, and Cloud DNS.

Outputs ``architecture.png`` and ``architecture.svg`` next to this script.

Usage:
    pip install diagrams        # also requires the Graphviz "dot" binary
    python docs/architecture.py
"""

from __future__ import annotations

from pathlib import Path

from diagrams import Cluster, Diagram, Edge
from diagrams.gcp.compute import GKE, ComputeEngine
from diagrams.gcp.database import SQL
from diagrams.gcp.devtools import ContainerRegistry
from diagrams.gcp.network import DNS, LoadBalancing, VirtualPrivateCloud
from diagrams.gcp.security import Iam, SecretManager
from diagrams.gcp.storage import GCS
from diagrams.k8s.compute import Deploy
from diagrams.k8s.ecosystem import ExternalDns
from diagrams.k8s.network import Ingress
from diagrams.k8s.others import CRD
from diagrams.k8s.podconfig import Secret
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.client import User
from diagrams.onprem.gitops import Argocd
from diagrams.onprem.vcs import Github

OUTPUT = Path(__file__).with_name("architecture")

# Color palette (loosely aligned with GCP / tooling brand colors).
GCP_GREEN = "#34A853"
GCP_YELLOW = "#FBBC04"
GCP_RED = "#EA4335"
GCP_BLUE = "#4285F4"
ARGO_ORANGE = "#EF7B4D"
GITHUB_DARK = "#24292E"
TF_PURPLE = "#7B42BC"
XP_TEAL = "#0EA5A4"

GRAPH_ATTR = {
    "fontsize": "22",
    "labelloc": "t",
    "pad": "0.6",
    "nodesep": "0.5",
    "ranksep": "1.0",
    "bgcolor": "white",
    "splines": "spline",
}


def main() -> None:
    with Diagram(
        "SS2026-INENP-IaC \u2014 Platform Architecture",
        filename=str(OUTPUT),
        outformat=["png", "svg"],
        show=False,
        direction="LR",
        graph_attr=GRAPH_ATTR,
    ):
        operator = User("Operator\n(gcloud / terraform / kubectl)")
        end_user = User("End users\n(*.inenp.werschlan.at)")

        with Cluster("GitHub (MCCE-2025 org)"):
            iac_repo = Github("IaC repo\nSS2026-INENP-IaC")
            gitops_repo = Github("GitOps repo\nSS2026-INENP-GitOps")
            backend_repo = Github("backend repo\nSS2026-INENP-backend")
            frontend_repo = Github("frontend repo\nSS2026-INENP-frontend")
            github_app = Github("GitHub App\nargocd-gitops-reader")
            gh_actions = GithubActions("GitHub Actions\n(build & push images)")

        with Cluster("Terraform bootstrap (local state)"):
            state_bucket = GCS("GCS state bucket\nterraform-state-<project_id>")

        with Cluster("Google Cloud project"):
            with Cluster("Managed services (Terraform / existing)"):
                secret_manager = SecretManager(
                    "Secret Manager\nargocd-github-app-*\ncloud-sql-app-password\navwx-api-key"
                )
                cloud_dns = DNS("Cloud DNS\nmanaged zone (existing)")

            with Cluster("Crossplane-managed GCP resources"):
                gar_backend = ContainerRegistry(
                    "Artifact Registry\nweather-app-backend"
                )
                gar_frontend = ContainerRegistry(
                    "Artifact Registry\nweather-app-frontend"
                )
                cloud_sql = SQL(
                    "Cloud SQL weather-app-db\n+ database & user weather_app"
                )
                frontend_bucket = GCS(
                    "GCS bucket\nstatic.inenp.werschlan.at"
                )

            with Cluster("IAM / Workload Identity"):
                wif_pool = Iam("WIF pool github-actions\n(OIDC, repo-scoped)")
                sa_ci = Iam("GSA ci-image-push\nartifactregistry.writer")
                sa_eso = Iam("GSA external-secrets\nsecretAccessor")
                wi_extdns = Iam("WI external-dns\nroles/dns.admin")
                sa_certmgr = Iam("GSA cert-manager-dns\nroles/dns.admin")
                sa_xp = Iam("GSA crossplane providers\nGAR / SQL / Storage admin")
                sa_backend = Iam("GSA weather-app-backend\nroles/cloudsql.client")

            with Cluster("VPC platform-cluster-vpc"):
                subnet = VirtualPrivateCloud("Subnet\n10.10.0.0/24 (europe-west3)")
                nlb = LoadBalancing(
                    "L4 Network Load Balancer\n(from ingress-nginx Service\ntype=LoadBalancer)"
                )

                with Cluster(
                    "GKE: platform-gke-cluster\n(Workload Identity, Managed Prometheus)"
                ):
                    node_pool = ComputeEngine(
                        "Node pool e2-standard-2\nautoscaling, multi-zone HA"
                    )

                    with Cluster("namespace: argocd"):
                        argocd = Argocd("Argo CD\n(Helm release)")
                        project_platform = CRD("AppProject\nplatform")
                        project_apps = CRD("AppProject\napps")
                        root_app = Argocd("root Application\n(app-of-apps)")
                        repo_secrets = Secret("repo credentials\ngitops / backend / frontend")

                    with Cluster("namespace: external-secrets"):
                        eso = Deploy("External Secrets\nOperator (Helm)")
                        css = CRD("ClusterSecretStore\ngcp-secret-manager")

                    with Cluster("namespace: crossplane-system (via GitOps)"):
                        crossplane = Deploy("Crossplane\n(+ GCP providers)")
                        xp_providers = CRD("provider-gcp\nartifact / sql / storage")
                        xp_compositions = CRD(
                            "XRDs + Compositions\n(XFrontendHosting, …)"
                        )

                    with Cluster("namespace: cert-manager (via GitOps)"):
                        cert_manager = Deploy("cert-manager\n(DNS-01 ACME solver)")

                    with Cluster("namespace: external-dns (via GitOps)"):
                        external_dns = ExternalDns("ExternalDNS\n(deployed by Argo CD)")

                    with Cluster("namespace: ingress-nginx (via GitOps)"):
                        ingress_nginx = Deploy(
                            "ingress-nginx controller\n(shared entrypoint, class=nginx)"
                        )

                    with Cluster("namespaces: backend + tenants/*\n(auto-discovered)"):
                        app_ingress = Ingress(
                            "frontend Ingress\nweather / tenant-a / tenant-z / staging\n(TLS via cert-manager)"
                        )
                        frontend = Deploy("weather-app-frontend\n(ClusterIP)")
                        backend = Deploy(
                            "weather-app-backend\n(ClusterIP, + Cloud SQL Auth Proxy)"
                        )

        # --- Provisioning & operator flow ---------------------------------
        operator >> Edge(label="maintains") >> iac_repo
        operator >> Edge(label="1. bootstrap apply", style="dashed", color=TF_PURPLE) >> state_bucket
        iac_repo >> Edge(label="2. terraform apply", style="dashed", color=TF_PURPLE) >> node_pool
        state_bucket >> Edge(label="remote state", style="dotted", color=TF_PURPLE) >> iac_repo
        operator >> Edge(label="3. upload GitHub App + AVWX secrets", style="dashed", color=GCP_YELLOW) >> secret_manager

        # --- Networking ----------------------------------------------------
        subnet >> Edge(style="invis") >> node_pool

        # --- CI image build & push (Workload Identity Federation) ----------
        backend_repo >> Edge(style="invis") >> gh_actions
        frontend_repo >> Edge(style="invis") >> gh_actions
        gh_actions >> Edge(label="OIDC token", style="dashed", color=GITHUB_DARK) >> wif_pool
        wif_pool >> Edge(label="impersonate (WIF)", style="dotted", color=GCP_YELLOW) >> sa_ci
        sa_ci >> Edge(label="push images", color=GCP_BLUE) >> gar_backend
        sa_ci >> Edge(label="push images", color=GCP_BLUE) >> gar_frontend
        gar_backend >> Edge(label="pull images (node SA)", style="dotted", color=GCP_BLUE) >> node_pool

        # --- Argo CD / GitOps ---------------------------------------------
        argocd >> Edge(label="defines", color=ARGO_ORANGE) >> project_platform
        argocd >> Edge(label="defines", color=ARGO_ORANGE) >> project_apps
        argocd >> Edge(label="manages", color=ARGO_ORANGE) >> root_app
        root_app >> Edge(label="syncs apps from", color=ARGO_ORANGE) >> gitops_repo
        argocd >> Edge(label="clone via GitHub App", style="dashed", color=GITHUB_DARK) >> gitops_repo
        repo_secrets >> Edge(label="repo creds", color=ARGO_ORANGE) >> argocd
        github_app >> Edge(label="read access", style="dotted", color=GITHUB_DARK) >> gitops_repo
        root_app >> Edge(label="deploys", style="dashed", color=GCP_GREEN) >> crossplane
        root_app >> Edge(label="deploys", style="dashed", color=GCP_GREEN) >> cert_manager
        root_app >> Edge(label="deploys", style="dashed", color=GCP_GREEN) >> external_dns
        root_app >> Edge(label="deploys", style="dashed", color=GCP_GREEN) >> ingress_nginx
        root_app >> Edge(label="deploys", style="dashed", color=GCP_GREEN) >> frontend
        root_app >> Edge(label="deploys", style="dashed", color=GCP_GREEN) >> backend

        # --- North/south traffic & Cloud Load Balancing -------------------
        # The L4 NLB is provisioned by the ingress-nginx Service (type=LoadBalancer);
        # only the data path is drawn to keep the graph acyclic.
        end_user >> Edge(label="HTTPS", color=GCP_BLUE) >> cloud_dns
        cloud_dns >> Edge(label="resolves *.inenp.werschlan.at", style="dotted", color=GCP_GREEN) >> nlb
        nlb >> Edge(label="forwards :80/:443", color=GCP_BLUE) >> ingress_nginx
        ingress_nginx >> Edge(label="host/path routing", color=GCP_BLUE) >> app_ingress
        app_ingress >> Edge(label="/", color=GCP_BLUE) >> frontend
        app_ingress >> Edge(label="/api", color=GCP_BLUE) >> backend

        # --- External Secrets flow ----------------------------------------
        eso >> Edge(label="configures", color=GCP_RED) >> css
        css >> Edge(label="reads secrets (WI)", color=GCP_RED) >> secret_manager
        eso >> Edge(label="syncs repo creds", color=GCP_RED) >> repo_secrets
        sa_eso >> Edge(label="WI binding", style="dotted", color=GCP_YELLOW) >> eso

        # --- ExternalDNS ---------------------------------------------------
        external_dns >> Edge(label="upserts records (WI)", color=GCP_GREEN) >> cloud_dns
        wi_extdns >> Edge(label="WI binding", style="dotted", color=GCP_YELLOW) >> external_dns

        # --- cert-manager (DNS-01) ----------------------------------------
        cert_manager >> Edge(label="ACME TXT records (WI)", color=GCP_GREEN) >> cloud_dns
        sa_certmgr >> Edge(label="WI binding", style="dotted", color=GCP_YELLOW) >> cert_manager

        # --- Crossplane provisioning --------------------------------------
        crossplane >> Edge(label="renders", color=XP_TEAL) >> xp_compositions
        xp_compositions >> Edge(label="composes", style="dotted", color=XP_TEAL) >> xp_providers
        crossplane >> Edge(label="provisions", color=XP_TEAL) >> cloud_sql
        crossplane >> Edge(label="provisions", color=XP_TEAL) >> gar_backend
        crossplane >> Edge(label="provisions", color=XP_TEAL) >> gar_frontend
        crossplane >> Edge(label="provisions", color=XP_TEAL) >> frontend_bucket
        sa_xp >> Edge(label="WI binding", style="dotted", color=GCP_YELLOW) >> xp_providers
        secret_manager >> Edge(label="ESO syncs DB password", style="dotted", color=GCP_RED) >> cloud_sql

        # --- Backend Cloud SQL access -------------------------------------
        backend >> Edge(label="Auth Proxy (WI)", color=GCP_BLUE) >> cloud_sql
        sa_backend >> Edge(label="WI binding", style="dotted", color=GCP_YELLOW) >> backend


if __name__ == "__main__":
    main()
